import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';

// ---------------------------------------------------------------------------
// Survey Question Model
// ---------------------------------------------------------------------------

class _SurveyQuestion {
  final String category; // must match WellnessSurveyResult key
  final String question;
  final List<String> options; // index 0 = best (score 100), 3 = worst (score 10)
  final IconData icon;
  final Color color;

  const _SurveyQuestion({
    required this.category,
    required this.question,
    required this.options,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Wellness Survey Screen
// ---------------------------------------------------------------------------

/// Simple 6-question wellness questionnaire. Saves answers to Supabase and
/// wires results into the ScoreCalculator's wellness pillar.
class WellnessSurveyScreen extends ConsumerStatefulWidget {
  const WellnessSurveyScreen({super.key});

  @override
  ConsumerState<WellnessSurveyScreen> createState() =>
      _WellnessSurveyScreenState();
}

class _WellnessSurveyScreenState extends ConsumerState<WellnessSurveyScreen> {
  final Map<String, int> _answers = {};
  bool _isSaving = false;

  // Questions map 0 (best) → score 100, 3 (worst) → score 10 per
  // WellnessSurveyResult.scoreForCategory().
  static final _questions = [
    _SurveyQuestion(
      category: 'ACTIVITY',
      question: 'How often does your pet get exercise?',
      options: [
        'Daily walks / vigorous play (30+ min)',
        'Regular activity (3–4 times per week)',
        'Occasional activity (1–2 times per week)',
        'Rarely active / mostly sedentary',
      ],
      icon: Icons.directions_run,
      color: WellxColors.bodyActivity,
    ),
    _SurveyQuestion(
      category: 'APPETITE',
      question: 'How would you describe your pet\'s diet quality?',
      options: [
        'Premium balanced diet with supplements',
        'Quality commercial food, consistent schedule',
        'Mixed diet, some table scraps',
        'Poor or inconsistent diet',
      ],
      icon: Icons.restaurant,
      color: WellxColors.metabolic,
    ),
    _SurveyQuestion(
      category: 'ENRICHMENT',
      question: 'How is your pet\'s rest and sleep quality?',
      options: [
        'Excellent — sleeps well, always rested',
        'Good — mostly sleeps well',
        'Fair — occasionally restless or anxious',
        'Poor — frequent sleep disruptions',
      ],
      icon: Icons.bedtime,
      color: WellxColors.wellnessDental,
    ),
    _SurveyQuestion(
      category: 'ENVIRONMENT',
      question: 'How is your pet\'s stress and anxiety level?',
      options: [
        'Very calm — rarely stressed',
        'Generally calm with occasional stress',
        'Moderate anxiety in some situations',
        'Frequently stressed or anxious',
      ],
      icon: Icons.psychology,
      color: WellxColors.inflammation,
    ),
    _SurveyQuestion(
      category: 'DENTAL',
      question: 'How is your pet\'s dental care?',
      options: [
        'Regular brushing + professional cleanings',
        'Occasional brushing or dental chews',
        'Dental chews only, no brushing',
        'No regular dental care',
      ],
      icon: Icons.mood,
      color: WellxColors.wellnessDental,
    ),
    _SurveyQuestion(
      category: 'MOBILITY',
      question: 'How is your pet\'s weight and mobility?',
      options: [
        'Ideal weight, moves freely',
        'Slightly over/under weight, moves well',
        'Noticeable weight issue, mild stiffness',
        'Significant weight or mobility problem',
      ],
      icon: Icons.monitor_weight,
      color: WellxColors.organStrength,
    ),
  ];

  Future<void> _saveSurvey() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final pet = ref.read(selectedPetProvider);
      final auth = ref.read(currentAuthProvider);
      if (pet == null || auth.userId == null) {
        throw Exception('No pet selected');
      }

      await ref.read(healthServiceProvider).saveWellnessSurvey(
        petId: pet.id,
        ownerId: auth.userId!,
        answers: _answers,
      );
      ref.invalidate(wellnessSurveyProvider(pet.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wellness survey saved!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save survey: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final answered = _answers.length;
    final total = _questions.length;
    final progress = answered / total;

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
            child: const Icon(Icons.close, size: 14, color: WellxColors.textSecondary),
          ),
        ),
        title: const Text('Wellness Survey'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            WellxCard(
              backgroundColor: WellxColors.inkPrimary,
              borderColor: Colors.transparent,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.health_and_safety,
                          color: Colors.white, size: 20),
                      const SizedBox(width: WellxSpacing.md),
                      Expanded(
                        child: Text(
                          '$answered of $total questions answered',
                          style: WellxTypography.heading
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(WellxColors.scoreGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Questions
            ...List.generate(_questions.length, (i) {
              return _buildQuestion(_questions[i]);
            }),

            const SizedBox(height: WellxSpacing.xl),

            WellxPrimaryButton(
              label: 'Save Survey',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveSurvey,
            ),
            const SizedBox(height: WellxSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(_SurveyQuestion q) {
    final selected = _answers[q.category];

    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: q.color.withValues(alpha: 0.12),
                ),
                child: Icon(q.icon, size: 18, color: q.color),
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Text(
                  q.question,
                  style: WellxTypography.chipText
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.md),
          ...List.generate(q.options.length, (optIndex) {
            final isSelected = selected == optIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _answers[q.category] = optIndex),
                child: Container(
                  padding: const EdgeInsets.all(WellxSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? q.color.withValues(alpha: 0.1)
                        : WellxColors.flatCardFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? q.color : WellxColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: isSelected
                            ? q.color
                            : WellxColors.textTertiary,
                      ),
                      const SizedBox(width: WellxSpacing.md),
                      Expanded(
                        child: Text(
                          q.options[optIndex],
                          style: WellxTypography.bodyText.copyWith(
                            color: isSelected
                                ? q.color
                                : WellxColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
