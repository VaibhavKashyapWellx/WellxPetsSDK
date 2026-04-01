import 'package:flutter_test/flutter_test.dart';
import 'package:wellx_pets_sdk/src/sdk/auth_delegate.dart';
import 'package:wellx_pets_sdk/src/sdk/xcoin_delegate.dart';

void main() {
  group('WellxAuthState', () {
    test('fullName joins firstName and lastName', () {
      const state = WellxAuthState(
        isAuthenticated: true,
        firstName: 'John',
        lastName: 'Doe',
      );
      expect(state.fullName, 'John Doe');
    });

    test('fullName handles null firstName', () {
      const state = WellxAuthState(
        isAuthenticated: true,
        lastName: 'Doe',
      );
      expect(state.fullName, 'Doe');
    });

    test('fullName handles null lastName', () {
      const state = WellxAuthState(
        isAuthenticated: true,
        firstName: 'John',
      );
      expect(state.fullName, 'John');
    });

    test('fullName returns empty string when both are null', () {
      const state = WellxAuthState(isAuthenticated: true);
      expect(state.fullName, '');
    });

    test('unauthenticated factory sets all fields to null/false', () {
      const state = WellxAuthState.unauthenticated();
      expect(state.isAuthenticated, false);
      expect(state.userId, isNull);
      expect(state.accessToken, isNull);
      expect(state.email, isNull);
      expect(state.firstName, isNull);
      expect(state.lastName, isNull);
    });
  });

  group('WellxCoinAction', () {
    test('all actions have positive defaultCoins', () {
      for (final action in WellxCoinAction.values) {
        expect(action.defaultCoins, greaterThan(0),
            reason: '${action.name} should have positive default coins');
      }
    });

    test('all actions have non-empty displayName', () {
      for (final action in WellxCoinAction.values) {
        expect(action.displayName.isNotEmpty, true,
            reason: '${action.name} should have a display name');
      }
    });

    test('dailyLogin has 5 coins', () {
      expect(WellxCoinAction.dailyLogin.defaultCoins, 5);
    });

    test('completePetProfile has 20 coins', () {
      expect(WellxCoinAction.completePetProfile.defaultCoins, 20);
    });
  });

  group('WellxCoinEvent', () {
    test('holds action and suggestedCoins', () {
      const event = WellxCoinEvent(
        action: WellxCoinAction.logWalk,
        suggestedCoins: 5,
        referenceId: 'walk-1',
        metadata: {'steps': 5000},
      );
      expect(event.action, WellxCoinAction.logWalk);
      expect(event.suggestedCoins, 5);
      expect(event.referenceId, 'walk-1');
    });
  });

  group('WellxWalletBalance', () {
    test('totalBalance sums coins and credits', () {
      const balance = WellxWalletBalance(
        coinsBalance: 100,
        creditsBalance: 50,
        totalCoinsEarned: 200,
      );
      expect(balance.totalBalance, 150);
    });

    test('defaults creditsBalance to 0', () {
      const balance = WellxWalletBalance(coinsBalance: 100);
      expect(balance.creditsBalance, 0);
      expect(balance.totalBalance, 100);
    });
  });
}
