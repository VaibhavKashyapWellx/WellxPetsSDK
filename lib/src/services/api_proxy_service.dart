import 'dart:convert';

import 'package:http/http.dart' as http;

import '../sdk/wellx_pets_config.dart';
import 'supabase_client.dart';

// ---------------------------------------------------------------------------
// API Proxy Service
// ---------------------------------------------------------------------------
// Routes all Anthropic Claude requests through a Supabase Edge Function so
// the API key NEVER leaves server infrastructure.
//
// Usage (when proxyUrl is configured in WellxPetsConfig):
//   POST {proxyUrl}/ai-proxy
//   Authorization: Bearer {supabase_access_token}
//   Body: { model, max_tokens, messages, system? }
//
// If no proxyUrl is configured the service throws an [ApiProxyException] to
// remind the developer to set it up.

class ApiProxyService {
  final WellxPetsConfig _config;

  static const _timeout = Duration(seconds: 60);

  ApiProxyService(this._config);

  // ── Headers ───────────────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final session = SupabaseManager.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Proxy URL ─────────────────────────────────────────────────────────────

  Uri get _proxyEndpoint {
    final base = _config.aiProxyUrl;
    if (base == null || base.isEmpty) {
      throw ApiProxyException(
        'No aiProxyUrl configured in WellxPetsConfig. '
        'Deploy the ai-proxy Supabase Edge Function and pass its URL.',
      );
    }
    return Uri.parse('$base/functions/v1/ai-proxy');
  }

  // ── Send message ──────────────────────────────────────────────────────────

  /// Send a list of [messages] to Claude via the server-side proxy.
  Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    int maxTokens = 4096,
  }) async {
    final body = <String, dynamic>{
      'model': model ?? _config.claudeModel,
      'max_tokens': maxTokens,
      'messages': messages,
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    final response = await http
        .post(_proxyEndpoint, headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);

    return _extractText(response);
  }

  /// Send a message that includes a base64-encoded image.
  Future<String> sendMessageWithVision({
    required List<Map<String, dynamic>> messages,
    required String imageBase64,
    String? systemPrompt,
    String mediaType = 'image/jpeg',
    int maxTokens = 4096,
  }) async {
    final userContent = <Map<String, dynamic>>[
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mediaType,
          'data': imageBase64,
        },
      },
    ];

    final enrichedMessages = List<Map<String, dynamic>>.from(
      messages.map((m) => Map<String, dynamic>.from(m)),
    );

    if (enrichedMessages.isNotEmpty &&
        enrichedMessages.last['role'] == 'user') {
      final lastContent = enrichedMessages.last['content'];
      if (lastContent is String) {
        enrichedMessages.last['content'] = [
          ...userContent,
          {'type': 'text', 'text': lastContent},
        ];
      } else if (lastContent is List) {
        enrichedMessages.last['content'] = [
          ...userContent,
          ...List<Map<String, dynamic>>.from(lastContent),
        ];
      }
    } else {
      enrichedMessages.add({'role': 'user', 'content': userContent});
    }

    return sendMessage(
      messages: enrichedMessages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _extractText(http.Response response) {
    if (response.statusCode == 429) {
      throw const ApiProxyException(
          'Too many requests. Please wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      // Sanitize — never surface raw server error bodies to the user.
      throw ApiProxyException(
          'AI service temporarily unavailable (${response.statusCode}). '
          'Please try again.');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw const ApiProxyException('No content in AI response.');
    }
    final textBlock = content.firstWhere(
      (b) => (b as Map<String, dynamic>)['type'] == 'text',
      orElse: () =>
          throw const ApiProxyException('No text block in AI response.'),
    ) as Map<String, dynamic>;
    return textBlock['text'] as String;
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class ApiProxyException implements Exception {
  final String message;
  const ApiProxyException(this.message);

  @override
  String toString() => message;
}
