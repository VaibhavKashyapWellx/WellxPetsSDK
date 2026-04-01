import 'package:flutter/foundation.dart';

import 'claude_proxy_service.dart';

// ---------------------------------------------------------------------------
// OCR Service — uses Claude Vision to extract medical data from documents
// ---------------------------------------------------------------------------

/// Result of an OCR document analysis.
@immutable
class DocumentAnalysisResult {
  final String? title;
  final String? date;
  final String? clinic;
  final List<String> diagnoses;
  final List<String> medications;
  final String? notes;
  final String rawText;

  const DocumentAnalysisResult({
    this.title,
    this.date,
    this.clinic,
    this.diagnoses = const [],
    this.medications = const [],
    this.notes,
    this.rawText = '',
  });

  /// Whether any meaningful data was extracted.
  bool get hasData =>
      title != null ||
      date != null ||
      clinic != null ||
      diagnoses.isNotEmpty ||
      medications.isNotEmpty ||
      notes != null;

  factory DocumentAnalysisResult.fromClaudeResponse(String response) {
    // Parse the structured response from Claude
    String? title;
    String? date;
    String? clinic;
    final diagnoses = <String>[];
    final medications = <String>[];
    String? notes;

    final lines = response.split('\n');
    String? currentSection;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Detect section headers
      final lowerTrimmed = trimmed.toLowerCase();
      if (lowerTrimmed.startsWith('title:') ||
          lowerTrimmed.startsWith('document title:')) {
        title = trimmed.split(':').skip(1).join(':').trim();
        currentSection = null;
      } else if (lowerTrimmed.startsWith('date:') ||
          lowerTrimmed.startsWith('document date:')) {
        date = trimmed.split(':').skip(1).join(':').trim();
        currentSection = null;
      } else if (lowerTrimmed.startsWith('clinic:') ||
          lowerTrimmed.startsWith('veterinary clinic:') ||
          lowerTrimmed.startsWith('hospital:')) {
        clinic = trimmed.split(':').skip(1).join(':').trim();
        currentSection = null;
      } else if (lowerTrimmed.contains('diagnos')) {
        currentSection = 'diagnoses';
        // Check if diagnosis is on same line
        final afterColon = trimmed.split(':').skip(1).join(':').trim();
        if (afterColon.isNotEmpty && !afterColon.startsWith('-')) {
          diagnoses.add(afterColon);
        }
      } else if (lowerTrimmed.contains('medication') ||
          lowerTrimmed.contains('prescription')) {
        currentSection = 'medications';
        final afterColon = trimmed.split(':').skip(1).join(':').trim();
        if (afterColon.isNotEmpty && !afterColon.startsWith('-')) {
          medications.add(afterColon);
        }
      } else if (lowerTrimmed.startsWith('notes:') ||
          lowerTrimmed.startsWith('additional notes:')) {
        currentSection = 'notes';
        final afterColon = trimmed.split(':').skip(1).join(':').trim();
        if (afterColon.isNotEmpty) notes = afterColon;
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        final item = trimmed.substring(1).trim();
        if (currentSection == 'diagnoses') {
          diagnoses.add(item);
        } else if (currentSection == 'medications') {
          medications.add(item);
        }
      } else if (currentSection == 'notes') {
        notes = (notes ?? '') + ' $trimmed';
      }
    }

    return DocumentAnalysisResult(
      title: title,
      date: date,
      clinic: clinic,
      diagnoses: diagnoses,
      medications: medications,
      notes: notes?.trim(),
      rawText: response,
    );
  }
}

/// Service for OCR document analysis using Claude Vision.
class OcrService {
  final ClaudeProxyService _claudeService;

  OcrService(this._claudeService);

  /// Analyze a document image and extract medical data.
  ///
  /// [imageBase64] is the base64-encoded image data.
  /// [petName] is used for context in the analysis prompt.
  Future<DocumentAnalysisResult> analyzeDocument({
    required String imageBase64,
    required String petName,
    String mediaType = 'image/jpeg',
  }) async {
    const systemPrompt = '''
You are an expert veterinary document OCR system. You extract structured medical information from veterinary documents (lab reports, vet visit summaries, prescriptions, vaccination records, etc.).

Analyze the provided document image and extract the following information in this EXACT format:

Title: [document title or type]
Date: [date of document in YYYY-MM-DD format if possible]
Clinic: [veterinary clinic or hospital name]

Diagnoses:
- [diagnosis 1]
- [diagnosis 2]

Medications:
- [medication 1 with dosage if available]
- [medication 2 with dosage if available]

Notes: [any additional important observations, test results, or recommendations]

Rules:
- If a field is not present in the document, omit it entirely
- For blood work / lab results, list abnormal values in the Notes section
- Extract exact values with units for lab results
- Be precise and don't invent data that isn't in the image
- If the document is not a medical/veterinary document, state that clearly
''';

    final messages = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content':
            'Please analyze this veterinary document for $petName and extract the medical information.',
      },
    ];

    final response = await _claudeService.sendMessageWithVision(
      messages: messages,
      imageBase64: imageBase64,
      systemPrompt: systemPrompt,
      mediaType: mediaType,
    );

    return DocumentAnalysisResult.fromClaudeResponse(response);
  }
}
