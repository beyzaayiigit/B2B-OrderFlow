import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/requests/application/request_threads_notifier.dart';
import '../types/user_role.dart';
import 'whatsapp_contact_picker.dart';
import 'whatsapp_icon.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionControllerProvider).role ?? UserRole.buyer;
    final producerUnread = role == UserRole.producer
        ? ref.watch(producerRequestUnreadCountProvider)
        : 0;
    final buyerUnread = role == UserRole.buyer
        ? ref.watch(buyerRequestUnreadCountProvider)
        : 0;
    final requestUnread =
        role == UserRole.producer ? producerUnread : buyerUnread;
    final whatsAppContacts = role == UserRole.producer
        ? producerWhatsAppContacts
        : buyerWhatsAppContacts;
    final canStackPop = context.canPop();
    final destinations = role == UserRole.producer
        ? const [
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: 'Gelenler',
            ),
            NavigationDestination(
              icon: Icon(Icons.factory_outlined),
              label: 'Üretim',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Sevk',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Katalog',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Katalog',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Sipariş',
            ),
            NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              label: 'Takip',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Sevk',
            ),
          ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) return;

        final rootNav = Navigator.maybeOf(context, rootNavigator: true);
        if (rootNav != null && rootNav.canPop()) {
          rootNav.pop();
          return;
        }

        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: canStackPop ? 0 : 16,
          leading: canStackPop
              ? IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: _BrandTitle(role: role),
          actions: [
            IconButton(
              tooltip: 'WhatsApp',
              onPressed: () =>
                  showWhatsAppContactPicker(context, whatsAppContacts),
              icon: const WhatsAppIcon(size: 26),
            ),
            IconButton(
              tooltip: role == UserRole.producer
                  ? 'Alıcı güncelleme talepleri'
                  : 'İstekler',
              onPressed: () => context.push('/requests'),
              icon: Badge(
                isLabelVisible: requestUnread > 0,
                label: Text(
                  requestUnread > 9 ? '9+' : '$requestUnread',
                ),
                child: const Icon(Icons.forum_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Hesap',
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            final role =
                ref.read(sessionControllerProvider).role ?? UserRole.buyer;
            final path = _pathFor(index, role);
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
            if (GoRouterState.of(context).uri.path != path) {
              context.go(path);
            }
          },
          destinations: destinations,
        ),
      ),
    );
  }

  String _pathFor(int index, UserRole role) {
    if (role == UserRole.producer) {
      return switch (index) {
        0 => '/catalog',
        1 => '/orders/new',
        2 => '/producer/shipped',
        3 => '/producer/catalog-admin',
        _ => '/catalog',
      };
    }
    return switch (index) {
      0 => '/catalog',
      1 => '/orders/new',
      2 => '/tracking',
      3 => '/buyer/shipped',
      _ => '/catalog',
    };
  }
}

/// AppBar başlığında küçük şirket logosu + şirket adı + panel adını
/// kapsül halinde tek bir blokta gösterir.
class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandBadge(role: role),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.companyName,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.4,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                role.panelName,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          role.logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            Icons.storefront_outlined,
            size: 22,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }
}
