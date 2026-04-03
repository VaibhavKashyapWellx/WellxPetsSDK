import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'supabase_client.dart';

// ---------------------------------------------------------------------------
// Notification Service
// ---------------------------------------------------------------------------
// Handles local notification scheduling (medication reminders) and
// FCM token registration for push notifications.
//
// SETUP REQUIRED:
//   1. Add google-services.json (Android) and GoogleService-Info.plist (iOS)
//   2. Run: firebase_messaging is initialized in main() before this service
//   3. Import firebase_messaging and call NotificationService.initialize()

// Notification channel IDs
const _kMedChannel = 'medication_reminders';
const _kChatChannel = 'vet_chat_replies';
const _kHealthChannel = 'health_alerts';

/// Manages local notifications and FCM token registration.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initialize local notification channels and request permissions.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly in onboarding
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }

    _initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  /// Request notification permissions (call from onboarding screen).
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final result = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  // ── FCM Token ─────────────────────────────────────────────────────────────

  /// Save the FCM device token to the user's Supabase profile so the server
  /// can send targeted push notifications.
  ///
  /// Call this after firebase_messaging.getToken() resolves.
  Future<void> saveFcmToken(String token, String userId) async {
    try {
      await SupabaseManager.instance.client.from('user_device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');
      debugPrint('[NotificationService] FCM token saved');
    } catch (e) {
      debugPrint('[NotificationService] Failed to save FCM token: $e');
    }
  }

  // ── Medication Reminders ──────────────────────────────────────────────────

  /// Schedule a daily local notification for a medication reminder.
  ///
  /// [id] should be a stable integer derived from the medication record ID
  /// (e.g. `medication.id.hashCode & 0x7FFFFFFF`).
  Future<void> scheduleMedicationReminder({
    required int id,
    required String petName,
    required String medicationName,
    required Time time,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _kMedChannel,
      'Medication Reminders',
      channelDescription: 'Daily reminders to give your pet their medication',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: _kMedChannel,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.periodicallyShowWithDuration(
      id,
      'Time for $petName\'s medication',
      'Give $medicationName now',
      const Duration(hours: 24),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel a scheduled medication reminder.
  Future<void> cancelMedicationReminder(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all pending notifications.
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  // ── Local notification helpers ────────────────────────────────────────────

  /// Show an immediate local notification (e.g. for incoming chat reply).
  Future<void> showChatReply({
    required String senderName,
    required String message,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _kChatChannel,
      'Vet Chat Replies',
      channelDescription: 'Messages from Dr. Layla',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: _kChatChannel,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      senderName,
      message,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Show a health alert notification.
  Future<void> showHealthAlert({
    required String petName,
    required String alertMessage,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _kHealthChannel,
      'Health Alerts',
      channelDescription: 'Important health alerts for your pet',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: _kHealthChannel,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$petName — Health Alert',
      alertMessage,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _createAndroidChannels() async {
    const plugin = AndroidFlutterLocalNotificationsPlugin();
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _kMedChannel,
        'Medication Reminders',
        description: 'Daily reminders to give your pet their medication',
        importance: Importance.high,
      ),
    );
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _kChatChannel,
        'Vet Chat Replies',
        description: 'Messages from Dr. Layla',
        importance: Importance.high,
      ),
    );
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _kHealthChannel,
        'Health Alerts',
        description: 'Important health alerts for your pet',
        importance: Importance.max,
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Deep-link routing based on notification payload
    // The host app should listen to this via a stream and navigate accordingly.
    debugPrint(
        '[NotificationService] Tapped: id=${response.id} payload=${response.payload}');
  }
}
