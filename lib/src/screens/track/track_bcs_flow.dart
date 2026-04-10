import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/bcs_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';

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
  XFile? _pickedFile;

  // Mock result data
  BCSRecord? _result;
  String? _error;

  // Scanning line animation
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  // Observation stagger animation
  late AnimationController _observationController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _observationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WellxColors.background,
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

  // ==========================================================================
  // STEP 1 — Instructions Screen
  // ==========================================================================

  Widget _buildInstructionsStep() {
    return Scaffold(
      key: const ValueKey('instructions'),
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: WellxColors.primary),
        ),
        title: Text(
          'Body Condition Scan',
          style: WellxTypography.cardTitle.copyWith(color: WellxColors.primary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: WellxColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: WellxSpacing.lg),

                  // Hero card with photo examples
                  _buildHeroPhotoCard(),

                  const SizedBox(height: WellxSpacing.xl),

                  // Heading
                  Text(
                    'Capture Perfection',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: WellxColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: WellxSpacing.sm),
                  Text(
                    'Better photos lead to more accurate BCS results. Follow these tips for the best scan.',
                    style: WellxTypography.captionText,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: WellxSpacing.xl),

                  // Numbered instruction steps
                  _buildInstructionCard(
                    number: 1,
                    title: 'Find Well-Lit Area',
                    description:
                        'Natural daylight or bright indoor lighting works best for clear photos.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 2,
                    title: 'Stand Pet Naturally',
                    description:
                        'Have your pet stand on all fours in a relaxed, natural posture.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 3,
                    title: 'Capture Side View',
                    description:
                        'Photograph the full body profile from the side at pet height.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 4,
                    title: 'Capture Top-Down View',
                    description:
                        'Stand above and photograph the back to see the waist outline.',
                  ),

                  const SizedBox(height: WellxSpacing.xxl),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(
              WellxSpacing.xl,
              WellxSpacing.lg,
              WellxSpacing.xl,
              WellxSpacing.xxl,
            ),
            decoration: BoxDecoration(
              color: WellxColors.background,
              boxShadow: [
                BoxShadow(
                  color: WellxColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: WellxColors.primary,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: WellxColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _step = _BCSStep.capture),
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: WellxSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shutter_speed,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: WellxSpacing.sm),
                          Text(
                            'Start Scan',
                            style: WellxTypography.buttonLabel,
                          ),
                        ],
                      ),
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

  Widget _buildHeroPhotoCard() {
    return Container(
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: WellxColors.tonalShadow,
      ),
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Row(
        children: [
          Expanded(child: _buildPhotoSlot('Side View')),
          const SizedBox(width: WellxSpacing.md),
          Expanded(child: _buildPhotoSlot('Top View')),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(String label) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Placeholder icon
            Center(
              child: Icon(
                Icons.pets,
                size: 40,
                color: WellxColors.outline.withValues(alpha: 0.3),
              ),
            ),
            // Gradient overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            // Pill badge
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: WellxColors.scoreGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: WellxColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required int number,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WellxColors.primaryContainer,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: WellxColors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: WellxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: WellxTypography.captionText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 2 — Camera Capture (preserved from original)
  // ==========================================================================

  Widget _buildCaptureStep() {
    return Scaffold(
      key: const ValueKey('capture'),
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              setState(() => _step = _BCSStep.instructions),
          icon: const Icon(Icons.arrow_back, color: WellxColors.primary),
        ),
        title: Text(
          'Capture Photo',
          style: WellxTypography.cardTitle.copyWith(color: WellxColors.primary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: Column(
          children: [
            // Preview area
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: WellxColors.inkPrimary,
                borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              ),
              child: _imagePath != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(WellxSpacing.cardRadius),
                      child: Image.file(
                        File(_imagePath!),
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
        _pickedFile = xFile;
        _imagePath = xFile.path;
        _error = null;
        _step = _BCSStep.processing;
      });
      _runMockAnalysis();
    } catch (e) {
      setState(() => _error = 'Failed to capture image. Please try again.');
    }
  }

  // ==========================================================================
  // STEP 3 — AI Processing
  // ==========================================================================

  Widget _buildProcessingStep() {
    final observations = [
      ('Checking rib coverage...', Icons.sync),
      ('Analyzing waist definition...', Icons.sync),
      ('Assessing abdominal tuck...', Icons.sync),
    ];

    return Scaffold(
      key: const ValueKey('processing'),
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            setState(() {
              _step = _BCSStep.capture;
              _imagePath = null;
            });
          },
          icon: const Icon(Icons.arrow_back, color: WellxColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: WellxSpacing.lg),

            // Heading
            Text(
              'AI Processing',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: WellxColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              'Analyzing pet biomechanics and fat distribution...',
              style: WellxTypography.captionText,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: WellxSpacing.xxl),

            // Main visual: Photo with scanning ring
            _buildScanningVisual(),

            const SizedBox(height: WellxSpacing.lg),

            // "Precision Scan Active" pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: WellxColors.scoreGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WellxColors.scoreGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Precision Scan Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WellxColors.scoreGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // "Live Observations" section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Live Observations',
                style: WellxTypography.cardTitle,
              ),
            ),
            const SizedBox(height: WellxSpacing.md),

            ...observations.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
                child: _buildObservationCard(entry.value.$1, entry.value.$2,
                    entry.key),
              );
            }),

            const SizedBox(height: WellxSpacing.xl),

            // Tip card
            Container(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              decoration: BoxDecoration(
                color: WellxColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
                border: Border(
                  left: BorderSide(
                    color: WellxColors.midPurple,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: WellxColors.midPurple,
                  ),
                  const SizedBox(width: WellxSpacing.md),
                  Expanded(
                    child: Text(
                      'Our AI model is trained on over 50,000 breed-specific data points for the highest accuracy.',
                      style: WellxTypography.captionText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningVisual() {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _scanLineAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Scanning ring
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 4,
                  color: WellxColors.primary.withValues(alpha: 0.6),
                  backgroundColor:
                      WellxColors.primary.withValues(alpha: 0.1),
                ),
              ),
              // Photo display
              ClipOval(
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: _imagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => Container(
                                color: WellxColors.surfaceContainerLow,
                                child: const Icon(Icons.pets, size: 60,
                                    color: WellxColors.outline),
                              ),
                            ),
                            // Scanning line overlay
                            Positioned(
                              top: 190 * _scanLineAnim.value - 2,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      WellxColors.primary
                                          .withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: WellxColors.surfaceContainerLow,
                          child: const Icon(Icons.pets,
                              size: 60, color: WellxColors.outline),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildObservationCard(String text, IconData icon, int index) {
    return AnimatedBuilder(
      animation: _observationController,
      builder: (context, child) {
        // Create a staggered pulsing effect
        final phase = (_observationController.value + index * 0.33) % 1.0;
        final opacity = 0.5 + 0.5 * sin(phase * 2 * pi);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WellxSpacing.lg,
            vertical: WellxSpacing.md,
          ),
          decoration: BoxDecoration(
            color: WellxColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.primaryContainer.withValues(alpha: 0.1),
                ),
                child: Opacity(
                  opacity: opacity,
                  child: Icon(
                    icon,
                    size: 18,
                    color: WellxColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: WellxTypography.chipText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _runMockAnalysis() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      // Generate mock BCS result
      final rng = Random();
      final score = 4 + rng.nextInt(3); // 4-6 range for demo
      final confidence = 0.82 + rng.nextDouble() * 0.15;

      final result = BCSRecord(
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

      setState(() {
        _result = result;
        _step = _BCSStep.results;
      });

      // Persist to Supabase (non-fatal fire-and-forget)
      _persistBCSResult(result);
    });
  }

  Future<void> _persistBCSResult(BCSRecord record) async {
    try {
      final pet = ref.read(selectedPetProvider);
      final auth = ref.read(currentAuthProvider);
      if (pet == null || auth.userId == null) return;

      final bcsService = ref.read(bcsServiceProvider);

      String? imageUrl;
      final file = _pickedFile;
      if (file != null) {
        try {
          final bytes = await file.readAsBytes();
          imageUrl = await bcsService.uploadBCSPhoto(
            petId: pet.id,
            photoData: bytes,
            fileName: file.name,
          );
        } catch (_) {
          // Photo upload failure is non-fatal
        }
      }

      await bcsService.saveBCSResult(
        petId: pet.id,
        ownerId: auth.userId!,
        score: record.score,
        imageUrl: imageUrl,
        muscleCondition: record.label,
        notes: record.keyObservations.join('; '),
      );
    } catch (_) {
      // BCS save failure is non-fatal — result is already shown to user
    }
  }

  // ==========================================================================
  // STEP 4 — Results Screen
  // ==========================================================================

  Widget _buildResultsStep() {
    final record = _result;
    if (record == null) return const SizedBox.shrink();

    return Scaffold(
      key: const ValueKey('results'),
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: WellxColors.primary),
        ),
        title: Text(
          'Scan Results',
          style: WellxTypography.cardTitle.copyWith(color: WellxColors.primary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: WellxSpacing.lg),

            // Hero score card (purple gradient)
            _buildHeroScoreCard(record),

            const SizedBox(height: WellxSpacing.xl),

            // BCS Reference Scale
            _buildReferenceScale(record),

            const SizedBox(height: WellxSpacing.xl),

            // AI Insights Deep Dive
            Text(
              'AI Insights Deep Dive',
              style: WellxTypography.heading,
            ),
            const SizedBox(height: WellxSpacing.md),

            // Bento cards row: Rib Definition + Waist Visibility
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.restaurant,
                    title: 'Rib Definition',
                    value: record.score <= 5 ? 'Healthy' : 'Excess Cover',
                    description: 'Ribs palpable with slight fat covering',
                  ),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: _buildInsightCard(
                    icon: Icons.visibility,
                    title: 'Waist Visibility',
                    value: record.score <= 5 ? 'Defined' : 'Reduced',
                    description: 'Waist visible from above',
                  ),
                ),
              ],
            ),
            const SizedBox(height: WellxSpacing.md),

            // Full-width dark card: Abdominal Tuck
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(WellxSpacing.cardPadding),
              decoration: BoxDecoration(
                color: WellxColors.onPrimaryFixedVariant,
                borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.straighten,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: WellxSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abdominal Tuck',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.score <= 5
                              ? 'Present and well-defined from the side'
                              : 'Reduced tuck suggests excess abdominal fat',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xxl),

            // Recommended Next Steps
            Text(
              'Recommended Next Steps',
              style: WellxTypography.heading,
            ),
            const SizedBox(height: WellxSpacing.md),

            // "View Nutrition Plan" full-width purple pill
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: WellxColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Nutrition plan action
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: WellxSpacing.lg,
                      ),
                      child: Center(
                        child: Text(
                          'View Nutrition Plan',
                          style: WellxTypography.buttonLabel,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: WellxSpacing.md),

            // Half-width buttons row
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryAction(
                    'Share with Vet',
                    Icons.share,
                    () {},
                  ),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: _buildSecondaryAction(
                    'Schedule Scan',
                    Icons.calendar_today,
                    () {
                      setState(() {
                        _step = _BCSStep.capture;
                        _imagePath = null;
                        _result = null;
                        _error = null;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroScoreCard(BCSRecord record) {
    final conditionLabel = record.label;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: WellxSpacing.xxl,
        horizontal: WellxSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: WellxColors.primaryGradient,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: Stack(
        children: [
          // Decorative blur orbs
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              Text(
                'SCAN ANALYSIS RESULT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: WellxSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${record.score}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/9',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WellxSpacing.md),
              // Condition pill badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '$conditionLabel Condition',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceScale(BCSRecord record) {
    // Position marker based on score (1-9 mapped to 0.0-1.0)
    final markerPosition = (record.score - 1) / 8.0;

    return Container(
      padding: const EdgeInsets.all(WellxSpacing.cardPadding),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BCS Reference Scale',
                style: WellxTypography.chipText
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: WellxColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '98% Accuracy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: WellxColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  // Underweight (1-3) — amber
                  Expanded(
                    flex: 3,
                    child: Container(color: WellxColors.amberWatch),
                  ),
                  // Ideal (4-5) — green
                  Expanded(
                    flex: 2,
                    child: Container(color: WellxColors.scoreGreen),
                  ),
                  // Overweight (6-7) — orange
                  Expanded(
                    flex: 2,
                    child: Container(color: WellxColors.scoreOrange),
                  ),
                  // Obese (8-9) — red
                  Expanded(
                    flex: 2,
                    child: Container(color: WellxColors.scoreRed),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.xs),

          // "YOUR PET" marker
          LayoutBuilder(
            builder: (context, constraints) {
              final markerX =
                  (constraints.maxWidth * markerPosition).clamp(12.0, constraints.maxWidth - 12.0);
              return SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: markerX - 6,
                      top: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: WellxColors.primary,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: WellxColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: (markerX - 30).clamp(0.0, constraints.maxWidth - 60),
                      top: 14,
                      child: Text(
                        'YOUR PET',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: WellxColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: WellxSpacing.sm),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _scaleLabel('Underweight', WellxColors.amberWatch),
              _scaleLabel('Ideal', WellxColors.scoreGreen),
              _scaleLabel('Overweight', WellxColors.scoreOrange),
              _scaleLabel('Obese', WellxColors.scoreRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scaleLabel(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: WellxColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WellxColors.primaryContainer.withValues(alpha: 0.3),
            ),
            child: Icon(icon, size: 20, color: WellxColors.primary),
          ),
          const SizedBox(height: WellxSpacing.md),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WellxColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: WellxColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: WellxTypography.smallLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction(
      String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: WellxSpacing.md,
              horizontal: WellxSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: WellxColors.onSurface),
                const SizedBox(width: WellxSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: WellxColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
