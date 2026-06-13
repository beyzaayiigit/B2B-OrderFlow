import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/llm/assist_api.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/date_input.dart';
import '../../../shared/order_date_labels.dart';
import '../../../shared/widgets/catalog_display_image.dart';
import '../../catalog/application/catalog_list_provider.dart';
import '../../catalog/domain/product_model.dart';
import '../../producer/application/producer_orders_notifier.dart';
import '../application/buyer_order_notes_notifier.dart';
import '../domain/buyer_order_note_limits.dart';
import '../application/orders_repository_provider.dart';
import '../application/tracked_orders_notifier.dart';
import '../data/orders_repository.dart';
import '../domain/order_color_palette.dart';
import '../domain/tracked_order.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key, this.selectedModel});

  final ProductModel? selectedModel;

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  static const defaultSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  static const colorPalette = orderColorPalette;

  final selectedColors = <String>{'Siyah', 'Beyaz'};
  final activeSizesByColor = <String, Set<String>>{};
  final quantities = <String, Map<String, int>>{};
  final colorTotalQty = <String, int>{};
  ProductModel? _selectedModel;
  int _formVersion = 0;
  final _producerNoteController = TextEditingController();
  late final TextEditingController _dueDateController;
  late DateTime _dueAt;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.selectedModel;
    _dueAt = _defaultDueAt();
    _dueDateController =
        TextEditingController(text: formatTurkishDateInput(_dueAt));
    for (final color in selectedColors) {
      activeSizesByColor[color] = defaultSizes.toSet();
    }
  }

  DateTime _defaultDueAt() {
    final base = dateOnly(DateTime.now());
    return base.add(const Duration(days: 21));
  }

  String get _dueAtLabel => formatOrderDateLong(_dueAt);

  bool get _dueDateComplete =>
      isTurkishDateInputComplete(_dueDateController.text);

  bool get _dueDateValid {
    if (!_dueDateComplete) return true;
    final parsed = parseTurkishDateString(_dueDateController.text);
    if (parsed == null) return false;
    final today = dateOnly(DateTime.now());
    return !dateOnly(parsed).isBefore(today);
  }

  @override
  void didUpdateWidget(covariant CreateOrderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedModel != oldWidget.selectedModel) {
      setState(() => _selectedModel = widget.selectedModel);
    }
  }

  @override
  void dispose() {
    _producerNoteController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _syncDueFromField() {
    final text = _dueDateController.text;
    final parsed = parseTurkishDateString(text);
    if (parsed != null) {
      final formatted = formatTurkishDateInput(dateOnly(parsed));
      if (text != formatted) {
        _dueDateController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      setState(() => _dueAt = dateOnly(parsed));
    } else {
      setState(() {});
    }
  }

  List<String> get orderedSelectedColors =>
      defaultColorOrder.where(selectedColors.contains).toList();

  int get totalQuantity =>
      colorTotalQty.values.fold(0, (sum, qty) => sum + qty);

  bool get canSubmit {
    if (_selectedModel == null) return false;
    if (!_dueDateComplete || !_dueDateValid) return false;
    if (orderedSelectedColors.isEmpty) return false;
    for (final color in orderedSelectedColors) {
      final enabledSizes = activeSizesByColor[color] ?? defaultSizes.toSet();
      if (enabledSizes.isEmpty) return false;
      final allRatiosFilled = enabledSizes.every(
        (size) => (quantities[color]?[size] ?? 0) > 0,
      );
      if (!allRatiosFilled) return false;
      if ((colorTotalQty[color] ?? 0) <= 0) return false;
    }
    return true;
  }

  void _toggleColor(String color, bool selected) {
    setState(() {
      if (selected) {
        selectedColors.add(color);
        activeSizesByColor.putIfAbsent(color, () => defaultSizes.toSet());
        quantities.putIfAbsent(color, () => {});
      } else {
        selectedColors.remove(color);
        activeSizesByColor.remove(color);
        quantities.remove(color);
        colorTotalQty.remove(color);
      }
    });
  }

  void _toggleSize(String color, String size) {
    setState(() {
      final enabled = activeSizesByColor.putIfAbsent(
        color,
        () => defaultSizes.toSet(),
      );
      if (enabled.contains(size)) {
        enabled.remove(size);
        quantities[color]?.remove(size);
      } else {
        enabled.add(size);
      }
    });
  }

  Future<void> _pickDueDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate: _dueAt.isBefore(today) ? today : dateOnly(_dueAt),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: 'Teslim tarihi seçin',
      cancelText: 'İptal',
      confirmText: 'Tamam',
    );
    if (picked != null && mounted) {
      setState(() => _dueAt = dateOnly(picked));
      _dueDateController.text = formatTurkishDateInput(_dueAt);
    }
  }

  Future<void> _openColorPicker() async {
    final temp = {...selectedColors};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Renk Seçimi',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 360,
                      child: ListView(
                        children: [
                          for (final color in defaultColorOrder)
                            CheckboxListTile(
                              value: temp.contains(color),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  _ColorSwatchBox(
                                    color:
                                        colorPalette[color] ??
                                        AppColors.neutral,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(color),
                                ],
                              ),
                              onChanged: (selected) {
                                setModalState(() {
                                  if (selected ?? false) {
                                    temp.add(color);
                                  } else {
                                    temp.remove(color);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        for (final color in defaultColorOrder) {
                          _toggleColor(color, temp.contains(color));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Uygula'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasModel = _selectedModel != null;
    return ResponsivePage(
      children: [
        Text(
          'Sipariş Oluşturma',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          hasModel
              ? 'Her renk için beden oranlarını ve toplam adedi girin.'
              : 'Devam etmek için katalogtan veya aşağıdaki listeden bir model seçin.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        _ModelSelectorCard(
          catalog: ref.watch(buyerCatalogItemsProvider),
          currentModel: _selectedModel,
          onChanged: (model) => setState(() => _selectedModel = model),
        ),
        const SizedBox(height: 12),
        if (hasModel) ...[
          _TechnicalInfoCard(
            selectedModel: _selectedModel!,
            previewColorName: orderedSelectedColors.isNotEmpty
                ? orderedSelectedColors.first
                : _selectedModel!.colorVariants.first.colorName,
          ),
          const SizedBox(height: 16),
          _ColorSelector(
            selectedColors: orderedSelectedColors,
            onEditTap: _openColorPicker,
            onRemoveColor: (color) => _toggleColor(color, false),
          ),
          const SizedBox(height: 16),
          for (final color in orderedSelectedColors) ...[
            _ColorSizeCard(
              key: ValueKey('color_card_${color}_$_formVersion'),
              color: color,
              colorTone: colorPalette[color] ?? AppColors.neutral,
              sizes: defaultSizes,
              activeSizes: activeSizesByColor.putIfAbsent(
                color,
                () => defaultSizes.toSet(),
              ),
              ratios: quantities.putIfAbsent(color, () => {}),
              colorTotal: colorTotalQty[color] ?? 0,
              formVersion: _formVersion,
              onRemoveColor: () => _toggleColor(color, false),
              onToggleSize: (size) => _toggleSize(color, size),
              onRatioChanged: (size, value) =>
                  setState(() => quantities[color]![size] = value),
              onTotalChanged: (value) =>
                  setState(() => colorTotalQty[color] = value),
            ),
            const SizedBox(height: 12),
          ],
          _DueDateCard(
            dueDateController: _dueDateController,
            isValid: _dueDateValid,
            onPick: _pickDueDate,
            onFieldChanged: _syncDueFromField,
          ),
          const SizedBox(height: 16),
          _OrderNoteCard(controller: _producerNoteController),
          const SizedBox(height: 16),
          _OrderSummary(
            totalColors: selectedColors.length,
            totalQuantity: totalQuantity,
            canSubmit: canSubmit,
            onSubmit: _handleSubmitTap,
          ),
        ] else
          const _EmptyModelState(),
      ],
    );
  }

  List<TrackedOrderLine> _buildOrderLines() {
    final lines = <TrackedOrderLine>[];
    for (final color in orderedSelectedColors) {
      final active = activeSizesByColor[color] ?? {};
      final ratioMap = <String, int>{};
      for (final s in active) {
        final r = quantities[color]?[s] ?? 0;
        if (r > 0) ratioMap[s] = r;
      }
      final total = colorTotalQty[color] ?? 0;
      if (ratioMap.isNotEmpty && total > 0) {
        lines.add(
          TrackedOrderLine(
            colorName: color,
            sizeRatios: ratioMap,
            totalQty: total,
          ),
        );
      }
    }
    return lines;
  }

  Future<void> _handleSubmitTap() async {
    final model = _selectedModel;
    if (model == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OrderConfirmDialog(
        model: model,
        orderedColors: orderedSelectedColors,
        defaultSizes: defaultSizes,
        activeSizesByColor: activeSizesByColor,
        quantities: quantities,
        colorTotalQty: colorTotalQty,
        colorPalette: colorPalette,
        totalQuantity: totalQuantity,
        orderNoteRaw: _producerNoteController.text,
        dueAtLabel: _dueAtLabel,
      ),
    );

    if (!mounted) return;

    if (confirmed != true) return;

    if (isBuyerOrderNoteTooLong(_producerNoteController.text)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Sipariş notu en fazla $kBuyerOrderNoteMaxLength karakter olabilir.',
          ),
        ),
      );
      return;
    }

    final orderNote = normalizeBuyerOrderNote(_producerNoteController.text);

    final repo = ref.read(ordersRepositoryProvider);
    if (repo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Sunucu bağlantısı kurulamadı.'),
        ),
      );
      return;
    }

    try {
      final result = await repo.createOrder(
        CreateOrderInput(
          model: model,
          dueAt: dateOnly(_dueAt),
          lines: _buildOrderLines(),
          buyerNote: orderNote,
        ),
      );
      await ref.read(trackedOrdersProvider.notifier).refresh();
      await ref.read(producerOrdersProvider.notifier).refresh();
      ref.read(buyerOrderNotesProvider.notifier).upsertForTrackedOrder(
            trackedOrderNo: result.tracked.orderNo,
            producerOrderCode: result.tracked.producerOrderCode,
            rawText: orderNote ?? '',
          );
      if (!mounted) return;
      _resetFormAfterSubmit();
      context.go('/orders/new');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'Sipariş gönderildi: ${result.tracked.orderNo}. '
            'Takip sekmesinden açabilirsiniz.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is OrderFailure ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg),
        ),
      );
    }
  }

  void _resetFormAfterSubmit() {
    setState(() {
      _selectedModel = null;
      selectedColors
        ..clear()
        ..addAll({'Siyah', 'Beyaz'});
      activeSizesByColor.clear();
      quantities.clear();
      colorTotalQty.clear();
      for (final color in selectedColors) {
        activeSizesByColor[color] = defaultSizes.toSet();
      }
      _producerNoteController.clear();
      _dueAt = _defaultDueAt();
      _dueDateController.text = formatTurkishDateInput(_dueAt);
      _formVersion++;
    });
  }
}

class _DueDateCard extends StatelessWidget {
  const _DueDateCard({
    required this.dueDateController,
    required this.isValid,
    required this.onPick,
    required this.onFieldChanged,
  });

  final TextEditingController dueDateController;
  final bool isValid;
  final VoidCallback onPick;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Teslim tarihi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Teslim alanına rakam yazın (ör. 20062026 → 20.06.2026). '
              'Takvim ikonu yalnızca gün seçimi içindir. Üretici bu tarihi '
              'sipariş detayında görür.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dueDateController,
              keyboardType: TextInputType.number,
              inputFormatters: [TurkishDateInputFormatter()],
              onChanged: (_) => onFieldChanged(),
              decoration: InputDecoration(
                labelText: 'Teslim',
                hintText: 'GG.AA.YYYY (ör. 20.06.2026)',
                errorText: isValid
                    ? null
                    : 'Geçerli bir tarih girin (GG.AA.YYYY, bugün veya sonrası).',
                suffixIcon: IconButton(
                  onPressed: onPick,
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: 'Takvimden seç',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderNoteCard extends ConsumerStatefulWidget {
  const _OrderNoteCard({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_OrderNoteCard> createState() => _OrderNoteCardState();
}

class _OrderNoteCardState extends ConsumerState<_OrderNoteCard> {
  bool _loading = false;

  Future<void> _runAssist() async {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce kısa da olsa not yazın.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(assistApiProvider).orderNote(raw);
      if (!mounted) return;
      widget.controller.text = result;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistAvailable = ref.read(assistApiProvider).available;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş notu',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Üreticinin göreceği bilgileri buraya yazın; Excel çıktısında da '
              'aynı metin kullanılır. En fazla $kBuyerOrderNoteMaxLength karakter.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.controller,
              maxLines: 6,
              maxLength: kBuyerOrderNoteMaxLength,
              decoration: const InputDecoration(
                hintText: 'Örn: hassas ürün, ölçü, barkod veya paketleme uyarıları…',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            if (assistAvailable) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _runAssist,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_loading ? 'Düzenleniyor…' : 'AI ile düzenle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyModelState extends StatelessWidget {
  const _EmptyModelState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.checkroom_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Henüz model seçilmedi. Katalogtan bir ürüne dokunun veya yukarıdaki listeden bir model seçin.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalInfoCard extends StatelessWidget {
  const _TechnicalInfoCard({
    required this.selectedModel,
    required this.previewColorName,
  });

  final ProductModel selectedModel;
  final String previewColorName;

  String get _previewAsset =>
      selectedModel.imageAssetForColor(previewColorName);

  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => _ProductPreviewDialog(
        model: selectedModel,
        previewColorName: previewColorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelName = selectedModel.name;
    final modelCode = selectedModel.code;
    final modelCategory = selectedModel.category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Görseli büyüt',
                  child: InkWell(
                    onTap: () => _openPreview(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceMuted,
                            child: catalogDisplayImage(
                              _previewAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    modelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Önizleme rengi: $previewColorName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Model Kodu: ${modelCode.isNotEmpty ? modelCode : '—'}',
            ),
            Text(
              'Kategori: ${modelCategory.isNotEmpty ? modelCategory : '—'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPreviewDialog extends StatelessWidget {
  const _ProductPreviewDialog({
    required this.model,
    required this.previewColorName,
  });

  final ProductModel model;
  final String previewColorName;

  @override
  Widget build(BuildContext context) {
    final asset = model.imageAssetForColor(previewColorName);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: catalogDisplayImage(
                  asset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.code,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        model.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        previewColorName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Kapat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelSelectorCard extends StatelessWidget {
  const _ModelSelectorCard({
    required this.catalog,
    required this.currentModel,
    required this.onChanged,
  });

  final List<ProductModel> catalog;
  final ProductModel? currentModel;
  final ValueChanged<ProductModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Seçimi',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ProductModel>(
              key: ValueKey(currentModel?.code ?? '_none'),
              initialValue: currentModel,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Model seçin',
                prefixIcon: Icon(Icons.checkroom_outlined),
              ),
              items: catalog
                  .map(
                    (model) => DropdownMenuItem<ProductModel>(
                      value: model,
                      child: Text(
                        '${model.code} - ${model.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (model) {
                if (model != null) onChanged(model);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.selectedColors,
    required this.onEditTap,
    required this.onRemoveColor,
  });

  final List<String> selectedColors;
  final VoidCallback onEditTap;
  final void Function(String color) onRemoveColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seçilen renkler',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(onPressed: onEditTap, child: const Text('Düzenle')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                selectedColors.isEmpty
                    ? 'Henüz renk seçilmedi'
                    : selectedColors.join(', '),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedColors
                  .map(
                    (color) => Chip(
                      label: Text(color),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemoveColor(color),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSizeCard extends StatelessWidget {
  const _ColorSizeCard({
    super.key,
    required this.color,
    required this.colorTone,
    required this.sizes,
    required this.activeSizes,
    required this.ratios,
    required this.colorTotal,
    required this.formVersion,
    required this.onRemoveColor,
    required this.onToggleSize,
    required this.onRatioChanged,
    required this.onTotalChanged,
  });

  final String color;
  final Color colorTone;
  final List<String> sizes;
  final Set<String> activeSizes;
  final Map<String, int> ratios;
  final int colorTotal;
  final int formVersion;
  final VoidCallback onRemoveColor;
  final void Function(String size) onToggleSize;
  final void Function(String size, int value) onRatioChanged;
  final void Function(int value) onTotalChanged;

  int get _ratioSum =>
      activeSizes.fold<int>(0, (sum, size) => sum + (ratios[size] ?? 0));

  int get _seriesCount => _ratioSum > 0 && colorTotal > 0
      ? colorTotal ~/ _ratioSum
      : 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ColorSwatchBox(color: colorTone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    color,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (colorTotal > 0)
                  Text(
                    '$colorTotal adet',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                IconButton(
                  onPressed: onRemoveColor,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Rengi kaldır',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in sizes)
                  FilterChip(
                    label: Text(size),
                    selected: activeSizes.contains(size),
                    onSelected: (_) => onToggleSize(size),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final size in sizes.where(activeSizes.contains)) ...[
              Row(
                key: ValueKey('row_${color}_${size}_$formVersion'),
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      size,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('input_${color}_${size}_$formVersion'),
                      initialValue: ratios[size]?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Oran'),
                      onChanged: (text) =>
                          onRatioChanged(size, int.tryParse(text) ?? 0),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onToggleSize(size),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Bedeni kaldır',
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (activeSizes.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 4),
              TextFormField(
                key: ValueKey('total_${color}_$formVersion'),
                initialValue: colorTotal > 0 ? colorTotal.toString() : null,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Toplam Adet',
                  hintText: 'Toplam sipariş adedi',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                onChanged: (text) =>
                    onTotalChanged(int.tryParse(text) ?? 0),
              ),
              if (_ratioSum > 0 && colorTotal > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_seriesCount seri x $_ratioSum adet/seri',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
            if (activeSizes.isEmpty)
              const Text(
                'Bu renk için beden seçilmedi. Gönderim için en az bir beden seçip oran girin.',
                style: TextStyle(
                  color: AppColors.critical,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.totalColors,
    required this.totalQuantity,
    required this.canSubmit,
    required this.onSubmit,
  });

  final int totalColors;
  final int totalQuantity;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Özet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Seçili renk: $totalColors'),
            Text('Toplam adet: $totalQuantity'),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              child: const Text('Siparişi Gönder'),
            ),
            if (!canSubmit)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Gönderim için her renkte beden oranları ve toplam adet dolu olmalı.',
                  style: TextStyle(color: AppColors.critical),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchBox extends StatelessWidget {
  const _ColorSwatchBox({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _OrderConfirmDialog extends StatelessWidget {
  const _OrderConfirmDialog({
    required this.model,
    required this.orderedColors,
    required this.defaultSizes,
    required this.activeSizesByColor,
    required this.quantities,
    required this.colorTotalQty,
    required this.colorPalette,
    required this.totalQuantity,
    required this.orderNoteRaw,
    required this.dueAtLabel,
  });

  final ProductModel model;
  final List<String> orderedColors;
  final List<String> defaultSizes;
  final Map<String, Set<String>> activeSizesByColor;
  final Map<String, Map<String, int>> quantities;
  final Map<String, int> colorTotalQty;
  final Map<String, Color> colorPalette;
  final int totalQuantity;
  final String orderNoteRaw;
  final String dueAtLabel;

  List<String> _orderedActiveSizes(String color) {
    final active = activeSizesByColor[color] ?? const <String>{};
    return defaultSizes.where(active.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final note = orderNoteRaw.trim();
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Siparişi Onayla',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Kapat',
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: catalogDisplayImage(
                            model.imageAssetPreferringColors(orderedColors),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.code,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              model.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              model.category,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStat(
                        label: 'Toplam renk',
                        value: '${orderedColors.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryStat(
                        label: 'Toplam adet',
                        value: '$totalQuantity',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 20,
                        color: AppColors.navy.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teslim tarihi',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dueAtLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sipariş notu',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      note.isEmpty
                          ? 'Bu siparişte not eklenmedi.'
                          : note,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight:
                            note.isEmpty ? FontWeight.w500 : FontWeight.w600,
                        color: note.isEmpty
                            ? AppColors.textMuted
                            : AppColors.text,
                        fontStyle: note.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Renk / Beden Detayı',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final color in orderedColors) ...[
                  _ColorBreakdown(
                    color: color,
                    tone: colorPalette[color] ?? AppColors.neutral,
                    activeSizes: _orderedActiveSizes(color),
                    ratios: quantities[color] ?? const {},
                    colorTotal: colorTotalQty[color] ?? 0,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu siparişi göndermek istediğinize emin misiniz?',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Hayır, düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(
                            color: AppColors.navy,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Evet, gönder'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(
                            color: AppColors.navy,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorBreakdown extends StatelessWidget {
  const _ColorBreakdown({
    required this.color,
    required this.tone,
    required this.activeSizes,
    required this.ratios,
    required this.colorTotal,
  });

  final String color;
  final Color tone;
  final List<String> activeSizes;
  final Map<String, int> ratios;
  final int colorTotal;

  int get _ratioSum =>
      activeSizes.fold<int>(0, (sum, s) => sum + (ratios[s] ?? 0));

  int get _seriesCount => _ratioSum > 0 && colorTotal > 0
      ? colorTotal ~/ _ratioSum
      : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ColorSwatchBox(color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  color,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$colorTotal adet',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final size in activeSizes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$size: ${ratios[size] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (_ratioSum > 0 && colorTotal > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$_seriesCount seri x $_ratioSum adet/seri',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
