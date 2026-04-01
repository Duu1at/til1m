import 'dart:async';

import 'package:flutter/foundation.dart';

/// Wraps a Stream into a ChangeNotifier so GoRouter can use it
/// as refreshListenable and re-evaluate the redirect callback
/// whenever the stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
