import 'package:flutter_test/flutter_test.dart';
import 'package:wellx_pets_sdk/src/models/credit_models.dart';

void main() {
  group('CreditWallet', () {
    const walletJson = {
      'id': 'w-1',
      'owner_id': 'user-1',
      'credits_balance': 500,
      'coins_balance': 200,
      'total_credits_purchased': 1000,
      'total_coins_earned': 350,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-06-01T00:00:00Z',
    };

    test('fromJson parses all fields', () {
      final wallet = CreditWallet.fromJson(walletJson);
      expect(wallet.id, 'w-1');
      expect(wallet.ownerId, 'user-1');
      expect(wallet.creditsBalance, 500);
      expect(wallet.coinsBalance, 200);
      expect(wallet.totalCreditsPurchased, 1000);
      expect(wallet.totalCoinsEarned, 350);
    });

    test('totalBalance returns sum of credits and coins', () {
      final wallet = CreditWallet.fromJson(walletJson);
      expect(wallet.totalBalance, 700);
    });

    test('copyWith updates only specified fields', () {
      final wallet = CreditWallet.fromJson(walletJson);
      final updated = wallet.copyWith(creditsBalance: 600, coinsBalance: 300);

      expect(updated.creditsBalance, 600);
      expect(updated.coinsBalance, 300);
      expect(updated.ownerId, 'user-1'); // unchanged
      expect(updated.totalCreditsPurchased, 1000); // unchanged
    });

    test('toJson produces correct keys', () {
      final wallet = CreditWallet.fromJson(walletJson);
      final json = wallet.toJson();
      expect(json['credits_balance'], 500);
      expect(json['coins_balance'], 200);
      expect(json['owner_id'], 'user-1');
    });
  });

  group('CreditTransaction', () {
    test('fromJson parses all fields', () {
      final tx = CreditTransaction.fromJson({
        'id': 'tx-1',
        'owner_id': 'user-1',
        'type': 'coin_earn',
        'amount': 10,
        'currency': 'coins',
        'balance_after': 210,
        'description': 'Daily login bonus',
        'reference_id': 'ref-1',
        'reference_type': 'daily_login',
        'created_at': '2024-06-01T00:00:00Z',
      });

      expect(tx.id, 'tx-1');
      expect(tx.type, 'coin_earn');
      expect(tx.amount, 10);
      expect(tx.currency, 'coins');
      expect(tx.balanceAfter, 210);
      expect(tx.description, 'Daily login bonus');
    });

    group('typeLabel', () {
      test('returns correct label for each type', () {
        const types = {
          'credit_purchase': 'Credits Purchased',
          'credit_award': 'Credits Awarded',
          'coin_earn': 'Coins Earned',
          'credit_spend': 'Credits Spent',
          'coin_spend': 'Coins Spent',
        };

        for (final entry in types.entries) {
          final tx = CreditTransaction(
            id: '1',
            ownerId: 'u1',
            type: entry.key,
            amount: 10,
            currency: 'coins',
            balanceAfter: 100,
          );
          expect(tx.typeLabel, entry.value);
        }
      });

      test('capitalizes unknown types', () {
        const tx = CreditTransaction(
          id: '1',
          ownerId: 'u1',
          type: 'bonus',
          amount: 10,
          currency: 'coins',
          balanceAfter: 100,
        );
        expect(tx.typeLabel, 'Bonus');
      });
    });

    group('typeIcon', () {
      test('returns correct icon for each type', () {
        const tx = CreditTransaction(
          id: '1',
          ownerId: 'u1',
          type: 'credit_purchase',
          amount: 10,
          currency: 'credits',
          balanceAfter: 100,
        );
        expect(tx.typeIcon, 'cart.fill');
      });
    });

    group('isIncoming', () {
      test('returns true for incoming types', () {
        for (final type in ['credit_purchase', 'credit_award', 'coin_earn']) {
          final tx = CreditTransaction(
            id: '1',
            ownerId: 'u1',
            type: type,
            amount: 10,
            currency: 'coins',
            balanceAfter: 100,
          );
          expect(tx.isIncoming, true, reason: '$type should be incoming');
        }
      });

      test('returns false for spending types', () {
        for (final type in ['credit_spend', 'coin_spend']) {
          final tx = CreditTransaction(
            id: '1',
            ownerId: 'u1',
            type: type,
            amount: 10,
            currency: 'coins',
            balanceAfter: 90,
          );
          expect(tx.isIncoming, false, reason: '$type should not be incoming');
        }
      });
    });
  });
}
