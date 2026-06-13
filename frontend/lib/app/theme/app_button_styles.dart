import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Eyleme göre semantik buton stilleri.
/// Birincil eylem temadaki varsayılan (indigo) stili kullanır; bu yardımcılar
/// yalnızca olumlu (ileri taşıyan) ve yıkıcı eylemleri renkle ayırır.
abstract final class AppButtonStyles {
  static ButtonStyle _filled(Color background) => FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );

  /// Onaylama / kabul gibi olumlu sonuç (yeşil).
  static ButtonStyle get positive => _filled(AppColors.success);

  /// Üretim / ilerletme gibi aktif akış adımı (teal).
  static ButtonStyle get progress => _filled(AppColors.softBlue);

  /// Sevk / tamamlama (mor — marka birincil).
  static ButtonStyle get brand => _filled(AppColors.navy);

  /// Silme / reddetme / iptal gibi yıkıcı eylem (kırmızı).
  static ButtonStyle get danger => _filled(AppColors.critical);

  /// Yıkıcı eylemin çerçeveli (ikincil) hâli.
  static ButtonStyle get dangerOutlined => OutlinedButton.styleFrom(
    foregroundColor: AppColors.critical,
    minimumSize: const Size(0, 52),
    side: const BorderSide(color: AppColors.critical, width: 1.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
}
