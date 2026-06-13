import 'package:flutter/foundation.dart';

/// GoRouter `redirect` oturum gibi dış state ile senkron kalsın diye
/// [SessionController] güncellemelerinde [notifyListeners] tetiklenir.
final class GoRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Router ile session arasında döngüsel import olmaması için ayrı dosya.
final goRouterRefresh = GoRouterRefresh();
