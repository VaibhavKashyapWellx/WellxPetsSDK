import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Connectivity Service
// ---------------------------------------------------------------------------
// Exposes a stream of online/offline status.  Screens can watch
// [connectivityProvider] to show an offline banner when disconnected.

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get onlineStream => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _resultIsOnline(result);

    // Listen for changes
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultIsOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
        debugPrint('[ConnectivityService] ${online ? 'online' : 'offline'}');
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  bool _resultIsOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

// ── Providers ─────────────────────────────────────────────────────────────

/// Riverpod provider exposing the current online/offline state.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onlineStream;
});

/// Synchronous read of the current online state.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ??
      ConnectivityService.instance.isOnline;
});
