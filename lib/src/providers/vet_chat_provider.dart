import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/health_models.dart';
import '../services/claude_proxy_service.dart';
import '../services/pet_health_context.dart';
import '../services/vet_system_prompt.dart';
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
}

// ---------------------------------------------------------------------------
// Chat State
// ---------------------------------------------------------------------------

@immutable
class VetChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const VetChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VetChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VetChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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

  VetChatNotifier({
    required ClaudeProxyService claudeService,
    required Ref ref,
  })  : _claudeService = claudeService,
        _ref = ref,
        super(const VetChatState());

  /// Build the system prompt by reading health data at call time.
  String get _systemPrompt {
    final pet = _ref.read(selectedPetProvider);
    if (pet == null) {
      return VetSystemPrompt.build(petContext: 'No pet selected.');
    }
    final biomarkers = _ref.read(biomarkersProvider(pet.id)).valueOrNull ?? [];
    final medications = _ref.read(medicationsProvider(pet.id)).valueOrNull ?? [];
    final healthAlerts = _ref.read(healthAlertsProvider(pet.id)).valueOrNull ?? [];
    final medicalRecords = _ref.read(medicalRecordsProvider(pet.id)).valueOrNull ?? [];
    final walkSessions = _ref.read(walkSessionsProvider(pet.id)).valueOrNull ?? [];
    final documents = _ref.read(documentsProvider(pet.id)).valueOrNull ?? [];
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

  /// Send a user message and get a response from Dr. Layla.
  /// Optionally attach an image [imageFile] which is sent via vision API.
  Future<void> sendMessage(String text, {File? imageFile}) async {
    final hasImage = imageFile != null;
    final messageText = text.trim().isEmpty && hasImage
        ? 'What do you see in this image?'
        : text.trim();
    if (messageText.isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: messageText,
      timestamp: DateTime.now(),
      imagePath: imageFile?.path,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

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

  /// Clear all messages.
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
  ref.watch(selectedPetIdProvider);

  return VetChatNotifier(
    claudeService: claudeService,
    ref: ref,
  );
});
