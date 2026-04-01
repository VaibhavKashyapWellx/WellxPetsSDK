import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/travel_models.dart';
import '../../providers/travel_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Travel plan checklist with checkable items, due dates, progress bar.
class TravelChecklistScreen extends ConsumerStatefulWidget {
  final TravelPlan plan;

  const TravelChecklistScreen({super.key, required this.plan});

  @override
  ConsumerState<TravelChecklistScreen> createState() =>
      _TravelChecklistScreenState();
}

class _TravelChecklistScreenState
    extends ConsumerState<TravelChecklistScreen> {
  late List<ChecklistItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.plan.checklist?.toList() ?? [];
  }

  double get _progress {
    if (_items.isEmpty) return 0;
    return _items.where((i) => i.completed).length / _items.length;
  }

  int get _completedCount => _items.where((i) => i.completed).length;

  Future<void> _toggleItem(int index) async {
    setState(() {
      _items[index].completed = !_items[index].completed;
    });
    await _saveChecklist();
  }

  Future<void> _saveChecklist() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(travelServiceProvider);
      await service.updatePlanChecklist(widget.plan.id, _items);
    } catch (_) {
      // Silently handle -- offline-friendly
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.plan.planStatus;

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text(widget.plan.destinationCountry),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WellxColors.deepPurple,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        children: [
          // Status card
          WellxCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(status.icon, size: 20, color: status.color),
                ),
                const SizedBox(width: WellxSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.displayName, style: WellxTypography.cardTitle),
                    if (widget.plan.travelDate != null)
                      Text(
                        'Travel: ${widget.plan.travelDate}',
                        style: WellxTypography.captionText,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: WellxSpacing.lg),

          // Progress bar
          WellxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Checklist Progress', style: WellxTypography.chipText),
                    Text(
                      '$_completedCount/${_items.length}',
                      style: WellxTypography.chipText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WellxColors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WellxSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: WellxColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progress >= 1.0
                          ? WellxColors.alertGreen
                          : WellxColors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: WellxSpacing.xs),
                Text(
                  _progress >= 1.0
                      ? 'All tasks completed!'
                      : '${(_progress * 100).toInt()}% complete',
                  style: WellxTypography.microLabel.copyWith(
                    color: _progress >= 1.0
                        ? WellxColors.alertGreen
                        : WellxColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: WellxSpacing.lg),

          // Checklist items grouped by category
          ..._buildGroupedItems(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems() {
    final categories = <String, List<MapEntry<int, ChecklistItem>>>{};
    for (var i = 0; i < _items.length; i++) {
      final cat = _items[i].category;
      categories.putIfAbsent(cat, () => []);
      categories[cat]!.add(MapEntry(i, _items[i]));
    }

    final widgets = <Widget>[];
    for (final entry in categories.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
          child: Row(
            children: [
              Icon(
                entry.value.first.value.categoryIcon,
                size: 14,
                color: entry.value.first.value.categoryColor,
              ),
              const SizedBox(width: 6),
              Text(
                entry.key.toUpperCase(),
                style: WellxTypography.sectionLabel.copyWith(
                  color: entry.value.first.value.categoryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

      for (final itemEntry in entry.value) {
        widgets.add(_checklistTile(itemEntry.key, itemEntry.value));
      }

      widgets.add(const SizedBox(height: WellxSpacing.lg));
    }

    return widgets;
  }

  Widget _checklistTile(int index, ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
      child: GestureDetector(
        onTap: () => _toggleItem(index),
        child: Container(
          padding: const EdgeInsets.all(WellxSpacing.md),
          decoration: BoxDecoration(
            color: WellxColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.completed
                  ? WellxColors.alertGreen.withOpacity(0.3)
                  : WellxColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.completed
                      ? WellxColors.alertGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: item.completed
                        ? WellxColors.alertGreen
                        : WellxColors.textTertiary,
                    width: 2,
                  ),
                ),
                child: item.completed
                    ? const Icon(Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.task,
                      style: WellxTypography.chipText.copyWith(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.completed
                            ? WellxColors.textTertiary
                            : WellxColors.textPrimary,
                      ),
                    ),
                    if (item.dueDate != null)
                      Text(
                        'Due: ${item.dueDate}',
                        style: WellxTypography.microLabel.copyWith(
                          color: WellxColors.coral,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
