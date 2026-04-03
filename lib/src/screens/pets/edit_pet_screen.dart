import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';

/// Form screen for editing an existing pet's details.
class EditPetScreen extends ConsumerStatefulWidget {
  final Pet pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  ConsumerState<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends ConsumerState<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;

  late String _species;
  late String _gender;
  late bool _isNeutered;
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  Uint8List? _newPhotoBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed);
    _weightController = TextEditingController(
      text: widget.pet.weight?.toString() ?? '',
    );
    _species = widget.pet.species ?? 'dog';
    _gender = widget.pet.gender ?? 'male';
    _isNeutered = widget.pet.isNeutered ?? false;
    if (widget.pet.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(widget.pet.dateOfBirth!);
    }
  }

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
    setState(() => _newPhotoBytes = bytes);
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
      final service = ref.read(petServiceProvider);

      final update = PetUpdate(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        species: _species,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T').first,
        gender: _gender,
        isNeutered: _isNeutered,
        weight: double.tryParse(_weightController.text.trim()),
      );

      await service.updatePet(widget.pet.id, update);

      if (_newPhotoBytes != null) {
        try {
          await service.uploadAndSetPhoto(widget.pet.id, _newPhotoBytes!);
        } catch (_) {
          // Update succeeded — photo upload failure is non-fatal
        }
      }

      ref.invalidate(petsProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception
                ? e.toString()
                : 'Could not update your pet. Please try again.'),
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
        title: Text('Edit ${widget.pet.name}',
            style: WellxTypography.heading),
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
                      image: _newPhotoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_newPhotoBytes!),
                              fit: BoxFit.cover,
                            )
                          : widget.pet.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.pet.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_newPhotoBytes == null && widget.pet.photoUrl == null)
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
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: WellxColors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: WellxSpacing.xl),

              // Name & Breed
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: WellxSpacing.lg),
                    _buildTextField(
                      controller: _breedController,
                      label: 'Breed',
                      hint: 'e.g. Golden Retriever',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Breed is required'
                          : null,
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
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = double.tryParse(v.trim());
                        if (d == null) return 'Enter a valid number';
                        if (d <= 0 || d > 200) {
                          return 'Weight must be between 0.1 and 200 kg';
                        }
                        return null;
                      },
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
                label: 'Save Changes',
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
            color:
                selected ? WellxColors.deepPurple : WellxColors.flatCardFill,
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
            color:
                selected ? WellxColors.deepPurple : WellxColors.flatCardFill,
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
