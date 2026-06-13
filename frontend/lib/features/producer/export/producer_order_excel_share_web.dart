import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

bool _isMissingPlugin(Object e) {
  final s = e.toString();
  return s.contains('MissingPluginException') ||
      s.contains('No implementation found for method share');
}

/// Web: paylaşım; olmazsa indirme / dosya kaydetme.
/// Dönüş: `null` = paylaşım; boş string = [file_saver]; dolu string web’de kullanılmıyor.
Future<String?> shareExcelWorkbookBytes(
  List<int> raw,
  String fileBase,
  String subjectAndTitle,
) async {
  final bytes = Uint8List.fromList(raw);
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
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
    await FileSaver.instance.saveFile(
      name: fileBase,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
    return '';
  }
  return null;
}
