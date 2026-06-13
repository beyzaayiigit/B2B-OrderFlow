import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'go_router_refresh.dart';
import '../features/auth/application/session_controller.dart';
import '../features/catalog/domain/product_model.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/catalog/presentation/catalog_page.dart';
import '../features/orders/domain/tracked_order.dart';
import '../features/orders/presentation/create_order_page.dart';
import '../features/orders/presentation/tracking_order_detail_page.dart';
import '../features/orders/presentation/buyer_shipped_page.dart';
import '../features/orders/presentation/tracking_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/requests/presentation/buyer_requests_page.dart';
import '../features/requests/presentation/producer_requests_page.dart';
import '../features/requests/presentation/request_thread_detail_page.dart';
import '../features/producer/catalog_admin/presentation/producer_catalog_admin_page.dart';
import '../features/producer/catalog_admin/presentation/producer_catalog_product_editor_page.dart';
import '../features/producer/presentation/producer_order_detail_page.dart';
import '../features/producer/presentation/producer_orders_page.dart';
import '../features/producer/presentation/producer_production_page.dart';
import '../features/producer/presentation/producer_shipped_page.dart';
import '../shared/types/user_role.dart';
import '../shared/widgets/app_shell.dart';
import '../shared/widgets/root_overlay_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}

UserRole _roleFrom(BuildContext context) {
  return ProviderScope.containerOf(
    context,
    listen: false,
  ).read(sessionControllerProvider).role ?? UserRole.buyer;
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: goRouterRefresh,
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const _SplashView()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RootOverlayScaffold(
        child: ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/requests',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final role = _roleFrom(context);
        return RootOverlayScaffold(
          child: role == UserRole.producer
              ? const ProducerRequestsPage()
              : const BuyerRequestsPage(),
        );
      },
      routes: [
        GoRoute(
          path: 'thread/:threadId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['threadId'];
            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('Geçersiz adres')),
              );
            }
            return RequestThreadDetailPage(threadId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/producer/incoming/:orderCode',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final code = state.pathParameters['orderCode'];
        if (code == null) {
          return const Scaffold(
            body: Center(child: Text('Geçersiz adres')),
          );
        }
        final role = _roleFrom(context);
        if (role != UserRole.producer) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erişim')),
            body: const Center(child: Text('Bu sayfaya erişiminiz yok.')),
          );
        }
        return ProducerOrderDetailPage(orderCode: code);
      },
    ),
    GoRoute(
      path: '/producer/catalog-admin/new',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final role = _roleFrom(context);
        if (role != UserRole.producer) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erişim')),
            body: const Center(child: Text('Bu sayfaya erişiminiz yok.')),
          );
        }
        return const ProducerCatalogProductEditorPage(initial: null);
      },
    ),
    GoRoute(
      path: '/producer/catalog-admin/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final role = _roleFrom(context);
        if (role != UserRole.producer) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erişim')),
            body: const Center(child: Text('Bu sayfaya erişiminiz yok.')),
          );
        }
        final extra = state.extra;
        if (extra is! ProductModel) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ürün')),
            body: const Center(child: Text('Ürün verisi bulunamadı.')),
          );
        }
        return ProducerCatalogProductEditorPage(initial: extra);
      },
    ),
    GoRoute(
      path: '/tracking/order/:orderNo',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final raw = state.pathParameters['orderNo'];
        if (raw == null) {
          return const Scaffold(
            body: Center(child: Text('Geçersiz adres')),
          );
        }
        final id = Uri.decodeComponent(raw).trim();
        final extra = state.extra;
        if (extra is TrackedOrder) {
          final matches = extra.orderNo == id ||
              (extra.producerOrderCode != null &&
                  extra.producerOrderCode == id);
          if (matches) {
            return TrackingOrderDetailPage(order: extra);
          }
        }
        return TrackingOrderDetailLoader(orderNoOrCode: id);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalog',
              pageBuilder: (context, state) => _noTransitionPage(
                state,
                _roleFrom(context) == UserRole.producer
                    ? const ProducerOrdersPage()
                    : const CatalogPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders/new',
              pageBuilder: (context, state) => _noTransitionPage(
                state,
                _roleFrom(context) == UserRole.producer
                    ? const ProducerProductionPage()
                    : CreateOrderPage(
                        selectedModel: state.extra is ProductModel
                            ? state.extra as ProductModel
                            : null,
                      ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tracking',
              redirect: (context, state) {
                if (_roleFrom(context) == UserRole.producer) {
                  return '/producer/shipped';
                }
                return null;
              },
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const TrackingPage()),
            ),
            GoRoute(
              path: '/producer/shipped',
              redirect: (context, state) {
                if (_roleFrom(context) != UserRole.producer) {
                  return '/tracking';
                }
                return null;
              },
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const ProducerShippedPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/buyer/shipped',
              redirect: (context, state) {
                if (_roleFrom(context) == UserRole.producer) {
                  return '/producer/catalog-admin';
                }
                return null;
              },
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const BuyerShippedPage()),
            ),
            GoRoute(
              path: '/producer/catalog-admin',
              redirect: (context, state) {
                if (_roleFrom(context) != UserRole.producer) {
                  return '/buyer/shipped';
                }
                return null;
              },
              pageBuilder: (context, state) => _noTransitionPage(
                state,
                const ProducerCatalogAdminPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(sessionControllerProvider);
    final loc = state.matchedLocation;

    if (!session.isLoaded) {
      return loc == '/splash' ? null : '/splash';
    }

    final isAuthRoute = loc == '/login' || loc == '/splash';

    if (!session.isAuthenticated) {
      return isAuthRoute ? (loc == '/splash' ? '/login' : null) : '/login';
    }

    if (isAuthRoute) {
      return '/catalog';
    }

    final role = session.role;
    if (role == UserRole.producer && loc.startsWith('/tracking')) {
      return '/catalog';
    }
    if (role == UserRole.buyer && loc.startsWith('/producer/')) {
      if (loc == '/producer/shipped') return '/buyer/shipped';
      return '/catalog';
    }
    if (role == UserRole.producer && loc == '/buyer/shipped') {
      return '/producer/shipped';
    }

    return null;
  },
);

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
