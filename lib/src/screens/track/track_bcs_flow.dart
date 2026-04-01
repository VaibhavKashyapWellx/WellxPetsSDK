import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';
import '../../models/bcs_models.dart';

// ---------------------------------------------------------------------------
// BCS Flow Steps
// ---------------------------------------------------------------------------

enum _BCSStep { instructions, capture, processing, results }

// ---------------------------------------------------------------------------
// Track BCS Flow — full-screen body condition score assessment
// ---------------------------------------------------------------------------

class TrackBCSFlow extends ConsumerStatefulWidget {
  const TrackBCSFlow({super.key});

  @override
  ConsumerState<TrackBCSFlow> createState() => _TrackBCSFlowState();
}

class _TrackBCSFlowState extends ConsumerState<TrackBCSFlow>
    with TickerProviderStateMixin {
  _BCSStep _step = _BCSStep.instructions;
  final _picker = ImagePicker();
  String? _imagePath;

  // Mock result data
  BCSRecord? _result;
  String? _error;

  // Processing animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Body Condition Score'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _BCSStep.instructions:
        return _buildInstructionsStep();
      case _BCSStep.capture:
        return _buildCaptureStep();
      case _BCSStep.processing:
        return _buildProcessingStep();
      case _BCSStep.results:
        return _buildResultsStep();
    }
  }

  // ---------- Step 1: Instructions ----------

  Widget _buildInstructionsStep() {
    return SingleChildScrollView(
      key: const ValueKey('instructions'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro card
          WellxCard(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WellxColors.deepPurple.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 36, color: WellxColors.deepPurple),
                ),
                const SizedBox(height: WellxSpacing.lg),
                Text('Take 3 Photos',
                    style: WellxTypography.heading
                        .copyWith(color: WellxColors.deepPurple)),
                const SizedBox(height: WellxSpacing.sm),
                Text(
                  'For the most accurate BCS score, we need photos from three angles.',
                  style: WellxTypography.captionText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Photo angles
          _instructionItem(
            number: 1,
            title: 'Side View (Lateral)',
            description:
                'Stand at your pet\'s side and capture their full body profile.',
            icon: Icons.pets,
          ),
          const SizedBox(height: WellxSpacing.md),
          _instructionItem(
            number: 2,
            title: 'Top View (Dorsal)',
            description:
                'Stand above and photograph the back/spine area to see the waist.',
            icon: Icons.visibility,
          ),
          const SizedBox(height: WellxSpacing.md),
          _instructionItem(
            number: 3,
            title: 'Rear View (Posterior)',
            description:
                'From behind, capture the hip/pelvic area for tuck assessment.',
            icon: Icons.center_focus_strong,
          ),

          const SizedBox(height: WellxSpacing.xxl),

          // BCS Scale reference
          _buildBCSScaleCard(),

          const SizedBox(height: WellxSpacing.xxl),

          WellxPrimaryButton(
            label: 'Start Photo Capture',
            icon: Icons.camera_alt,
            onPressed: () {
              setState(() => _step = _BCSStep.capture);
            },
          ),
          const SizedBox(height: WellxSpacing.xl),
        ],
      ),
    );
  }

  Widget _instructionItem({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return WellxCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WellxColors.deepPurple.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: WellxColors.deepPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: WellxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WellxTypography.chipText.copyWith(
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 2),
                Text(description, style: WellxTypography.captionText),
              ],
            ),
          ),
          Icon(icon, size: 20, color: WellxColors.lightPurple),
        ],
      ),
    );
  }

  Widget _buildBCSScaleCard() {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BCS Scale (1-9)',
              style: WellxTypography.chipText
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: WellxSpacing.md),
          // Color bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: List.generate(9, (i) {
                final score = i + 1;
                return Expanded(
                  child: Container(
                    height: 28,
                    color: _segmentColor(score),
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendLabel('1-3', 'Under', WellxColors.scoreOrange),
              _legendLabel('4-5', 'Ideal', WellxColors.scoreGreen),
              _legendLabel('6-7', 'Over', WellxColors.amberWatch),
              _legendLabel('8-9', 'Obese', WellxColors.scoreRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendLabel(String range, String label, Color color) {
    return Column(
      children: [
        Text(range,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: WellxColors.textTertiary)),
      ],
    );
  }

  Color _segmentColor(int score) {
    switch (score) {
      case 1:
      case 2:
        return WellxColors.scoreRed;
      case 3:
        return WellxColors.scoreOrange;
      case 4:
      case 5:
        return WellxColors.scoreGreen;
      case 6:
        return WellxColors.scoreGreen.withValues(alpha: 0.8);
      case 7:
        return WellxColors.scoreOrange;
      case 8:
        return WellxColors.scoreOrange.withValues(alpha: 0.9);
      case 9:
        return WellxColors.scoreRed;
      default:
        return Colors.grey;
    }
  }

  // ---------- Step 2: Camera Capture ----------

  Widget _buildCaptureStep() {
    return SingleChildScrollView(
      key: const ValueKey('capture'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Preview area
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: WellxColors.inkPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _cameraPlaceholder(),
                    ),
                  )
                : _cameraPlaceholder(),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Camera / gallery buttons
          Row(
            children: [
              Expanded(
                child: WellxPrimaryButton(
                  label: 'Take Photo',
                  icon: Icons.camera_alt,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: WellxSecondaryButton(
                  label: 'Upload Photo',
                  icon: Icons.photo_library,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: WellxSpacing.lg),
            WellxCard(
              borderColor: WellxColors.coral,
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: WellxColors.coral, size: 20),
                  const SizedBox(width: WellxSpacing.sm),
                  Expanded(
                    child: Text(_error!,
                        style: WellxTypography.captionText
                            .copyWith(color: WellxColors.coral)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.camera_alt, size: 32, color: Colors.white),
        ),
        const SizedBox(height: WellxSpacing.lg),
        const Text(
          'Take a Photo for BCS Analysis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: WellxSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Capture a side and top-down photo of your pet.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(source: source, imageQuality: 85);
      if (xFile == null) return;
      setState(() {
        _imagePath = xFile.path;
        _error = null;
        _step = _BCSStep.processing;
      });
      _runMockAnalysis();
    } catch (e) {
      setState(() => _error = 'Failed to capture image. Please try again.');
    }
  }

  // ---------- Step 3: Processing ----------

  Widget _buildProcessingStep() {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: WellxCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: WellxSpacing.xl),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WellxColors.deepPurple.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 44, color: WellxColors.deepPurple),
                    ),
                  );
                },
              ),
              const SizedBox(height: WellxSpacing.xl),
              Text('Analyzing with AI...',
                  style: WellxTypography.heading
                      .copyWith(color: WellxColors.deepPurple)),
              const SizedBox(height: WellxSpacing.sm),
              Text(
                'Evaluating rib coverage, waist definition, and abdominal tuck.',
                style: WellxTypography.captionText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WellxSpacing.xl),
              const LinearProgressIndicator(
                color: WellxColors.deepPurple,
                backgroundColor: WellxColors.border,
              ),
              const SizedBox(height: WellxSpacing.xl),
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = _BCSStep.capture;
                    _imagePath = null;
                  });
                },
                child: Text('Cancel',
                    style: WellxTypography.captionText
                        .copyWith(color: WellxColors.textSecondary)),
              ),
              const SizedBox(height: WellxSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _runMockAnalysis() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Generate mock BCS result
      final rng = Random();
      final score = 4 + rng.nextInt(3); // 4-6 range for demo
      final confidence = 0.82 + rng.nextDouble() * 0.15;

      setState(() {
        _result = BCSRecord(
          id: 'bcs_mock_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          score: score,
          label: score <= 3
              ? 'Underweight'
              : score <= 5
                  ? 'Ideal'
                  : score <= 7
                      ? 'Overweight'
                      : 'Obese',
          confidence: confidence,
          onLineSummary: score <= 5
              ? 'Your pet appears to be in good body condition with appropriate weight distribution.'
              : 'Your pet shows signs of being slightly over ideal weight with reduced waist definition.',
          keyObservations: [
            'Ribs palpable with slight fat covering',
            'Waist visible when viewed from above',
            'Abdominal tuck present from the side',
            'Overall muscular condition appears healthy',
          ],
          healthFlags: score > 5
              ? ['Consider portion control', 'Increase daily exercise']
              : [],
          dietaryRecommendation: score <= 5
              ? 'Maintain current diet and exercise regimen. Consider adding omega-3 supplements.'
              : 'Consider reducing daily food intake by 10-15%. Increase exercise duration by 15 minutes.',
          speciesDetected: 'Dog',
          breedDetected: 'Mixed Breed',
          recheckWeeks: 4,
          viewQuality: const BCSViewQuality(
            lateral: 'good',
            dorsal: 'partial',
            posterior: 'good',
          ),
        );
        _step = _BCSStep.results;
      });
    });
  }

  // ---------- Step 4: Results ----------

  Widget _buildResultsStep() {
    final record = _result;
    if (record == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Score card
          WellxCard(
            child: Column(
              children: [
                Row(
                  children: [
                    // Score ring
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color: _scoreColor(record.score).withValues(alpha: 0.2),
                            backgroundColor: Colors.transparent,
                          ),
                          CircularProgressIndicator(
                            value: record.score / 9.0,
                            strokeWidth: 8,
                            color: _scoreColor(record.score),
                            backgroundColor: Colors.transparent,
                            strokeCap: StrokeCap.round,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${record.score}',
                                style: WellxTypography.dataNumber,
                              ),
                              Text('/ 9',
                                  style: WellxTypography.smallLabel),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: WellxSpacing.lg),

                    // Label + summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.label,
                            style: WellxTypography.heading.copyWith(
                              color: _scoreColor(record.score),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.onLineSummary,
                            style: WellxTypography.captionText,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 12, color: WellxColors.scoreGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Confidence: ${(record.confidence * 100).toInt()}%',
                                style: WellxTypography.smallLabel.copyWith(
                                  color: WellxColors.scoreGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dietary recommendation
                if (record.dietaryRecommendation.isNotEmpty) ...[
                  const SizedBox(height: WellxSpacing.lg),
                  const Divider(color: WellxColors.border),
                  const SizedBox(height: WellxSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.restaurant,
                          size: 16, color: WellxColors.midPurple),
                      const SizedBox(width: WellxSpacing.sm),
                      Expanded(
                        child: Text(
                          record.dietaryRecommendation,
                          style: WellxTypography.captionText,
                        ),
                      ),
                    ],
                  ),
                ],

                // Health flags
                if (record.healthFlags.isNotEmpty) ...[
                  const SizedBox(height: WellxSpacing.md),
                  ...record.healthFlags.map(
                    (flag) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 14, color: WellxColors.amberWatch),
                          const SizedBox(width: WellxSpacing.sm),
                          Expanded(
                            child: Text(flag,
                                style: WellxTypography.captionText
                                    .copyWith(color: WellxColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Key observations
          WellxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Observations',
                    style: WellxTypography.chipText
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: WellxSpacing.md),
                ...record.keyObservations.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: WellxColors.midPurple
                                    .withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: WellxColors.midPurple,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: WellxSpacing.md),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(entry.value,
                                    style: WellxTypography.captionText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // BCS Scale with marker
          _buildBCSScaleCard(),

          const SizedBox(height: WellxSpacing.xxl),

          // Action buttons
          WellxPrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: WellxSpacing.md),
          WellxSecondaryButton(
            label: 'Scan Again',
            icon: Icons.refresh,
            onPressed: () {
              setState(() {
                _step = _BCSStep.capture;
                _imagePath = null;
                _result = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: WellxSpacing.xl),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score <= 3) return WellxColors.scoreOrange;
    if (score <= 5) return WellxColors.scoreGreen;
    if (score == 6) return WellxColors.amberWatch;
    return WellxColors.scoreRed;
  }
}
