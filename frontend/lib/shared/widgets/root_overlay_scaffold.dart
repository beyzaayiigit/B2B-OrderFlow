import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell dışında (profil, istekler) tam ekran sayfalar için AppBar + geri.
class RootOverlayScaffold extends StatelessWidget {
  const RootOverlayScaffold({
    required this.child,
    this.title,
    super.key,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/catalog');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: title != null
            ? Text(title!, style: const TextStyle(fontWeight: FontWeight.w800))
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: child),
    );
  }
}
