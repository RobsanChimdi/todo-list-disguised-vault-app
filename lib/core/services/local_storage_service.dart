// lib/core/services/local_storage_service.dart

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

  // ================= GENERIC METHODS (for AuthController) =================

  /// Generic write data to settings box
  Future<void> writeData(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Generic read data from settings box
  Future<dynamic> readData(String key) async {
    return _settingsBox.get(key);
  }

  /// Generic delete data from settings box
  Future<void> deleteData(String key) async {
    await _settingsBox.delete(key);
  }

  /// Clear all data from all boxes
  Future<void> clearAll() async {
    await _notesBox.clear();
    await _settingsBox.clear();
    await _vaultBox.clear();
  }

  // ================= NOTES =================

  /// Save or update a note
  Future<void> saveNote(Map<String, dynamic> noteData) async {
    await _notesBox.put(noteData['id'], noteData);
  }

  /// Get all notes
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    return _notesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get single note by ID
  Future<Map<String, dynamic>?> getNote(String id) async {
    final data = _notesBox.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Delete note by ID
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  /// Clear all notes
  Future<void> clearAllNotes() async {
    await _notesBox.clear();
  }

  // ================= SETTINGS =================

  /// Save setting to settings box
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get setting from settings box
  dynamic getSetting(String key) {
    return _settingsBox.get(key);
  }

  // ================= VAULT =================

  /// Save vault item
  Future<void> saveVaultItem(Map<String, dynamic> itemData) async {
    await _vaultBox.put(itemData['id'], itemData);
  }

  /// Get all vault items
  List<Map<String, dynamic>> getAllVaultItems() {
    return _vaultBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get single vault item by ID
  Future<Map<String, dynamic>?> getVaultItem(String id) async {
    final data = _vaultBox.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Delete vault item by ID
  Future<void> deleteVaultItem(String id) async {
    await _vaultBox.delete(id);
  }

  /// Clear all vault items
  Future<void> clearVault() async {
    await _vaultBox.clear();
  }

  // ================= GENERIC BOX METHODS (for repositories) =================

  /// Generic save method for any box
  Future<void> save<T>(String boxName, T value, {String? id}) async {
    final key = id ?? (value as dynamic).id;
    switch (boxName) {
      case 'notes_box':
        await _notesBox.put(key, value);
        break;
      case 'settings_box':
        await _settingsBox.put(key, value);
        break;
      case 'vault_box':
        await _vaultBox.put(key, value);
        break;
    }
  }

  /// Generic get by ID for any box
  Future<dynamic> getById(String boxName, String id) async {
    switch (boxName) {
      case 'notes_box':
        return _notesBox.get(id);
      case 'settings_box':
        return _settingsBox.get(id);
      case 'vault_box':
        return _vaultBox.get(id);
      default:
        return null;
    }
  }

  /// Generic get all for any box
  Future<List<dynamic>> getAll(String boxName) async {
    switch (boxName) {
      case 'notes_box':
        return _notesBox.values.toList();
      case 'settings_box':
        return _settingsBox.values.toList();
      case 'vault_box':
        return _vaultBox.values.toList();
      default:
        return [];
    }
  }

  /// Generic update for any box
  Future<void> update<T>(String boxName, T value, {String? id}) async {
    await save(boxName, value, id: id);
  }

  /// Generic delete for any box
  Future<void> delete(String boxName, String id) async {
    switch (boxName) {
      case 'notes_box':
        await _notesBox.delete(id);
        break;
      case 'settings_box':
        await _settingsBox.delete(id);
        break;
      case 'vault_box':
        await _vaultBox.delete(id);
        break;
    }
  }

  // ================= CLEANUP =================

  Future<void> dispose() async {
    await Hive.close();
  }
}
