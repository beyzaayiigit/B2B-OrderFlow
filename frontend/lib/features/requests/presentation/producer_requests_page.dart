import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/list_sort_count_row.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../application/request_threads_notifier.dart';
import '../domain/request_thread.dart';
import 'open_request_thread.dart';
import 'request_thread_order_status_row.dart';

/// Üretici: alıcının sipariş bazlı güncelleme taleplerinin listesi.
class ProducerRequestsPage extends ConsumerStatefulWidget {
  const ProducerRequestsPage({super.key});

  @override
  ConsumerState<ProducerRequestsPage> createState() =>
      _ProducerRequestsPageState();
}

class _ProducerRequestsPageState extends ConsumerState<ProducerRequestsPage> {
  static final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

  String _query = '';
  /// `true`: son aktivite yeniden eskiye (`lastActivityAt` azalan).
  bool _newestFirst = true;

  int _compareByLastActivity(RequestThread a, RequestThread b, {required bool newestFirst}) {
    final ta = a.lastActivityAt;
    final tb = b.lastActivityAt;
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return newestFirst ? tb.compareTo(ta) : ta.compareTo(tb);
  }

  void _sortThreads(List<RequestThread> list) {
    list.sort(
      (a, b) => _compareByLastActivity(a, b, newestFirst: _newestFirst),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(requestThreadsProvider);
    final threads = listState.items;
    final filtered = threads.where((t) {
      return matchesAnySearchPrefix(
        [t.orderNo, t.productLabel, t.lastPreview],
        _query,
      );
    }).toList();
    _sortThreads(filtered);

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Alıcı güncelleme talepleri',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          '“Yanıt gerekli”: Son hareket alıcı talebi; üretici onay veya geri bildirim vermeli. “Güncel”: Son işlem sizden veya yeni alıcı talebi yok.',
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
        const SizedBox(height: 12),
        ListSortCountRow(
          count: filtered.length,
          arrowPointsUp: _newestFirst,
          unitLabel: 'talep',
          onToggle: () => setState(() => _newestFirst = !_newestFirst),
        ),
        const SizedBox(height: 16),
        if (threads.isEmpty)
          const _ProducerEmptyCard()
        else if (filtered.isEmpty)
          const _ProducerFilteredEmptyCard()
        else
          for (final thread in filtered) ...[
            _ProducerThreadCard(
              thread: thread,
              dateFmt: _dateFmt,
              onTap: () {
                ref
                    .read(requestThreadsProvider.notifier)
                    .markProducerRead(thread.id);
                context.push('/requests/thread/${thread.id}');
              },
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ProducerEmptyCard extends StatelessWidget {
  const _ProducerEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.inbox_outlined, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Henüz alıcıdan gelen güncelleme talebi yok.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProducerFilteredEmptyCard extends StatelessWidget {
  const _ProducerFilteredEmptyCard();

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

class _ProducerThreadCard extends StatelessWidget {
  const _ProducerThreadCard({
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
            border: Border.all(
              color: thread.hasPendingBuyerRequest
                  ? AppColors.warning.withValues(alpha: 0.55)
                  : AppColors.border,
              width: thread.hasPendingBuyerRequest ? 1.5 : 1,
            ),
            color: thread.hasPendingBuyerRequest
                ? AppColors.warning.withValues(alpha: 0.06)
                : AppColors.surfaceContainer.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (thread.hasPendingBuyerRequest) ...[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 28, right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    RequestThreadModelThumbnail(
                      productCode: thread.productCode,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: thread.hasPendingBuyerRequest
                                        ? AppColors.warning.withValues(alpha: 0.14)
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: thread.hasPendingBuyerRequest
                                          ? AppColors.warning.withValues(alpha: 0.45)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      thread.hasPendingBuyerRequest
                                          ? 'Yanıt gerekli'
                                          : 'Güncel',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: thread.hasPendingBuyerRequest
                                            ? AppColors.warning
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                  style: const TextStyle(fontSize: 14, height: 1.35),
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
