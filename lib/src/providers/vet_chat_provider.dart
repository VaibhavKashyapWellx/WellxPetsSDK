import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/health_models.dart';
import '../services/claude_proxy_service.dart';
import '../services/pet_health_context.dart';
import '../services/supabase_client.dart';
import '../services/vet_system_prompt.dart';
import 'auth_provider.dart';
import 'health_provider.dart';
import 'pet_provider.dart';
import 'sdk_providers.dart';

// ---------------------------------------------------------------------------
// Chat Message
// ---------------------------------------------------------------------------

@immutable
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  /// Local file path of an attached image (user messages only).
  final String? imagePath;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.imagePath,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toSupabaseJson({
    required String petId,
    required String userId,
  }) =>
      {
        'id': id,
        'pet_id': petId,
        'user_id': userId,
        'role': role,
        'content': content,
        'image_url': imagePath,
        'created_at': timestamp.toUtc().toIso8601String(),
      };

  static ChatMessage fromSupabaseJson(Map<String, dynamic> json) =>
      ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['created_at'] as String),
        imagePath: json['image_url'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Chat State
// ---------------------------------------------------------------------------

@immutable
class VetChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingHistory;
  final String? errorMessage;
  final bool hasMoreHistory;

  const VetChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.errorMessage,
    this.hasMoreHistory = false,
  });

  VetChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingHistory,
    String? errorMessage,
    bool? hasMoreHistory,
  }) {
    return VetChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: errorMessage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }
}

// ---------------------------------------------------------------------------
// Vet Chat Notifier
// ---------------------------------------------------------------------------

class VetChatNotifier extends StateNotifier<VetChatState> {
  final ClaudeProxyService _claudeService;
  // Ref is used to lazily read health data at message-send time so that
  // watching those async providers doesn't cause the notifier to rebuild
  // (which would wipe the chat history every time Supabase data arrives).
  final Ref _ref;

  static const _uuid = Uuid();
  static const _pageSize = 50;

  /// Rate limiting: minimum interval between outbound messages (2 seconds).
  static const _minMessageInterval = Duration(seconds: 2);
  DateTime? _lastMessageSentAt;

  VetChatNotifier({
    required ClaudeProxyService claudeService,
    required Ref ref,
  })  : _claudeService = claudeService,
        _ref = ref,
        super(const VetChatState());

  // ── History persistence ───────────────────────────────────────────────────

  /// Load the most recent [_pageSize] messages for [petId] from Supabase.
  Future<void> loadHistory(String petId) async {
    if (state.isLoadingHistory) return;
    state = state.copyWith(isLoadingHistory: true, errorMessage: null);
    try {
      final rows = await SupabaseManager.instance.client
          .from('chat_messages')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final messages = (rows as List)
          .map((r) =>
              ChatMessage.fromSupabaseJson(r as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        hasMoreHistory: messages.length >= _pageSize,
      );
    } catch (e, st) {
      debugPrint('[WellxPetsSDK] loadHistory failed: $e\n$st');
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  /// Load an additional page of older messages (prepend to list).
  Future<void> loadMoreHistory(String petId) async {
    if (state.isLoadingHistory || state.messages.isEmpty) return;
    state = state.copyWith(isLoadingHistory: true);
    try {
      final oldest = state.messages.first.timestamp.toUtc().toIso8601String();
      final rows = await SupabaseManager.instance.client
          .from('chat_messages')
          .select()
          .eq('pet_id', petId)
          .lt('created_at', oldest)
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final older = (rows as List)
          .map((r) =>
              ChatMessage.fromSupabaseJson(r as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingHistory: false,
        hasMoreHistory: older.length >= _pageSize,
      );
    } catch (e, st) {
      debugPrint('[WellxPetsSDK] loadMoreHistory failed: $e\n$st');
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  Future<void> _persistMessage(ChatMessage msg, String petId) async {
    final auth = _ref.read(authStateProvider);
    final userId = auth.userId;
    if (userId == null) return;
    try {
      await SupabaseManager.instance.client
          .from('chat_messages')
          .insert(msg.toSupabaseJson(petId: petId, userId: userId));
    } catch (e, st) {
      debugPrint('[WellxPetsSDK] _persistMessage failed: $e\n$st');
    }
  }

  // ── System prompt ─────────────────────────────────────────────────────────

  /// Build the system prompt by reading health data at call time.
  String get _systemPrompt {
    final pet = _ref.read(selectedPetProvider);
    if (pet == null) {
      return VetSystemPrompt.build(petContext: 'No pet selected.');
    }
    final biomarkers = _ref.read(biomarkersProvider(pet.id)).valueOrNull ?? [];
    final medications =
        _ref.read(medicationsProvider(pet.id)).valueOrNull ?? [];
    final healthAlerts =
        _ref.read(healthAlertsProvider(pet.id)).valueOrNull ?? [];
    final medicalRecords =
        _ref.read(medicalRecordsProvider(pet.id)).valueOrNull ?? [];
    final walkSessions =
        _ref.read(walkSessionsProvider(pet.id)).valueOrNull ?? [];
    final documents =
        _ref.read(documentsProvider(pet.id)).valueOrNull ?? [];
    final context = PetHealthContext.build(
      pet: pet,
      biomarkers: biomarkers,
      medications: medications,
      healthAlerts: healthAlerts,
      medicalRecords: medicalRecords,
      walkSessions: walkSessions,
      documents: documents,
    );
    return VetSystemPrompt.build(petContext: context);
  }

  /// Build the messages list in Anthropic API format from chat history.
  List<Map<String, dynamic>> get _conversationHistory {
    return state.messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
  }

  // ── Send message ──────────────────────────────────────────────────────────

  /// Send a user message and get a response from Dr. Layla.
  /// Optionally attach an image [imageFile] which is sent via vision API.
  Future<void> sendMessage(String text, {File? imageFile}) async {
    // Rate limit: enforce minimum interval between messages.
    final now = DateTime.now();
    if (_lastMessageSentAt != null &&
        now.difference(_lastMessageSentAt!) < _minMessageInterval) {
      return;
    }

    final hasImage = imageFile != null;
    final messageText = text.trim().isEmpty && hasImage
        ? 'What do you see in this image?'
        : text.trim();
    if (messageText.isEmpty) return;

    _lastMessageSentAt = now;

    final petId = _ref.read(selectedPetProvider)?.id;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: messageText,
      timestamp: now,
      imagePath: imageFile?.path,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    // Persist user message to Supabase (non-blocking)
    if (petId != null) unawaited(_persistMessage(userMsg, petId));

    try {
      final history = _conversationHistory;
      String reply;
      if (hasImage) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        reply = await _claudeService.sendMessageWithVision(
          messages: history,
          imageBase64: base64Image,
          systemPrompt: _systemPrompt,
        );
      } else {
        reply = await _claudeService.sendMessage(
          messages: history,
          systemPrompt: _systemPrompt,
        );
      }

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );

      // Persist assistant reply to Supabase (non-blocking)
      if (petId != null) unawaited(_persistMessage(assistantMsg, petId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Dr. Layla couldn\'t respond. Please try again.',
      );
    }
  }

  /// Retry the last failed message.
  void retryLast() {
    if (state.messages.isEmpty) return;
    final last = state.messages.last;
    if (last.role == 'user') {
      // Remove the last user message and re-send
      final msgs = List<ChatMessage>.from(state.messages)..removeLast();
      state = state.copyWith(messages: msgs, errorMessage: null);
      sendMessage(last.content);
    }
  }

  /// Clear all messages (in-memory only; does not delete from Supabase).
  void clearChat() {
    state = const VetChatState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provider for the ClaudeProxyService, constructed from SDK config.
final claudeProxyServiceProvider = Provider<ClaudeProxyService>((ref) {
  final config = ref.watch(configProvider);
  return ClaudeProxyService(config);
});

/// Provider for the vet chat notifier.
/// Only rebuilds when the Claude service or selected pet ID changes — health
/// data is read lazily at message-send time to avoid wiping chat history when
/// Supabase queries resolve.
final vetChatProvider =
    StateNotifierProvider<VetChatNotifier, VetChatState>((ref) {
  final claudeService = ref.watch(claudeProxyServiceProvider);
  // Watch only the pet ID so switching pets resets the chat, but loading
  // health data (biomarkers, meds, etc.) does NOT reset the conversation.
  final petId = ref.watch(selectedPetIdProvider);

  final notifier = VetChatNotifier(
    claudeService: claudeService,
    ref: ref,
  );

  // Load history from Supabase whenever the selected pet changes.
  if (petId != null) {
    Future.microtask(() => notifier.loadHistory(petId));
  }

  return notifier;
});
