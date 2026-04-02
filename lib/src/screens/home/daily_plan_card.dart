import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Daily plan task model.
class DailyTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int coinReward;
  final bool isToggleable;
  final String? route;

  const DailyTask({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.icon,
    this.coinReward = 0,
    this.isToggleable = true,
    this.route,
  });
}

/// Daily plan cards showing personalized tasks for today.
class DailyPlanCard extends StatefulWidget {
  final String petName;

  const DailyPlanCard({super.key, required this.petName});

  @override
  State<DailyPlanCard> createState() => _DailyPlanCardState();
}

class _DailyPlanCardState extends State<DailyPlanCard> {
  final Set<String> _completedIds = {};

  late List<DailyTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = _buildTasks();
  }

  @override
  void didUpdateWidget(DailyPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petName != widget.petName) {
      _tasks = _buildTasks();
    }
  }

  List<DailyTask> _buildTasks() {
    return [
      DailyTask(
        id: 'walk',
        title: 'Take ${widget.petName} for a walk',
        subtitle: '20+ min recommended',
        icon: Icons.directions_walk,
        coinReward: 5,
        route: '/track',
      ),
      DailyTask(
        id: 'symptoms',
        title: 'Log symptoms',
        subtitle: 'Quick daily check-in',
        icon: Icons.edit_note,
        coinReward: 5,
        route: '/symptom-logger',
      ),
      DailyTask(
        id: 'body-check',
        title: 'Complete body check',
        subtitle: 'AI-powered health assessment',
        icon: Icons.camera_alt,
        coinReward: 10,
        route: '/bcs-check',
      ),
      DailyTask(
        id: 'chat',
        title: 'Ask Dr. Layla',
        subtitle: 'Get health advice',
        icon: Icons.medical_services,
        coinReward: 10,
        route: '/vet',
      ),
      DailyTask(
        id: 'upload',
        title: 'Upload a document',
        subtitle: 'Lab results, vaccine records',
        icon: Icons.upload_file,
        coinReward: 10,
        route: '/wallet',
      ),
    ];
  }

  int get _completedCount =>
      _tasks.where((t) => _completedIds.contains(t.id) && t.coinReward > 0).length;

  int get _completableCount => _tasks.where((t) => t.coinReward > 0).length;

  int get _totalCoins => _tasks.fold(0, (s, t) => s + t.coinReward);

  bool get _allDone =>
      _completedCount == _completableCount && _completableCount > 0;

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S PLAN",
                      style: WellxTypography.sectionLabel.copyWith(
                        color: WellxColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personalised for ${widget.petName}',
                      style: WellxTypography.captionText,
                    ),
                  ],
                ),
              ),
              // Progress ring
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _completableCount > 0
                          ? _completedCount / _completableCount
                          : 0,
                      strokeWidth: 3,
                      backgroundColor:
                          WellxColors.textPrimary.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation(
                        WellxColors.scoreGreen,
                      ),
                    ),
                    Text(
                      '$_completedCount/$_completableCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _allDone
                            ? WellxColors.scoreGreen
                            : WellxColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _completableCount > 0
                  ? _completedCount / _completableCount
                  : 0,
              minHeight: 4,
              backgroundColor: WellxColors.textPrimary.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(
                WellxColors.scoreGreen,
              ),
            ),
          ),

          const SizedBox(height: WellxSpacing.md),

          // Task rows
          ...List.generate(_tasks.length, (index) {
            final task = _tasks[index];
            final isCompleted = _completedIds.contains(task.id);
            return _TaskRow(
              task: task,
              isCompleted: isCompleted,
              isFirst: index == 0,
              isLast: index == _tasks.length - 1,
              onToggle: () {
                setState(() {
                  if (_completedIds.contains(task.id)) {
                    _completedIds.remove(task.id);
                  } else {
                    _completedIds.add(task.id);
                  }
                });
              },
              onTap: () {
                if (task.route != null) {
                  context.push(task.route!);
                }
              },
            );
          }),

          const SizedBox(height: WellxSpacing.md),

          // Bottom coins summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _allDone
                  ? WellxColors.scoreGreen.withValues(alpha: 0.08)
                  : WellxColors.textPrimary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pets,
                  size: 12,
                  color: _allDone
                      ? WellxColors.scoreGreen
                      : WellxColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _allDone
                        ? 'All done! $_totalCoins coins = $_totalCoins meals for shelter dogs'
                        : 'Complete all = $_totalCoins coins = $_totalCoins meals for shelter dogs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          _allDone ? FontWeight.w600 : FontWeight.w500,
                      color: _allDone
                          ? WellxColors.scoreGreen
                          : WellxColors.textSecondary,
                    ),
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
// Task Row
// ---------------------------------------------------------------------------

class _TaskRow extends StatelessWidget {
  final DailyTask task;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: task.isToggleable ? onToggle : onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // Timeline connector + checkbox
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 10,
                    color: isCompleted
                        ? WellxColors.scoreGreen.withValues(alpha: 0.3)
                        : WellxColors.textPrimary.withValues(alpha: 0.08),
                  )
                else
                  const SizedBox(height: 10),
                if (isCompleted)
                  const Icon(Icons.check_circle,
                      size: 22, color: WellxColors.scoreGreen)
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WellxColors.textTertiary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(task.icon,
                        size: 10, color: WellxColors.textTertiary),
                  ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 10,
                    color: isCompleted
                        ? WellxColors.scoreGreen.withValues(alpha: 0.3)
                        : WellxColors.textPrimary.withValues(alpha: 0.08),
                  )
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: WellxTypography.chipText.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? WellxColors.textTertiary
                        : WellxColors.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.subtitle.isNotEmpty)
                  Text(
                    task.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: WellxColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Coin reward
          if (task.coinReward > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${task.coinReward}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? WellxColors.textTertiary
                        : WellxColors.amberWatch,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.star,
                  size: 7,
                  color: isCompleted
                      ? WellxColors.textTertiary
                      : WellxColors.amberWatch,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
