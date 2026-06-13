import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../producer/catalog_admin/data/catalog_storage_service.dart';
import '../domain/product_model.dart';
import 'catalog_repository.dart';
import 'catalog_status_mapper.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseClient get _client => SupabaseBootstrap.client;

  static const _bucket = 'catalog-images';

  Future<Map<String, dynamic>> _profileRow() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const CatalogFailure('Oturum bulunamadı.');
    final row = await _client
        .from('profiles')
        .select('company_id, role')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) {
      throw const CatalogFailure('Profil bulunamadı.');
    }
    return row;
  }

  @override
  Future<List<ProductModel>> fetchCatalog() async {
    try {
      final rows = await _client
          .from('catalog_models')
          .select(
            'id, code, name, category, status, '
            'catalog_color_variants(id, color_name, image_url, sort_order)',
          )
          .order('sort_order', ascending: true);

      final list = rows as List<dynamic>;
      return list.map(_mapModel).toList();
    } on PostgrestException catch (e) {
      throw CatalogFailure(e.message);
    } catch (e) {
      if (e is CatalogFailure) rethrow;
      throw CatalogFailure('Katalog yüklenemedi: $e');
    }
  }

  ProductModel _mapModel(dynamic row) {
    final map = row as Map<String, dynamic>;
    final variantsRaw = map['catalog_color_variants'] as List<dynamic>? ?? [];
    final sortedRaw = [...variantsRaw]
      ..sort((a, b) {
        final sa = (a as Map)['sort_order'] as int? ?? 0;
        final sb = (b as Map)['sort_order'] as int? ?? 0;
        return sa.compareTo(sb);
      });

    final category = map['category'] as String? ?? '';
    final sortedVariants = sortedRaw.map((v) {
      final vm = v as Map<String, dynamic>;
      final url = (vm['image_url'] as String?)?.trim() ?? '';
      final colorName = vm['color_name'] as String? ?? '';
      return ProductColorVariant(
        id: vm['id'] as String?,
        colorName: colorName,
        imageAsset: url.isNotEmpty
            ? url
            : catalogPlaceholderAsset(category, colorName),
      );
    }).toList();

    return ProductModel(
      id: map['id'] as String?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      status: CatalogStatusMapper.toUi(map['status'] as String? ?? 'draft'),
      colorVariants: sortedVariants,
    );
  }

  String _colorSlug(String colorName) {
    final lower = colorName.trim().toLowerCase();
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return slug.isEmpty ? 'renk' : slug;
  }

  Future<({String url, int byteSize})?> _uploadLocalImage({
    required String companyId,
    required String modelCode,
    required String colorName,
    required String localPath,
  }) async {
    if (localPath.startsWith('http') || localPath.startsWith('assets/')) {
      return null;
    }
    if (kIsWeb) return null;

    final file = File(localPath);
    if (!await file.exists()) return null;

    final ext = _extension(localPath);
    final path =
        '$companyId/${modelCode.trim()}/${_colorSlug(colorName)}.$ext';
    final bytes = await file.readAsBytes();
    await CatalogStorageService(client: _client).ensureCanAdd(bytes.length);
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _mimeForExt(ext),
          ),
        );
    final url = _client.storage.from(_bucket).getPublicUrl(path);
    return (url: url, byteSize: bytes.length);
  }

  String _extension(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return 'jpg';
    final ext = path.substring(i + 1).toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Future<List<String>> fetchActiveCategoryNames() async {
    try {
      final rows = await _client
          .from('catalog_categories')
          .select('name')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return (rows as List<dynamic>)
          .map((r) => (r as Map<String, dynamic>)['name'] as String? ?? '')
          .where((name) => name.trim().isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      throw CatalogFailure(e.message);
    } catch (e) {
      if (e is CatalogFailure) rethrow;
      throw CatalogFailure('Kategoriler yüklenemedi: $e');
    }
  }

  @override
  Future<void> upsertProduct(ProductModel product, {required bool isNew}) async {
    try {
      final profile = await _profileRow();
      final role = profile['role'] as String?;
      if (role != 'producer') {
        throw const CatalogFailure('Yalnızca üretici katalog düzenleyebilir.');
      }
      final companyId = profile['company_id'] as String;

      final resolvedVariants = <({
        ProductColorVariant variant,
        int? fileSizeBytes,
      })>[];
      for (final v in product.colorVariants) {
        var imageUrl = v.imageAsset;
        int? fileSizeBytes;
        if (!imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
          final uploaded = await _uploadLocalImage(
            companyId: companyId,
            modelCode: product.code,
            colorName: v.colorName,
            localPath: imageUrl,
          );
          if (uploaded != null) {
            imageUrl = uploaded.url;
            fileSizeBytes = uploaded.byteSize;
          }
        } else if (imageUrl.startsWith('assets/')) {
          imageUrl = '';
        }
        resolvedVariants.add((
          variant: ProductColorVariant(
            id: v.id,
            colorName: v.colorName,
            imageAsset: imageUrl,
          ),
          fileSizeBytes: fileSizeBytes,
        ));
      }

      for (final entry in resolvedVariants) {
        final url = entry.variant.imageAsset.trim();
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          throw const CatalogFailure(
            'Her renk için galeri veya kameradan fotoğraf seçin.',
          );
        }
      }

      final dbStatus = CatalogStatusMapper.toDb(product.status);
      String modelId = product.id ?? '';
      final oldSizesByColor = <String, int>{};

      if (!isNew && modelId.isNotEmpty) {
        final oldRows = await _client
            .from('catalog_color_variants')
            .select('color_name, file_size_bytes')
            .eq('model_id', modelId);
        for (final row in oldRows as List<dynamic>) {
          final map = row as Map<String, dynamic>;
          final name = map['color_name'] as String? ?? '';
          oldSizesByColor[name] = (map['file_size_bytes'] as int?) ?? 0;
        }
      }

      if (isNew || modelId.isEmpty) {
        final inserted = await _client
            .from('catalog_models')
            .insert({
              'producer_company_id': companyId,
              'code': product.code.trim(),
              'name': product.name.trim(),
              'category': product.category,
              'status': dbStatus,
            })
            .select('id')
            .single();
        modelId = inserted['id'] as String;
      } else {
        await _client.from('catalog_models').update({
          'name': product.name.trim(),
          'category': product.category,
          'status': dbStatus,
        }).eq('id', modelId);
        await _client
            .from('catalog_color_variants')
            .delete()
            .eq('model_id', modelId);
      }

      for (var i = 0; i < resolvedVariants.length; i++) {
        final entry = resolvedVariants[i];
        final v = entry.variant;
        final url = v.imageAsset.startsWith('http') ? v.imageAsset : null;
        final size = entry.fileSizeBytes ??
            oldSizesByColor[v.colorName.trim()] ??
            (url != null ? oldSizesByColor[v.colorName] : null);
        await _client.from('catalog_color_variants').insert({
          'model_id': modelId,
          'color_name': v.colorName.trim(),
          'image_url': url,
          'sort_order': i + 1,
          if (size != null && size > 0) 'file_size_bytes': size,
        });
      }

      final storage = CatalogStorageService(client: _client);
      final keepUrls = resolvedVariants
          .map((e) => e.variant.imageAsset)
          .where((url) => url.startsWith('http'))
          .toList();
      await storage.syncModelFolder(
        companyId: companyId,
        modelCode: product.code,
        keepUrls: keepUrls,
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const CatalogFailure('Bu model kodu zaten kullanılıyor.');
      }
      throw CatalogFailure(e.message);
    } catch (e) {
      if (e is CatalogFailure) rethrow;
      throw CatalogFailure('Kayıt başarısız: $e');
    }
  }

  @override
  Future<void> deleteByCode(String code) async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'producer') {
        throw const CatalogFailure('Yalnızca üretici silebilir.');
      }
      final companyId = profile['company_id'] as String;
      final trimmed = code.trim();

      await CatalogStorageService(client: _client).deleteModelFolder(
        companyId: companyId,
        modelCode: trimmed,
      );
      await _client.from('catalog_models').delete().eq('code', trimmed);
    } on PostgrestException catch (e) {
      throw CatalogFailure(e.message);
    }
  }
}
