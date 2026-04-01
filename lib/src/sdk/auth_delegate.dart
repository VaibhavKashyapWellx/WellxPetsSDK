import 'dart:async';

/// Auth state provided by the host app.
class WellxAuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final String? email;
  final String? firstName;
  final String? lastName;

  const WellxAuthState({
    required this.isAuthenticated,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.email,
    this.firstName,
    this.lastName,
  });

  const WellxAuthState.unauthenticated()
      : isAuthenticated = false,
        userId = null,
        accessToken = null,
        refreshToken = null,
        email = null,
        firstName = null,
        lastName = null;

  String get fullName => [firstName, lastName].whereType<String>().join(' ');
}

/// Abstract delegate for authentication.
///
/// The host Wellx app implements this to provide auth state to the SDK.
/// The SDK never shows login/signup UI — auth is entirely managed by the host.
abstract class WellxAuthDelegate {
  /// Stream of auth state changes. SDK listens to this to stay in sync.
  Stream<WellxAuthState> get authStateStream;

  /// Current auth state (synchronous snapshot).
  WellxAuthState get currentAuthState;

  /// Called when SDK needs a fresh Supabase session token.
  /// Host should refresh and return new access token.
  Future<String> refreshToken();

  /// Called when SDK detects auth has become invalid.
  /// Host should navigate user back to login.
  void onAuthInvalidated();
}
