import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/owner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sdk_providers.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Settings page.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(currentOwnerProvider);
    final owner = ownerAsync.valueOrNull;

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: WellxSpacing.xl,
          vertical: WellxSpacing.md,
        ),
        child: Column(
          children: [
            // Profile card
            _ProfileCard(
              owner: owner,
              onTap: () => context.push('/edit-profile'),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Features card
            _FeaturesCard(),
            const SizedBox(height: WellxSpacing.xl),

            // Notification preferences
            GestureDetector(
              onTap: () {},
              child: WellxCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: WellxColors.coral.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active,
                          size: 18, color: WellxColors.coral),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Preferences',
                            style: WellxTypography.chipText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customize reminder times',
                            style: WellxTypography.smallLabel,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 12, color: WellxColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Legal & Privacy
            _LegalCard(),
            const SizedBox(height: WellxSpacing.xl),

            // App info
            _AppInfoCard(),
            const SizedBox(height: WellxSpacing.xl),

            // Sign out
            GestureDetector(
              onTap: () {
                final delegate = ref.read(authDelegateProvider);
                delegate.onAuthInvalidated();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: WellxColors.coral.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: WellxColors.coral.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 14, color: WellxColors.coral),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: WellxTypography.buttonLabel.copyWith(
                        color: WellxColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Delete account
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete,
                        size: 14,
                        color: Color(0x80E65A4D)),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Account',
                      style: WellxTypography.buttonLabel.copyWith(
                        color: WellxColors.coral.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your pet data, health records, and preferences will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: WellxColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final Owner? owner;
  final VoidCallback onTap;

  const _ProfileCard({this.owner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WellxCard(
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WellxColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  owner != null
                      ? owner!.firstName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner?.fullName ?? 'Pet Parent',
                    style: WellxTypography.cardTitle,
                  ),
                  if (owner?.email != null)
                    Text(owner!.email!, style: WellxTypography.captionText),
                  if (owner?.phone != null && owner!.phone!.isNotEmpty)
                    Text(
                      owner!.phone!,
                      style: WellxTypography.smallLabel,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 12, color: WellxColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Features Card
// ---------------------------------------------------------------------------

class _FeaturesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: WellxColors.amberWatch),
              const SizedBox(width: 10),
              Text(
                'FEATURES',
                style: WellxTypography.sectionLabel.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WellxColors.amberWatch,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.lg),
          _featureRow(Icons.pets, 'Pet Management', WellxColors.textPrimary),
          const Divider(height: 1, indent: 44),
          _featureRow(Icons.favorite, 'Health Tracking', WellxColors.coral),
          const Divider(height: 1, indent: 44),
          _featureRow(
              Icons.camera_alt, 'AI Health Checks', WellxColors.scoreGreen),
          const Divider(height: 1, indent: 44),
          _featureRow(
              Icons.directions_walk, 'Walk Tracker', WellxColors.bodyActivity),
          const Divider(height: 1, indent: 44),
          _featureRow(Icons.medical_services, 'Medical Records',
              WellxColors.aiPurple),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: WellxTypography.chipText
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.check,
              size: 11, color: WellxColors.scoreGreen),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legal Card
// ---------------------------------------------------------------------------

class _LegalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield,
                  size: 14, color: WellxColors.amberWatch),
              const SizedBox(width: 10),
              Text(
                'LEGAL & PRIVACY',
                style: WellxTypography.sectionLabel.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WellxColors.amberWatch,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.lg),
          _legalRow(Icons.psychology, 'AI Technology Disclosure',
              WellxColors.aiPurple),
          const Divider(height: 1, indent: 44),
          _legalRow(Icons.privacy_tip, 'Privacy Policy',
              WellxColors.textPrimary,
              isExternal: true),
          const Divider(height: 1, indent: 44),
          _legalRow(Icons.description, 'Terms of Service',
              WellxColors.textPrimary,
              isExternal: true),
        ],
      ),
    );
  }

  Widget _legalRow(IconData icon, String title, Color color,
      {bool isExternal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: WellxTypography.chipText
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            isExternal ? Icons.open_in_new : Icons.chevron_right,
            size: 11,
            color: WellxColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App Info Card
// ---------------------------------------------------------------------------

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: WellxColors.textTertiary),
                  const SizedBox(width: 10),
                  Text('Version', style: WellxTypography.chipText),
                ],
              ),
              const Spacer(),
              Text(
                '1.0.0',
                style: WellxTypography.chipText.copyWith(
                  color: WellxColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.build,
                      size: 14, color: WellxColors.textTertiary),
                  const SizedBox(width: 10),
                  Text('Build', style: WellxTypography.chipText),
                ],
              ),
              const Spacer(),
              Text(
                '1',
                style: WellxTypography.chipText.copyWith(
                  color: WellxColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
