import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/supabase_client.dart';

// ---------------------------------------------------------------------------
// Analytics Events — mirrors iOS AnalyticsService.swift
// ---------------------------------------------------------------------------

enum AnalyticsEvent {
  // App lifecycle
  appOpen('app_open'),
  appBackground('app_background'),

  // Auth
  signUp('sign_up'),
  signIn('sign_in'),
  signOut('sign_out'),

  // Health checks
  healthCheckStarted('health_check_started'),
  healthCheckCompleted('health_check_completed'),
  scoreRevealed('score_revealed'),

  // Documents
  documentUploaded('document_uploaded'),
  documentViewed('document_viewed'),
  documentScanStarted('document_scan_started'),
  documentScanCompleted('document_scan_completed'),
  documentScanFailed('document_scan_failed'),

  // Screens
  screenViewed('screen_viewed'),

  // Engagement
  coinEarned('coin_earned'),
  coinAllocated('coin_allocated'),
  tabSwitched('tab_switched'),
  dailyTaskCompleted('daily_task_completed'),

  // Pets
  petAdded('pet_added'),
  petEdited('pet_edited'),
  petPhotoUploaded('pet_photo_uploaded'),

  // AI Features
  bcsStarted('bcs_started'),
  bcsCompleted('bcs_completed'),
  bcsFailed('bcs_failed'),
  laylaChatStarted('layla_chat_started'),
  laylaChatMessageSent('layla_chat_message_sent'),
  vetChatPhotoShared('vet_chat_photo_shared'),
  wellnessCheckStarted('wellness_check_started'),
  wellnessCheckCompleted('wellness_check_completed'),
  symptomLogged('symptom_logged'),

  // Venues
  venuesOpened('venues_opened'),
  venueViewed('venue_viewed'),
  venueFavorited('venue_favorited'),
  cityDiscovered('city_discovered'),

  // Travel
  travelOpened('travel_opened'),
  travelDestinationViewed('travel_destination_viewed'),
  travelDocGenerated('travel_doc_generated'),
  travelDocFailed('travel_doc_failed'),

  // Reports
  reportExported('report_exported'),

  // Medications
  medicationAdded('medication_added'),

  // Settings
  settingsOpened('settings_opened'),

  // Onboarding
  onboardingCompleted('onboarding_completed'),

  // Health score
  healthScoreViewed('health_score_viewed'),
  scoreUnlocked('score_unlocked');

  final String rawValue;
  const AnalyticsEvent(this.rawValue);
}

// ---------------------------------------------------------------------------
// Analytics Service — fire-and-forget batch queue, mirrors iOS pattern
// ---------------------------------------------------------------------------

class AnalyticsService {
  static final AnalyticsService shared = AnalyticsService._();

  final List<_QueuedEvent> _queue = [];
  final int _batchSize = 10;
  final Duration _flushInterval = const Duration(seconds: 30);
  Timer? _flushTimer;
  String _sessionId = _generateId();
  String? _ownerId;

  AnalyticsService._() {
    _startFlushTimer();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void track(AnalyticsEvent event, {Map<String, dynamic>? properties}) {
    _enqueue(event.rawValue, properties);
  }

  void trackName(String name, {Map<String, dynamic>? properties}) {
    _enqueue(name, properties);
  }

  void setOwnerId(String? id) {
    _ownerId = id;
  }

  void newSession() {
    _sessionId = _generateId();
  }

  void flush() {
    if (_queue.isEmpty) return;
    final batch = List<_QueuedEvent>.from(_queue);
    _queue.clear();
    _sendBatch(batch);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _enqueue(String eventName, Map<String, dynamic>? properties) {
    final event = _QueuedEvent(
      ownerId: _ownerId,
      eventName: eventName,
      propertiesJson: properties != null ? jsonEncode(properties) : '{}',
      sessionId: _sessionId,
      createdAt: DateTime.now().toIso8601String(),
    );
    _queue.add(event);
    if (_queue.length >= _batchSize) flush();
  }

  void _sendBatch(List<_QueuedEvent> batch) {
    Future.microtask(() async {
      try {
        final client = SupabaseManager.instance.client;
        final rows = batch.map((e) => {
          'owner_id': e.ownerId,
          'event_name': e.eventName,
          'properties': e.propertiesJson,
          'session_id': e.sessionId,
          'created_at': e.createdAt,
        }).toList();
        await client.from('analytics_events').insert(rows);
        debugPrint('[Analytics] Flushed ${batch.length} events');
      } catch (e) {
        debugPrint('[Analytics] Flush failed: $e');
        // Re-queue (cap at 100 to avoid bloat)
        if (_queue.length < 100) {
          _queue.insertAll(0, batch);
        }
      }
    });
  }

  void _startFlushTimer() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  void dispose() {
    flush();
    _flushTimer?.cancel();
  }

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16)}-${(now * 31).toRadixString(16)}';
  }
}

// ---------------------------------------------------------------------------
// Internal queued event model
// ---------------------------------------------------------------------------

class _QueuedEvent {
  final String? ownerId;
  final String eventName;
  final String propertiesJson;
  final String sessionId;
  final String createdAt;

  const _QueuedEvent({
    required this.ownerId,
    required this.eventName,
    required this.propertiesJson,
    required this.sessionId,
    required this.createdAt,
  });
}
