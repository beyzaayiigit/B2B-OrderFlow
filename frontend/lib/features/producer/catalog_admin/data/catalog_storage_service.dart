import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/config/supabase_bootstrap.dart';
import '../../../catalog/data/catalog_repository.dart';

class CatalogStorageUsage {
  const CatalogStorageUsage({
    required this.usedBytes,
    required this.quotaBytes,
  });

  final int usedBytes;
  final int quotaBytes;

  double get ratio =>
      quotaBytes <= 0 ? 0 : (usedBytes / quotaBytes).clamp(0.0, 1.0);

  int get remainingBytes => (quotaBytes - usedBytes).clamp(0, quotaBytes);

  bool get isNearLimit => ratio >= 0.8;

  bool get isFull => usedBytes >= quotaBytes;
}

class CatalogStorageQuotaExceeded implements Exception {
  const CatalogStorageQuotaExceeded(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Üretici şirket prefix'i altındaki `catalog-images` kullanımı.
class CatalogStorageService {
  CatalogStorageService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;
  static const _bucket = 'catalog-images';

  Future<String> _companyId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const CatalogFailure('Oturum bulunamadı.');
    final row = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) throw const CatalogFailure('Profil bulunamadı.');
    return row['company_id'] as String;
  }

  Future<CatalogStorageUsage> fetchUsage() async {
    final companyId = await _companyId();
    final quota = AppEnv.storageQuotaBytes;
    final db = await _sumFromDatabase(companyId);
    final listed = await _sumFromStorageList(companyId);
    final fromUrls = await _sumFromImageUrls(companyId);
    final used = [db, listed, fromUrls].reduce((a, b) => a > b ? a : b);
    return CatalogStorageUsage(usedBytes: used, quotaBytes: quota);
  }

  Future<void> ensureCanAdd(int additionalBytes) async {
    if (additionalBytes <= 0) return;
    final usage = await fetchUsage();
    if (usage.usedBytes + additionalBytes > usage.quotaBytes) {
      throw CatalogStorageQuotaExceeded(
        'Depolama kotası dolu (${formatStorageMb(usage.usedBytes)} / '
        '${formatStorageGb(usage.quotaBytes)}). Eski görselleri silin veya '
        'daha küçük fotoğraf seçin.',
      );
    }
  }

  Future<int> _sumFromDatabase(String companyId) async {
    try {
      final variants = await _client
          .from('catalog_color_variants')
          .select(
            'file_size_bytes, catalog_models!inner(producer_company_id)',
          )
          .eq('catalog_models.producer_company_id', companyId);

      var sum = 0;
      for (final row in variants as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        sum += (map['file_size_bytes'] as int?) ?? 0;
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _sumFromStorageList(String companyId) async {
    try {
      return await _walkList(companyId);
    } catch (_) {
      return 0;
    }
  }

  Future<int> _sumFromImageUrls(String companyId) async {
    try {
      final rows = await _client
          .from('catalog_color_variants')
          .select(
            'image_url, catalog_models!inner(producer_company_id)',
          )
          .eq('catalog_models.producer_company_id', companyId);

      final storage = _client.storage.from(_bucket);
      var sum = 0;
      final seen = <String>{};

      for (final row in rows as List<dynamic>) {
        final url = (row as Map<String, dynamic>)['image_url'] as String?;
        final objectPath = pathFromPublicUrl(url);
        if (objectPath == null || !seen.add(objectPath)) continue;
        try {
          final info = await storage.info(objectPath);
          sum += info.size ?? 0;
        } catch (_) {
          // Dosya silinmiş veya erişim yok.
        }
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  String? pathFromPublicUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final marker = '/storage/v1/object/public/$_bucket/';
    final i = url.indexOf(marker);
    if (i < 0) return null;
    return Uri.decodeComponent(url.substring(i + marker.length));
  }

  /// Model klasöründeki tüm görselleri siler (`{companyId}/{modelCode}/`).
  Future<void> deleteModelFolder({
    required String companyId,
    required String modelCode,
  }) async {
    final prefix = '$companyId/${modelCode.trim()}';
    final paths = await _collectFilePaths(prefix);
    if (paths.isEmpty) return;
    await _client.storage.from(_bucket).remove(paths);
  }

  /// Klasörde kalmaması gereken dosyaları temizler (renk silme / URL değişimi).
  Future<void> syncModelFolder({
    required String companyId,
    required String modelCode,
    required Iterable<String?> keepUrls,
  }) async {
    final keepPaths = keepUrls
        .map(pathFromPublicUrl)
        .whereType<String>()
        .toSet();
    final prefix = '$companyId/${modelCode.trim()}';
    final allPaths = await _collectFilePaths(prefix);
    final toRemove =
        allPaths.where((path) => !keepPaths.contains(path)).toList();
    if (toRemove.isEmpty) return;
    await _client.storage.from(_bucket).remove(toRemove);
  }

  Future<List<String>> _collectFilePaths(String path) async {
    try {
      final storage = _client.storage.from(_bucket);
      final entries = await storage.list(path: path);
      final paths = <String>[];

      for (final entry in entries) {
        final fullPath = path.isEmpty ? entry.name : '$path/${entry.name}';
        final isFile = entry.id != null || _looksLikeFile(entry.name);

        if (isFile) {
          paths.add(fullPath);
          continue;
        }

        if (!entry.name.contains('.')) {
          paths.addAll(await _collectFilePaths(fullPath));
        }
      }
      return paths;
    } catch (_) {
      return [];
    }
  }

  Future<int> _walkList(String path) async {
    final storage = _client.storage.from(_bucket);
    final entries = await storage.list(path: path);
    var sum = 0;

    for (final entry in entries) {
      final fullPath = path.isEmpty ? entry.name : '$path/${entry.name}';
      final isFile = entry.id != null || _looksLikeFile(entry.name);

      if (isFile) {
        var size = _entrySizeBytes(entry);
        if (size == 0) {
          try {
            final info = await storage.info(fullPath);
            size = info.size ?? 0;
          } catch (_) {}
        }
        sum += size;
        continue;
      }

      if (!entry.name.contains('.')) {
        sum += await _walkList(fullPath);
      }
    }
    return sum;
  }

  bool _looksLikeFile(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1;
  }

  int _entrySizeBytes(FileObject entry) {
    final meta = entry.metadata;
    if (meta != null) {
      for (final key in ['size', 'contentLength', 'content_length']) {
        final raw = meta[key];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
      }
    }
    return 0;
  }
}

String formatStorageMb(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1 && bytes > 0) return '< 0,1 MB';
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
}

String formatStorageGb(int bytes) {
  final gb = bytes / (1024 * 1024 * 1024);
  if (gb >= 1) {
    return '${gb.toStringAsFixed(gb >= 10 ? 1 : 2)} GB';
  }
  return formatStorageMb(bytes);
}
