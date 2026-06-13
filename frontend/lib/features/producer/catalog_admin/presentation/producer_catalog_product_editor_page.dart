import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/catalog_display_image.dart';
import '../../../../core/widgets/responsive_page.dart';
import '../../../catalog/application/catalog_list_provider.dart';
import '../../../catalog/application/catalog_repository_provider.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/domain/product_model.dart';
import '../data/catalog_storage_service.dart';

const _kStatuses = ['Taslak', 'Yayında'];

bool _isValidVariantImagePath(String path) {
  final t = path.trim();
  if (t.isEmpty || t.startsWith('assets/')) return false;
  if (t.startsWith('http://') || t.startsWith('https://')) return true;
  return !kIsWeb;
}

class _VariantEdit {
  _VariantEdit({required this.colorName, required this.imageAsset});

  final TextEditingController colorName;
  String imageAsset;
}

/// Üretici: ürün oluştur / düzenle (mock kayıt; görseller ileride Supabase Storage).
class ProducerCatalogProductEditorPage extends ConsumerStatefulWidget {
  const ProducerCatalogProductEditorPage({super.key, this.initial});

  /// `null` → yeni ürün.
  final ProductModel? initial;

  @override
  ConsumerState<ProducerCatalogProductEditorPage> createState() =>
      _ProducerCatalogProductEditorPageState();
}

class _ProducerCatalogProductEditorPageState
    extends ConsumerState<ProducerCatalogProductEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late String _category;
  late String _status;
  late List<_VariantEdit> _variants;
  bool _categorySynced = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _code = TextEditingController(text: i?.code ?? '');
    _name = TextEditingController(text: i?.name ?? '');
    _category = i?.category ?? '';
    _status = i?.status ?? 'Taslak';
    _variants = i != null
        ? i.colorVariants
            .map(
              (v) => _VariantEdit(
                colorName: TextEditingController(text: v.colorName),
                imageAsset: v.imageAsset.startsWith('assets/')
                    ? ''
                    : v.imageAsset,
              ),
            )
            .toList()
        : [
            _VariantEdit(
              colorName: TextEditingController(text: 'Siyah'),
              imageAsset: '',
            ),
          ];
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    for (final v in _variants) {
      v.colorName.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        _VariantEdit(
          colorName: TextEditingController(),
          imageAsset: '',
        ),
      );
    });
  }

  void _removeVariant(int index) {
    if (_variants.length <= 1) return;
    setState(() {
      _variants[index].colorName.dispose();
      _variants.removeAt(index);
    });
  }

  Future<void> _pickVariantImage(int index, ImageSource source) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Galeri ve kamera şimdilik mobil uygulamada; web için yükleme yakında.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null || !mounted) return;
      if (ref.read(catalogUsesSupabaseProvider)) {
        final length = await File(file.path).length();
        try {
          await CatalogStorageService().ensureCanAdd(length);
        } on CatalogStorageQuotaExceeded catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
      setState(() => _variants[index].imageAsset = file.path);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Görsel seçilemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _validateVariantImages() async {
    for (final v in _variants) {
      if (v.colorName.text.trim().isEmpty) continue;
      final path = v.imageAsset.trim();
      if (!_isValidVariantImagePath(path)) return false;
      if (!path.startsWith('http')) {
        if (!await File(path).exists()) return false;
      }
    }
    return true;
  }

  List<String> _categoryOptions(List<String> activeNames) {
    final options = [...activeNames];
    if (_category.isNotEmpty && !options.contains(_category)) {
      options.insert(0, _category);
    }
    return options;
  }

  ProductModel? _productFromForm() {
    final code = _code.text.trim();
    final name = _name.text.trim();
    final variants = <ProductColorVariant>[];
    for (final v in _variants) {
      final c = v.colorName.text.trim();
      if (c.isEmpty) continue;
      variants.add(ProductColorVariant(colorName: c, imageAsset: v.imageAsset));
    }
    if (variants.isEmpty) return null;
    return ProductModel(
      id: widget.initial?.id,
      code: code,
      name: name,
      category: _category,
      status: _status,
      colorVariants: variants,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_category.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori seçin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!await _validateVariantImages()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Her renk için galeri veya kameradan bir fotoğraf seçin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final product = _productFromForm();
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir geçerli renk satırı girin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final list = ref.read(catalogItemsProvider);
    final isNew = widget.initial == null;
    if (isNew && list.any((e) => e.code == product.code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu model kodu zaten kullanılıyor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CatalogProductConfirmDialog(
        product: product,
        isEdit: !isNew,
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await ref
          .read(catalogListProvider.notifier)
          .upsert(product, isNew: isNew);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew ? 'Ürün kataloğa eklendi.' : 'Ürün güncellendi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = switch (e) {
        CatalogFailure(:final message) => message,
        CatalogStorageQuotaExceeded(:final message) => message,
        _ => e.toString(),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final categoriesState = ref.watch(catalogCategoriesProvider);

    if (!categoriesState.isLoading &&
        categoriesState.names.isNotEmpty &&
        !_categorySynced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _categorySynced = true;
          if (_category.isEmpty) {
            _category = categoriesState.names.first;
          }
        });
      });
    }

    final categoryOptions = _categoryOptions(categoriesState.names);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ürünü düzenle' : 'Yeni ürün'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ResponsivePage(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Temel bilgiler',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              readOnly: isEdit,
              decoration: const InputDecoration(
                labelText: 'Model kodu',
                hintText: 'Örn. MD-2024-X02',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Model kodu gerekli.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Ürün adı',
              ),
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty) return 'Ürün adı gerekli.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (categoriesState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (categoriesState.error != null)
              Text(
                categoriesState.error!,
                style: const TextStyle(color: AppColors.critical),
              )
            else if (categoryOptions.isEmpty)
              const Text(
                'Aktif kategori yok. Supabase catalog_categories tablosuna ekleyin.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                initialValue:
                    categoryOptions.contains(_category) ? _category : null,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in categoryOptions)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
                validator: (v) {
                  if ((v ?? _category).trim().isEmpty) {
                    return 'Kategori seçin.';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_status),
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                helperText:
                    'Taslak: alıcı kataloğunda görünmez. Yayında: alıcı görür.',
              ),
              items: [
                for (final s in _kStatuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Renk ve görseller',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Renk ekle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Her renk için galeri veya kameradan fotoğraf seçin. '
              'Görsel seçilmeden kayıt yapılamaz.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _variants.length; i++) ...[
              _VariantCard(
                index: i,
                edit: _variants[i],
                onRemove: () => _removeVariant(i),
                canRemove: _variants.length > 1,
                onPickGallery: () => _pickVariantImage(i, ImageSource.gallery),
                onPickCamera: () => _pickVariantImage(i, ImageSource.camera),
              ),
              if (i < _variants.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Kaydet ve kapat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogProductConfirmDialog extends StatelessWidget {
  const _CatalogProductConfirmDialog({
    required this.product,
    required this.isEdit,
  });

  final ProductModel product;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final isDraft = product.status == 'Taslak';
    final confirmLabel = isEdit ? 'Evet, güncelle' : 'Evet, kaydet';
    final warningText = isEdit
        ? 'Bu ürünü güncellemek istediğinize emin misiniz?'
        : 'Bu ürünü kataloğa eklemek istediğinize emin misiniz?';

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isEdit ? 'Güncellemeyi Onayla' : 'Ürünü Onayla',
              style: const TextStyle(fontWeight: FontWeight.w900),
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
                          child: ColoredBox(
                            color: AppColors.surfaceMuted,
                            child: _CatalogConfirmThumb(asset: product.primaryImageAsset),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.code,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.category} · ${product.status}',
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
                      child: _CatalogConfirmStat(
                        label: 'Renk sayısı',
                        value: '${product.colorVariants.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CatalogConfirmStat(
                        label: 'Durum',
                        value: product.status,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Renk ve görseller',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final v in product.colorVariants) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: ColoredBox(
                              color: AppColors.surfaceMuted,
                              child: _CatalogConfirmThumb(asset: v.imageAsset),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            v.colorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isDraft) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Taslak ürünler alıcı kataloğunda görünmez; yalnızca '
                      'üretici katalog yönetiminde listelenir.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warningText,
                          style: const TextStyle(
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
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(confirmLabel),
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

class _CatalogConfirmThumb extends StatelessWidget {
  const _CatalogConfirmThumb({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    if (!_isValidVariantImagePath(asset)) {
      return const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 22),
      );
    }
    return catalogDisplayImage(asset, fit: BoxFit.contain);
  }
}

class _CatalogConfirmStat extends StatelessWidget {
  const _CatalogConfirmStat({required this.label, required this.value});

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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

String _imageSourceLabel(String path) {
  if (path.trim().isEmpty) {
    return 'Henüz fotoğraf seçilmedi';
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return 'Yüklenmiş görsel';
  }
  final parts = path.replaceAll('\\', '/').split('/');
  final name = parts.isNotEmpty ? parts.last : path;
  if (name.length > 36) {
    return '${name.substring(0, 33)}…';
  }
  return name;
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.index,
    required this.edit,
    required this.onRemove,
    required this.canRemove,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  final int index;
  final _VariantEdit edit;
  final VoidCallback onRemove;
  final bool canRemove;
  final Future<void> Function() onPickGallery;
  final Future<void> Function() onPickCamera;

  @override
  Widget build(BuildContext context) {
    final hasImage = _isValidVariantImagePath(edit.imageAsset);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Renk ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                canRemove
                    ? IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                        tooltip: 'Satırı kaldır',
                      )
                    : const SizedBox(width: 48, height: 48),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: edit.colorName,
              decoration: const InputDecoration(labelText: 'Renk adı'),
            ),
            const SizedBox(height: 14),
            Text(
              'Ürün görseli',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Galeri'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onPickCamera,
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('Kamera'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _imageSourceLabel(edit.imageAsset),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: hasImage
                      ? catalogDisplayImage(
                          edit.imageAsset,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
