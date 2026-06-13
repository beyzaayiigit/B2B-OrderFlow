import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

bool _isMissingPlugin(Object e) {
  if (e is MissingPluginException) return true;
  final s = e.toString();
  return s.contains('MissingPluginException') ||
      s.contains('No implementation found for method share');
}

/// Mobil / masaüstü (dart:io): önce paylaşım; [share_plus] bağlı değilse dosya kaydı.
/// Dönüş: `null` = paylaşım açıldı; boş string = [file_saver] ile kaydedildi (konum OS’e bağlı);
/// dolu string = tam dosya yolu (uygulama belgelerine kopyalandı).
Future<String?> shareExcelWorkbookBytes(
  List<int> raw,
  String fileBase,
  String subjectAndTitle,
) async {
  final bytes = Uint8List.fromList(raw);
  final dir = await getTemporaryDirectory();
  final path = p.join(
    dir.path,
    '${fileBase}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
  );
  await File(path).writeAsBytes(bytes, flush: true);

  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            mimeType: _xlsxMime,
            name: '$fileBase.xlsx',
          ),
        ],
        fileNameOverrides: ['$fileBase.xlsx'],
        subject: subjectAndTitle,
        title: subjectAndTitle,
        downloadFallbackEnabled: true,
      ),
    );
  } catch (e) {
    if (!_isMissingPlugin(e)) rethrow;
    try {
      await FileSaver.instance.saveFile(
        name: fileBase,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      return '';
    } catch (_) {
      final downloads = await getDownloadsDirectory();
      final targetDir = downloads ?? await getApplicationDocumentsDirectory();
      final outPath = p.join(targetDir.path, '$fileBase.xlsx');
      await File(outPath).writeAsBytes(bytes, flush: true);
      return outPath;
    }
  }
  return null;
}
