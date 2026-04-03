import 'dart:async';
import 'package:flutter/foundation.dart';
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

    // Set initial session from host auth.
    // Prefer refresh token for full session restoration (enables auto-refresh).
    // Fall back to access token for environments that don't provide a refresh token.
    final authState = authDelegate.currentAuthState;
    if (authState.isAuthenticated) {
      final token = authState.refreshToken ?? authState.accessToken;
      if (token != null) {
        try {
          await manager.client.auth.setSession(token);
        } catch (e) {
          debugPrint('[WellxPetsSDK] Could not set initial session: $e');
        }
      }
    }

    // Listen for auth state changes from host
    manager._authSubscription = authDelegate.authStateStream.listen(
      (state) async {
        if (state.isAuthenticated) {
          final token = state.refreshToken ?? state.accessToken;
          if (token != null) {
            try {
              await manager.client.auth.setSession(token);
            } catch (e) {
              debugPrint('[WellxPetsSDK] Could not update session: $e');
            }
          }
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
