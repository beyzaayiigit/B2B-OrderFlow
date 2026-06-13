import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../application/request_threads_notifier.dart';
import '../domain/request_thread.dart';
import 'open_request_thread.dart';
import 'request_thread_order_status_row.dart';

/// Alıcı: sipariş bazlı güncelleme / değişiklik talepleri listesi.
class BuyerRequestsPage extends ConsumerStatefulWidget {
  const BuyerRequestsPage({super.key});

  @override
  ConsumerState<BuyerRequestsPage> createState() => _BuyerRequestsPageState();
}

class _BuyerRequestsPageState extends ConsumerState<BuyerRequestsPage> {
  static final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(requestThreadsProvider);
    final threads = listState.items;
    final filtered = threads
        .where(
          (t) => matchesAnySearchPrefix(
            [t.orderNo, t.productLabel, t.lastPreview],
            _query,
          ),
        )
        .toList();

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Güncelleme talepleri',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Gönderilmiş siparişlerde adet, teslim veya içerik değişikliği gibi taleplerinizi sipariş bağlamında üreticiye iletin.',
          style: TextStyle(color: AppColors.textMuted, height: 1.35),
        ),
        if (listState.isLoading && threads.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (listState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              listState.error!,
              style: const TextStyle(color: AppColors.critical),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Sipariş, ürün veya talep ara…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() => _query = ''),
                    icon: const Icon(Icons.close),
                    tooltip: 'Aramayı temizle',
                  ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        if (threads.isEmpty)
          const _EmptyRequestsCard()
        else if (filtered.isEmpty)
          const _BuyerFilteredEmptyCard()
        else
          for (final thread in filtered) ...[
            _RequestThreadCard(
              thread: thread,
              dateFmt: _dateFmt,
              onTap: () => context.push('/requests/thread/${thread.id}'),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  const _EmptyRequestsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.fact_check_outlined, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Henüz kayıtlı talep yok. Takip üzerinden siparişe bağlı talep oluşturma ileride eklenecek; şimdilik listeden detaya giderek talep girebilirsiniz.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerFilteredEmptyCard extends StatelessWidget {
  const _BuyerFilteredEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.search_off, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu kriterlere uyan talep yok. Aramayı değiştirin veya temizleyin.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestThreadCard extends StatelessWidget {
  const _RequestThreadCard({
    required this.thread,
    required this.dateFmt,
    required this.onTap,
  });

  final RequestThread thread;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = thread.lastActivityAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.surfaceContainer.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequestThreadModelThumbnail(
                      productCode: thread.productCode,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#${thread.orderNo}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              if (thread.unreadForBuyer) ...[
                                const SizedBox(width: 8),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.success.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Üretici yanıtı',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            thread.productLabel,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RequestThreadOrderStatusRow(
                  orderStatusKey: thread.orderStatusKey,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Son talep',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thread.lastPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (t != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dateFmt.format(t),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
