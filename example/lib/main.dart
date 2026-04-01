import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wellx_pets_sdk/wellx_pets_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
