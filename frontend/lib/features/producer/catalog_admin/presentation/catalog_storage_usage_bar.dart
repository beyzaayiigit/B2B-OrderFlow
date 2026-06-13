import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/config/supabase_ready_provider.dart';
import '../application/catalog_storage_usage_provider.dart';
import '../data/catalog_storage_service.dart';

/// Üretici katalog admin: görsel depolama kotası.
class CatalogStorageUsageBar extends ConsumerWidget {
  const CatalogStorageUsageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(supabaseReadyProvider);
    final configured = AppEnv.supabaseConfigured;

    if (!configured) {
      return const _HintCard(
        icon: Icons.settings_outlined,
        message:
            'Depolama kotası için proje kökündeki .env dosyasında SUPABASE_URL tanımlı olmalı.',
      );
    }

    if (!ready) {
      return const _HintCard(
        icon: Icons.cloud_off_outlined,
        message: 'Supabase bağlantısı kuruluyor veya başarısız. '
            'Uygulamayı tamamen kapatıp yeniden açın.',
      );
    }

    final async = ref.watch(catalogStorageUsageProvider);

    return async.when(
      data: (usage) => _UsageCard(usage: usage),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Depolama hesaplanıyor…'),
            ],
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.critical),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Depolama bilgisi alınamadı: $e',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref
                      .read(catalogStorageUsageProvider.notifier)
                      .refresh(),
                  child: const Text('Yenile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});

  final CatalogStorageUsage usage;

  @override
  Widget build(BuildContext context) {
    final pct = (usage.ratio * 100).round();
    final barColor = usage.isFull
        ? AppColors.critical
        : usage.isNearLimit
            ? AppColors.warning
            : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: barColor, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Görsel depolama',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatStorageMb(usage.usedBytes)} / ${formatStorageGb(usage.quotaBytes)} kullanılıyor',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: usage.ratio,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                color: barColor,
              ),
            ),
            if (usage.isNearLimit) ...[
              const SizedBox(height: 8),
              Text(
                usage.isFull
                    ? 'Kota dolu. Yeni fotoğraf yükleyemezsiniz.'
                    : 'Kota dolmak üzere (%80+).',
                style: TextStyle(
                  fontSize: 11,
                  color: barColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
