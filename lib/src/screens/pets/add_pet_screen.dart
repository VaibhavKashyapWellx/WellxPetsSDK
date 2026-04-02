import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';

/// Form screen for adding a new pet.
class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  String _species = 'dog';
  String _gender = 'male';
  bool _isNeutered = false;
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  XFile? _pickedPhoto;
  Uint8List? _photoBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedPhoto = picked;
      _photoBytes = bytes;
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now.subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: WellxColors.deepPurple,
              onPrimary: Colors.white,
              surface: WellxColors.cardSurface,
              onSurface: WellxColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(currentAuthProvider);
      final service = ref.read(petServiceProvider);

      final pet = PetCreate(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        species: _species,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T').first,
        gender: _gender,
        isNeutered: _isNeutered,
        weight: double.tryParse(_weightController.text.trim()),
        ownerId: auth.userId,
      );

      final created = await service.createPet(pet);

      // Upload photo if one was picked
      if (_photoBytes != null) {
        try {
          await service.uploadAndSetPhoto(created.id, _photoBytes!);
        } catch (e) {
          // Pet was created — photo upload failure is non-fatal, but inform user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pet saved, but photo upload failed: $e'),
                backgroundColor: WellxColors.amberWatch,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      ref.invalidate(petsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add pet: $e'),
            backgroundColor: WellxColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text('Add Pet', style: WellxTypography.heading),
        backgroundColor: WellxColors.background,
        elevation: 0,
        foregroundColor: WellxColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pet photo
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: WellxColors.flatCardFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: WellxColors.border, width: 2),
                      image: _photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_photoBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 32, color: WellxColors.textTertiary),
                              const SizedBox(height: 4),
                              Text('Add Photo',
                                  style: WellxTypography.microLabel.copyWith(
                                    color: WellxColors.textTertiary,
                                  )),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: WellxSpacing.xl),

              // Name
              WellxCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PET DETAILS',
                        style: WellxTypography.sectionLabel),
                    const SizedBox(height: WellxSpacing.lg),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: "Your pet's name",
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: WellxSpacing.lg),
                    _buildTextField(
                      controller: _breedController,
                      label: 'Breed',
                      hint: 'e.g. Golden Retriever',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Breed is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WellxSpacing.lg),

              // Species selector
              WellxCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SPECIES', style: WellxTypography.sectionLabel),
                    const SizedBox(height: WellxSpacing.md),
                    Row(
                      children: [
                        _buildSpeciesChip('dog', 'Dog'),
                        const SizedBox(width: WellxSpacing.sm),
                        _buildSpeciesChip('cat', 'Cat'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WellxSpacing.lg),

              // Date of birth, gender, weight, neutered
              WellxCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MORE INFO',
                        style: WellxTypography.sectionLabel),
                    const SizedBox(height: WellxSpacing.lg),

                    // Date of Birth
                    GestureDetector(
                      onTap: _pickDateOfBirth,
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: TextEditingController(
                            text: _dateOfBirth != null
                                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                : '',
                          ),
                          label: 'Date of Birth',
                          hint: 'Tap to select',
                          suffixIcon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.lg),

                    // Gender
                    Text('Gender', style: WellxTypography.captionText),
                    const SizedBox(height: WellxSpacing.sm),
                    Row(
                      children: [
                        _buildGenderChip('male', 'Male'),
                        const SizedBox(width: WellxSpacing.sm),
                        _buildGenderChip('female', 'Female'),
                      ],
                    ),
                    const SizedBox(height: WellxSpacing.lg),

                    // Weight
                    _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: 'e.g. 25.5',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: WellxSpacing.lg),

                    // Neutered toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Neutered / Spayed',
                            style: WellxTypography.bodyText),
                        Switch(
                          value: _isNeutered,
                          onChanged: (v) => setState(() => _isNeutered = v),
                          activeColor: WellxColors.deepPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WellxSpacing.xl),

              // Save button
              WellxPrimaryButton(
                label: 'Save Pet',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _savePet,
              ),
              const SizedBox(height: WellxSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: WellxTypography.captionText),
        const SizedBox(height: WellxSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: WellxTypography.inputText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WellxTypography.inputText.copyWith(
              color: WellxColors.textTertiary,
            ),
            filled: true,
            fillColor: WellxColors.flatCardFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: WellxSpacing.lg,
              vertical: WellxSpacing.md,
            ),
            suffixIcon:
                suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesChip(String value, String label) {
    final selected = _species == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _species = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: WellxSpacing.md),
          decoration: BoxDecoration(
            color: selected ? WellxColors.deepPurple : WellxColors.flatCardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WellxColors.deepPurple : WellxColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: WellxTypography.chipText.copyWith(
                color: selected ? Colors.white : WellxColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: WellxSpacing.md),
          decoration: BoxDecoration(
            color: selected ? WellxColors.deepPurple : WellxColors.flatCardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WellxColors.deepPurple : WellxColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: WellxTypography.chipText.copyWith(
                color: selected ? Colors.white : WellxColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
