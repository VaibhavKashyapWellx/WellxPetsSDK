import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sdk/xcoin_delegate.dart';
import 'sdk_providers.dart';

final walletBalanceProvider = FutureProvider<WellxWalletBalance>((ref) async {
  final delegate = ref.watch(xCoinDelegateProvider);
  return delegate.getBalance();
});

final balanceStreamProvider = StreamProvider<WellxWalletBalance>((ref) {
  final delegate = ref.watch(xCoinDelegateProvider);
  return delegate.balanceStream;
});
