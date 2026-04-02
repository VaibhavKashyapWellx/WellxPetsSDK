import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_models.dart';
import '../../models/pet.dart';
import '../../providers/credit_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/health_service.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Records/Wallet tab — documents and xCoins balance.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _searchText = '';
  String _selectedFilter = 'All';
  bool _showSearch = false;

  static const _docCategories = [
    'All',
    'Lab Report',
    'Vaccine',
    'Dental',
    'Prescription',
    'X-ray',
    'Other',
  ];

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
                  color: WellxColors.deepPurple.withOpacity(0.1),
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
                  color: WellxColors.scoreBlue.withOpacity(0.1),
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
      final doc = DocumentCreate(
        id: const Uuid().v4(),
        petId: petId,
        title: picked.name.split('.').first,
        date: DateTime.now().toIso8601String().split('T').first,
        category: category,
        fileType: picked.name.split('.').last,
      );
      await healthService.addDocument(doc);
      ref.invalidate(documentsProvider(petId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
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

    final balanceAsync = ref.watch(balanceStreamProvider);
    final balance = balanceAsync.valueOrNull;

    final filteredDocs = _filterDocuments(documents);

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
            // Title bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.lg,
                  WellxSpacing.lg,
                  WellxSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    Text('Records', style: WellxTypography.screenTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _uploadDocument(context, ref, petId),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: WellxColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pet switcher
            if (pets.length > 1)
              SliverToBoxAdapter(
                child: _PetSwitcher(
                  pets: pets,
                  selectedPet: selectedPet,
                  onSelect: (id) =>
                      ref.read(selectedPetIdProvider.notifier).state = id,
                ),
              ),

            // Hero stats card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WellxSpacing.lg),
                child: _RecordsHeroCard(
                  petName: selectedPet?.name ?? 'Your Pet',
                  petEmoji: selectedPet?.speciesEmoji ?? '\u{1F415}',
                  docCount: documents.length,
                  onUpload: () => _uploadDocument(context, ref, petId),
                  onScan: () => context.push('/ocr-scan'),
                ),
              ),
            ),

            // Search + filter bar
            SliverToBoxAdapter(
              child: _SearchFilterBar(
                showSearch: _showSearch,
                searchText: _searchText,
                selectedFilter: _selectedFilter,
                categories: _docCategories,
                onToggleSearch: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchText = '';
                  });
                },
                onSearchChanged: (val) => setState(() => _searchText = val),
                onFilterChanged: (val) =>
                    setState(() => _selectedFilter = val),
              ),
            ),

            // Document list
            if (isLoadingDocs && documents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WellxSpacing.lg),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: WellxSpacing.md),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: WellxColors.flatCardFill,
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
                child: _EmptyRecordsState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.lg,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = filteredDocs[index];
                      return _DocumentTile(
                        doc: doc,
                        onTap: () => context.push('/document-detail/${doc.id}'),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              ),

            // Coins balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.lg,
                  WellxSpacing.xl,
                  WellxSpacing.lg,
                  100,
                ),
                child: _CoinsBalanceCard(
                  coinsBalance: balance?.coinsBalance ?? 0,
                  onTap: () => context.push('/credits-wallet'),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.lg,
        vertical: WellxSpacing.md,
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WellxColors.textPrimary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : WellxColors.border,
                  ),
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
                            ? Colors.white.withOpacity(0.25)
                            : WellxColors.textPrimary.withOpacity(0.08),
                      ),
                      child: Icon(
                        (pet.species ?? 'dog').toLowerCase() == 'cat'
                            ? Icons.pets
                            : Icons.pets,
                        size: 12,
                        color: isSelected
                            ? Colors.white
                            : WellxColors.textPrimary,
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
                            : WellxColors.textPrimary,
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
// Records Hero Card
// ---------------------------------------------------------------------------

class _RecordsHeroCard extends StatelessWidget {
  final String petName;
  final String petEmoji;
  final int docCount;
  final VoidCallback? onUpload;
  final VoidCallback? onScan;

  const _RecordsHeroCard({
    required this.petName,
    required this.petEmoji,
    required this.docCount,
    this.onUpload,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return WellxFlatCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(petName, style: WellxTypography.heading),
                    const SizedBox(height: 4),
                    Text(
                      '$docCount record${docCount == 1 ? '' : 's'} on file',
                      style: WellxTypography.bodyText.copyWith(
                        color: WellxColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: WellxColors.flatCardFill,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(petEmoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.lg),
          Row(
            children: [
              _QuickActionButton(
                icon: Icons.upload_file,
                label: 'Upload',
                color: WellxColors.textPrimary,
                onTap: onUpload ?? () {},
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.camera_alt,
                label: 'Scan',
                color: WellxColors.scoreGreen,
                onTap: onScan ?? () {},
              ),
              const SizedBox(width: 10),
              _QuickActionButton(
                icon: Icons.medical_services,
                label: 'Dr. Layla',
                color: WellxColors.hormonalHarmony,
                onTap: () => context.go('/vet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: WellxTypography.captionText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: WellxColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search + Filter Bar
// ---------------------------------------------------------------------------

class _SearchFilterBar extends StatelessWidget {
  final bool showSearch;
  final String searchText;
  final String selectedFilter;
  final List<String> categories;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const _SearchFilterBar({
    required this.showSearch,
    required this.searchText,
    required this.selectedFilter,
    required this.categories,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
          child: Row(
            children: [
              Text(
                'YOUR RECORDS',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.deepPurple,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggleSearch,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: WellxColors.flatCardFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showSearch ? Icons.close : Icons.search,
                    size: 13,
                    color: WellxColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search bar
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WellxSpacing.lg,
              WellxSpacing.md,
              WellxSpacing.lg,
              0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: WellxColors.flatCardFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 14, color: WellxColors.textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: WellxTypography.bodyText,
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        hintStyle: WellxTypography.bodyText.copyWith(
                          color: WellxColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (searchText.isNotEmpty)
                    GestureDetector(
                      onTap: () => onSearchChanged(''),
                      child: const Icon(Icons.cancel,
                          size: 14, color: WellxColors.textTertiary),
                    ),
                ],
              ),
            ),
          ),

        // Filter pills
        const SizedBox(height: WellxSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
          child: Row(
            children: categories.map((cat) {
              final isSelected = selectedFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onFilterChanged(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? WellxColors.textPrimary
                          : WellxColors.flatCardFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: WellxTypography.captionText.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : WellxColors.textPrimary,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Empty Records State
// ---------------------------------------------------------------------------

class _EmptyRecordsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: WellxColors.flatCardFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search,
                size: 28, color: WellxColors.textTertiary),
          ),
          const SizedBox(height: WellxSpacing.lg),
          Text(
            'No records yet',
            style: WellxTypography.inputText
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload vet records, lab reports, and certificates to keep everything in one place.',
              textAlign: TextAlign.center,
              style: WellxTypography.captionText
                  .copyWith(color: WellxColors.textTertiary),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: WellxColors.textPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_file,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Upload First Record',
                  style: WellxTypography.chipText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document Tile
// ---------------------------------------------------------------------------

class _DocumentTile extends StatelessWidget {
  final PetDocument doc;
  final VoidCallback onTap;

  const _DocumentTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WellxColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: WellxColors.inkSecondary,
                    child: Center(
                      child: Icon(
                        _categoryIcon(doc.category),
                        size: 22,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(doc.category),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _shortCategory(doc.category),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WellxTypography.smallLabel.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WellxColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(doc.date),
                    style: WellxTypography.microLabel,
                  ),
                ],
              ),
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
        return Icons.science;
      case 'vaccine':
      case 'vaccination':
        return Icons.vaccines;
      case 'dental':
        return Icons.mood;
      case 'prescription':
        return Icons.medication;
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  Color _categoryColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return WellxColors.coral;
      case 'vaccine':
      case 'vaccination':
        return WellxColors.scoreGreen;
      case 'dental':
        return WellxColors.bloodImmunity;
      case 'prescription':
        return WellxColors.amberWatch;
      case 'x-ray':
      case 'xray':
        return WellxColors.hormonalHarmony;
      default:
        return WellxColors.textSecondary;
    }
  }

  String _shortCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'lab report':
      case 'lab':
        return 'LAB';
      case 'vaccine':
      case 'vaccination':
        return 'VACCINE';
      case 'dental':
        return 'DENTAL';
      case 'prescription':
        return 'RX';
      case 'x-ray':
      case 'xray':
      case 'imaging':
        return 'X-RAY';
      default:
        return 'DOC';
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Coins Balance Card
// ---------------------------------------------------------------------------

class _CoinsBalanceCard extends StatelessWidget {
  final int coinsBalance;
  final VoidCallback onTap;

  const _CoinsBalanceCard({
    required this.coinsBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WellxCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WellxColors.amberWatch.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star,
                  size: 18, color: WellxColors.amberWatch),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COINS EARNED',
                    style: WellxTypography.sectionLabel.copyWith(
                      letterSpacing: 1,
                      color: WellxColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '$coinsBalance',
                        style: WellxTypography.heading,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'coins',
                        style: WellxTypography.smallLabel.copyWith(
                          color: WellxColors.amberWatch,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 12, color: WellxColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
