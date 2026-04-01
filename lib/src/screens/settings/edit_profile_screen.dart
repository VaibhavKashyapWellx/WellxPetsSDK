import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_client.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_primary_button.dart';

/// Edit user profile form.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;
  bool _didInit = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerAsync = ref.watch(currentOwnerProvider);
    final owner = ownerAsync.valueOrNull;

    // Initialize controllers once
    if (!_didInit && owner != null) {
      _firstNameController.text = owner.firstName;
      _lastNameController.text = owner.lastName;
      _phoneController.text = owner.phone ?? '';
      _didInit = true;
    }

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit Profile'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: WellxColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    owner != null
                        ? owner.firstName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: WellxSpacing.xxl),

            // First name
            Text(
              'FIRST NAME',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            _InputField(controller: _firstNameController),

            const SizedBox(height: WellxSpacing.xl),

            // Last name
            Text(
              'LAST NAME',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            _InputField(controller: _lastNameController),

            const SizedBox(height: WellxSpacing.xl),

            // Phone
            Text(
              'PHONE',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            _InputField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: WellxSpacing.xxl),

            // Email (read-only)
            if (owner?.email != null) ...[
              Text(
                'EMAIL',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: WellxSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WellxSpacing.lg),
                decoration: BoxDecoration(
                  color: WellxColors.flatCardFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  owner!.email!,
                  style: WellxTypography.inputText.copyWith(
                    color: WellxColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: WellxSpacing.xxl),
            ],

            // Save button
            WellxPrimaryButton(
              label: 'Save Changes',
              isLoading: _isSaving,
              icon: Icons.check,
              onPressed: () => _save(owner?.id),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _save(String? ownerId) async {
    if (ownerId == null) return;
    setState(() => _isSaving = true);

    try {
      await SupabaseManager.instance.client.from('owners').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).eq('id', ownerId);

      ref.invalidate(currentOwnerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated'),
            backgroundColor: WellxColors.scoreGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: WellxColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WellxColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: WellxTypography.inputText,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(WellxSpacing.lg),
          hintStyle: WellxTypography.inputText.copyWith(
            color: WellxColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
