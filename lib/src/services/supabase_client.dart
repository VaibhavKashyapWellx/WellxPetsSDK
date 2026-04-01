import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../sdk/wellx_pets_config.dart';
import '../sdk/auth_delegate.dart';

/// Manages the Supabase client connection.
///
/// Uses the host app's auth token (via [WellxAuthDelegate]) to authenticate.
class SupabaseManager {
  static SupabaseManager? _instance;

  static SupabaseManager get instance {
    assert(_instance != null, 'SupabaseManager.initialize() must be called first');
    return _instance!;
  }

  late final SupabaseClient client;
  StreamSubscription<WellxAuthState>? _authSubscription;

  SupabaseManager._();

  /// Initialize with config and auth delegate.
  static Future<void> initialize(
    WellxPetsConfig config,
    WellxAuthDelegate authDelegate,
  ) async {
    final manager = SupabaseManager._();

    // Create raw Supabase client (not using Supabase.initialize to avoid
    // conflicting with host app's Supabase instance)
    manager.client = SupabaseClient(
      config.supabaseUrl,
      config.supabaseAnonKey,
    );

    // Set initial session from host auth
    final authState = authDelegate.currentAuthState;
    if (authState.isAuthenticated && authState.accessToken != null) {
      await manager.client.auth.setSession(authState.accessToken!);
    }

    // Listen for auth state changes from host
    manager._authSubscription = authDelegate.authStateStream.listen(
      (state) async {
        if (state.isAuthenticated && state.accessToken != null) {
          await manager.client.auth.setSession(state.accessToken!);
        }
      },
    );

    _instance = manager;
  }

  /// Clean up resources.
  void dispose() {
    _authSubscription?.cancel();
    _instance = null;
  }
}
