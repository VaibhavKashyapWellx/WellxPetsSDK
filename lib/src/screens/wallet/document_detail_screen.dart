import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Document detail view: title, date, category, clinic, file preview, notes.
class DocumentDetailScreen extends ConsumerWidget {
  final String docId;

  const DocumentDetailScreen({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Document'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: WellxColors.textPrimary),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: WellxColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: WellxColors.coral),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: WellxColors.coral)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview placeholder
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: WellxColors.inkSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description,
                      size: 48,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: WellxSpacing.md),
                    Text(
                      'Document Preview',
                      style: WellxTypography.captionText.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Title
            Text(
              'Document #$docId',
              style: WellxTypography.heading,
            ),
            const SizedBox(height: WellxSpacing.sm),

            // Metadata rows
            WellxCard(
              child: Column(
                children: [
                  _detailRow(Icons.calendar_today, 'Date', 'Loading...'),
                  const Divider(height: 1, color: WellxColors.border),
                  _detailRow(Icons.category, 'Category', 'Document'),
                  const Divider(height: 1, color: WellxColors.border),
                  _detailRow(Icons.local_hospital, 'Clinic', 'N/A'),
                  const Divider(height: 1, color: WellxColors.border),
                  _detailRow(Icons.insert_drive_file, 'File Type', 'PDF'),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Notes section
            Text(
              'NOTES',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            WellxCard(
              child: Text(
                'No notes available for this document.',
                style: WellxTypography.bodyText.copyWith(
                  color: WellxColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.xxl),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: WellxColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Share',
                            style: WellxTypography.buttonLabel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: WellxColors.flatCardFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WellxColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download,
                            size: 16, color: WellxColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Download',
                          style: WellxTypography.buttonLabel.copyWith(
                            color: WellxColors.textPrimary,
                          ),
                        ),
                      ],
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: WellxColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: WellxTypography.chipText),
          const Spacer(),
          Text(
            value,
            style: WellxTypography.chipText.copyWith(
              color: WellxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // go back
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: WellxColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}
