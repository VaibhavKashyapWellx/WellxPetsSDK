import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';
import '../../providers/pet_provider.dart';

// ---------------------------------------------------------------------------
// Wellness Question Model
// ---------------------------------------------------------------------------

class _WellnessQuestion {
  final String category;
  final String question;
  final String educationalContext;
  final List<String> options;
  final IconData icon;
  final Color color;

  const _WellnessQuestion({
    required this.category,
    required this.question,
    required this.educationalContext,
    required this.options,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Sample Questions
// ---------------------------------------------------------------------------

List<_WellnessQuestion> _sampleQuestions(String petName) => [
      _WellnessQuestion(
        category: 'Exercise',
        question: 'How often does $petName get exercise?',
        educationalContext:
            'Regular exercise is crucial for maintaining healthy weight, joint mobility, and mental stimulation.',
        options: [
          'Daily walks (30+ min)',
          '3-4 times per week',
          '1-2 times per week',
          'Rarely / sedentary',
        ],
        icon: Icons.directions_run,
        color: WellxColors.scoreGreen,
      ),
      _WellnessQuestion(
        category: 'Diet',
        question: 'How would you describe $petName\'s diet quality?',
        educationalContext:
            'A balanced diet with the right macronutrients supports organ function, coat health, and longevity.',
        options: [
          'Premium balanced diet with supplements',
          'Quality commercial food, consistent schedule',
          'Mixed diet, some table scraps',
          'Mostly human food or irregular feeding',
        ],
        icon: Icons.restaurant,
        color: WellxColors.midPurple,
      ),
      _WellnessQuestion(
        category: 'Dental',
        question: 'How often does $petName receive dental care?',
        educationalContext:
            'Dental disease affects 80% of dogs by age 3. Regular dental care prevents bacteria from entering the bloodstream.',
        options: [
          'Daily brushing + annual professional cleaning',
          'Weekly brushing or dental chews',
          'Occasional dental treats only',
          'No dental care routine',
        ],
        icon: Icons.mood,
        color: WellxColors.scoreBlue,
      ),
      _WellnessQuestion(
        category: 'Preventive',
        question: 'Is $petName up to date on preventive care?',
        educationalContext:
            'Vaccinations, parasite prevention, and regular check-ups can add years to your pet\'s life.',
        options: [
          'All vaccines current + monthly parasite prevention',
          'Vaccines current, occasional parasite prevention',
          'Partially vaccinated, no parasite prevention',
          'Overdue on most preventive care',
        ],
        icon: Icons.health_and_safety,
        color: WellxColors.deepPurple,
      ),
      _WellnessQuestion(
        category: 'Mental Health',
        question: 'How is $petName\'s mental stimulation and social life?',
        educationalContext:
            'Mental enrichment reduces anxiety, destructive behavior, and cognitive decline in aging pets.',
        options: [
          'Daily enrichment + regular socialization',
          'Some toys and occasional social interaction',
          'Limited stimulation, mostly alone at home',
          'No enrichment activities, isolated',
        ],
        icon: Icons.psychology,
        color: WellxColors.amberWatch,
      ),
    ];

// ---------------------------------------------------------------------------
// Track Wellness Flow — breed-specific wellness questionnaire
// ---------------------------------------------------------------------------

class TrackWellnessFlow extends ConsumerStatefulWidget {
  const TrackWellnessFlow({super.key});

  @override
  ConsumerState<TrackWellnessFlow> createState() => _TrackWellnessFlowState();
}

class _TrackWellnessFlowState extends ConsumerState<TrackWellnessFlow> {
  late List<_WellnessQuestion> _questions;
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  bool _showResults = false;
  int? _showIdealExplanation;

  @override
  void initState() {
    super.initState();
    _questions = _sampleQuestions('your pet'); // Updated in build via pet
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(selectedPetProvider);
    final petName = pet?.name ?? 'your pet';
    final breed = pet?.breed ?? '';
    final isBreedKnown =
        breed.isNotEmpty && breed != (pet?.species ?? 'Dog');

    // Rebuild questions with actual pet name
    if (_questions.first.question.contains('your pet') && pet != null) {
      _questions = _sampleQuestions(petName);
    }

    final navTitle = isBreedKnown ? '$breed Lifestyle Check' : 'Wellness Check';

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
        title: Text(navTitle),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
      ),
      body: _showResults
          ? _buildResultsSummary(petName)
          : _buildQuestionView(),
    );
  }

  // ---------- Progress Bar ----------

  Widget _buildProgressBar() {
    final question = _questions[_currentIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                question.category.toUpperCase(),
                style: WellxTypography.sectionLabel.copyWith(
                  color: question.color,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1} of ${_questions.length}',
                style: WellxTypography.captionText,
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: WellxColors.textPrimary.withValues(alpha: 0.1),
              color: question.color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Question View ----------

  Widget _buildQuestionView() {
    return Column(
      children: [
        const SizedBox(height: WellxSpacing.sm),
        _buildProgressBar(),
        Expanded(
          child: PageView.builder(
            itemCount: _questions.length,
            controller: PageController(initialPage: _currentIndex),
            onPageChanged: (i) => setState(() {
              _currentIndex = i;
              _showIdealExplanation = null;
            }),
            itemBuilder: (context, index) => _buildQuestionPage(index),
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final selectedOption = _answers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.xl,
        vertical: WellxSpacing.lg,
      ),
      child: Column(
        children: [
          // Educational banner
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: WellxColors.amberWatch.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.lightbulb,
                      size: 14, color: WellxColors.amberWatch),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Did you know?',
                        style: WellxTypography.captionText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WellxColors.amberWatch,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.educationalContext,
                        style: WellxTypography.captionText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Category icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: question.color.withValues(alpha: 0.12),
            ),
            child: Icon(question.icon, size: 24, color: question.color),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Question text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
            child: Text(
              question.question,
              style: WellxTypography.heading.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final optIndex = entry.key;
            final option = entry.value;
            final isSelected = selectedOption == optIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _answers.containsKey(index)
                      ? null
                      : () => _selectOption(index, optIndex),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? question.color.withValues(alpha: 0.08)
                          : WellxColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? question.color
                            : WellxColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: WellxTypography.bodyText.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: question.color, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Ideal explanation after answering
          if (_showIdealExplanation == index && selectedOption != null) ...[
            const SizedBox(height: WellxSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: selectedOption == 0
                    ? WellxColors.scoreGreen.withValues(alpha: 0.06)
                    : WellxColors.midPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      selectedOption == 0
                          ? Icons.verified
                          : Icons.arrow_upward,
                      size: 14,
                      color: selectedOption == 0
                          ? WellxColors.scoreGreen
                          : WellxColors.midPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedOption == 0
                          ? 'Great job! Keep up the excellent care.'
                          : 'There\'s room to improve here. Small changes can make a big difference.',
                      style: WellxTypography.captionText.copyWith(
                        color: selectedOption == 0
                            ? WellxColors.scoreGreen
                            : WellxColors.midPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectOption(int questionIndex, int optionIndex) {
    setState(() {
      _answers[questionIndex] = optionIndex;
      _showIdealExplanation = questionIndex;
    });

    // Auto-advance after delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _currentIndex != questionIndex) return;
      if (questionIndex < _questions.length - 1) {
        setState(() {
          _currentIndex = questionIndex + 1;
          _showIdealExplanation = null;
        });
      } else {
        setState(() => _showResults = true);
      }
    });
  }

  // ---------- Bottom Controls ----------

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.xl,
        vertical: WellxSpacing.xl,
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            TextButton.icon(
              onPressed: () => setState(() {
                _currentIndex -= 1;
                _showIdealExplanation = null;
              }),
              icon: const Icon(Icons.chevron_left, size: 14),
              label: const Text('Previous'),
              style: TextButton.styleFrom(
                foregroundColor: WellxColors.textPrimary,
                textStyle: WellxTypography.bodyText
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            )
          else
            const SizedBox(width: 80),

          const Spacer(),

          // Dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _questions.length,
              (i) => Container(
                width: i == _currentIndex ? 8 : 6,
                height: i == _currentIndex ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentIndex
                      ? WellxColors.textPrimary
                      : WellxColors.textPrimary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          const Spacer(),

          if (_currentIndex < _questions.length - 1)
            TextButton.icon(
              onPressed: () => setState(() {
                _currentIndex += 1;
                _showIdealExplanation = null;
              }),
              label: const Text('Skip'),
              icon: const SizedBox.shrink(),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                foregroundColor: WellxColors.textSecondary,
                textStyle: WellxTypography.bodyText
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  // ---------- Results Summary ----------

  Widget _buildResultsSummary(String petName) {
    final overallScore = _computeOverallScore();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: WellxSpacing.xl),

          // Score ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  color: WellxColors.textPrimary.withValues(alpha: 0.08),
                  backgroundColor: Colors.transparent,
                ),
                CircularProgressIndicator(
                  value: overallScore / 100.0,
                  strokeWidth: 8,
                  color: overallScore >= 70
                      ? WellxColors.scoreGreen
                      : WellxColors.amberWatch,
                  backgroundColor: Colors.transparent,
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$overallScore',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: WellxColors.textPrimary,
                      ),
                    ),
                    Text('/ 100', style: WellxTypography.captionText),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          Text('Wellness Check Complete',
              style: WellxTypography.heading),
          const SizedBox(height: 6),
          Text(
            overallScore >= 80
                ? '$petName is doing great!'
                : overallScore >= 60
                    ? 'Some areas could use attention'
                    : 'A few areas need improvement',
            style: WellxTypography.captionText,
          ),

          const SizedBox(height: WellxSpacing.xxl),

          // Per-category breakdown
          WellxCard(
            child: Column(
              children: _questions.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                final answer = _answers[i];
                final score = answer != null
                    ? [100, 70, 40, 10][answer.clamp(0, 3)]
                    : 50;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          q.category,
                          style: WellxTypography.chipText,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100.0,
                            backgroundColor:
                                WellxColors.textPrimary.withValues(alpha: 0.06),
                            color: score >= 70
                                ? WellxColors.scoreGreen
                                : score >= 40
                                    ? WellxColors.amberWatch
                                    : WellxColors.coral,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: WellxSpacing.md),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$score',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: score >= 70
                                ? WellxColors.scoreGreen
                                : score >= 40
                                    ? WellxColors.amberWatch
                                    : WellxColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: WellxSpacing.xxl),

          WellxPrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: WellxSpacing.xl),
        ],
      ),
    );
  }

  int _computeOverallScore() {
    if (_answers.isEmpty) return 50;
    final scores = _answers.values.map((a) {
      switch (a) {
        case 0:
          return 100;
        case 1:
          return 70;
        case 2:
          return 40;
        case 3:
          return 10;
        default:
          return 50;
      }
    });
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}
