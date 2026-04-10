import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_models.dart';
import '../../models/pet.dart';
import '../../providers/credit_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';

/// Records Hub tab — documents wallet with smart sync.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _searchText = '';
  String _selectedFilter = 'All';

  static const _docCategories = [
    'All',
    'Lab Report',
    'Vaccine',
    'Dental',
    'Prescription',
    'X-ray',
    'Other',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadDocument(
      BuildContext context, WidgetRef ref, String? petId) async {
    if (petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a pet first')),
      );
      return;
    }

    final category = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Document Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            for (final cat in _docCategories.where((c) => c != 'All'))
              ListTile(
                title: Text(cat),
                onTap: () => Navigator.pop(ctx, cat),
              ),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;

    // Let user choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: WellxColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: WellxColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WellxColors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: WellxColors.deepPurple, size: 20),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to photograph a document'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WellxColors.scoreBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: WellxColors.scoreBlue, size: 20),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select an existing file'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    try {
      final healthService = ref.read(healthServiceProvider);

      // Upload file bytes to Supabase storage first
      final fileBytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final contentType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
      final fileUrl = await healthService.uploadDocument(
        petId: petId,
        fileName: picked.name,
        fileData: fileBytes,
        contentType: contentType,
      );

      // Create the document record with the real storage URL
      final doc = DocumentCreate(
        id: const Uuid().v4(),
        petId: petId,
        title: picked.name.split('.').first,
        date: DateTime.now().toIso8601String().split('T').first,
        category: category,
        fileType: ext,
        fileUrl: fileUrl,
      );
      await healthService.addDocument(doc);
      ref.invalidate(documentsProvider(petId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: WellxColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id;

    final documentsAsync =
        petId != null ? ref.watch(documentsProvider(petId)) : null;
    final documents = documentsAsync?.valueOrNull ?? [];
    final isLoadingDocs = documentsAsync?.isLoading ?? false;

    // Keep balance provider warm for invalidation on refresh.
    ref.watch(balanceStreamProvider);

    final filteredDocs = _filterDocuments(documents);

    // Estimate storage used (rough: count * 2MB avg)
    final storageMB = (documents.length * 2.4).clamp(0, 1024).toDouble();
    final storagePercent = (storageMB / 1024).clamp(0.0, 1.0);

    return SafeArea(
      child: RefreshIndicator(
        color: WellxColors.deepPurple,
        onRefresh: () async {
          if (petId != null) {
            ref.invalidate(documentsProvider(petId));
          }
          ref.invalidate(walletBalanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header: "Records Hub" ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.xl, WellxSpacing.xl, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Records Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: WellxColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Everything about ${selectedPet?.name ?? 'your pet'}\'s health, in one secure place.',
                      style: WellxTypography.bodyText.copyWith(
                        color: WellxColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pet Switcher ──
            if (pets.length > 1)
              SliverToBoxAdapter(
                child: _PetSwitcher(
                  pets: pets,
                  selectedPet: selectedPet,
                  onSelect: (id) =>
                      ref.read(selectedPetIdProvider.notifier).state = id,
                ),
              ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.lg, WellxSpacing.xl, 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: WellxColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: WellxColors.onSurface.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search,
                          size: 22, color: WellxColors.outlineVariant),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchText = val),
                          style: WellxTypography.bodyText,
                          decoration: InputDecoration(
                            hintText: 'Search lab reports, vaccines...',
                            hintStyle: WellxTypography.bodyText.copyWith(
                              color: WellxColors.outlineVariant,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      if (_searchText.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(Icons.cancel,
                                size: 18, color: WellxColors.outlineVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Smart Sync Card (dark hero) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.xl, WellxSpacing.xl, 0,
                ),
                child: _SmartSyncCard(),
              ),
            ),

            // ── Vaccine Passport Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.lg, WellxSpacing.xl, 0,
                ),
                child: _VaccinePassportCard(
                  vaccineCount: documents
                      .where((d) =>
                          (d.category ?? '')
                              .toLowerCase()
                              .contains('vaccine'))
                      .length,
                ),
              ),
            ),

            // ── Filter Chips ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: WellxSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: WellxSpacing.xl),
                      child: Row(
                        children: [
                          Text(
                            'Recent Documents',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: WellxColors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'View All',
                              style: WellxTypography.captionText.copyWith(
                                fontWeight: FontWeight.w700,
                                color: WellxColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: WellxSpacing.xl),
                      child: Row(
                        children: _docCategories.map((cat) {
                          final isSelected = _selectedFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedFilter = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? WellxColors.onSurface
                                      : WellxColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  cat,
                                  style: WellxTypography.captionText.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : WellxColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: WellxSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Document List ──
            if (isLoadingDocs && documents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WellxSpacing.xl),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: WellxSpacing.md),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: WellxColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (filteredDocs.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyRecordsState(
                  onUpload: () => _uploadDocument(context, ref, petId),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = filteredDocs[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: WellxSpacing.md),
                        child: _DocumentCard(
                          doc: doc,
                          onTap: () =>
                              context.push('/document-detail/${doc.id}'),
                        ),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              ),

            // ── Storage Indicator ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.lg, WellxSpacing.xl, 0,
                ),
                child: _StorageIndicator(
                  usedMB: storageMB,
                  totalGB: 1.0,
                  percent: storagePercent,
                ),
              ),
            ),

            // ── Bottom Padding for floating nav ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  List<PetDocument> _filterDocuments(List<PetDocument> docs) {
    var filtered = docs;
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where(
            (d) =>
                (d.category ?? '')
                    .toLowerCase()
                    .contains(_selectedFilter.toLowerCase()),
          )
          .toList();
    }
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      filtered = filtered
          .where(
            (d) =>
                d.title.toLowerCase().contains(query) ||
                (d.category ?? '').toLowerCase().contains(query),
          )
          .toList();
    }
    return filtered;
  }
}

// ---------------------------------------------------------------------------
// Pet Switcher
// ---------------------------------------------------------------------------

class _PetSwitcher extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selectedPet;
  final ValueChanged<String> onSelect;

  const _PetSwitcher({
    required this.pets,
    required this.selectedPet,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        WellxSpacing.xl, WellxSpacing.lg, WellxSpacing.xl, 0,
      ),
      child: Row(
        children: pets.map((pet) {
          final isSelected = selectedPet?.id == pet.id;
          return Padding(
            padding: const EdgeInsets.only(right: WellxSpacing.sm),
            child: GestureDetector(
              onTap: () => onSelect(pet.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WellxColors.onSurface
                      : WellxColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : WellxColors.onSurface.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 12,
                        color:
                            isSelected ? Colors.white : WellxColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pet.name,
                      style: WellxTypography.chipText.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : WellxColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart Sync Card (Dark Hero)
// ---------------------------------------------------------------------------

class _SmartSyncCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        decoration: const BoxDecoration(
          color: WellxColors.onPrimaryFixedVariant,
        ),
        child: Stack(
          children: [
            // Decorative blur orb
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mail_rounded,
                        size: 18,
                        color: WellxColors.tertiaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'SMART SYNC',
                      style: WellxTypography.sectionLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: WellxColors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WellxSpacing.md),
                Text(
                  'Missing recent records?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: WellxColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect your email and we\'ll automatically pull in PDF results from your vet clinic.',
                  style: WellxTypography.bodyText.copyWith(
                    color: WellxColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: WellxSpacing.xl),
                GestureDetector(
                  onTap: () => context.push('/email-scan'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14,
                    ),
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
                    child: Text(
                      'Connect Email',
                      style: WellxTypography.buttonLabel.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vaccine Passport Card
// ---------------------------------------------------------------------------

class _VaccinePassportCard extends StatelessWidget {
  final int vaccineCount;

  const _VaccinePassportCard({required this.vaccineCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.xl),
      decoration: BoxDecoration(
        color: WellxColors.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded,
              size: 36, color: WellxColors.tertiary),
          const SizedBox(height: WellxSpacing.md),
          Text(
            'Vaccine Passport',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: WellxColors.tertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$vaccineCount active immunization${vaccineCount == 1 ? '' : 's'}.',
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.tertiary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to vaccine passport
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Passport',
                  style: WellxTypography.captionText.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WellxColors.tertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward,
                    size: 14, color: WellxColors.tertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document Card (List Item)
// ---------------------------------------------------------------------------

class _DocumentCard extends StatelessWidget {
  final PetDocument doc;
  final VoidCallback onTap;

  const _DocumentCard({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: WellxColors.onSurface.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _iconBgColor(doc.category),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(doc.category),
                size: 26,
                color: _iconColor(doc.category),
              ),
            ),
            const SizedBox(width: WellxSpacing.lg),
            // Title & meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WellxTypography.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      color: WellxColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: WellxColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(doc.date),
                        style: WellxTypography.smallLabel,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.description_outlined,
                          size: 12, color: WellxColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _fileSize(doc.fileType),
                        style: WellxTypography.smallLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: WellxSpacing.sm),
            // Category tag + download
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _tagBgColor(doc.category),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _shortCategory(doc.category).toUpperCase(),
                    style: WellxTypography.microLabel.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: _tagTextColor(doc.category),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.download_rounded,
                    size: 20, color: WellxColors.outlineVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return Icons.science_rounded;
      case 'vaccine':
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'dental':
        return Icons.mood_rounded;
      case 'prescription':
        return Icons.medication_rounded;
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _iconBgColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return WellxColors.primaryContainer.withValues(alpha: 0.3);
      case 'prescription':
        return WellxColors.secondaryContainer.withValues(alpha: 0.5);
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return WellxColors.errorContainer.withValues(alpha: 0.2);
      case 'vaccine':
      case 'vaccination':
        return WellxColors.tertiaryContainer.withValues(alpha: 0.3);
      case 'dental':
        return WellxColors.secondaryContainer.withValues(alpha: 0.4);
      default:
        return WellxColors.surfaceContainerHigh;
    }
  }

  Color _iconColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return WellxColors.primary;
      case 'prescription':
        return WellxColors.secondary;
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return WellxColors.error;
      case 'vaccine':
      case 'vaccination':
        return WellxColors.tertiary;
      case 'dental':
        return WellxColors.bloodImmunity;
      default:
        return WellxColors.onSurfaceVariant;
    }
  }

  Color _tagBgColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return WellxColors.tertiaryContainer.withValues(alpha: 0.4);
      case 'prescription':
        return WellxColors.secondaryContainer.withValues(alpha: 0.6);
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return WellxColors.errorContainer.withValues(alpha: 0.3);
      case 'vaccine':
      case 'vaccination':
        return WellxColors.tertiaryContainer.withValues(alpha: 0.3);
      case 'dental':
        return WellxColors.secondaryContainer.withValues(alpha: 0.4);
      default:
        return WellxColors.surfaceContainerHigh;
    }
  }

  Color _tagTextColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return WellxColors.tertiary;
      case 'prescription':
        return WellxColors.secondary;
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return WellxColors.error;
      case 'vaccine':
      case 'vaccination':
        return WellxColors.tertiary;
      case 'dental':
        return WellxColors.bloodImmunity;
      default:
        return WellxColors.onSurfaceVariant;
    }
  }

  String _shortCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return 'Lab Report';
      case 'vaccine':
      case 'vaccination':
        return 'Vaccine';
      case 'dental':
        return 'Dental';
      case 'prescription':
        return 'Prescription';
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return 'Imaging';
      default:
        return 'Doc';
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _fileSize(String? fileType) {
    switch ((fileType ?? '').toLowerCase()) {
      case 'pdf':
        return '2.4 MB';
      case 'jpg':
      case 'jpeg':
        return '1.8 MB';
      case 'png':
        return '3.2 MB';
      default:
        return '840 KB';
    }
  }
}

// ---------------------------------------------------------------------------
// Empty Records State
// ---------------------------------------------------------------------------

class _EmptyRecordsState extends StatelessWidget {
  final VoidCallback? onUpload;

  const _EmptyRecordsState({this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_rounded,
                size: 28, color: WellxColors.outlineVariant),
          ),
          const SizedBox(height: WellxSpacing.xl),
          Text(
            'No records yet',
            style: WellxTypography.heading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload vet records, lab reports, and certificates to keep everything in one place.',
            textAlign: TextAlign.center,
            style: WellxTypography.captionText.copyWith(
              color: WellxColors.outlineVariant,
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),
          GestureDetector(
            onTap: onUpload,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: WellxColors.onSurface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Upload First Record',
                    style: WellxTypography.buttonLabel.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage Indicator
// ---------------------------------------------------------------------------

class _StorageIndicator extends StatelessWidget {
  final double usedMB;
  final double totalGB;
  final double percent;

  const _StorageIndicator({
    required this.usedMB,
    required this.totalGB,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.xl),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLOUD STORAGE',
                  style: WellxTypography.microLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: WellxColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${usedMB.toStringAsFixed(0)} MB of ${totalGB.toStringAsFixed(0)} GB Used',
                  style: WellxTypography.captionText.copyWith(
                    fontWeight: FontWeight.w600,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 6,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: WellxColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        WellxColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: WellxSpacing.lg),
          GestureDetector(
            onTap: () {
              // TODO: manage storage
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: WellxColors.primary.withValues(alpha: 0.05),
              ),
              child: Text(
                'Manage',
                style: WellxTypography.captionText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WellxColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
