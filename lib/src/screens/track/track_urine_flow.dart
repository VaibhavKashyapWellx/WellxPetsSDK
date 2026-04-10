import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

// ---------------------------------------------------------------------------
// Urine Parameter Result
// ---------------------------------------------------------------------------

class _UrineParameter {
  final String name;
  final String value;
  final String status; // normal, borderline, abnormal
  final IconData icon;
  final Color color;

  const _UrineParameter({
    required this.name,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Urine Flow Steps
// ---------------------------------------------------------------------------

enum _UrineStep { instructions, capture, processing, results }

// ---------------------------------------------------------------------------
// Track Urine Flow — full-screen urine strip screening
// ---------------------------------------------------------------------------

class TrackUrineFlow extends ConsumerStatefulWidget {
  const TrackUrineFlow({super.key});

  @override
  ConsumerState<TrackUrineFlow> createState() => _TrackUrineFlowState();
}

class _TrackUrineFlowState extends ConsumerState<TrackUrineFlow>
    with TickerProviderStateMixin {
  _UrineStep _step = _UrineStep.instructions;
  final _picker = ImagePicker();
  String? _imagePath;
  String? _error;
  List<_UrineParameter>? _results;

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
      case _UrineStep.instructions:
        return _buildInstructionsStep();
      case _UrineStep.capture:
        return _buildCaptureStep();
      case _UrineStep.processing:
        return _buildProcessingStep();
      case _UrineStep.results:
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
          'Urine Screening',
          style:
              WellxTypography.cardTitle.copyWith(color: WellxColors.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: WellxSpacing.lg),

                  // Hero card with strip example placeholder
                  _buildHeroCard(),

                  const SizedBox(height: WellxSpacing.xl),

                  // Numbered instruction steps
                  _buildInstructionCard(
                    number: 1,
                    title: 'Dip Strip in Sample',
                    description:
                        'Dip strip in fresh sample for 2 seconds.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 2,
                    title: 'Wait for Colors',
                    description:
                        'Wait 60 seconds for colors to develop.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 3,
                    title: 'Place on White Surface',
                    description:
                        'Place strip on white paper/surface.',
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  _buildInstructionCard(
                    number: 4,
                    title: 'Capture from Above',
                    description:
                        'Take a clear photo from directly above.',
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Fixed bottom pill button
          _buildFixedBottomButton(
            label: 'Start Scan',
            icon: Icons.shutter_speed,
            onTap: () => setState(() => _step = _UrineStep.capture),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: WellxColors.tonalShadow,
      ),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Image placeholder showing urine strip example
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 48,
                    color: WellxColors.outline.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: WellxSpacing.sm),
                  Text(
                    'Urine Strip Example',
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Heading
          Text(
            'Scan Your Strip',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: WellxColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            'Place the urine test strip on a flat white surface for accurate readings.',
            style: WellxTypography.captionText,
            textAlign: TextAlign.center,
          ),
        ],
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
            decoration: const BoxDecoration(
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
  // STEP 2 — Camera Capture
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
              setState(() => _step = _UrineStep.instructions),
          icon: const Icon(Icons.arrow_back, color: WellxColors.primary),
        ),
        title: Text(
          'Capture Strip',
          style:
              WellxTypography.cardTitle.copyWith(color: WellxColors.primary),
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
                borderRadius:
                    BorderRadius.circular(WellxSpacing.cardRadius),
              ),
              child: _imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                          WellxSpacing.cardRadius),
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) =>
                            _capturePlaceholder(),
                      ),
                    )
                  : _capturePlaceholder(),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Camera / gallery pill buttons
            Row(
              children: [
                Expanded(
                  child: _buildPillActionButton(
                    label: 'Take Photo',
                    icon: Icons.camera_alt,
                    filled: true,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: _buildPillActionButton(
                    label: 'From Library',
                    icon: Icons.photo_library,
                    filled: false,
                    onTap: () => _pickImage(ImageSource.gallery),
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

            const SizedBox(height: WellxSpacing.xl),

            // Tip card
            WellxCard(
              backgroundColor:
                  WellxColors.scoreBlue.withValues(alpha: 0.04),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: WellxColors.scoreBlue),
                  const SizedBox(width: WellxSpacing.sm),
                  Expanded(
                    child: Text(
                      'Place the strip on a white surface for the clearest reading.',
                      style: WellxTypography.captionText
                          .copyWith(color: WellxColors.scoreBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _capturePlaceholder() {
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
          child: const Icon(Icons.qr_code_scanner,
              size: 32, color: Colors.white),
        ),
        const SizedBox(height: WellxSpacing.lg),
        const Text(
          'Scan Your Test Strip',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: WellxSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Place strip on a white surface and capture from above.',
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
      final xFile =
          await _picker.pickImage(source: source, imageQuality: 85);
      if (xFile == null) return;
      setState(() {
        _imagePath = xFile.path;
        _error = null;
        _step = _UrineStep.processing;
      });
      _runMockAnalysis();
    } catch (e) {
      setState(
          () => _error = 'Failed to capture image. Please try again.');
    }
  }

  // ==========================================================================
  // STEP 3 — AI Processing
  // ==========================================================================

  Widget _buildProcessingStep() {
    final observations = [
      ('Calibrating color channels...', Icons.tune),
      ('Measuring pH levels...', Icons.scale),
      ('Analyzing protein markers...', Icons.science),
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
              _step = _UrineStep.capture;
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
              'Analyzing Strip...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: WellxColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              'Color calibration and chemical analysis in progress...',
              style: WellxTypography.captionText,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: WellxSpacing.xxl),

            // Main visual: Photo with scanning overlay
            _buildScanningVisual(),

            const SizedBox(height: WellxSpacing.lg),

            // "Precision Analysis Active" pill
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: WellxColors.scoreGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Precision Analysis Active',
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

            // Live observations
            ...observations.asMap().entries.map((entry) {
              final idx = entry.key;
              final obs = entry.value;
              return AnimatedBuilder(
                animation: _observationController,
                builder: (context, child) {
                  final phase =
                      (_observationController.value * 3 - idx).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 0.4 + 0.6 * phase,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: WellxSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: null,
                              color: WellxColors.primary
                                  .withValues(alpha: phase),
                            ),
                          ),
                          const SizedBox(width: WellxSpacing.md),
                          Icon(obs.$2,
                              size: 16,
                              color: WellxColors.primary
                                  .withValues(alpha: 0.6)),
                          const SizedBox(width: WellxSpacing.sm),
                          Text(
                            obs.$1,
                            style: WellxTypography.captionText.copyWith(
                              color: WellxColors.onSurface
                                  .withValues(alpha: 0.5 + 0.5 * phase),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: WellxSpacing.xl),

            // Tip card about AI accuracy
            WellxCard(
              backgroundColor:
                  WellxColors.primary.withValues(alpha: 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: WellxColors.primary),
                  const SizedBox(width: WellxSpacing.sm),
                  Expanded(
                    child: Text(
                      'AI color-matching uses calibrated reference values for veterinary-grade accuracy.',
                      style: WellxTypography.captionText
                          .copyWith(color: WellxColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningVisual() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        color: WellxColors.inkPrimary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        child: Stack(
          children: [
            // Photo or placeholder
            if (_imagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => const SizedBox.shrink(),
                ),
              ),

            // Primary tint overlay
            Positioned.fill(
              child: Container(
                color: WellxColors.primary.withValues(alpha: 0.25),
              ),
            ),

            // Scanning line
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (context, child) {
                return Positioned(
                  top: _scanLineAnim.value * 220,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          WellxColors.primary.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Center scanning icon
            Center(
              child: AnimatedBuilder(
                animation: _scanLineController,
                builder: (context, child) {
                  return Opacity(
                    opacity:
                        0.6 + 0.4 * _scanLineAnim.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runMockAnalysis() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final rng = Random();

      setState(() {
        _results = [
          _UrineParameter(
            name: 'pH',
            value: (6.0 + rng.nextDouble() * 1.5).toStringAsFixed(1),
            status: 'normal',
            icon: Icons.scale,
            color: WellxColors.scoreBlue,
          ),
          _UrineParameter(
            name: 'Protein',
            value: 'Negative',
            status: 'normal',
            icon: Icons.science,
            color: WellxColors.scoreGreen,
          ),
          _UrineParameter(
            name: 'Glucose',
            value: 'Negative',
            status: 'normal',
            icon: Icons.water_drop,
            color: WellxColors.scoreGreen,
          ),
          _UrineParameter(
            name: 'Ketones',
            value: 'Trace',
            status: 'borderline',
            icon: Icons.local_fire_department,
            color: WellxColors.amberWatch,
          ),
          _UrineParameter(
            name: 'Bilirubin',
            value: 'Negative',
            status: 'normal',
            icon: Icons.health_and_safety,
            color: WellxColors.scoreGreen,
          ),
          _UrineParameter(
            name: 'Blood',
            value: 'Negative',
            status: 'normal',
            icon: Icons.bloodtype,
            color: WellxColors.scoreGreen,
          ),
          _UrineParameter(
            name: 'Specific Gravity',
            value: '1.0${20 + rng.nextInt(15)}',
            status: 'normal',
            icon: Icons.speed,
            color: WellxColors.scoreBlue,
          ),
          _UrineParameter(
            name: 'Leukocytes',
            value: 'Negative',
            status: 'normal',
            icon: Icons.bubble_chart,
            color: WellxColors.scoreGreen,
          ),
        ];
        _step = _UrineStep.results;
      });
    });
  }

  // ==========================================================================
  // STEP 4 — Results
  // ==========================================================================

  Widget _buildResultsStep() {
    final results = _results;
    if (results == null) return const SizedBox.shrink();

    final normalCount =
        results.where((r) => r.status == 'normal').length;
    final borderlineCount =
        results.where((r) => r.status == 'borderline').length;
    final abnormalCount =
        results.where((r) => r.status == 'abnormal').length;

    final overallStatus = abnormalCount > 0
        ? 'Abnormal'
        : borderlineCount > 0
            ? 'Borderline'
            : 'Normal';

    final conditionLabel = abnormalCount > 0
        ? 'Needs Veterinary Review'
        : borderlineCount > 0
            ? 'Monitor Closely'
            : 'All Clear';

    return Scaffold(
      key: const ValueKey('results'),
      backgroundColor: WellxColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: WellxSpacing.xl,
          right: WellxSpacing.xl,
          bottom: 120,
        ),
        child: Column(
          children: [
            // Purple gradient hero
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 0),
              padding: const EdgeInsets.fromLTRB(
                WellxSpacing.xl,
                60,
                WellxSpacing.xl,
                WellxSpacing.xxl,
              ),
              decoration: BoxDecoration(
                gradient: WellxColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(WellxSpacing.heroRadius),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Back button row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.xl),

                    // "SCREENING COMPLETE" label
                    Text(
                      'SCREENING COMPLETE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.md),

                    // Overall status
                    Text(
                      overallStatus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.md),

                    // Condition pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        conditionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.sm),
                    Text(
                      '$normalCount normal \u00B7 $borderlineCount borderline \u00B7 $abnormalCount abnormal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Parameter cards list
            ...results.map((param) => _buildParameterResultCard(param)),

            const SizedBox(height: WellxSpacing.xl),

            // Recommended Next Steps
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 4, bottom: WellxSpacing.md),
                child: Text(
                  'RECOMMENDED NEXT STEPS',
                  style: WellxTypography.sectionLabel,
                ),
              ),
            ),

            // "Share with Vet" full-width purple pill
            SizedBox(
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
                    onTap: () {},
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: WellxSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share,
                              color: Colors.white, size: 18),
                          const SizedBox(width: WellxSpacing.sm),
                          Text('Share with Vet',
                              style: WellxTypography.buttonLabel),
                        ],
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
                  child: _buildPillActionButton(
                    label: 'Schedule Follow-up',
                    icon: Icons.calendar_today,
                    filled: false,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: _buildPillActionButton(
                    label: 'Save Results',
                    icon: Icons.save_alt,
                    filled: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Disclaimer
            WellxCard(
              backgroundColor:
                  WellxColors.scoreBlue.withValues(alpha: 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: WellxColors.scoreBlue),
                  const SizedBox(width: WellxSpacing.sm),
                  Expanded(
                    child: Text(
                      'These results are for screening purposes only. Always consult your veterinarian for medical advice.',
                      style: WellxTypography.captionText
                          .copyWith(color: WellxColors.scoreBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterResultCard(_UrineParameter param) {
    final statusColor = _statusColor(param.status);
    final statusBgColor = _statusBgColor(param.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          boxShadow: WellxColors.subtleShadow,
        ),
        child: Row(
          children: [
            // Icon in colored circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.12),
              ),
              child: Icon(param.icon, size: 18, color: statusColor),
            ),
            const SizedBox(width: WellxSpacing.md),

            // Name + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    param.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WellxColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(param.value,
                      style: WellxTypography.captionText),
                ],
              ),
            ),

            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                param.status[0].toUpperCase() +
                    param.status.substring(1),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Shared Helpers
  // ==========================================================================

  Widget _buildFixedBottomButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
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
              onTap: onTap,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: WellxSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: WellxSpacing.sm),
                    Text(label, style: WellxTypography.buttonLabel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: filled ? WellxColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: filled
            ? null
            : Border.all(color: WellxColors.primary, width: 1.5),
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
                Icon(
                  icon,
                  size: 16,
                  color:
                      filled ? Colors.white : WellxColors.primary,
                ),
                const SizedBox(width: WellxSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: filled
                          ? Colors.white
                          : WellxColors.primary,
                    ),
                    maxLines: 1,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'normal':
        return WellxColors.scoreGreen;
      case 'borderline':
        return WellxColors.amberWatch;
      case 'abnormal':
        return WellxColors.coral;
      default:
        return WellxColors.textTertiary;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'normal':
        return WellxColors.tertiaryContainer.withValues(alpha: 0.3);
      case 'borderline':
        return WellxColors.amberWatch.withValues(alpha: 0.12);
      case 'abnormal':
        return WellxColors.errorContainer.withValues(alpha: 0.2);
      default:
        return WellxColors.surfaceContainerLow;
    }
  }
}
