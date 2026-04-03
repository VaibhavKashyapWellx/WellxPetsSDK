import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ---------------------------------------------------------------------------
// Cache Service
// ---------------------------------------------------------------------------
// Provides local data caching using Hive so the SDK can display data when
// the device is offline.  All cached data is stored as JSON strings.
//
// Usage:
//   await CacheService.initialize();  // call once in SDK init
//   await CacheService.instance.putPets(ownerId, pets);
//   final pets = CacheService.instance.getPets(ownerId);

const _kPetsBox = 'wellx_pets';
const _kHealthBox = 'wellx_health';
const _kChatBox = 'wellx_chat';
const _kMiscBox = 'wellx_misc';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance {
    assert(_instance != null, 'CacheService.initialize() must be called first');
    return _instance!;
  }

  late final Box<String> _petsBox;
  late final Box<String> _healthBox;
  late final Box<String> _chatBox;
  late final Box<String> _miscBox;

  CacheService._();

  /// Initialize Hive and open all boxes. Call once during SDK startup.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    final instance = CacheService._();
    instance._petsBox = await Hive.openBox<String>(_kPetsBox);
    instance._healthBox = await Hive.openBox<String>(_kHealthBox);
    instance._chatBox = await Hive.openBox<String>(_kChatBox);
    instance._miscBox = await Hive.openBox<String>(_kMiscBox);
    _instance = instance;
    debugPrint('[CacheService] initialized');
  }

  // ── Pets ─────────────────────────────────────────────────────────────────

  Future<void> putPets(String ownerId, List<Map<String, dynamic>> pets) async {
    await _petsBox.put('pets_$ownerId', jsonEncode(pets));
  }

  List<Map<String, dynamic>>? getPets(String ownerId) {
    final raw = _petsBox.get('pets_$ownerId');
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Health data ───────────────────────────────────────────────────────────

  Future<void> putBiomarkers(
      String petId, List<Map<String, dynamic>> data) async {
    await _healthBox.put('biomarkers_$petId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? getBiomarkers(String petId) =>
      _decodeList(_healthBox.get('biomarkers_$petId'));

  Future<void> putMedications(
      String petId, List<Map<String, dynamic>> data) async {
    await _healthBox.put('medications_$petId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? getMedications(String petId) =>
      _decodeList(_healthBox.get('medications_$petId'));

  Future<void> putDocuments(
      String petId, List<Map<String, dynamic>> data) async {
    await _healthBox.put('documents_$petId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? getDocuments(String petId) =>
      _decodeList(_healthBox.get('documents_$petId'));

  Future<void> putMedicalRecords(
      String petId, List<Map<String, dynamic>> data) async {
    await _healthBox.put('medical_records_$petId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? getMedicalRecords(String petId) =>
      _decodeList(_healthBox.get('medical_records_$petId'));

  // ── Chat history ──────────────────────────────────────────────────────────

  Future<void> putChatMessages(
      String petId, List<Map<String, dynamic>> messages) async {
    await _chatBox.put('chat_$petId', jsonEncode(messages));
  }

  List<Map<String, dynamic>>? getChatMessages(String petId) =>
      _decodeList(_chatBox.get('chat_$petId'));

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<void> put(String key, dynamic value) async {
    await _miscBox.put(key, jsonEncode(value));
  }

  T? get<T>(String key) {
    final raw = _miscBox.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as T?;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _petsBox.clear();
    await _healthBox.clear();
    await _chatBox.clear();
    await _miscBox.clear();
  }

  Future<void> clearPet(String petId) async {
    await _healthBox.delete('biomarkers_$petId');
    await _healthBox.delete('medications_$petId');
    await _healthBox.delete('documents_$petId');
    await _healthBox.delete('medical_records_$petId');
    await _chatBox.delete('chat_$petId');
  }

  // ── Private ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>>? _decodeList(String? raw) {
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
