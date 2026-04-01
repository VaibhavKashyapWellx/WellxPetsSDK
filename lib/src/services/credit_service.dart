import '../models/credit_models.dart';
import '../sdk/xcoin_delegate.dart';
import 'supabase_client.dart';

/// Service for wallet and transaction operations.
///
/// Reading wallet/transaction data is done directly via Supabase.
/// Earning coins is delegated to the host app via [WellxXCoinDelegate],
/// which owns the coin-awarding logic. Spending credits is still done
/// directly against Supabase since it is an SDK-internal operation.
class CreditService {
  final WellxXCoinDelegate _xCoinDelegate;

  CreditService(this._xCoinDelegate);

  // ---------------------------------------------------------------------------
  // Wallet (read from Supabase)
  // ---------------------------------------------------------------------------

  /// Fetch the wallet for an owner, or create one if it doesn't exist.
  Future<CreditWallet> getOrCreateWallet(String ownerId) async {
    try {
      final existing = await SupabaseManager.instance.client
          .from('user_wallets')
          .select()
          .eq('owner_id', ownerId)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        return CreditWallet.fromJson(existing.first as Map<String, dynamic>);
      }

      // Create new wallet with zero balances
      final now = DateTime.now().toUtc().toIso8601String();
      final newWallet = {
        'owner_id': ownerId,
        'credits_balance': 0,
        'coins_balance': 0,
        'total_credits_purchased': 0,
        'total_coins_earned': 0,
        'created_at': now,
        'updated_at': now,
      };

      final created = await SupabaseManager.instance.client
          .from('user_wallets')
          .insert(newWallet)
          .select()
          .single();
      return CreditWallet.fromJson(created);
    } catch (e) {
      throw CreditServiceException('Failed to get or create wallet: $e');
    }
  }

  /// Fetch wallet without creating (returns null if not found).
  Future<CreditWallet?> getWallet(String ownerId) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('user_wallets')
          .select()
          .eq('owner_id', ownerId)
          .limit(1);

      if ((result as List).isEmpty) return null;
      return CreditWallet.fromJson(result.first as Map<String, dynamic>);
    } catch (e) {
      throw CreditServiceException('Failed to fetch wallet: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Transactions (read from Supabase)
  // ---------------------------------------------------------------------------

  /// Fetch recent transactions for an owner.
  Future<List<CreditTransaction>> getTransactions(
    String ownerId, {
    int limit = 50,
  }) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('credit_transactions')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (result as List)
          .map((e) => CreditTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CreditServiceException('Failed to fetch transactions: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Earn Coins (delegate to host via xCoin delegate)
  // ---------------------------------------------------------------------------

  /// Earn coins for a completed action by delegating to the host app.
  ///
  /// The host app's [WellxXCoinDelegate.onCoinEvent] handles deduplication,
  /// wallet updates, and transaction recording. This keeps the SDK decoupled
  /// from the host's coin-awarding strategy.
  Future<int> earnCoins({
    required WellxCoinAction action,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = WellxCoinEvent(
        action: action,
        suggestedCoins: action.defaultCoins,
        referenceId: referenceId,
        metadata: metadata,
      );
      final newBalance = await _xCoinDelegate.onCoinEvent(event);
      return newBalance;
    } catch (e) {
      throw CreditServiceException('Failed to earn coins: $e');
    }
  }

  /// Get current wallet balance from the host delegate.
  ///
  /// This is the preferred way to get the balance since the host may have
  /// made changes outside the SDK.
  Future<WellxWalletBalance> getBalance() async {
    try {
      return await _xCoinDelegate.getBalance();
    } catch (e) {
      throw CreditServiceException('Failed to get balance: $e');
    }
  }

  /// Stream of balance updates from the host.
  Stream<WellxWalletBalance> get balanceStream => _xCoinDelegate.balanceStream;

  // ---------------------------------------------------------------------------
  // Spend Credits (direct to Supabase -- SDK-internal operation)
  // ---------------------------------------------------------------------------

  /// Spend credits/coins on a purchase. Deducts from credits first, then coins.
  Future<CreditWallet> spendCredits({
    required String ownerId,
    required int amount,
    required String description,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final wallet = await getOrCreateWallet(ownerId);

      if (wallet.totalBalance < amount) {
        throw CreditServiceException(
          'Insufficient balance. Please add more credits.',
        );
      }

      // Deduct from credits first, then coins
      final creditsToDeduct =
          amount < wallet.creditsBalance ? amount : wallet.creditsBalance;
      final coinsToDeduct = amount - creditsToDeduct;

      final newCredits = wallet.creditsBalance - creditsToDeduct;
      final newCoins = wallet.coinsBalance - coinsToDeduct;
      final now = DateTime.now().toUtc().toIso8601String();

      // Update wallet
      await SupabaseManager.instance.client.from('user_wallets').update({
        'credits_balance': newCredits,
        'coins_balance': newCoins,
        'updated_at': now,
      }).eq('id', wallet.id);

      // Record credit spend transaction (if any credits deducted)
      if (creditsToDeduct > 0) {
        await SupabaseManager.instance.client
            .from('credit_transactions')
            .insert({
          'owner_id': ownerId,
          'type': 'credit_spend',
          'amount': creditsToDeduct,
          'currency': 'credits',
          'balance_after': newCredits,
          'description': description,
          'reference_id': referenceId,
          'reference_type': referenceType,
        });
      }

      // Record coin spend transaction (if any coins deducted)
      if (coinsToDeduct > 0) {
        await SupabaseManager.instance.client
            .from('credit_transactions')
            .insert({
          'owner_id': ownerId,
          'type': 'coin_spend',
          'amount': coinsToDeduct,
          'currency': 'coins',
          'balance_after': newCoins,
          'description': description,
          'reference_id': referenceId,
          'reference_type': referenceType,
        });
      }

      return wallet.copyWith(
        creditsBalance: newCredits,
        coinsBalance: newCoins,
        updatedAt: now,
      );
    } catch (e) {
      if (e is CreditServiceException) rethrow;
      throw CreditServiceException('Failed to spend credits: $e');
    }
  }
}

/// Exception thrown by [CreditService] operations.
class CreditServiceException implements Exception {
  final String message;
  const CreditServiceException(this.message);

  @override
  String toString() => 'CreditServiceException: $message';
}
