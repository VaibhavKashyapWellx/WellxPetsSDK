import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sdk/wellx_pets_config.dart';
import '../sdk/auth_delegate.dart';
import '../sdk/xcoin_delegate.dart';

/// Provider for SDK configuration. Overridden at SDK initialization.
final configProvider = Provider<WellxPetsConfig>((ref) {
  throw UnimplementedError('configProvider must be overridden by WellxPetsSDK');
});

/// Provider for the auth delegate. Overridden at SDK initialization.
final authDelegateProvider = Provider<WellxAuthDelegate>((ref) {
  throw UnimplementedError('authDelegateProvider must be overridden by WellxPetsSDK');
});

/// Provider for the xCoin delegate. Overridden at SDK initialization.
final xCoinDelegateProvider = Provider<WellxXCoinDelegate>((ref) {
  throw UnimplementedError('xCoinDelegateProvider must be overridden by WellxPetsSDK');
});
