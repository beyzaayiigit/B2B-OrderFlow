import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/app_env.dart';
import '../core/config/supabase_bootstrap.dart';
import '../core/constants/brand_assets.dart';
import '../core/push/fcm_service.dart';
import '../shared/widgets/brand_logo_image.dart';
import 'app.dart';
import 'theme/app_colors.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;
  String? _configError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final splashMin = Future<void>.delayed(const Duration(seconds: 3));

    await AppEnv.load();
    try {
      await SupabaseBootstrap.init().timeout(const Duration(seconds: 12));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppBootstrap: init hatası: $e\n$st');
      }
    }

    if (!AppEnv.supabaseConfigured || !SupabaseBootstrap.isInitialized) {
      await splashMin;
      if (mounted) {
        setState(() {
          _configError =
              'Sunucu yapılandırması eksik. .env dosyasında Supabase '
              'bilgilerini tanımlayıp uygulamayı yeniden başlatın.';
          _ready = true;
        });
      }
      return;
    }

    try {
      await FcmService.init();
    } catch (e) {
      if (kDebugMode) debugPrint('AppBootstrap: FCM init hatası: $e');
    }

    await splashMin;
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _retryInit() async {
    setState(() {
      _ready = false;
      _configError = null;
    });
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Transform.translate(
                    offset: const Offset(-10, 0),
                    child: const BrandLogoImage(
                      assetPath: BrandAssets.textileFlowLogo,
                      height: 96,
                      maxWidth: 280,
                      fallbackLabel: 'TextileFlow',
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.navyDark,
                  ),
                ),
                const Spacer(flex: 5),
              ],
            ),
          ),
        ),
      );
    }

    if (_configError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: AppColors.navyDark,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bağlantı yapılandırılamadı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _configError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _retryInit,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeniden dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const TextileFlowApp();
  }
}
