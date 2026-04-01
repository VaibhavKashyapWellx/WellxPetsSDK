import 'package:flutter/material.dart';

/// Presentation style for navigation destinations.
enum PresentationStyle { tab, sheet, fullScreen }

/// All navigable destinations in the SDK.
///
/// Maps 1:1 to FureverApp's AppDestination enum.
enum AppDestination {
  // Tab-based
  home(tabIndex: 0, icon: Icons.home_rounded, label: 'Home'),
  reports(tabIndex: 1, icon: Icons.description_outlined, label: 'Reports'),
  vetChat(tabIndex: 2, icon: Icons.favorite_rounded, label: 'Layla'),
  track(tabIndex: 3, icon: Icons.crop_free_rounded, label: 'Check'),
  wallet(tabIndex: 4, icon: Icons.inbox_rounded, label: 'Records'),

  // Sheet-based
  medications(icon: Icons.medication_rounded, label: 'Medications'),
  scoreBreakdown(icon: Icons.analytics_rounded, label: 'Score'),
  venues(icon: Icons.place_rounded, label: 'Venues'),
  addPet(icon: Icons.add_rounded, label: 'Add Pet'),
  travel(icon: Icons.flight_rounded, label: 'Travel'),
  symptomLogger(icon: Icons.edit_note_rounded, label: 'Symptoms'),
  healthTimeline(icon: Icons.timeline_rounded, label: 'Timeline'),

  // Full-screen
  bcsCheck(icon: Icons.camera_alt_rounded, label: 'Body Check'),
  wellnessCheck(icon: Icons.checklist_rounded, label: 'Wellness'),
  urineCheck(icon: Icons.science_rounded, label: 'Urine'),
  ;

  final int? tabIndex;
  final IconData icon;
  final String label;

  const AppDestination({
    this.tabIndex,
    required this.icon,
    required this.label,
  });

  PresentationStyle get presentationStyle {
    if (tabIndex != null) return PresentationStyle.tab;
    switch (this) {
      case AppDestination.bcsCheck:
      case AppDestination.wellnessCheck:
      case AppDestination.urineCheck:
        return PresentationStyle.fullScreen;
      default:
        return PresentationStyle.sheet;
    }
  }
}
