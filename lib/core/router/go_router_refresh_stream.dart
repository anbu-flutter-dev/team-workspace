import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a bloc's state stream to go_router's refreshListenable so
/// navigation reacts to auth state without a rebuild-triggering widget.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
