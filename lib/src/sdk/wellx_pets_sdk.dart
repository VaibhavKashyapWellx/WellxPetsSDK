import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wellx_pets_config.dart';
import 'auth_delegate.dart';
import 'xcoin_delegate.dart';
import '../services/supabase_client.dart';
import '../theme/wellx_pets_theme.dart';
import '../navigation/navigation_router.dart';
import '../providers/sdk_providers.dart';

/// Main entry point for the WellxPetsSDK.
///
/// Initialize with [initialize], then embed [buildRootWidget] in your widget tree.
class WellxPetsSDK {
  static WellxPetsSDK? _instance;

  /// Access the initialized SDK instance.
  static WellxPetsSDK get instance {
    assert(_instance != null, 'WellxPetsSDK.initialize() must be called first');
    return _instance!;
  }

  final WellxPetsConfig config;
  final WellxAuthDelegate authDelegate;
  final WellxXCoinDelegate xCoinDelegate;

  WellxPetsSDK._({
    required this.config,
    required this.authDelegate,
    required this.xCoinDelegate,
  });

  /// Initialize the SDK. Must be called before [buildRootWidget].
  static Future<WellxPetsSDK> initialize({
    required WellxPetsConfig config,
    required WellxAuthDelegate authDelegate,
    required WellxXCoinDelegate xCoinDelegate,
  }) async {
    // Initialize Supabase with delegate-based auth
    await SupabaseManager.initialize(config, authDelegate);

    final sdk = WellxPetsSDK._(
      config: config,
      authDelegate: authDelegate,
      xCoinDelegate: xCoinDelegate,
    );
    _instance = sdk;
    return sdk;
  }

  /// Returns the root widget for embedding in the host app's widget tree.
  Widget buildRootWidget() {
    return ProviderScope(
      overrides: [
        configProvider.overrideWithValue(config),
        authDelegateProvider.overrideWithValue(authDelegate),
        xCoinDelegateProvider.overrideWithValue(xCoinDelegate),
      ],
      child: const _WellxPetsApp(),
    );
  }

  /// Teardown the SDK and release resources.
  Future<void> dispose() async {
    SupabaseManager.instance.dispose();
    _instance = null;
  }
}

class _WellxPetsApp extends ConsumerWidget {
  const _WellxPetsApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Wellx Pets',
      theme: WellxPetsTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
