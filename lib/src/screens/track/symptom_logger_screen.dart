import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_primary_button.dart';
import '../../providers/pet_provider.dart';

// ---------------------------------------------------------------------------
// Symptom Definition
// ---------------------------------------------------------------------------

class _SymptomDef {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const _SymptomDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const _commonSymptoms = [
  _SymptomDef(
    id: 'vomiting',
    name: 'Vomiting',
    icon: Icons.sick,
    color: WellxColors.scoreOrange,
  ),
  _SymptomDef(
    id: 'diarrhea',
    name: 'Diarrhea',
    icon: Icons.water_damage,
    color: WellxColors.amberWatch,
  ),
  _SymptomDef(
    id: 'lethargy',
    name: 'Lethargy',
    icon: Icons.bedtime,
    color: WellxColors.scoreBlue,
  ),
  _SymptomDef(
    id: 'loss_of_appetite',
    name: 'Loss of Appetite',
    icon: Icons.no_food,
    color: WellxColors.coral,
  ),
  _SymptomDef(
    id: 'coughing',
    name: 'Coughing',
    icon: Icons.air,
    color: WellxColors.lightPurple,
  ),
  _SymptomDef(
    id: 'limping',
    name: 'Limping',
    icon: Icons.accessibility_new,
    color: WellxColors.deepPurple,
  ),
  _SymptomDef(
    id: 'scratching',
    name: 'Scratching',
    icon: Icons.pan_tool,
    color: WellxColors.scoreOrange,
  ),
  _SymptomDef(
    id: 'excessive_thirst',
    name: 'Excessive Thirst',
    icon: Icons.local_drink,
    color: WellxColors.scoreBlue,
  ),
  _SymptomDef(
    id: 'other',
    name: 'Other',
    icon: Icons.more_horiz,
    color: WellxColors.textSecondary,
  ),
];

// ---------------------------------------------------------------------------
// Severity Level
// ---------------------------------------------------------------------------

enum _Severity {
  mild,
  moderate,
  severe;

  String get label => name[0].toUpperCase() + name.substring(1);

  Color get color {
    switch (this) {
      case _Severity.mild:
        return WellxColors.scoreGreen;
      case _Severity.moderate:
        return WellxColors.amberWatch;
      case _Severity.severe:
        return WellxColors.coral;
    }
  }

  IconData get icon {
    switch (this) {
      case _Severity.mild:
        return Icons.check_circle_outline;
      case _Severity.moderate:
        return Icons.warning_amber;
      case _Severity.severe:
        return Icons.error_outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Symptom Logger Screen
// ---------------------------------------------------------------------------

class SymptomLoggerScreen extends ConsumerStatefulWidget {
  const SymptomLoggerScreen({super.key});

  @override
  ConsumerState<SymptomLoggerScreen> createState() =>
      _SymptomLoggerScreenState();
}

class _SymptomLoggerScreenState extends ConsumerState<SymptomLoggerScreen> {
  final Set<String> _selectedSymptoms = {};
  _Severity? _severity;
  final _notesController = TextEditingController();
  final _notesFocusNode = FocusNode();
  bool _isSaving = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(selectedPetProvider);
    final petName = pet?.name ?? 'your pet';

    if (_showSuccess) {
      return _buildSuccessView(petName);
    }

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WellxColors.textPrimary.withValues(alpha: 0.06),
            ),
            child: const Icon(Icons.close,
                size: 14, color: WellxColors.textSecondary),
          ),
        ),
        title: const Text('Log Symptom'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'What\'s going on with $petName?',
                    style: WellxTypography.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select one or more symptoms to log',
                    style: WellxTypography.captionText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Symptom grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _commonSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom.id);
                return _buildSymptomCard(symptom, isSelected);
              }).toList(),
            ),
            const SizedBox(height: WellxSpacing.xxl),

            // Severity picker
            if (_selectedSymptoms.isNotEmpty) ...[
              Text(
                'SEVERITY',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: WellxSpacing.md),
              Row(
                children: _Severity.values.map((severity) {
                  final isSelected = _severity == severity;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: severity != _Severity.severe
                            ? WellxSpacing.sm
                            : 0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _severity = severity),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? severity.color.withValues(alpha: 0.1)
                                  : WellxColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? severity.color
                                    : WellxColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(severity.icon,
                                    size: 20, color: severity.color),
                                const SizedBox(height: 6),
                                Text(
                                  severity.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? severity.color
                                        : WellxColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: WellxSpacing.xl),

              // Notes field
              Text(
                'NOTES (OPTIONAL)',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: WellxSpacing.sm),
              TextField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: 3,
                style: WellxTypography.inputText,
                decoration: InputDecoration(
                  hintText: 'Any additional details...',
                  hintStyle: WellxTypography.captionText
                      .copyWith(color: WellxColors.textTertiary),
                  filled: true,
                  fillColor: WellxColors.cardSurface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: WellxColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: WellxColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: WellxColors.deepPurple, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: WellxSpacing.xxl),

              // Save button
              WellxPrimaryButton(
                label: 'Log & Save to Timeline',
                icon: Icons.check_circle,
                isLoading: _isSaving,
                onPressed: _severity != null ? _saveSymptom : null,
              ),

              const SizedBox(height: WellxSpacing.md),

              // Coin reward hint
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star,
                        size: 10, color: WellxColors.midPurple),
                    const SizedBox(width: 6),
                    Text(
                      'Earn 3 xCoins for logging symptoms',
                      style: WellxTypography.captionText
                          .copyWith(color: WellxColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WellxSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Symptom Card ----------

  Widget _buildSymptomCard(_SymptomDef symptom, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedSymptoms.remove(symptom.id);
            } else {
              _selectedSymptoms.add(symptom.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? symptom.color.withValues(alpha: 0.08)
                : WellxColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? symptom.color : WellxColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: symptom.color.withValues(alpha: 0.12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(symptom.icon, size: 22, color: symptom.color),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: symptom.color,
                          ),
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                symptom.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: WellxColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Save ----------

  Future<void> _saveSymptom() async {
    if (_selectedSymptoms.isEmpty || _severity == null) return;
    setState(() => _isSaving = true);

    // Mock save delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _showSuccess = true;
    });
  }

  // ---------- Success View ----------

  Widget _buildSuccessView(String petName) {
    return Scaffold(
      backgroundColor: WellxColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(WellxSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.scoreGreen.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.check_circle,
                    size: 40, color: WellxColors.scoreGreen),
              ),
              const SizedBox(height: WellxSpacing.xl),
              Text('Symptom Logged', style: WellxTypography.heading),
              const SizedBox(height: WellxSpacing.sm),
              Text(
                'Your entry has been saved to $petName\'s health timeline.',
                style: WellxTypography.captionText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WellxSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star,
                      size: 14, color: WellxColors.midPurple),
                  const SizedBox(width: 4),
                  Text(
                    '+3 xCoins Earned',
                    style: WellxTypography.chipText.copyWith(
                      color: WellxColors.midPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WellxSpacing.xxl),
              WellxPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
