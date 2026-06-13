import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import 'whatsapp_icon.dart';

class WhatsAppContact {
  const WhatsAppContact({
    required this.displayName,
    required this.phoneDigits,
  });

  final String displayName;
  /// Uluslararası format, yalnızca rakam (ör. 905000000000).
  final String phoneDigits;
}

const producerWhatsAppContacts = [
  WhatsAppContact(
    displayName: 'Demo Üretici İletişim',
    phoneDigits: '905000000001',
  ),
];

const buyerWhatsAppContacts = [
  WhatsAppContact(
    displayName: 'Demo Alıcı İletişim',
    phoneDigits: '905000000002',
  ),
];

Future<void> launchWhatsAppChat(
  BuildContext context,
  WhatsAppContact contact,
) async {
  final uri = Uri.parse('https://wa.me/${contact.phoneDigits}');
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showLaunchError(context);
    }
  } catch (_) {
    if (context.mounted) _showLaunchError(context);
  }
}

void _showLaunchError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('WhatsApp açılamadı. Uygulamanın yüklü olduğundan emin olun.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> showWhatsAppContactPicker(
  BuildContext context,
  List<WhatsAppContact> contacts,
) async {
  if (contacts.isEmpty) return;

  if (contacts.length == 1) {
    await launchWhatsAppChat(context, contacts.first);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'WhatsApp ile iletişim',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sohbet açmak için kişi seçin',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            for (final contact in contacts)
              ListTile(
                leading: const WhatsAppIcon(size: 28),
                title: Text(
                  contact.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await launchWhatsAppChat(context, contact);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
