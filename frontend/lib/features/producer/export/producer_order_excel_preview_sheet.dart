import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/catalog_display_image.dart';
import '../domain/producer_order.dart';
import 'producer_order_excel.dart';

const _excelHeaderFill = Color(0xFFFFF59D);
const _excelImageFill = Color(0xFFF5F5F5);

/// AppBar Excel ikonu: önce şablona yakın önizleme, sonra onay diyaloğu ile indirme.
Future<void> showProducerOrderExcelPreview(
  BuildContext pageContext,
  ProducerOrder order,
) async {
  await showModalBottomSheet<void>(
    context: pageContext,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return SizedBox(
        height: maxH,
        child: _ProducerOrderExcelPreviewBody(
          pageContext: pageContext,
          sheetContext: sheetContext,
          order: order,
          notesBody: ProducerOrderExcelExport.effectiveNotesForExport(
            order.buyerNote,
          ),
        ),
      );
    },
  );
}

class _ProducerOrderExcelPreviewBody extends StatelessWidget {
  const _ProducerOrderExcelPreviewBody({
    required this.pageContext,
    required this.sheetContext,
    required this.order,
    required this.notesBody,
  });

  final BuildContext pageContext;
  final BuildContext sheetContext;
  final ProducerOrder order;
  final String notesBody;

  Future<void> _onDownloadPressed() async {
    final go = await showDialog<bool>(
      context: sheetContext,
      builder: (dCtx) => AlertDialog(
        title: const Text('Excel indir'),
        content: Text(
          'Sipariş #${order.code} için .xlsx oluşturulacak; ardından paylaşım veya '
          'kayıt seçenekleri açılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('İndir'),
          ),
        ],
      ),
    );
    if (go != true || !pageContext.mounted) return;
    Navigator.of(sheetContext).pop();
    await ProducerOrderExcelExport.share(
      pageContext,
      order,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(order.orderedAt);
    final labels = ProducerOrderExcelExport.sizeLabels;
    final colors = order.colorBreakdown.entries.toList();
    final totalFmt =
        NumberFormat('#,##0', 'tr_TR').format(order.totalQuantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.table_chart_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Excel önizleme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetaBlock(order: order, dateStr: dateStr),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final stack = c.maxWidth < 420;
                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NotesPanel(text: notesBody),
                          const SizedBox(height: 8),
                          _OrderPreviewVisual(order: order),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _NotesPanel(text: notesBody),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _OrderPreviewVisual(order: order),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Sipariş tablosu',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _PreviewDataTable(
                    order: order,
                    labels: labels,
                    colors: colors,
                    totalFmt: totalFmt,
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _onDownloadPressed,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Excel indir'),
          ),
        ),
      ],
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.order, required this.dateStr});

  final ProducerOrder order;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _metaHeaderCell('MODEL KODU')),
              Expanded(child: _metaValueCell(order.product.code)),
              Expanded(child: _metaHeaderCell('SİPARİŞ TARİHİ')),
              Expanded(child: _metaValueCell(dateStr)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _metaHeaderCell('MODEL İSMİ')),
              Expanded(
                flex: 3,
                child: _metaValueCell(
                  order.product.name,
                  align: TextAlign.center,
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _metaHeaderCell(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        color: _excelHeaderFill,
        alignment: Alignment.centerLeft,
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );

  static Widget _metaValueCell(
    String t, {
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        alignment: _alignmentFor(align),
        child: Text(
          t,
          textAlign: align,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 13 : 12,
          ),
        ),
      );

  static Alignment _alignmentFor(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _excelHeaderFill.withValues(alpha: 0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Siparişteki renk sırasına göre katalogdaki temsili görsel (detay sayfasıyla aynı mantık).
class _OrderPreviewVisual extends StatelessWidget {
  const _OrderPreviewVisual({required this.order});

  final ProducerOrder order;

  String get _asset =>
      order.product.imageAssetPreferringColors(order.colorBreakdown.keys);

  String get _colorLabel {
    for (final name in order.colorBreakdown.keys) {
      if (name.trim().isNotEmpty) return name.trim();
    }
    return order.product.colorVariants.first.colorName;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: _excelImageFill,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                catalogDisplayImage(_asset, fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _colorLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.product.code,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewDataTable extends StatelessWidget {
  const _PreviewDataTable({
    required this.order,
    required this.labels,
    required this.colors,
    required this.totalFmt,
  });

  final ProducerOrder order;
  final List<String> labels;
  final List<MapEntry<String, int>> colors;
  final String totalFmt;

  @override
  Widget build(BuildContext context) {
    final headers = <String>[
      'SİPARİŞ VEREN',
      'RENK',
      'ADET',
      ...labels,
    ];

    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: _excelHeaderFill),
        children: headers
            .map(
              (h) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  h,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ];

    for (var i = 0; i < colors.length; i++) {
      final e = colors[i];
      final sizes = ProducerOrderExcelExport.sizeRatiosForColor(order, e.key);
      rows.add(
        TableRow(
          children: [
            _td(i == 0 ? ProducerOrderExcelExport.orderedByLabel(order) : ''),
            _td(e.key.toUpperCase()),
            _td('${e.value}'),
            ...sizes.map((n) => _td('$n')),
          ],
        ),
      );
    }

    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: _excelHeaderFill.withValues(alpha: 0.4),
        ),
        children: [
          _td('TOPLAM ADET', bold: true, red: true),
          _td(''),
          _td(totalFmt, bold: true, red: true),
          ...List.generate(labels.length, (_) => _td('')),
        ],
      ),
    );

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(120),
        1: FixedColumnWidth(76),
        2: FixedColumnWidth(44),
        3: FixedColumnWidth(38),
        4: FixedColumnWidth(38),
        5: FixedColumnWidth(38),
        6: FixedColumnWidth(38),
        7: FixedColumnWidth(38),
      },
      border: TableBorder.all(color: AppColors.border),
      children: rows,
    );
  }

  static Widget _td(
    String text, {
    bool bold = false,
    bool red = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12,
          color: red ? const Color(0xFFC62828) : AppColors.text,
        ),
      ),
    );
  }
}
