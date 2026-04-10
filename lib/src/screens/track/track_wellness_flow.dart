import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
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
    // breed kept for potential future use
    // ignore: unused_local_variable
    final breed = pet?.breed ?? '';

    // Rebuild questions with actual pet name
    if (_questions.first.question.contains('your pet') && pet != null) {
      _questions = _sampleQuestions(petName);
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.7),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: cs.primary),
              ),
              title: Text(
                'Wellness Check',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.help_outline_rounded,
                      size: 22, color: cs.primary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _showResults
          ? _buildResultsSummary(petName)
          : _buildQuestionView(),
    );
  }

  // ---------- Progress Bar ----------

  Widget _buildProgressBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
      child: Column(
        children: [
          // "Question X of Y" label
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: WellxTypography.captionText.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
              color: cs.primary,
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
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + WellxSpacing.md),
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
        _buildBottomNav(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    final selectedOption = _answers[index];
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.xl,
        vertical: WellxSpacing.lg,
      ),
      child: Column(
        children: [
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: question.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              question.category.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: question.color,
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Category icon in circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: question.color.withValues(alpha: 0.1),
            ),
            child: Icon(question.icon, size: 22, color: question.color),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Question text (Plus Jakarta Sans, xl bold)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
            child: Text(
              question.question,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Educational context in surfaceContainerLow card
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: WellxColors.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.educationalContext,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: WellxColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Answer options — vertical pill-shaped buttons
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
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : WellxColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : WellxColors.subtleShadow,
                    ),
                    child: Row(
                      children: [
                        // Radio-style indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : WellxColors.outlineVariant,
                              width: isSelected ? 0 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              color: isSelected
                                  ? Colors.white
                                  : cs.onSurface,
                            ),
                          ),
                        ),
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
                borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      selectedOption == 0
                          ? Icons.verified_rounded
                          : Icons.arrow_upward_rounded,
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

  // ---------- Bottom Navigation ----------

  Widget _buildBottomNav() {
    final cs = Theme.of(context).colorScheme;
    final hasAnswer = _answers.containsKey(_currentIndex);
    final isLast = _currentIndex == _questions.length - 1;
    final buttonLabel = isLast ? 'See Results' : 'Next';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.xl,
        vertical: WellxSpacing.lg,
      ),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedOpacity(
          opacity: hasAnswer ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasAnswer
                  ? () {
                      if (isLast) {
                        setState(() => _showResults = true);
                      } else {
                        setState(() {
                          _currentIndex += 1;
                          _showIdealExplanation = null;
                        });
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: WellxSpacing.lg),
                decoration: BoxDecoration(
                  gradient: hasAnswer ? WellxColors.primaryGradient : null,
                  color: hasAnswer ? null : cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonLabel,
                  style: WellxTypography.buttonLabel.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Results Summary ----------

  Widget _buildResultsSummary(String petName) {
    final overallScore = _computeOverallScore();
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + WellxSpacing.lg,
        left: WellxSpacing.xl,
        right: WellxSpacing.xl,
        bottom: 120,
      ),
      child: Column(
        children: [
          // Purple gradient hero card with score
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: WellxSpacing.xxl,
              horizontal: WellxSpacing.xl,
            ),
            decoration: BoxDecoration(
              gradient: WellxColors.primaryGradient,
              borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Wellness Check Complete',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$overallScore',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/100',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WellxSpacing.sm),
                Text(
                  overallScore >= 80
                      ? '$petName is doing great!'
                      : overallScore >= 60
                          ? 'Some areas could use attention'
                          : 'A few areas need improvement',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Per-category breakdown cards
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final answer = _answers[i];
            final score = answer != null
                ? [100, 70, 40, 10][answer.clamp(0, 3)]
                : 50;
            final scoreColor = score >= 70
                ? WellxColors.scoreGreen
                : score >= 40
                    ? WellxColors.amberWatch
                    : WellxColors.coral;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WellxColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
                  boxShadow: WellxColors.subtleShadow,
                ),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: q.color.withValues(alpha: 0.1),
                      ),
                      child: Icon(q.icon, size: 18, color: q.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.category,
                            style: WellxTypography.chipText.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: score / 100.0,
                              backgroundColor:
                                  cs.onSurface.withValues(alpha: 0.06),
                              color: scoreColor,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: WellxSpacing.xl),

          // Done pill button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: WellxSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: WellxColors.primaryGradient,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Done',
                    style: WellxTypography.buttonLabel.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
