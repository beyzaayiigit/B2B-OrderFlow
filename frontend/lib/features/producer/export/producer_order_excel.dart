import 'dart:io';

import 'package:excel_community/excel_community.dart' as xl;
import 'package:excel_community/excel_community.dart' show Excel, CellIndex, TextCellValue, IntCellValue, CellStyle, ExcelColor, HorizontalAlign, VerticalAlign, TextWrapping, ExcelImage, ExcelImageType, ImageAnchor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'producer_order_excel_share_io.dart'
    if (dart.library.html) 'producer_order_excel_share_web.dart' as share_impl;

import '../../../core/config/supabase_bootstrap.dart';
import '../domain/producer_order.dart';

/// Üretici sipariş özet şablonuna yakın Excel üretimi.
/// Beden oranları artık siparişte saklanıyor; Excel'e birebir yazılır.
abstract final class ProducerOrderExcelExport {
  static const _sizeLabels = ['S', 'M', 'L', 'XL', 'XXL'];

  /// Excel sol sarı birleşik hücre + önizleme: alıcı sipariş notu.
  static const excelNotesEmptyPlaceholder =
      'Sipariş notu henüz girilmedi. Alıcı tarafında sipariş oluştururken veya '
      'takip detayından eklenebilir.';

  static List<String> get sizeLabels => List.unmodifiable(_sizeLabels);

  /// [buyerNote] doluysa aynen; boşsa [excelNotesEmptyPlaceholder].
  static String effectiveNotesForExport(String? buyerNote) {
    final t = buyerNote?.trim();
    if (t == null || t.isEmpty) return excelNotesEmptyPlaceholder;
    return t;
  }

  static String excelImageCaption(ProducerOrder order) =>
      'Ürün: ${order.product.code}\n${order.product.name}';

  /// Verilen renk için beden oranlarını [_sizeLabels] sırasıyla döndürür.
  static List<int> sizeRatiosForColor(ProducerOrder order, String colorName) {
    final ratios = order.colorSizeRatios[colorName] ?? {};
    return _sizeLabels.map((s) => ratios[s] ?? 0).toList();
  }

  static bool _looksLikeXlsx(List<int> bytes) {
    return bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  static String orderedByLabel(ProducerOrder order) {
    final name = order.orderedByName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return order.buyerCompany;
  }

  /// Sunucuda exceljs ile üretilmiş .xlsx baytları; başarısızsa `null`.
  static Future<List<int>?> _fetchWorkbookFromEdge(
    ProducerOrder order,
  ) async {
    if (!SupabaseBootstrap.isInitialized) return null;

    try {
      final body = <String, dynamic>{
        'producer_order_no': order.code,
      };

      final res = await SupabaseBootstrap.client.functions.invoke(
        'generate-order-excel',
        body: body,
      );

      if (res.status != 200) {
        debugPrint(
          'generate-order-excel HTTP ${res.status}: ${res.data}',
        );
        return null;
      }

      final data = res.data;
      List<int>? bytes;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = data;
      }

      if (bytes != null && _looksLikeXlsx(bytes)) {
        debugPrint(
          'ProducerOrderExcelExport: edge workbook ${bytes.length} bytes',
        );
        return bytes;
      }

      debugPrint(
        'ProducerOrderExcelExport: unexpected edge response ${data.runtimeType}',
      );
      return null;
    } catch (e, st) {
      debugPrint('ProducerOrderExcelExport edge: $e\n$st');
      return null;
    }
  }

  static Future<List<int>?> _buildWorkbookLocally(
    ProducerOrder order, {
    required BuildContext context,
  }) async {
    final buyerNote = order.buyerNote;

    Uint8List? imageBytes;
    ExcelImageType? imageType;
    try {
      final result = await _loadProductImage(order);
      imageBytes = result.$1;
      imageType = result.$2;
      debugPrint(
        'ProducerOrderExcelExport: local image ${imageBytes?.length ?? 0} bytes',
      );
    } catch (e) {
      debugPrint('ProducerOrderExcelExport: image load failed: $e');
    }

    if (context.mounted && (imageBytes == null || imageBytes.isEmpty)) {
      final src = order.product.imageAssetPreferringColors(
        order.colorBreakdown.keys,
      );
      if (src.startsWith('http://') || src.startsWith('https://')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün görseli yerel Excel\'e eklenemedi; sunucu üretimi deneyin.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    try {
      return buildWorkbook(
        order,
        buyerExcelNote: buyerNote,
        productImageBytes: imageBytes,
        productImageType: imageType,
      );
    } catch (e, st) {
      debugPrint('ProducerOrderExcelExport.buildWorkbook: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel oluşturulamadı: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  static Future<void> share(
    BuildContext context,
    ProducerOrder order,
  ) async {
    final safeName = order.code.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final outName = 'Siparis_$safeName';
    final title = 'Sipariş ${order.code}';

    List<int>? raw = await _fetchWorkbookFromEdge(order);

    if (raw == null || raw.isEmpty) {
      if (SupabaseBootstrap.isInitialized && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sunucu Excel üretilemedi; yerel şablon deneniyor. '
              'Görsel sorunu için generate-order-excel fonksiyonunu deploy edin.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      raw = await _buildWorkbookLocally(
        order,
        context: context,
      );
    }

    if (raw == null || raw.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel oluşturulamadı (boş dosya).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final fallback = await share_impl.shareExcelWorkbookBytes(
        raw,
        outName,
        title,
      );
      if (context.mounted && fallback != null) {
        final msg = fallback.isEmpty
            ? 'Paylaşım kullanılamadı; Excel kaydedildi. İndirilenler veya Dosyalar uygulamasından kontrol edin.'
            : 'Paylaşım kullanılamadı; Excel şu konuma kaydedildi:\n$fallback';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('ProducerOrderExcelExport.share: $e\n$st');
      if (context.mounted) {
        final es = e.toString();
        final isPlugin = es.contains('MissingPluginException') ||
            es.contains('No implementation found for method share');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPlugin
                  ? 'Excel dışa aktarılamadı (yerel eklenti yok). Uygulamayı cihazdan kaldırıp yeniden yükleyin veya tam derleme: flutter clean && flutter run.'
                  : 'Excel paylaşımı başarısız: $e',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    }
  }

  static ExcelImageType _detectImageType(String source) {
    final lower = source.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return ExcelImageType.jpeg;
    }
    if (lower.endsWith('.gif')) return ExcelImageType.gif;
    if (lower.endsWith('.bmp')) return ExcelImageType.bmp;
    if (lower.endsWith('.webp')) return ExcelImageType.webp;
    // Supabase URLs may not have extension; check content-type header
    // during download. Default to PNG.
    return ExcelImageType.png;
  }

  static const _storageBucket = 'catalog-images';

  /// Supabase Storage public/authenticated URL → bucket içi dosya yolu.
  static String? _storagePathFromUrl(Uri uri) {
    final segments = uri.pathSegments;
    final bucketIdx = segments.indexOf(_storageBucket);
    if (bucketIdx < 0 || bucketIdx >= segments.length - 1) return null;
    return segments.sublist(bucketIdx + 1).join('/');
  }

  static bool _isSupabaseStorageUrl(String source) {
    if (!source.startsWith('http')) return false;
    final uri = Uri.tryParse(source);
    if (uri == null) return false;
    return uri.path.contains('/storage/v1/object/') &&
        uri.pathSegments.contains(_storageBucket);
  }

  static Future<Uint8List?> _downloadFromSupabaseStorage(String source) async {
    if (!SupabaseBootstrap.isInitialized) return null;
    final uri = Uri.parse(source);
    final path = _storagePathFromUrl(uri);
    if (path == null || path.isEmpty) return null;
    try {
      final bytes = await SupabaseBootstrap.client.storage
          .from(_storageBucket)
          .download(path);
      if (bytes.isNotEmpty) {
        debugPrint(
          'ProducerOrderExcelExport: Supabase storage download ok '
          '($path, ${bytes.length} bytes)',
        );
        return bytes;
      }
    } catch (e) {
      debugPrint(
        'ProducerOrderExcelExport: Supabase storage download failed: $e',
      );
    }
    return null;
  }

  static Future<http.Response> _httpGetWithOptionalAuth(Uri uri) async {
    final headers = <String, String>{};
    if (SupabaseBootstrap.isInitialized) {
      final token =
          SupabaseBootstrap.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
  }

  static ExcelImageType _imageTypeFromContentType(
    String contentType,
    String fallbackSource,
  ) {
    if (contentType.contains('jpeg') || contentType.contains('jpg')) {
      return ExcelImageType.jpeg;
    }
    if (contentType.contains('gif')) return ExcelImageType.gif;
    if (contentType.contains('webp')) return ExcelImageType.webp;
    if (contentType.contains('png')) return ExcelImageType.png;
    return _detectImageType(fallbackSource);
  }

  static Future<(Uint8List?, ExcelImageType?)> _loadProductImage(
    ProducerOrder order,
  ) async {
    final source = order.product.imageAssetPreferringColors(
      order.colorBreakdown.keys,
    );
    debugPrint('ProducerOrderExcelExport: loading image from: $source');

    if (source.isEmpty) return (null, null);

    if (source.startsWith('assets/')) {
      final data = await rootBundle.load(source);
      return (
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        _detectImageType(source),
      );
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      Uint8List? bytes;
      String contentType = '';

      if (_isSupabaseStorageUrl(source)) {
        bytes = await _downloadFromSupabaseStorage(source);
      }

      if (bytes == null || bytes.isEmpty) {
        final response = await _httpGetWithOptionalAuth(Uri.parse(source));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          bytes = response.bodyBytes;
          contentType = response.headers['content-type'] ?? '';
          debugPrint(
            'ProducerOrderExcelExport: HTTP ${response.statusCode}, '
            'bytes=${bytes.length}',
          );
        } else {
          debugPrint(
            'ProducerOrderExcelExport: HTTP failed ${response.statusCode}',
          );
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        final type = contentType.isNotEmpty
            ? _imageTypeFromContentType(contentType, source)
            : _detectImageType(source);
        return (bytes, type);
      }
      return (null, null);
    }

    final file = File(source);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return (bytes, _detectImageType(source));
    }
    debugPrint('ProducerOrderExcelExport: file not found: $source');
    return (null, null);
  }

  /// Ham .xlsx baytları; hata durumunda `null`.
  static List<int>? buildWorkbook(
    ProducerOrder order, {
    String? buyerExcelNote,
    Uint8List? productImageBytes,
    ExcelImageType? productImageType,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Sipariş';
    final defaultName = excel.getDefaultSheet();
    excel.rename(defaultName ?? excel.tables.keys.first, sheetName);
    final sheet = excel[sheetName];

    final thin = xl.Border(borderStyle: xl.BorderStyle.Thin);

    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.yellow,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );
    final valueStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );
    final tableHeader = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.yellow,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );
    final footerRed = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.red,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );
    final footerYellow = CellStyle(
      backgroundColorHex: ExcelColor.yellow,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );

    final dateStr = DateFormat('dd.MM.yyyy').format(order.orderedAt);

    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      TextCellValue('MODEL KODU'),
      cellStyle: labelStyle,
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
      TextCellValue(order.product.code),
      cellStyle: labelStyle,
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
      TextCellValue('SİPARİŞ TARİHİ'),
      cellStyle: labelStyle,
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      TextCellValue(dateStr),
      cellStyle: labelStyle,
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
    );

    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      TextCellValue('MODEL İSMİ'),
      cellStyle: labelStyle,
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      TextCellValue(order.product.name),
      cellStyle: valueStyle,
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bold: true,
        leftBorder: thin,
        rightBorder: thin,
        topBorder: thin,
        bottomBorder: thin,
      ),
    );

    final notesBody = effectiveNotesForExport(buyerExcelNote);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      TextCellValue(notesBody),
      cellStyle: CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        fontSize: 11,
        leftBorder: thin,
        rightBorder: thin,
        topBorder: thin,
        bottomBorder: thin,
      ),
    );
    const imageRowStart = 2;
    const imageRowEnd = 10;
    const captionRow = 11;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: imageRowStart),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: imageRowEnd),
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: imageRowStart),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: imageRowEnd),
    );

    final imgCaption = excelImageCaption(order);
    final hasImage =
        productImageBytes != null && productImageBytes.isNotEmpty;

    if (!hasImage) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: imageRowStart),
        TextCellValue(imgCaption),
        cellStyle: CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
          backgroundColorHex: ExcelColor.grey50,
          fontSize: 11,
          leftBorder: thin,
          rightBorder: thin,
          topBorder: thin,
          bottomBorder: thin,
        ),
      );
    } else {
      sheet.addImage(ExcelImage(
        imageBytes: productImageBytes,
        imageType: productImageType ?? ExcelImageType.png,
        anchor: ImageAnchor.fromPixels(
          column: 3,
          row: imageRowStart,
          widthPixels: 248,
          heightPixels: 198,
        ),
      ));
    }

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: captionRow),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: captionRow),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: captionRow),
      TextCellValue(hasImage ? imgCaption : ''),
      cellStyle: CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        backgroundColorHex: ExcelColor.grey50,
        fontSize: 10,
        bold: true,
        leftBorder: thin,
        rightBorder: thin,
        topBorder: thin,
        bottomBorder: thin,
      ),
    );

    const tableTop = 13;
    final headers = <String>[
      'SİPARİŞ VEREN',
      'RENK',
      'ADET',
      ..._sizeLabels,
    ];
    for (var c = 0; c < headers.length; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: tableTop),
        TextCellValue(headers[c]),
        cellStyle: tableHeader,
      );
    }

    final orderer = orderedByLabel(order);
    final colors = order.colorBreakdown.entries.toList();
    for (var i = 0; i < colors.length; i++) {
      final r = tableTop + 1 + i;
      final colorName = colors[i].key;
      final adet = colors[i].value;
      final sizes = sizeRatiosForColor(order, colorName);

      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
        TextCellValue(i == 0 ? orderer : ''),
        cellStyle: valueStyle,
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r),
        TextCellValue(colorName.toUpperCase()),
        cellStyle: valueStyle,
      );
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r),
        IntCellValue(adet),
        cellStyle: valueStyle,
      );
      for (var s = 0; s < 5; s++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3 + s, rowIndex: r),
          IntCellValue(sizes[s]),
          cellStyle: valueStyle,
        );
      }
    }

    final footerRow = tableTop + 1 + colors.length;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: footerRow),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: footerRow),
      customValue: TextCellValue('TOPLAM ADET'),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: footerRow),
      footerRed,
    );

    final total = order.totalQuantity;
    final totalFmt = NumberFormat('#,##0', 'tr_TR').format(total);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: footerRow),
      TextCellValue(totalFmt),
      cellStyle: footerRed,
    );
    for (var c = 3; c <= 7; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: footerRow),
        TextCellValue(''),
        cellStyle: footerYellow,
      );
    }

    const colWidths = [20.0, 18.0, 12.0, 10.0, 10.0, 10.0, 10.0, 10.0];
    for (var c = 0; c < colWidths.length; c++) {
      sheet.setColumnWidth(c, colWidths[c]);
    }

    return excel.encode();
  }
}
