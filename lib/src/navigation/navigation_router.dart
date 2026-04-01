import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_tab_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/shelter_directory_screen.dart';
import '../screens/home/shelter_dogs_list_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/vet/vet_chat_screen.dart';
import '../screens/track/track_screen.dart';
import '../screens/track/track_bcs_flow.dart';
import '../screens/track/track_wellness_flow.dart';
import '../screens/track/track_urine_flow.dart';
import '../screens/track/symptom_logger_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/document_detail_screen.dart';
import '../screens/credits/credits_wallet_screen.dart';
import '../screens/credits/earn_coins_screen.dart';
import '../screens/health/health_dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/edit_profile_screen.dart';

/// Global navigation key for the router.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod provider for the GoRouter.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainTabShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportScreen(),
            ),
          ),
          GoRoute(
            path: '/vet',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VetChatScreen(),
            ),
          ),
          GoRoute(
            path: '/track',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TrackScreen(),
            ),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WalletScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell, no tab bar)
      GoRoute(
        path: '/bcs-check',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: TrackBCSFlow(),
        ),
      ),
      GoRoute(
        path: '/wellness-check',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: TrackWellnessFlow(),
        ),
      ),
      GoRoute(
        path: '/urine-check',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: TrackUrineFlow(),
        ),
      ),
      GoRoute(
        path: '/symptom-logger',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: SymptomLoggerScreen(),
        ),
      ),

      // Health dashboard
      GoRoute(
        path: '/health-dashboard/:petId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return MaterialPage(
            fullscreenDialog: true,
            child: HealthDashboardScreen(petId: petId),
          );
        },
      ),

      // Credits wallet
      GoRoute(
        path: '/credits-wallet',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: CreditsWalletScreen(),
        ),
      ),

      // Earn coins
      GoRoute(
        path: '/earn-coins',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: EarnCoinsScreen(),
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: SettingsScreen(),
        ),
      ),

      // Edit profile
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: EditProfileScreen(),
        ),
      ),

      // Document detail
      GoRoute(
        path: '/document-detail/:docId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final docId = state.pathParameters['docId']!;
          return MaterialPage(
            fullscreenDialog: true,
            child: DocumentDetailScreen(docId: docId),
          );
        },
      ),

      // Shelter directory
      GoRoute(
        path: '/shelter-directory',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ShelterDirectoryScreen(),
        ),
      ),

      // Shelter dogs list
      GoRoute(
        path: '/shelter-dogs',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ShelterDogsListScreen(),
        ),
      ),
    ],
  );
});
