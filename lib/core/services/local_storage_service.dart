// lib/core/services/local_storage_service.dart (add initialization flag)

import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  // Box names
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';
  static const String vaultBox = 'vault_box';
  static const String vaultItemsBox = 'vault_items';

  late Box _notesBox;
  late Box _settingsBox;
  late Box _vaultBox;
  late Box _vaultItemsBox;

  bool _isInitialized = false;

  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  // ================= INIT =================
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _notesBox = await Hive.openBox(notesBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _vaultBox = await Hive.openBox(vaultBox);
    _vaultItemsBox = await Hive.openBox(vaultItemsBox);

    _isInitialized = true;
  }

  // Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ================= GENERIC METHODS =================

  Future<void> writeData(String key, dynamic value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  Future<dynamic> readData(String key) async {
    await _ensureInitialized();
    return _settingsBox.get(key);
  }

  Future<void> deleteData(String key) async {
    await _ensureInitialized();
    await _settingsBox.delete(key);
  }

  Future<void> clearAll() async {
    await _ensureInitialized();
    await _notesBox.clear();
    await _settingsBox.clear();
    await _vaultBox.clear();
    await _vaultItemsBox.clear();
  }

  // ================= NOTES =================

  Future<void> saveNote(Map<String, dynamic> noteData) async {
    await _ensureInitialized();
    await _notesBox.put(noteData['id'], noteData);
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    await _ensureInitialized();
    return _notesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> getNote(String id) async {
    await _ensureInitialized();
    final data = _notesBox.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> deleteNote(String id) async {
    await _ensureInitialized();
    await _notesBox.delete(id);
  }

  Future<void> clearAllNotes() async {
    await _ensureInitialized();
    await _notesBox.clear();
  }

  // ================= SETTINGS =================

  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key) {
    return _settingsBox.get(key);
  }

  // ================= VAULT (Map-based) =================

  Future<void> saveVaultItem(Map<String, dynamic> itemData) async {
    await _ensureInitialized();
    await _vaultBox.put(itemData['id'], itemData);
  }

  List<Map<String, dynamic>> getAllVaultItems() {
    return _vaultBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> getVaultItem(String id) async {
    await _ensureInitialized();
    final data = _vaultBox.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> deleteVaultItem(String id) async {
    await _ensureInitialized();
    await _vaultBox.delete(id);
  }

  Future<void> clearVault() async {
    await _ensureInitialized();
    await _vaultBox.clear();
  }

  // ================= TYPE-SAFE VAULT METHODS =================

  Future<void> saveVaultItemModel<T>(T item) async {
    await _ensureInitialized();
    try {
      final id = _getIdFromValue(item);
      await _vaultItemsBox.put(id, item);
    } catch (e) {
      print('Error saving vault item model: $e');
      rethrow;
    }
  }

  Future<List<T>> getAllVaultItemModels<T>() async {
    await _ensureInitialized();
    try {
      return _vaultItemsBox.values.whereType<T>().toList();
    } catch (e) {
      print('Error getting vault item models: $e');
      return [];
    }
  }

  Future<T?> getVaultItemModelById<T>(String id) async {
    await _ensureInitialized();
    try {
      final value = _vaultItemsBox.get(id);
      if (value != null && value is T) {
        return value;
      }
      return null;
    } catch (e) {
      print('Error getting vault item model: $e');
      return null;
    }
  }

  Future<void> deleteVaultItemModel(String id) async {
    await _ensureInitialized();
    try {
      await _vaultItemsBox.delete(id);
    } catch (e) {
      print('Error deleting vault item model: $e');
      rethrow;
    }
  }

  Future<void> clearAllVaultItemModels() async {
    await _ensureInitialized();
    await _vaultItemsBox.clear();
  }

  // ================= GENERIC BOX METHODS =================

  Future<void> saveTyped<T>(String boxName, T value, {String? id}) async {
    await _ensureInitialized();
    final key = id ?? _getIdFromValue(value);
    final box = _getTypedBox(boxName);
    await box.put(key, value);
  }

  Future<T?> getTypedById<T>(String boxName, String id) async {
    await _ensureInitialized();
    final box = _getTypedBox(boxName);
    final value = box.get(id);
    if (value != null && value is T) {
      return value;
    }
    return null;
  }

  Future<List<T>> getAllTyped<T>(String boxName) async {
    await _ensureInitialized();
    final box = _getTypedBox(boxName);
    return box.values.whereType<T>().toList();
  }

  Future<void> updateTyped<T>(String boxName, T value, {String? id}) async {
    await saveTyped(boxName, value, id: id);
  }

  Future<void> deleteTyped(String boxName, String id) async {
    await _ensureInitialized();
    final box = _getTypedBox(boxName);
    await box.delete(id);
  }

  Box _getTypedBox(String boxName) {
    switch (boxName) {
      case 'notes_box':
        return _notesBox;
      case 'settings_box':
        return _settingsBox;
      case 'vault_box':
        return _vaultBox;
      case 'vault_items':
        return _vaultItemsBox;
      default:
        throw Exception('Unknown box: $boxName');
    }
  }

  String _getIdFromValue(dynamic value) {
    try {
      if (value is Map) {
        return value['id'] as String;
      } else if (value is HiveObject) {
        return value.key.toString();
      } else {
        final json = value.toJson();
        if (json is Map && json.containsKey('id')) {
          return json['id'] as String;
        }
      }
      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> dispose() async {
    await Hive.close();
  }
}
