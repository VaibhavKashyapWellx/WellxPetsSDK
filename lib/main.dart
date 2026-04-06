// This file is the module's entry point when running standalone (flutter run).
// In production, the host app uses WellxPetsSDK.buildRootWidget() instead.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wellx_pets_sdk.dart';

const _supabaseUrl = 'https://raniqvhddcwfukvaljer.supabase.co';

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

  runApp(_DevApp(
    supabaseAnonKey: supabaseAnonKey,
    anthropicApiKey: anthropicApiKey,
  ));
}

// ---------------------------------------------------------------------------
// Dev wrapper: login screen → SDK
// ---------------------------------------------------------------------------

class _DevApp extends StatelessWidget {
  final String supabaseAnonKey;
  final String anthropicApiKey;

  const _DevApp({
    required this.supabaseAnonKey,
    required this.anthropicApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4D33B3),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: _LoginScreen(
        supabaseAnonKey: supabaseAnonKey,
        anthropicApiKey: anthropicApiKey,
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  final String supabaseAnonKey;
  final String anthropicApiKey;

  const _LoginScreen({
    required this.supabaseAnonKey,
    required this.anthropicApiKey,
  });

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailController = TextEditingController(text: 'demo@wellx.com');
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseClient(_supabaseUrl, widget.supabaseAnonKey);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _launchSDK(response.session!);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (response.session != null) {
        _launchSDK(response.session!);
      } else {
        setState(() => _error = 'Check your email to confirm, then sign in.');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _launchSDK(Session session) {
    final authDelegate = _RealAuthDelegate(session: session, supabase: _supabase);
    final xCoinDelegate = _MockXCoinDelegate();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _SDKLoader(
          supabaseAnonKey: widget.supabaseAnonKey,
          anthropicApiKey: widget.anthropicApiKey,
          authDelegate: authDelegate,
          xCoinDelegate: xCoinDelegate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐾', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text('WellxPets Dev',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 8),
                Text('Sign in to Supabase to test the SDK',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        )),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _signUp,
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SDK loader — initializes and shows the SDK widget
// ---------------------------------------------------------------------------

class _SDKLoader extends StatefulWidget {
  final String supabaseAnonKey;
  final String anthropicApiKey;
  final _RealAuthDelegate authDelegate;
  final _MockXCoinDelegate xCoinDelegate;

  const _SDKLoader({
    required this.supabaseAnonKey,
    required this.anthropicApiKey,
    required this.authDelegate,
    required this.xCoinDelegate,
  });

  @override
  State<_SDKLoader> createState() => _SDKLoaderState();
}

class _SDKLoaderState extends State<_SDKLoader> {
  Widget? _sdkWidget;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  Future<void> _initSDK() async {
    final sdk = await WellxPetsSDK.initialize(
      config: WellxPetsConfig(
        supabaseUrl: _supabaseUrl,
        supabaseAnonKey: widget.supabaseAnonKey,
        anthropicApiKey: widget.anthropicApiKey,
      ),
      authDelegate: widget.authDelegate,
      xCoinDelegate: widget.xCoinDelegate,
    );
    if (mounted) {
      setState(() => _sdkWidget = sdk.buildRootWidget());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _sdkWidget ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}

// ---------------------------------------------------------------------------
// Real auth delegate — wraps a live Supabase session
// ---------------------------------------------------------------------------

class _RealAuthDelegate implements WellxAuthDelegate {
  final SupabaseClient _supabase;
  Session _session;
  final _controller = StreamController<WellxAuthState>.broadcast();

  _RealAuthDelegate({
    required Session session,
    required SupabaseClient supabase,
  })  : _session = session,
        _supabase = supabase;

  @override
  WellxAuthState get currentAuthState => WellxAuthState(
        isAuthenticated: true,
        userId: _session.user.id,
        accessToken: _session.accessToken,
        refreshToken: _session.refreshToken,
        email: _session.user.email,
        firstName: _session.user.userMetadata?['first_name'] as String? ?? 'Dev',
        lastName: _session.user.userMetadata?['last_name'] as String? ?? 'User',
      );

  @override
  Stream<WellxAuthState> get authStateStream => _controller.stream;

  @override
  Future<String> refreshToken() async {
    final response = await _supabase.auth.refreshSession();
    _session = response.session!;
    _controller.add(currentAuthState);
    return _session.accessToken;
  }

  @override
  void onAuthInvalidated() {
    debugPrint('[DevApp] Auth invalidated — session expired');
  }
}

// ---------------------------------------------------------------------------
// Mock xCoin delegate (unchanged)
// ---------------------------------------------------------------------------

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
