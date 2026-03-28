import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  // Box names
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';
  static const String vaultBox = 'vault_box';

  late Box _notesBox;
  late Box _settingsBox;
  late Box _vaultBox;

  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  // ================= INIT =================
  Future<void> init() async {
    await Hive.initFlutter();

    _notesBox = await Hive.openBox(notesBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _vaultBox = await Hive.openBox(vaultBox);
  }

  // ================= NOTES =================

  /// Save or update a note
  Future<void> saveNote(Map<String, dynamic> noteData) async {
    await _notesBox.put(noteData['id'], noteData);
  }

  /// Get all notes
  List<Map<String, dynamic>> getAllNotes() {
    return _notesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get single note
  Map<String, dynamic>? getNote(String id) {
    final data = _notesBox.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Delete note
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  /// Clear all notes
  Future<void> clearAllNotes() async {
    await _notesBox.clear();
  }

  // ================= SETTINGS =================

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key) {
    return _settingsBox.get(key);
  }

  // ================= VAULT =================

  Future<void> saveVaultItem(Map<String, dynamic> itemData) async {
    await _vaultBox.put(itemData['id'], itemData);
  }

  List<Map<String, dynamic>> getAllVaultItems() {
    return _vaultBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> deleteVaultItem(String id) async {
    await _vaultBox.delete(id);
  }

  Future<void> clearVault() async {
    await _vaultBox.clear();
  }

  // ================= CLEANUP =================

  Future<void> dispose() async {
    await Hive.close();
  }
}
