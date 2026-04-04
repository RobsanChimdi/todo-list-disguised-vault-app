// lib/core/services/local_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  // Box names
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';
  static const String vaultBox = 'vault_box';
  static const String vaultItemsBox =
      'vault_items'; // For type-safe vault items

  late Box _notesBox;
  late Box _settingsBox;
  late Box _vaultBox;
  late Box _vaultItemsBox;

  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  // ================= INIT =================
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters if needed
    // Hive.registerAdapter(VaultItemModelAdapter());

    _notesBox = await Hive.openBox(notesBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _vaultBox = await Hive.openBox(vaultBox);
    _vaultItemsBox = await Hive.openBox(vaultItemsBox);
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
    await _vaultItemsBox.clear();
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

  // ================= VAULT (Map-based) =================

  /// Save vault item as Map
  Future<void> saveVaultItem(Map<String, dynamic> itemData) async {
    await _vaultBox.put(itemData['id'], itemData);
  }

  /// Get all vault items as Maps
  List<Map<String, dynamic>> getAllVaultItems() {
    return _vaultBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Get single vault item by ID as Map
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

  // ================= TYPE-SAFE VAULT METHODS (for VaultRepository) =================

  /// Save typed vault item model
  Future<void> saveVaultItemModel<T>(T item) async {
    try {
      final id = _getIdFromValue(item);
      await _vaultItemsBox.put(id, item);
    } catch (e) {
      print('Error saving vault item model: $e');
      rethrow;
    }
  }

  /// Get all typed vault items
  Future<List<T>> getAllVaultItemModels<T>() async {
    try {
      return _vaultItemsBox.values.whereType<T>().toList();
    } catch (e) {
      print('Error getting vault item models: $e');
      return [];
    }
  }

  /// Get typed vault item by ID
  Future<T?> getVaultItemModelById<T>(String id) async {
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

  /// Delete typed vault item by ID
  Future<void> deleteVaultItemModel(String id) async {
    try {
      await _vaultItemsBox.delete(id);
    } catch (e) {
      print('Error deleting vault item model: $e');
      rethrow;
    }
  }

  /// Clear all typed vault items
  Future<void> clearAllVaultItemModels() async {
    await _vaultItemsBox.clear();
  }

  // ================= GENERIC BOX METHODS (for repositories) =================

  /// Generic save method for any box (returns typed)
  Future<void> saveTyped<T>(String boxName, T value, {String? id}) async {
    final key = id ?? _getIdFromValue(value);
    final box = _getTypedBox(boxName);
    await box.put(key, value);
  }

  /// Generic get by ID for any box (returns typed)
  Future<T?> getTypedById<T>(String boxName, String id) async {
    final box = _getTypedBox(boxName);
    final value = box.get(id);
    if (value != null && value is T) {
      return value;
    }
    return null;
  }

  /// Generic get all for any box (returns typed list)
  Future<List<T>> getAllTyped<T>(String boxName) async {
    final box = _getTypedBox(boxName);
    return box.values.whereType<T>().toList();
  }

  /// Generic update for any box
  Future<void> updateTyped<T>(String boxName, T value, {String? id}) async {
    await saveTyped(boxName, value, id: id);
  }

  /// Generic delete for any box
  Future<void> deleteTyped(String boxName, String id) async {
    final box = _getTypedBox(boxName);
    await box.delete(id);
  }

  /// Get the appropriate Hive box for typed operations
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

  /// Extract ID from value
  String _getIdFromValue(dynamic value) {
    try {
      // Check for id property via toJson or direct access
      if (value is Map) {
        return value['id'] as String;
      } else if (value is HiveObject) {
        return value.key.toString();
      } else {
        // Try to call toJson() or access id property
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

  // ================= GENERIC METHODS (legacy support) =================

  /// Generic save method for any box (legacy - returns dynamic)
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
      case 'vault_items':
        await _vaultItemsBox.put(key, value);
        break;
      default:
        throw Exception('Unknown box: $boxName');
    }
  }

  /// Generic get by ID for any box (legacy - returns dynamic)
  Future<dynamic> getById(String boxName, String id) async {
    switch (boxName) {
      case 'notes_box':
        return _notesBox.get(id);
      case 'settings_box':
        return _settingsBox.get(id);
      case 'vault_box':
        return _vaultBox.get(id);
      case 'vault_items':
        return _vaultItemsBox.get(id);
      default:
        return null;
    }
  }

  /// Generic get all for any box (legacy - returns List<dynamic>)
  Future<List<dynamic>> getAll(String boxName) async {
    switch (boxName) {
      case 'notes_box':
        return _notesBox.values.toList();
      case 'settings_box':
        return _settingsBox.values.toList();
      case 'vault_box':
        return _vaultBox.values.toList();
      case 'vault_items':
        return _vaultItemsBox.values.toList();
      default:
        return [];
    }
  }

  /// Generic update for any box (legacy)
  Future<void> update<T>(String boxName, T value, {String? id}) async {
    await save(boxName, value, id: id);
  }

  /// Generic delete for any box (legacy)
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
      case 'vault_items':
        await _vaultItemsBox.delete(id);
        break;
    }
  }

  // ================= CLEANUP =================

  Future<void> dispose() async {
    await Hive.close();
  }
}
