import '../models/shelter_models.dart';
import '../models/credit_models.dart';
import 'supabase_client.dart';

/// Service for shelter impact, profiles, dogs, and donation operations.
class ShelterService {
  // ── Global Impact ──

  Future<ShelterImpact> getGlobalImpact() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('shelter_impact')
          .select()
          .eq('id', 'global')
          .limit(1);
      final list = result as List;
      if (list.isEmpty) return ShelterImpact.empty;
      return ShelterImpact.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      throw ShelterServiceException('Failed to load global impact: $e');
    }
  }

  // ── Featured Dogs ──

  Future<List<ShelterDog>> getFeaturedDogs() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('shelter_dogs')
          .select()
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);
      return (result as List)
          .map((e) => ShelterDog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ShelterServiceException('Failed to load featured dogs: $e');
    }
  }

  Future<List<ShelterDog>> getAllDogs() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('shelter_dogs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return (result as List)
          .map((e) => ShelterDog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ShelterServiceException('Failed to load dogs: $e');
    }
  }

  // ── Shelter Profiles ──

  Future<List<ShelterProfile>> getShelterProfiles() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('shelter_profiles')
          .select()
          .eq('is_active', true)
          .order('total_coins_received', ascending: false)
          .limit(50);
      return (result as List)
          .map((e) => ShelterProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ShelterServiceException('Failed to load shelter profiles: $e');
    }
  }

  // ── Community Donation Pool ──

  Future<CommunityPool> getCommunityPool(String? currentUserId) async {
    try {
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);
      final monthStart = firstOfMonth.toUtc().toIso8601String();

      // Month label
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthLabel = '${months[now.month - 1]} ${now.year}';

      // Fetch donation transactions this month
      final result = await SupabaseManager.instance.client
          .from('credit_transactions')
          .select()
          .eq('type', 'coin_donate')
          .gte('created_at', monthStart);

      final donations = (result as List)
          .map((e) => CreditTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      final totalCoins =
          donations.fold<int>(0, (sum, d) => sum + d.amount);
      final uniqueDonors =
          donations.map((d) => d.ownerId).toSet().length;
      final userContribution = currentUserId != null
          ? donations
              .where((d) => d.ownerId == currentUserId)
              .fold<int>(0, (sum, d) => sum + d.amount)
          : 0;

      // Dynamic goal: 500-based tiers
      const goalBase = 500;
      final currentLevel = (totalCoins ~/ goalBase) + 1;
      final monthGoal = currentLevel * goalBase;

      return CommunityPool(
        totalCoins: totalCoins,
        donorCount: uniqueDonors,
        monthLabel: monthLabel,
        monthGoal: monthGoal,
        userContribution: userContribution,
      );
    } catch (e) {
      throw ShelterServiceException('Failed to load community pool: $e');
    }
  }

  // ── Allocate Coins ──

  Future<bool> allocateCoins({
    required String ownerId,
    required String shelterProfileId,
    required int coins,
  }) async {
    try {
      // 1. Check wallet balance
      final wallets = await SupabaseManager.instance.client
          .from('user_wallets')
          .select()
          .eq('owner_id', ownerId)
          .limit(1);

      final walletList = wallets as List;
      if (walletList.isEmpty) return false;
      final wallet =
          CreditWallet.fromJson(walletList.first as Map<String, dynamic>);
      if (wallet.coinsBalance < coins) return false;

      // 2. Record donation transaction
      final now = DateTime.now().toUtc().toIso8601String();
      await SupabaseManager.instance.client.from('credit_transactions').insert({
        'owner_id': ownerId,
        'type': 'coin_donate',
        'amount': coins,
        'currency': 'coins',
        'balance_after': wallet.coinsBalance - coins,
        'description': 'Shelter donation',
        'reference_id': shelterProfileId,
        'reference_type': 'shelter_donation',
      });

      // 3. Deduct from wallet
      await SupabaseManager.instance.client.from('user_wallets').update({
        'coins_balance': wallet.coinsBalance - coins,
        'updated_at': now,
      }).eq('id', wallet.id);

      return true;
    } catch (e) {
      throw ShelterServiceException('Failed to allocate coins: $e');
    }
  }
}

/// Exception thrown by [ShelterService] operations.
class ShelterServiceException implements Exception {
  final String message;
  const ShelterServiceException(this.message);

  @override
  String toString() => 'ShelterServiceException: $message';
}
