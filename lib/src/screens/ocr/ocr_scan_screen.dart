import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/pet_provider.dart';
import '../../providers/vet_chat_provider.dart';
import '../../services/ocr_service.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_spacing.dart';
import '../../theme/wellx_typography.dart';
import '../../widgets/wellx_card.dart';

/// Document scanner screen using Claude Vision for OCR.
class OcrScanScreen extends ConsumerStatefulWidget {
  const OcrScanScreen({super.key});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  final _picker = ImagePicker();

  _ScanState _state = _ScanState.idle;
  File? _selectedImage;
  DocumentAnalysisResult? _result;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _state = _ScanState.preview;
        _result = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _analyzeDocument() async {
    if (_selectedImage == null) return;

    setState(() {
      _state = _ScanState.processing;
      _errorMessage = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64 = base64Encode(bytes);
      final pet = ref.read(selectedPetProvider);
      final claudeService = ref.read(claudeProxyServiceProvider);
      final ocrService = OcrService(claudeService);

      final result = await ocrService.analyzeDocument(
        imageBase64: base64,
        petName: pet?.name ?? 'your pet',
      );

      setState(() {
        _result = result;
        _state = _ScanState.results;
      });
    } catch (e) {
      setState(() {
        _state = _ScanState.preview;
        _errorMessage = 'Analysis failed: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _selectedImage = null;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.cardSurface,
        elevation: 0,
        title: Text(
          'Document Scanner',
          style: WellxTypography.cardTitle.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_state != _ScanState.idle)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              color: WellxColors.textTertiary,
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_state) {
            _ScanState.idle => _buildIdleState(),
            _ScanState.preview => _buildPreviewState(),
            _ScanState.processing => _buildProcessingState(),
            _ScanState.results => _buildResultsState(),
          },
        ),
      ),
    );
  }

  // ── Idle: pick source ────────────────────────────────────────────────────

  Widget _buildIdleState() {
    return Padding(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: WellxSpacing.xxl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WellxColors.deepPurple.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 36,
              color: WellxColors.deepPurple,
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
          Text('Scan a Vet Document', style: WellxTypography.heading),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            'Take a photo or upload an image of a lab report, prescription, or vet record. AI will extract the key medical data.',
            textAlign: TextAlign.center,
            style: WellxTypography.bodyText.copyWith(
              color: WellxColors.textSecondary,
            ),
          ),
          const SizedBox(height: WellxSpacing.xxl),

          // Camera option
          _buildPickerButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            subtitle: 'Use your camera to capture the document',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: WellxSpacing.md),

          // Gallery option
          _buildPickerButton(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select an existing photo',
            onTap: () => _pickImage(ImageSource.gallery),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: WellxSpacing.lg),
            _buildErrorWidget(_errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WellxCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WellxColors.primaryGradient,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: WellxTypography.cardTitle.copyWith(fontSize: 15)),
                  Text(
                    subtitle,
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: WellxColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview: show image before analyzing ─────────────────────────────────

  Widget _buildPreviewState() {
    return Padding(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          if (_errorMessage != null) ...[
            _buildErrorWidget(_errorMessage!),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Analyze button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _analyzeDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: WellxColors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: WellxSpacing.sm),
                  Text(
                    'Analyze with AI',
                    style: WellxTypography.buttonLabel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          TextButton(
            onPressed: _reset,
            child: Text(
              'Choose a different image',
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Processing: loading animation ────────────────────────────────────────

  Widget _buildProcessingState() {
    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: WellxColors.deepPurple,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),
          Text(
            'Analyzing Document...',
            style: WellxTypography.heading,
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            'AI is extracting medical data from your document',
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Results: show extracted data ─────────────────────────────────────────

  Widget _buildResultsState() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.alertGreen.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: WellxColors.alertGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analysis Complete', style: WellxTypography.cardTitle),
                    Text(
                      'Review the extracted data below',
                      style: WellxTypography.captionText.copyWith(
                        color: WellxColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Document info card
          if (result.title != null || result.date != null || result.clinic != null)
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DOCUMENT INFO', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.sm),
                  if (result.title != null)
                    _buildFieldRow(Icons.description_rounded, 'Title', result.title!),
                  if (result.date != null)
                    _buildFieldRow(Icons.calendar_today_rounded, 'Date', result.date!),
                  if (result.clinic != null)
                    _buildFieldRow(Icons.local_hospital_rounded, 'Clinic', result.clinic!),
                ],
              ),
            ),
          const SizedBox(height: WellxSpacing.md),

          // Diagnoses card
          if (result.diagnoses.isNotEmpty)
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIAGNOSES', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.sm),
                  ...result.diagnoses.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: WellxColors.alertRed,
                            ),
                            const SizedBox(width: WellxSpacing.sm),
                            Expanded(
                              child: Text(
                                d,
                                style: WellxTypography.bodyText.copyWith(
                                  color: WellxColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: WellxSpacing.md),

          // Medications card
          if (result.medications.isNotEmpty)
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MEDICATIONS', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.sm),
                  ...result.medications.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.medication_rounded,
                              size: 16,
                              color: WellxColors.deepPurple,
                            ),
                            const SizedBox(width: WellxSpacing.sm),
                            Expanded(
                              child: Text(
                                m,
                                style: WellxTypography.bodyText.copyWith(
                                  color: WellxColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: WellxSpacing.md),

          // Notes card
          if (result.notes != null && result.notes!.isNotEmpty)
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTES', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.sm),
                  Text(
                    result.notes!,
                    style: WellxTypography.bodyText.copyWith(
                      color: WellxColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: WellxSpacing.xl),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Save as medical record — pop back with result
                Navigator.of(context).pop(result);
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(
                'Save as Medical Record',
                style: WellxTypography.buttonLabel,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: WellxColors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: Text(
                'Scan Another Document',
                style: WellxTypography.buttonLabel.copyWith(
                  color: WellxColors.deepPurple,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: WellxColors.deepPurple,
                side: const BorderSide(color: WellxColors.deepPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildFieldRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: WellxColors.deepPurple),
          const SizedBox(width: WellxSpacing.sm),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WellxTypography.bodyText.copyWith(
                color: WellxColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.md),
      decoration: BoxDecoration(
        color: WellxColors.alertRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, size: 16, color: WellxColors.alertRed),
          const SizedBox(width: WellxSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: WellxTypography.captionText.copyWith(
                color: WellxColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── State enum ─────────────────────────────────────────────────────────────

enum _ScanState { idle, preview, processing, results }
