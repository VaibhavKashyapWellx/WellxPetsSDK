import 'dart:convert';

import 'package:http/http.dart' as http;

import '../sdk/wellx_pets_config.dart';

// ---------------------------------------------------------------------------
// Claude Proxy Service
// ---------------------------------------------------------------------------
// Makes HTTP calls to the Anthropic Messages API.
// Ported from FureverApp's ClaudeProxyService.swift.

class ClaudeProxyService {
  final WellxPetsConfig _config;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _anthropicVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 60);

  ClaudeProxyService(this._config);

  // ── Headers ──────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _config.anthropicApiKey,
        'anthropic-version': _anthropicVersion,
      };

  // ── Send text message ────────────────────────────────────────────────────

  /// Send a list of [messages] with an optional [systemPrompt] and return
  /// the assistant's text reply.
  ///
  /// [messages] should be a list of `{role: 'user'|'assistant', content: ...}`
  /// maps following the Anthropic Messages API format.
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
        .post(
          Uri.parse(_endpoint),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return _extractText(response);
  }

  // ── Send message with image (vision) ─────────────────────────────────────

  /// Send a message that includes a base64-encoded image for Claude's vision
  /// capabilities (e.g., OCR, photo analysis).
  Future<String> sendMessageWithVision({
    required List<Map<String, dynamic>> messages,
    required String imageBase64,
    String? systemPrompt,
    String mediaType = 'image/jpeg',
    int maxTokens = 4096,
  }) async {
    // Build the last user message to include the image block
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

    // If the last message is from the user, append image to its content
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
      enrichedMessages.add({
        'role': 'user',
        'content': userContent,
      });
    }

    final body = <String, dynamic>{
      'model': _config.claudeModel,
      'max_tokens': maxTokens,
      'messages': enrichedMessages,
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return _extractText(response);
  }

  // ── Raw call & JSON extraction ───────────────────────────────────────────

  /// Low-level call that returns the raw JSON-decoded response body.
  Future<Map<String, dynamic>> callRaw(Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw ClaudeProxyException(
        'API error (${response.statusCode}): ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Call Claude and return the text, stripping markdown code fences if
  /// present (useful when asking for JSON output).
  Future<String> callAndExtractCleanJson(Map<String, dynamic> body) async {
    final raw = await callRaw(body);
    var text = _textFromBody(raw);

    // Strip markdown fences
    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  String _extractText(http.Response response) {
    if (response.statusCode != 200) {
      throw ClaudeProxyException(
        'API error (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _textFromBody(decoded);
  }

  String _textFromBody(Map<String, dynamic> body) {
    final content = body['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw const ClaudeProxyException('No content in AI response');
    }
    final textBlock = content.firstWhere(
      (block) => (block as Map<String, dynamic>)['type'] == 'text',
      orElse: () => throw const ClaudeProxyException(
        'No text block in AI response',
      ),
    ) as Map<String, dynamic>;
    return textBlock['text'] as String;
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class ClaudeProxyException implements Exception {
  final String message;
  const ClaudeProxyException(this.message);

  @override
  String toString() => 'ClaudeProxyException: $message';
}
