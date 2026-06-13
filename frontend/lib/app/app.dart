import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/push/fcm_service.dart';
import '../core/sync/push_navigation.dart';
import '../core/sync/remote_data_sync.dart';
import '../features/auth/application/session_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// GoRouter redirect sırasında `child` geçici null olabiliyor; siyah pencere yerine yükleme.
class _RouterLoadingFallback extends StatelessWidget {
  const _RouterLoadingFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class TextileFlowApp extends StatefulWidget {
  const TextileFlowApp({super.key});

  @override
  State<TextileFlowApp> createState() => _TextileFlowAppState();
}

class _TextileFlowAppState extends State<TextileFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FcmService.listenForeground(onMessage: _handleForegroundPush);
    FcmService.listenNotificationOpen(onOpen: _handleNotificationOpen);
    _consumeInitialNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final ctx = appRouter.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    final container = ProviderScope.containerOf(ctx, listen: false);
    RemoteDataSync.scheduleRefresh(container);
  }

  ProviderContainer? _appContainer() {
    final ctx = appRouter.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return null;
    return ProviderScope.containerOf(ctx, listen: false);
  }

  void _handleForegroundPush(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final container = _appContainer();
    if (container == null) return;

    RemoteDataSync.scheduleRefresh(container);

    final ctx = appRouter.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;

    final role = container.read(sessionControllerProvider).role;
    final targetRoute = pushTargetRoute(message, role);

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'Bildirim',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null) Text(notification.body!),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: targetRoute != null
            ? SnackBarAction(
                label: 'Görüntüle',
                onPressed: () => _handleNotificationOpen(message),
              )
            : null,
      ),
    );
  }

  Future<void> _consumeInitialNotification() async {
    await FcmService.consumeInitialMessage(onOpen: _handleNotificationOpen);
  }

  Future<void> _goWhenSessionReady(String targetRoute) async {
    for (var i = 0; i < 14; i++) {
      final container = _appContainer();
      if (container != null) {
        final session = container.read(sessionControllerProvider);
        if (session.isLoaded && session.isAuthenticated) {
          navigatePushTarget(targetRoute);
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    appRouter.go('/catalog');
    navigatePushTarget(targetRoute);
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    final container = _appContainer();
    if (container != null) {
      await RemoteDataSync.refreshAfterRemoteEvent(container);
    }

    final role = container?.read(sessionControllerProvider).role;
    final route = pushTargetRoute(message, role);
    if (route != null) {
      await _goWhenSessionReady(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TextileFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.35,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child ?? const _RouterLoadingFallback(),
        );
      },
    );
  }
}
