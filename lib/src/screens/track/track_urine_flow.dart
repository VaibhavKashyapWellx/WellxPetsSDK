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
    with SingleTickerProviderStateMixin {
  _UrineStep _step = _UrineStep.instructions;
  final _picker = ImagePicker();
  String? _imagePath;
  String? _error;
  List<_UrineParameter>? _results;

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
            child: const Icon(Icons.close,
                size: 14, color: WellxColors.textSecondary),
          ),
        ),
        title: const Text('Urine Screening'),
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

  // ---------- Step 1: Instructions ----------

  Widget _buildInstructionsStep() {
    return SingleChildScrollView(
      key: const ValueKey('instructions'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Intro card
          WellxCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WellxColors.scoreBlue.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.water_drop,
                      size: 22, color: WellxColors.scoreBlue),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('At-Home Urine Screening',
                          style: WellxTypography.cardTitle.copyWith(
                              fontSize: 16, color: WellxColors.deepPurple)),
                      const SizedBox(height: 4),
                      Text(
                        'Screen for early signs of kidney, liver, and metabolic issues.',
                        style: WellxTypography.captionText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // How It Works
          WellxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How It Works',
                    style: WellxTypography.chipText
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: WellxSpacing.md),
                _instructionRow(1, Icons.water_drop,
                    'Dip the urine test strip per manufacturer instructions'),
                const SizedBox(height: 10),
                _instructionRow(
                    2, Icons.timer, 'Wait the recommended time (usually 60 seconds)'),
                const SizedBox(height: 10),
                _instructionRow(3, Icons.camera_alt,
                    'Place strip on a white surface and take a photo'),
                const SizedBox(height: 10),
                _instructionRow(4, Icons.auto_awesome,
                    'AI analyzes the color pads and returns results'),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Parameters analyzed
          _buildParametersCard(),

          const SizedBox(height: WellxSpacing.xxl),

          WellxPrimaryButton(
            label: 'Scan My Strip',
            icon: Icons.camera_alt,
            onPressed: () => setState(() => _step = _UrineStep.capture),
          ),
          const SizedBox(height: WellxSpacing.xl),
        ],
      ),
    );
  }

  Widget _instructionRow(int step, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WellxColors.scoreBlue.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 12, color: WellxColors.scoreBlue),
        ),
        const SizedBox(width: WellxSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: WellxTypography.captionText),
          ),
        ),
      ],
    );
  }

  Widget _buildParametersCard() {
    final parameters = [
      ('pH', Icons.scale, WellxColors.scoreBlue),
      ('Protein', Icons.science, WellxColors.scoreOrange),
      ('Glucose', Icons.water_drop, WellxColors.amberWatch),
      ('Ketones', Icons.local_fire_department, WellxColors.scoreRed),
      ('Bilirubin', Icons.health_and_safety, WellxColors.scoreOrange),
      ('Blood', Icons.bloodtype, WellxColors.scoreRed),
      ('Specific Gravity', Icons.speed, WellxColors.scoreGreen),
      ('Leukocytes', Icons.bubble_chart, WellxColors.deepPurple),
    ];

    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parameters Analyzed',
              style: WellxTypography.chipText
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: WellxSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.5,
            children: parameters.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: WellxColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(p.$2, size: 14, color: p.$3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.$1,
                        style: WellxTypography.captionText
                            .copyWith(fontWeight: FontWeight.w500,
                                color: WellxColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('--',
                        style: WellxTypography.captionText
                            .copyWith(color: WellxColors.textTertiary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Step 2: Camera Capture ----------

  Widget _buildCaptureStep() {
    return SingleChildScrollView(
      key: const ValueKey('capture'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Preview
          Container(
            height: 200,
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
                      errorBuilder: (_, e, st) => _capturePlaceholder(),
                    ),
                  )
                : _capturePlaceholder(),
          ),
          const SizedBox(height: WellxSpacing.xl),

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
                  label: 'From Library',
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

          const SizedBox(height: WellxSpacing.xl),

          // Tip card
          WellxCard(
            backgroundColor: WellxColors.scoreBlue.withValues(alpha: 0.04),
            borderColor: WellxColors.scoreBlue.withValues(alpha: 0.15),
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
        ],
      ),
    );
  }

  Widget _capturePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.qr_code_scanner,
              size: 24, color: Colors.white),
        ),
        const SizedBox(height: WellxSpacing.md),
        const Text(
          'Scan Your Test Strip',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
        _step = _UrineStep.processing;
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
                        color: WellxColors.scoreBlue.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.water_drop,
                          size: 44, color: WellxColors.scoreBlue),
                    ),
                  );
                },
              ),
              const SizedBox(height: WellxSpacing.xl),
              Text('Analyzing urine strip...',
                  style: WellxTypography.heading
                      .copyWith(color: WellxColors.scoreBlue)),
              const SizedBox(height: WellxSpacing.sm),
              Text(
                'Reading color pads and comparing to reference values.',
                style: WellxTypography.captionText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WellxSpacing.xl),
              const LinearProgressIndicator(
                color: WellxColors.scoreBlue,
                backgroundColor: WellxColors.border,
              ),
              const SizedBox(height: WellxSpacing.xl),
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = _UrineStep.capture;
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

  // ---------- Step 4: Results ----------

  Widget _buildResultsStep() {
    final results = _results;
    if (results == null) return const SizedBox.shrink();

    final normalCount = results.where((r) => r.status == 'normal').length;
    final borderlineCount =
        results.where((r) => r.status == 'borderline').length;
    final abnormalCount = results.where((r) => r.status == 'abnormal').length;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: Column(
        children: [
          // Summary card
          WellxCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: abnormalCount > 0
                        ? WellxColors.coral.withValues(alpha: 0.12)
                        : borderlineCount > 0
                            ? WellxColors.amberWatch.withValues(alpha: 0.12)
                            : WellxColors.scoreGreen.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    abnormalCount > 0
                        ? Icons.warning_amber
                        : borderlineCount > 0
                            ? Icons.info_outline
                            : Icons.check_circle,
                    size: 28,
                    color: abnormalCount > 0
                        ? WellxColors.coral
                        : borderlineCount > 0
                            ? WellxColors.amberWatch
                            : WellxColors.scoreGreen,
                  ),
                ),
                const SizedBox(height: WellxSpacing.md),
                Text(
                  abnormalCount > 0
                      ? 'Some Results Need Attention'
                      : borderlineCount > 0
                          ? 'Mostly Normal'
                          : 'All Parameters Normal',
                  style: WellxTypography.heading,
                ),
                const SizedBox(height: 4),
                Text(
                  '$normalCount normal, $borderlineCount borderline, $abnormalCount abnormal',
                  style: WellxTypography.captionText,
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Individual parameter results
          WellxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detailed Results',
                    style: WellxTypography.chipText
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: WellxSpacing.md),
                ...results.map(
                  (param) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(param.status)
                                .withValues(alpha: 0.12),
                          ),
                          child: Icon(param.icon,
                              size: 14, color: _statusColor(param.status)),
                        ),
                        const SizedBox(width: WellxSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(param.name,
                                  style: WellxTypography.chipText
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(param.value,
                                  style: WellxTypography.captionText),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(param.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            param.status[0].toUpperCase() +
                                param.status.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(param.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Disclaimer
          WellxCard(
            backgroundColor: WellxColors.scoreBlue.withValues(alpha: 0.04),
            borderColor: WellxColors.scoreBlue.withValues(alpha: 0.15),
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
          const SizedBox(height: WellxSpacing.xxl),

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
                _step = _UrineStep.capture;
                _imagePath = null;
                _results = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: WellxSpacing.xl),
        ],
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
}
