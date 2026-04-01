import 'dart:async';

/// Actions that can earn xCoins within the SDK.
enum WellxCoinAction {
  dailyLogin(defaultCoins: 5, displayName: 'Daily Login'),
  completePetProfile(defaultCoins: 20, displayName: 'Complete Pet Profile'),
  uploadDocument(defaultCoins: 10, displayName: 'Upload Document'),
  logWalk(defaultCoins: 5, displayName: 'Log Walk'),
  chatDrLayla(defaultCoins: 10, displayName: 'Chat with Dr. Layla'),
  healthCheck(defaultCoins: 10, displayName: 'Health Check'),
  logSymptom(defaultCoins: 5, displayName: 'Log Symptom');

  final int defaultCoins;
  final String displayName;

  const WellxCoinAction({
    required this.defaultCoins,
    required this.displayName,
  });
}

/// Event fired when the user earns coins in the SDK.
class WellxCoinEvent {
  final WellxCoinAction action;
  final int suggestedCoins;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  const WellxCoinEvent({
    required this.action,
    required this.suggestedCoins,
    this.referenceId,
    this.metadata,
  });
}

/// Balance information from the host wallet.
class WellxWalletBalance {
  final int coinsBalance;
  final int creditsBalance;
  final int totalCoinsEarned;

  const WellxWalletBalance({
    required this.coinsBalance,
    this.creditsBalance = 0,
    this.totalCoinsEarned = 0,
  });

  int get totalBalance => coinsBalance + creditsBalance;
}

/// Abstract delegate for the xCoin reward system.
///
/// The host Wellx app implements this to manage coin rewards.
/// The SDK fires events when users complete coin-earning actions,
/// and the host awards xCoins via its own system.
abstract class WellxXCoinDelegate {
  /// Called when user completes a coin-earning action inside the SDK.
  /// Host awards xCoins and returns the new coin balance.
  Future<int> onCoinEvent(WellxCoinEvent event);

  /// Get current wallet balance for display.
  Future<WellxWalletBalance> getBalance();

  /// Stream of balance updates pushed by the host when balance changes externally.
  Stream<WellxWalletBalance> get balanceStream;
}
