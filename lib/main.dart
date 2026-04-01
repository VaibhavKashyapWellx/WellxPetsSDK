// This file is the module's entry point when running standalone (flutter run).
// In production, the host app uses WellxPetsSDK.buildRootWidget() instead.

import 'dart:async';
import 'package:flutter/material.dart';
import 'wellx_pets_sdk.dart';
import 'src/sdk/auth_delegate.dart';
import 'src/sdk/xcoin_delegate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keys are injected at build time via --dart-define:
  //   flutter run --dart-define=SUPABASE_ANON_KEY=... --dart-define=ANTHROPIC_API_KEY=...
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const anthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  assert(supabaseAnonKey.isNotEmpty,
      'Missing SUPABASE_ANON_KEY — pass --dart-define=SUPABASE_ANON_KEY=<key>');
  assert(anthropicApiKey.isNotEmpty,
      'Missing ANTHROPIC_API_KEY — pass --dart-define=ANTHROPIC_API_KEY=<key>');

  final sdk = await WellxPetsSDK.initialize(
    config: const WellxPetsConfig(
      supabaseUrl: 'https://raniqvhddcwfukvaljer.supabase.co',
      supabaseAnonKey: supabaseAnonKey,
      anthropicApiKey: anthropicApiKey,
    ),
    authDelegate: _MockAuthDelegate(),
    xCoinDelegate: _MockXCoinDelegate(),
  );

  runApp(sdk.buildRootWidget());
}

/// Mock auth delegate for standalone development.
class _MockAuthDelegate implements WellxAuthDelegate {
  final _controller = StreamController<WellxAuthState>.broadcast();

  @override
  WellxAuthState get currentAuthState => const WellxAuthState(
        isAuthenticated: true,
        userId: 'mock-user-id',
        accessToken: 'mock-token',
        email: 'demo@wellx.com',
        firstName: 'Demo',
        lastName: 'User',
      );

  @override
  Stream<WellxAuthState> get authStateStream => _controller.stream;

  @override
  Future<String> refreshToken() async => 'mock-refreshed-token';

  @override
  void onAuthInvalidated() {}
}

/// Mock xCoin delegate for standalone development.
class _MockXCoinDelegate implements WellxXCoinDelegate {
  int _balance = 100;
  final _controller = StreamController<WellxWalletBalance>.broadcast();

  @override
  Future<int> onCoinEvent(WellxCoinEvent event) async {
    _balance += event.suggestedCoins;
    return _balance;
  }

  @override
  Future<WellxWalletBalance> getBalance() async => WellxWalletBalance(
        coinsBalance: _balance,
        totalCoinsEarned: _balance,
      );

  @override
  Stream<WellxWalletBalance> get balanceStream => _controller.stream;
}
