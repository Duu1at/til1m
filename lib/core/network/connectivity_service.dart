import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService() {
    unawaited(_init());
  }

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onlineStream => _controller.stream;

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _isOnline = _connected(initial);

      _sub = _connectivity.onConnectivityChanged.listen(
        (results) {
          final online = _connected(results);
          if (online == _isOnline) return;
          _isOnline = online;
          if (!_controller.isClosed) _controller.add(online);
        },
        onError: (Object e) =>
            debugPrint('[ConnectivityService] stream error: $e'),
      );
    } on Object catch (e) {
      debugPrint('[ConnectivityService] init error: $e');
    }
  }

  static bool _connected(List<ConnectivityResult> results) => results.any(
    (r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet,
  );

  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_controller.close());
  }
}
