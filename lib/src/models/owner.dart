import 'package:flutter/foundation.dart';

/// Owner model — maps to the "owners" table.
@immutable
class Owner {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final bool? isAdmin;
  final String? createdAt;

  const Owner({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.isAdmin,
    this.createdAt,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isAdmin: json['is_admin'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'is_admin': isAdmin,
      'created_at': createdAt,
    };
  }

  String get fullName => '$firstName $lastName';

  /// True if this owner has admin privileges.
  bool get hasAdminAccess => isAdmin == true;
}

/// Payload for creating a new owner.
@immutable
class OwnerCreate {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  const OwnerCreate({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
  });

  factory OwnerCreate.fromJson(Map<String, dynamic> json) {
    return OwnerCreate(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }
}

/// Membership model — maps to the "memberships" table.
@immutable
class Membership {
  final String id;
  final String? tier;
  final String? status;
  final String? startDate;
  final String? nextBillingDate;
  final String? createdAt;

  const Membership({
    required this.id,
    this.tier,
    this.status,
    this.startDate,
    this.nextBillingDate,
    this.createdAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String,
      tier: json['tier'] as String?,
      status: json['status'] as String?,
      startDate: json['start_date'] as String?,
      nextBillingDate: json['next_billing_date'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier,
      'status': status,
      'start_date': startDate,
      'next_billing_date': nextBillingDate,
      'created_at': createdAt,
    };
  }
}
