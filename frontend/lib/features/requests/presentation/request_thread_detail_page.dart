import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_button_styles.dart';
import '../../../core/llm/assist_api.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../features/auth/application/session_controller.dart';
import '../../../shared/types/user_role.dart';
import '../application/request_threads_notifier.dart';
import '../domain/request_thread.dart';
import 'request_thread_order_status_row.dart';

/// Siparişe bağlı talep + üretici onayı / geri bildirimi (mesajlaşma değil).
class RequestThreadDetailPage extends ConsumerStatefulWidget {
  const RequestThreadDetailPage({required this.threadId, super.key});

  final String threadId;

  @override
  ConsumerState<RequestThreadDetailPage> createState() =>
      _RequestThreadDetailPageState();
}

class _RequestThreadDetailPageState extends ConsumerState<RequestThreadDetailPage> {
  final _talepController = TextEditingController();
  final _geriBildirimController = TextEditingController();
  final _onayNotuController = TextEditingController();
  final _kapatNotuController = TextEditingController();
  static final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');
  bool _talepAssistLoading = false;

  Future<void> _assistTalep(String orderNo) async {
    final raw = _talepController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce kısa da olsa talebinizi yazın.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _talepAssistLoading = true);
    try {
      final result = await ref
          .read(assistApiProvider)
          .updateRequest(raw, orderCode: orderNo);
      if (!mounted) return;
      _talepController.text = result;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _talepAssistLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(requestThreadsProvider.notifier).refresh();
      final role = ref.read(sessionControllerProvider).role;
      if (role == UserRole.buyer) {
        ref.read(requestThreadsProvider.notifier).markBuyerRead(widget.threadId);
      }
    });
  }

  @override
  void dispose() {
    _talepController.dispose();
    _geriBildirimController.dispose();
    _onayNotuController.dispose();
    _kapatNotuController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndCloseForProducer(RequestThread thread) async {
    _kapatNotuController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Talebi kapat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sipariş #${thread.orderNo}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Son işlem geri bildirim olarak kayıtlıdır. Talebi sonlandırmak için onay kaydı ekleyin; '
                'onay sonrası sipariş sevk edilebilir.',
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _kapatNotuController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Kapatma notu (isteğe bağlı)',
                  hintText: 'Örn: Geri bildirim bilgilendirme amaçlıydı, talep kapatıldı.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(requestThreadsProvider.notifier).producerApprove(
            thread.id,
            note: _kapatNotuController.text,
          );
      if (!mounted) return;
      _kapatNotuController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talep kapatıldı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionControllerProvider).role ?? UserRole.buyer;
    final isBuyer = role == UserRole.buyer;
    final isProducer = role == UserRole.producer;
    final threads = ref.watch(requestThreadsProvider).items;

    RequestThread? matched;
    for (final t in threads) {
      if (t.id == widget.threadId) {
        matched = t;
        break;
      }
    }

    if (matched == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Güncelleme talebi')),
        body: const Center(child: Text('Kayıt bulunamadı.')),
      );
    }
    final thread = matched;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '#${thread.orderNo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ResponsivePage(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sipariş',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            thread.productLabel,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RequestThreadOrderStatusRow(
                            orderStatusKey: thread.orderStatusKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Talep ve yanıtlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBuyer
                        ? 'Gönderdiğiniz talepler ile üreticinin onayı veya geri bildirimi tek akışta görünür.'
                        : 'Alıcı talebini inceleyin: onaylayın veya geri bildirim yazın. Kayıtlar alıcıda aynı kartta görünür.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (thread.entries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          isBuyer
                              ? 'Henüz talep yok. Aşağıdan metin girip kaydedin.'
                              : 'Bu sipariş için henüz alıcı talebi yok.',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final e in thread.sortedEntries) ...[
                      _TimelineEntryTile(
                        entry: e,
                        dateFmt: _dateFmt,
                      ),
                      const SizedBox(height: 10),
                    ],
                  if (isProducer) ...[
                    const SizedBox(height: 8),
                    if (thread.hasPendingBuyerRequest)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.warning,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pending_actions_outlined,
                                    color: AppColors.warning.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Alıcı talebi — yanıt bekleniyor',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Aşağıdan talebi onaylayın veya metinli geri bildirim gönderin. İşlem kaydedildikten sonra bu blok, alıcı yeni talep gönderene kadar kapanır.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _onayNotuController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Onay notu (isteğe bağlı)',
                                  hintText:
                                      'Örn: Üretim planına alındı, teslim 22 Mayıs',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(requestThreadsProvider.notifier)
                                        .producerApprove(
                                          thread.id,
                                          note: _onayNotuController.text,
                                        );
                                    if (!context.mounted) return;
                                    _onayNotuController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Onay kaydedildi. Alıcı aynı kartta görecek.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Talebi onayla'),
                                style: AppButtonStyles.positive,
                              ),
                              const Divider(height: 28),
                              TextField(
                                controller: _geriBildirimController,
                                minLines: 2,
                                maxLines: 6,
                                decoration: const InputDecoration(
                                  labelText: 'Geri bildirim metni',
                                  hintText:
                                      'Örn: İstenen ek adet için tarih / kapasite bilgisi…',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final t =
                                      _geriBildirimController.text.trim();
                                  if (t.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Geri bildirim metnini yazın.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(requestThreadsProvider.notifier)
                                        .producerGeriBildirim(thread.id, t);
                                    if (!context.mounted) return;
                                    _geriBildirimController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Geri bildirim gönderildi.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.reply_outlined),
                                label: const Text('Geri bildirimi kaydet'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (thread.lastIsProducerFeedback &&
                              thread.entries.isNotEmpty) ...[
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppColors.warning
                                              .withValues(alpha: 0.9),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Son işlem geri bildirim',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Geri bildirim kaydı geçerlidir; talebi kapatmak için aşağıdan onaylayın. '
                                      'Onay sonrası sipariş sevk sürecine alınabilir.',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _confirmAndCloseForProducer(thread),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      label: const Text('Talebi kapat'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success
                                        .withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      thread.entries.isEmpty
                                          ? 'Alıcı henüz talep göndermedi.'
                                          : 'Son işlem sizden (onay veya geri bildirim) veya bekleyen yeni alıcı talebi yok. Liste “Güncel” olarak görünür; alıcı yeni talep eklediğinde burada tekrar yanıt verebilirsiniz.',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                  if (isBuyer) ...[
                    if (thread.isOrderShipped) ...[
                      const SizedBox(height: 20),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Bu sipariş sevk edildi. Yeni güncelleme talebi gönderilemez; geçmiş kayıtlar yalnızca görüntüleme içindir.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (thread.hasPendingBuyerRequest &&
                        thread.entries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.hourglass_top_outlined,
                                size: 20,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Son talebiniz üretici tarafında bekliyor. Yine de ek düzeltme yazmak isterseniz aşağıdan devam edebilirsiniz.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (!thread.isOrderShipped) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 22,
                                  color: AppColors.navy.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Yeni güncelleme talebi',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Adet, teslim veya içerik değişikliğini tek metin halinde yazın. Göndermeden önce özet penceresi açılır.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _talepController,
                              minLines: 4,
                              maxLines: 10,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                alignLabelWithHint: true,
                                hintText:
                                    'Örn: SPRS-0000001 M beden toplamına +10, sevk 20 Mayıs…',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.surfaceMuted,
                              ),
                            ),
                            if (ref.read(assistApiProvider).available) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: _talepAssistLoading
                                      ? null
                                      : () => _assistTalep(thread.orderNo),
                                  icon: _talepAssistLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome, size: 18),
                                  label: Text(
                                    _talepAssistLoading
                                        ? 'Düzenleniyor…'
                                        : 'AI ile düzenle',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    side: const BorderSide(color: AppColors.navy),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () async {
                                final text = _talepController.text.trim();
                                if (text.isEmpty) return;
                                final ok = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Talebi üreticiye ilet'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Sipariş #${thread.orderNo}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Gönderilecek metin:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            text,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.45,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('İptal'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Gönder'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true || !context.mounted) return;
                                try {
                                  await ref
                                      .read(requestThreadsProvider.notifier)
                                      .addBuyerRequest(thread.id, text);
                                  if (!context.mounted) return;
                                  _talepController.clear();
                                  FocusScope.of(context).unfocus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Talep iletildi. Üretici aynı sipariş güncelleme ekranında görecek.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save_outlined, size: 20),
                              label: const Text('Göndermek için onayla'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ],
                ],
        ),
      ),
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  const _TimelineEntryTile({
    required this.entry,
    required this.dateFmt,
  });

  final RequestEntry entry;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    switch (entry.kind) {
      case RequestEntryKind.buyerRequest:
        return _EntryShell(
          stripe: AppColors.navy.withValues(alpha: 0.45),
          icon: Icons.note_add_outlined,
          title: 'Alıcı — güncelleme talebi',
          trailing: dateFmt.format(entry.createdAt),
          body: Text(
            entry.text ?? '',
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        );
      case RequestEntryKind.producerApproval:
        return _EntryShell(
          stripe: AppColors.success.withValues(alpha: 0.65),
          icon: Icons.check_circle_outline,
          title: 'Üretici — talep onayı',
          trailing: dateFmt.format(entry.createdAt),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu talep onaylandı.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if ((entry.text ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.text!.trim(),
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ],
            ],
          ),
        );
      case RequestEntryKind.producerFeedback:
        return _EntryShell(
          stripe: AppColors.softBlue.withValues(alpha: 0.8),
          icon: Icons.reply_outlined,
          title: 'Üretici — geri bildirim',
          trailing: dateFmt.format(entry.createdAt),
          body: Text(
            entry.text ?? '',
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        );
    }
  }
}

class _EntryShell extends StatelessWidget {
  const _EntryShell({
    required this.stripe,
    required this.icon,
    required this.title,
    required this.trailing,
    required this.body,
  });

  final Color stripe;
  final IconData icon;
  final String title;
  final String trailing;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(9),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Text(
                          trailing,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    body,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
