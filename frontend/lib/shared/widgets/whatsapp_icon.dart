import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Resmi WhatsApp marka ikonu (assets/icons/whatsapp.svg).
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/whatsapp.svg',
      width: size,
      height: size,
      semanticsLabel: 'WhatsApp',
    );
  }
}
