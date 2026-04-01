import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Credit Wallet — maps to "user_wallets" table
// ---------------------------------------------------------------------------

@immutable
class CreditWallet {
  final String id;
  final String ownerId;
  final int creditsBalance;
  final int coinsBalance;
  final int totalCreditsPurchased;
  final int totalCoinsEarned;
  final String? createdAt;
  final String? updatedAt;

  const CreditWallet({
    required this.id,
    required this.ownerId,
    required this.creditsBalance,
    required this.coinsBalance,
    required this.totalCreditsPurchased,
    required this.totalCoinsEarned,
    this.createdAt,
    this.updatedAt,
  });

  factory CreditWallet.fromJson(Map<String, dynamic> json) {
    return CreditWallet(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      creditsBalance: json['credits_balance'] as int,
      coinsBalance: json['coins_balance'] as int,
      totalCreditsPurchased: json['total_credits_purchased'] as int,
      totalCoinsEarned: json['total_coins_earned'] as int,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'credits_balance': creditsBalance,
      'coins_balance': coinsBalance,
      'total_credits_purchased': totalCreditsPurchased,
      'total_coins_earned': totalCoinsEarned,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Total spendable balance (credits + coins).
  int get totalBalance => creditsBalance + coinsBalance;

  /// Returns a copy with updated balances.
  CreditWallet copyWith({
    int? creditsBalance,
    int? coinsBalance,
    int? totalCreditsPurchased,
    int? totalCoinsEarned,
    String? updatedAt,
  }) {
    return CreditWallet(
      id: id,
      ownerId: ownerId,
      creditsBalance: creditsBalance ?? this.creditsBalance,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      totalCreditsPurchased: totalCreditsPurchased ?? this.totalCreditsPurchased,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Credit Transaction — maps to "credit_transactions" table
// ---------------------------------------------------------------------------

@immutable
class CreditTransaction {
  final String id;
  final String ownerId;
  final String type; // credit_purchase, credit_award, coin_earn, credit_spend, coin_spend
  final int amount;
  final String currency; // "credits" or "coins"
  final int balanceAfter;
  final String? description;
  final String? referenceId;
  final String? referenceType;
  final String? createdAt;

  const CreditTransaction({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    this.referenceType,
    this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      balanceAfter: json['balance_after'] as int,
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'balance_after': balanceAfter,
      'description': description,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'created_at': createdAt,
    };
  }

  /// User-friendly label for the transaction type.
  String get typeLabel {
    switch (type) {
      case 'credit_purchase':
        return 'Credits Purchased';
      case 'credit_award':
        return 'Credits Awarded';
      case 'coin_earn':
        return 'Coins Earned';
      case 'credit_spend':
        return 'Credits Spent';
      case 'coin_spend':
        return 'Coins Spent';
      default:
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }

  /// Icon name for the transaction type.
  String get typeIcon {
    switch (type) {
      case 'credit_purchase':
        return 'cart.fill';
      case 'credit_award':
        return 'gift.fill';
      case 'coin_earn':
        return 'star.fill';
      case 'credit_spend':
      case 'coin_spend':
        return 'bag.fill';
      default:
        return 'circle.fill';
    }
  }

  /// Whether this is an incoming (positive) transaction.
  bool get isIncoming =>
      type == 'credit_purchase' ||
      type == 'credit_award' ||
      type == 'coin_earn';
}
