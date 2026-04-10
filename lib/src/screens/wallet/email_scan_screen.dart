import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_models.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_spacing.dart';
import '../../theme/wellx_typography.dart';

// ---------------------------------------------------------------------------
// Data model for a discovered email document
// ---------------------------------------------------------------------------

class _EmailDocument {
  final String title;
  final String senderEmail;
  final String date;
  final String category;
  final String fileSize;
  bool selected = true;

  _EmailDocument({
    required this.title,
    required this.senderEmail,
    required this.date,
    required this.category,
    required this.fileSize,
  });

  IconData get categoryIcon {
    switch (category) {
      case 'Lab Report':
        return Icons.science_outlined;
      case 'Vaccine':
        return Icons.vaccines_outlined;
      case 'Dental':
        return Icons.medical_services_outlined;
      case 'Prescription':
        return Icons.receipt_long_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'Lab Report':
        return WellxColors.scoreBlue;
      case 'Vaccine':
        return WellxColors.tertiary;
      case 'Dental':
        return WellxColors.aiPurple;
      case 'Prescription':
        return WellxColors.alertOrange;
      default:
        return WellxColors.onSurfaceVariant;
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen email scanning flow for auto-importing vet documents.
class EmailScanScreen extends ConsumerStatefulWidget {
  const EmailScanScreen({super.key});

  @override
  ConsumerState<EmailScanScreen> createState() => _EmailScanScreenState();
}

class _EmailScanScreenState extends ConsumerState<EmailScanScreen>
    with TickerProviderStateMixin {
  // Current step: 0 = connect, 1 = scanning, 2 = review, 3 = complete
  int _currentStep = 0;

  // Scanning state
  final List<String> _scanUpdates = [];

  // Found documents
  late List<_EmailDocument> _foundDocuments;

  // Import state
  bool _isImporting = false;
  int _importedCount = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _checkController;
  bool _howItWorksExpanded = false;

  @override
  void initState() {
    super.initState();
    _foundDocuments = [];
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _selectProvider(String provider) {
    setState(() => _currentStep = 1);
    _runScan();
  }

  Future<void> _runScan() async {
    final updates = [
      '\u{1F50D} Searching for veterinary emails...',
      '\u{1F4CE} Found 3 emails with attachments...',
      '\u{1F4C4} Extracting documents from VetClinic Dubai...',
      '\u{1F9EA} Analyzing lab report from Feb 2026...',
      '\u2705 Found 4 importable documents',
    ];

    for (var i = 0; i < updates.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _scanUpdates.add(updates[i]));
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _foundDocuments = [
      _EmailDocument(
        title: 'Blood Panel Results - Feb 2026',
        senderEmail: 'results@vetclinic.ae',
        date: '2026-02-15',
        category: 'Lab Report',
        fileSize: '1.2 MB',
      ),
      _EmailDocument(
        title: 'Rabies Vaccination Certificate',
        senderEmail: 'records@dubaivet.com',
        date: '2026-01-20',
        category: 'Vaccine',
        fileSize: '840 KB',
      ),
      _EmailDocument(
        title: 'Annual Health Check Summary',
        senderEmail: 'clinic@pawshealth.ae',
        date: '2025-12-05',
        category: 'Lab Report',
        fileSize: '2.1 MB',
      ),
      _EmailDocument(
        title: 'Dental Cleaning Report',
        senderEmail: 'info@petdental.ae',
        date: '2025-11-18',
        category: 'Dental',
        fileSize: '960 KB',
      ),
    ];

    setState(() {
      _currentStep = 2;
    });
  }

  void _toggleSelectAll() {
    final allSelected = _foundDocuments.every((d) => d.selected);
    setState(() {
      for (final doc in _foundDocuments) {
        doc.selected = !allSelected;
      }
    });
  }

  int get _selectedCount => _foundDocuments.where((d) => d.selected).length;

  Future<void> _importDocuments() async {
    final pet = ref.read(selectedPetProvider);
    if (pet == null) return;

    setState(() => _isImporting = true);

    final healthService = ref.read(healthServiceProvider);
    final selected = _foundDocuments.where((d) => d.selected).toList();
    const uuid = Uuid();
    var imported = 0;

    for (final doc in selected) {
      try {
        await healthService.addDocument(
          DocumentCreate(
            id: uuid.v4(),
            petId: pet.id,
            title: doc.title,
            date: doc.date,
            fileType: 'pdf',
            category: doc.category,
            fileUrl: null,
          ),
        );
        imported++;
      } catch (_) {
        // Continue importing remaining documents on failure
      }
    }

    // Invalidate the documents provider to refresh wallet
    ref.invalidate(documentsProvider);

    if (!mounted) return;
    _checkController.forward();
    setState(() {
      _importedCount = imported;
      _isImporting = false;
      _currentStep = 3;
    });
  }

  void _scanAgain() {
    setState(() {
      _currentStep = 0;
      _scanUpdates.clear();
      _foundDocuments = [];
      _importedCount = 0;
    });
    _checkController.reset();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WellxColors.surface,
      appBar: AppBar(
        backgroundColor: WellxColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: WellxColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Smart Sync',
          style: WellxTypography.heading,
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _ConnectEmailStep(
          key: const ValueKey('step_connect'),
          onProviderSelected: _selectProvider,
          howItWorksExpanded: _howItWorksExpanded,
          onToggleHowItWorks: () {
            setState(() => _howItWorksExpanded = !_howItWorksExpanded);
          },
        );
      case 1:
        return _ScanningStep(
          key: const ValueKey('step_scanning'),
          updates: _scanUpdates,
          pulseController: _pulseController,
        );
      case 2:
        return _ReviewStep(
          key: const ValueKey('step_review'),
          documents: _foundDocuments,
          isImporting: _isImporting,
          selectedCount: _selectedCount,
          onToggleDocument: (index) {
            setState(() {
              _foundDocuments[index].selected =
                  !_foundDocuments[index].selected;
            });
          },
          onToggleSelectAll: _toggleSelectAll,
          onImport: _importDocuments,
        );
      case 3:
        final pet = ref.watch(selectedPetProvider);
        return _CompleteStep(
          key: const ValueKey('step_complete'),
          importedCount: _importedCount,
          petName: pet?.name ?? 'your pet',
          documents: _foundDocuments.where((d) => d.selected).toList(),
          checkController: _checkController,
          onViewRecords: () => Navigator.of(context).pop(),
          onScanAgain: _scanAgain,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// STEP 1 — Connect Email
// =============================================================================

class _ConnectEmailStep extends StatelessWidget {
  final ValueChanged<String> onProviderSelected;
  final bool howItWorksExpanded;
  final VoidCallback onToggleHowItWorks;

  const _ConnectEmailStep({
    super.key,
    required this.onProviderSelected,
    required this.howItWorksExpanded,
    required this.onToggleHowItWorks,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: WellxSpacing.xl),
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WellxSpacing.xxl),
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
              boxShadow: WellxColors.subtleShadow,
            ),
            child: Column(
              children: [
                // Gradient icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WellxColors.accentGradient,
                  ),
                  child: const Icon(
                    Icons.mail_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: WellxSpacing.xl),
                Text(
                  'Connect Your Email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: WellxColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WellxSpacing.md),
                Text(
                  'We\'ll scan your inbox for vet records, lab results, '
                  'and prescriptions. Your data stays private.',
                  style: WellxTypography.bodyText.copyWith(
                    color: WellxColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: WellxSpacing.xxl),

          // Email provider buttons
          _ProviderButton(
            label: 'Continue with Gmail',
            icon: Icons.g_mobiledata_rounded,
            iconColor: const Color(0xFFDB4437),
            backgroundColor: Colors.white,
            textColor: WellxColors.onSurface,
            borderColor: WellxColors.outlineVariant.withValues(alpha: 0.4),
            onTap: () => onProviderSelected('google'),
          ),
          const SizedBox(height: WellxSpacing.md),
          _ProviderButton(
            label: 'Continue with Outlook',
            icon: Icons.window_rounded,
            iconColor: const Color(0xFF0078D4),
            backgroundColor: Colors.white,
            textColor: WellxColors.onSurface,
            borderColor: WellxColors.outlineVariant.withValues(alpha: 0.4),
            onTap: () => onProviderSelected('microsoft'),
          ),
          const SizedBox(height: WellxSpacing.md),
          _ProviderButton(
            label: 'Continue with Apple Mail',
            icon: Icons.apple_rounded,
            iconColor: Colors.white,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onTap: () => onProviderSelected('apple'),
          ),
          const SizedBox(height: WellxSpacing.md),
          _ProviderButton(
            label: 'Other Email Provider',
            icon: Icons.email_outlined,
            iconColor: WellxColors.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            textColor: WellxColors.onSurface,
            borderColor: WellxColors.outlineVariant,
            onTap: () => onProviderSelected('other'),
          ),

          const SizedBox(height: WellxSpacing.xl),

          // Privacy note card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WellxSpacing.lg),
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(WellxSpacing.lg),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: WellxColors.tertiary,
                  size: 20,
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: Text(
                    'We only scan for pet health documents. '
                    'We never read personal emails.',
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: WellxSpacing.lg),

          // How does this work?
          GestureDetector(
            onTap: onToggleHowItWorks,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(WellxSpacing.lg),
              decoration: BoxDecoration(
                color: WellxColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(WellxSpacing.lg),
                border: Border.all(color: WellxColors.ghostBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: WellxColors.primary,
                      ),
                      const SizedBox(width: WellxSpacing.sm),
                      Text(
                        'How does this work?',
                        style: WellxTypography.chipText.copyWith(
                          color: WellxColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: howItWorksExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: WellxColors.primary,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: WellxSpacing.md),
                      child: Text(
                        'We use AI to securely scan your email for messages '
                        'from veterinary clinics, labs, and pet health providers. '
                        'We identify attachments like lab reports, vaccination '
                        'certificates, and prescriptions, then let you review '
                        'and import them into your pet\'s health records.',
                        style: WellxTypography.captionText,
                      ),
                    ),
                    crossFadeState: howItWorksExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: textColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 2 — Scanning
// =============================================================================

class _ScanningStep extends StatelessWidget {
  final List<String> updates;
  final AnimationController pulseController;

  const _ScanningStep({
    super.key,
    required this.updates,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Pulsing progress indicator
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 + pulseController.value * 0.12;
              final opacity = 0.3 + pulseController.value * 0.5;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: WellxColors.primary.withValues(alpha: opacity),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: WellxColors.accentGradient,
                    ),
                    child: const Icon(
                      Icons.mail_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: WellxSpacing.xxl),
          Text(
            'Scanning Inbox...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: WellxColors.onSurface,
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            'Looking for vet clinic emails, lab reports, '
            'and medical records...',
            style: WellxTypography.bodyText.copyWith(
              color: WellxColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Live scan updates
          Expanded(
            child: ListView.builder(
              itemCount: updates.length,
              itemBuilder: (context, index) {
                return _ScanUpdateRow(
                  text: updates[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanUpdateRow extends StatefulWidget {
  final String text;
  final int index;

  const _ScanUpdateRow({required this.text, required this.index});

  @override
  State<_ScanUpdateRow> createState() => _ScanUpdateRowState();
}

class _ScanUpdateRowState extends State<_ScanUpdateRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WellxSpacing.lg,
              vertical: WellxSpacing.md,
            ),
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(WellxSpacing.md),
            ),
            child: Text(
              widget.text,
              style: WellxTypography.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 3 — Review Found Documents
// =============================================================================

class _ReviewStep extends StatelessWidget {
  final List<_EmailDocument> documents;
  final bool isImporting;
  final int selectedCount;
  final ValueChanged<int> onToggleDocument;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onImport;

  const _ReviewStep({
    super.key,
    required this.documents,
    required this.isImporting,
    required this.selectedCount,
    required this.onToggleDocument,
    required this.onToggleSelectAll,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = documents.every((d) => d.selected);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: WellxSpacing.xl),
                // Heading with count badge
                Row(
                  children: [
                    Text(
                      'Documents Found',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: WellxColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: WellxSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WellxColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${documents.length}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WellxSpacing.xs),
                Text(
                  'Review and select which documents to import.',
                  style: WellxTypography.bodyText.copyWith(
                    color: WellxColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),

                // Select All / Deselect All
                GestureDetector(
                  onTap: onToggleSelectAll,
                  child: Row(
                    children: [
                      Icon(
                        allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: WellxColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: WellxSpacing.sm),
                      Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: WellxTypography.chipText.copyWith(
                          color: WellxColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),

                // Document cards
                ...List.generate(documents.length, (i) {
                  final doc = documents[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: WellxSpacing.md),
                    child: _DocumentCard(
                      document: doc,
                      onToggle: () => onToggleDocument(i),
                    ),
                  );
                }),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),

        // Bottom import button
        Container(
          padding: const EdgeInsets.fromLTRB(
            WellxSpacing.xl,
            WellxSpacing.lg,
            WellxSpacing.xl,
            WellxSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: WellxColors.surface,
            boxShadow: [
              BoxShadow(
                color: WellxColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    selectedCount > 0 && !isImporting ? onImport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WellxColors.primary,
                  foregroundColor: WellxColors.onPrimary,
                  disabledBackgroundColor:
                      WellxColors.primary.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Import $selectedCount Document${selectedCount != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final _EmailDocument document;
  final VoidCallback onToggle;

  const _DocumentCard({
    required this.document,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(WellxSpacing.lg),
        decoration: BoxDecoration(
          color: document.selected
              ? WellxColors.surfaceContainerLowest
              : WellxColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          border: Border.all(
            color: document.selected
                ? WellxColors.primary.withValues(alpha: 0.3)
                : WellxColors.ghostBorder,
          ),
          boxShadow:
              document.selected ? WellxColors.subtleShadow : null,
        ),
        child: Row(
          children: [
            // Document icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: document.categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                document.categoryIcon,
                color: document.categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: WellxSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WellxColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.senderEmail,
                    style: WellxTypography.smallLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WellxSpacing.xs),
                  Row(
                    children: [
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              document.categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          document.category,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: document.categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: WellxSpacing.sm),
                      Text(
                        document.fileSize,
                        style: WellxTypography.smallLabel.copyWith(
                          color: WellxColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: WellxSpacing.sm),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: document.selected
                    ? WellxColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: document.selected
                      ? WellxColors.primary
                      : WellxColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: document.selected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 4 — Import Complete
// =============================================================================

class _CompleteStep extends StatelessWidget {
  final int importedCount;
  final String petName;
  final List<_EmailDocument> documents;
  final AnimationController checkController;
  final VoidCallback onViewRecords;
  final VoidCallback onScanAgain;

  const _CompleteStep({
    super.key,
    required this.importedCount,
    required this.petName,
    required this.documents,
    required this.checkController,
    required this.onViewRecords,
    required this.onScanAgain,
  });

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final doc in documents) {
      counts[doc.category] = (counts[doc.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryCounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Green check in glowing circle
          ScaleTransition(
            scale: CurvedAnimation(
              parent: checkController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.tertiary.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: WellxColors.tertiary,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: WellxSpacing.xl),
          Text(
            'Import Complete!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: WellxColors.onSurface,
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            '$importedCount document${importedCount != 1 ? 's have' : ' has'} '
            'been added to $petName\'s records.',
            style: WellxTypography.bodyText.copyWith(
              color: WellxColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: WellxSpacing.xxl),

          // Summary cards
          ...categories.entries.map((entry) {
            final icon = _iconForCategory(entry.key);
            final color = _colorForCategory(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: WellxSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(WellxSpacing.lg),
                decoration: BoxDecoration(
                  color: WellxColors.surfaceContainerLowest,
                  borderRadius:
                      BorderRadius.circular(WellxSpacing.cardRadius),
                  boxShadow: WellxColors.subtleShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: WellxSpacing.md),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: WellxSpacing.xxl),

          // View Records button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onViewRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: WellxColors.primary,
                foregroundColor: WellxColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'View Records',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.md),

          // Scan Again button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: onScanAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: WellxColors.primary,
                side: const BorderSide(color: WellxColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Scan Again',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WellxColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'Lab Report':
        return Icons.science_outlined;
      case 'Vaccine':
        return Icons.vaccines_outlined;
      case 'Dental':
        return Icons.medical_services_outlined;
      case 'Prescription':
        return Icons.receipt_long_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  static Color _colorForCategory(String category) {
    switch (category) {
      case 'Lab Report':
        return WellxColors.scoreBlue;
      case 'Vaccine':
        return WellxColors.tertiary;
      case 'Dental':
        return WellxColors.aiPurple;
      case 'Prescription':
        return WellxColors.alertOrange;
      default:
        return WellxColors.onSurfaceVariant;
    }
  }
}
