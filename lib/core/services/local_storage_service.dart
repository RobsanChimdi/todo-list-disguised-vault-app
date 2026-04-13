// lib/core/services/local_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/vault/data/models/vault_item_model.dart';

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
  final Map<String, Box> _typedBoxes = {};

  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  // ================= INIT =================
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Register adapters BEFORE opening any boxes
      _registerAdapters();

      // Open boxes
      _notesBox = await Hive.openBox(notesBox);
      _settingsBox = await Hive.openBox(settingsBox);
      _vaultBox = await Hive.openBox(vaultBox);
      _vaultItemsBox = await Hive.openBox(vaultItemsBox);

      // Store in typed boxes map
      _typedBoxes[notesBox] = _notesBox;
      _typedBoxes[settingsBox] = _settingsBox;
      _typedBoxes[vaultBox] = _vaultBox;
      _typedBoxes[vaultItemsBox] = _vaultItemsBox;

      _isInitialized = true;
      print('✅ LocalStorageService initialized successfully');
      print('📦 Opened boxes: ${_typedBoxes.keys}');
    } catch (e) {
      print('❌ Failed to initialize LocalStorageService: $e');
      rethrow;
    }
  }

  void _registerAdapters() {
    // Register VaultItemModel adapter if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VaultItemModelAdapter());
      print('✅ Registered VaultItemModelAdapter (typeId: 1)');
    }
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

  Future<dynamic> getSetting(String key) async {
    await _ensureInitialized();
    return _settingsBox.get(key);
  }

  Future<void> deleteSetting(String key) async {
    await _ensureInitialized();
    await _settingsBox.delete(key);
  }

  // ================= VAULT (Map-based) =================

  Future<void> saveVaultItem(Map<String, dynamic> itemData) async {
    await _ensureInitialized();
    if (!itemData.containsKey('id')) {
      throw Exception('Vault item must have an id field');
    }
    await _vaultBox.put(itemData['id'], itemData);
  }

  Future<List<Map<String, dynamic>>> getAllVaultItems() async {
    await _ensureInitialized();
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

  /// Save a typed object to a box
  Future<void> saveTyped<T>(String boxName, T item) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      final id = _getIdFromItem(item);

      if (id == null) {
        throw Exception('Cannot get ID from item of type ${T.runtimeType}');
      }

      await box.put(id, item);
      print('✅ Saved typed item with id: $id to box: $boxName');
    } catch (e) {
      print('❌ Error saving typed item to $boxName: $e');
      rethrow;
    }
  }

  /// Get a typed object by ID
  Future<T?> getTypedById<T>(String boxName, String id) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      final value = box.get(id);

      if (value != null && value is T) {
        return value;
      }
      return null;
    } catch (e) {
      print('❌ Error getting typed item from $boxName: $e');
      return null;
    }
  }

  /// Get all typed objects from a box
  Future<List<T>> getAllTyped<T>(String boxName) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      final List<T> results = [];

      for (final value in box.values) {
        if (value is T) {
          results.add(value);
        }
      }

      return results;
    } catch (e) {
      print('❌ Error getting all typed items from $boxName: $e');
      return [];
    }
  }

  /// Update a typed object
  Future<void> updateTyped<T>(String boxName, T item) async {
    await saveTyped(boxName, item);
  }

  /// Delete a typed object by ID
  Future<void> deleteTyped(String boxName, String id) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      await box.delete(id);
      print('✅ Deleted typed item with id: $id from box: $boxName');
    } catch (e) {
      print('❌ Error deleting typed item from $boxName: $e');
      rethrow;
    }
  }

  /// Check if a typed object exists
  Future<bool> existsTyped(String boxName, String id) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      return box.containsKey(id);
    } catch (e) {
      print('❌ Error checking typed item existence: $e');
      return false;
    }
  }

  /// Get count of items in a box
  Future<int> countTyped(String boxName) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      return box.length;
    } catch (e) {
      print('❌ Error getting count from $boxName: $e');
      return 0;
    }
  }

  /// Clear all items from a typed box
  Future<void> clearTyped(String boxName) async {
    await _ensureInitialized();

    try {
      final box = await _getOrCreateBox(boxName);
      await box.clear();
      print('✅ Cleared all items from box: $boxName');
    } catch (e) {
      print('❌ Error clearing box $boxName: $e');
      rethrow;
    }
  }

  // ================= HELPER METHODS =================

  /// Get or create a box (supports dynamic box names)
  Future<Box> _getOrCreateBox(String boxName) async {
    // Check if box already exists in cache
    if (_typedBoxes.containsKey(boxName)) {
      return _typedBoxes[boxName]!;
    }

    // Try to open existing box or create new one
    try {
      final box = await Hive.openBox(boxName);
      _typedBoxes[boxName] = box;
      return box;
    } catch (e) {
      print('❌ Failed to open box $boxName: $e');
      rethrow;
    }
  }

  /// Extract ID from various item types
  String? _getIdFromItem(dynamic item) {
    try {
      // Case 1: Item has an 'id' property (Map)
      if (item is Map && item.containsKey('id')) {
        return item['id'].toString();
      }

      // Case 2: Item has an 'id' getter (Model with id property)
      try {
        // Use reflection-like approach to get id
        final id = item.id;
        if (id != null) {
          return id.toString();
        }
      } catch (e) {
        // No .id property
      }

      // Case 3: Item has a 'key' property (HiveObject)
      try {
        final key = item.key;
        if (key != null) {
          return key.toString();
        }
      } catch (e) {
        // No .key property
      }

      // Case 4: Try to convert to JSON and get id
      try {
        final json = (item as dynamic).toJson();
        if (json is Map && json.containsKey('id')) {
          return json['id'].toString();
        }
      } catch (e) {
        // No toJson method
      }

      // Fallback: generate ID
      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      print('⚠️ Failed to extract ID from item: $e');
      return null;
    }
  }

  // ================= BOX MANAGEMENT =================

  /// Get a specific box (for advanced operations)
  Future<Box> getBox(String boxName) async {
    await _ensureInitialized();
    return await _getOrCreateBox(boxName);
  }

  /// Check if a box exists
  Future<bool> boxExists(String boxName) async {
    await _ensureInitialized();
    return Hive.isBoxOpen(boxName) || await Hive.boxExists(boxName);
  }

  /// Delete an entire box
  Future<void> deleteBox(String boxName) async {
    await _ensureInitialized();

    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.close();
      }

      await Hive.deleteBoxFromDisk(boxName);
      _typedBoxes.remove(boxName);
      print('✅ Deleted box: $boxName');
    } catch (e) {
      print('❌ Error deleting box $boxName: $e');
      rethrow;
    }
  }

  /// Close all boxes
  Future<void> closeAllBoxes() async {
    await _ensureInitialized();

    for (final box in _typedBoxes.values) {
      await box.close();
    }

    _typedBoxes.clear();
    print('✅ All boxes closed');
  }

  /// Reset all storage (clears all data)
  Future<void> resetAllStorage() async {
    try {
      print('⚠️ Resetting all storage...');

      // Close all open boxes
      await closeAllBoxes();

      // Delete all boxes from disk
      await Hive.deleteBoxFromDisk(notesBox);
      await Hive.deleteBoxFromDisk(settingsBox);
      await Hive.deleteBoxFromDisk(vaultBox);
      await Hive.deleteBoxFromDisk(vaultItemsBox);

      // Clear cache
      _typedBoxes.clear();
      _isInitialized = false;

      print('✅ All storage reset successfully');

      // Reinitialize
      await init();
    } catch (e) {
      print('❌ Failed to reset storage: $e');
      rethrow;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();

    final stats = <String, dynamic>{};

    for (final entry in _typedBoxes.entries) {
      stats[entry.key] = {
        'size': entry.value.length,
        'keys': entry.value.keys.toList(),
      };
    }

    return stats;
  }

  // ================= BATCH OPERATIONS =================

  /// Save multiple items in batch
  Future<void> saveBatch<T>(String boxName, List<T> items) async {
    await _ensureInitialized();

    final box = await _getOrCreateBox(boxName);

    try {
      final Map<String, dynamic> batchMap = {};
      for (final item in items) {
        final id =
            _getIdFromItem(item) ??
            DateTime.now().millisecondsSinceEpoch.toString();
        batchMap[id] = item;
      }

      await box.putAll(batchMap);
      print('✅ Saved batch of ${items.length} items to $boxName');
    } catch (e) {
      print('❌ Error saving batch to $boxName: $e');
      rethrow;
    }
  }

  /// Delete multiple items in batch
  Future<void> deleteBatch(String boxName, List<String> ids) async {
    await _ensureInitialized();

    final box = await _getOrCreateBox(boxName);

    try {
      await box.deleteAll(ids);
      print('✅ Deleted batch of ${ids.length} items from $boxName');
    } catch (e) {
      print('❌ Error deleting batch from $boxName: $e');
      rethrow;
    }
  }

  // ================= WATCHERS =================

  /// Listen to changes in a box
  Stream<BoxEvent> watchBox(String boxName) async* {
    await _ensureInitialized();
    final box = await _getOrCreateBox(boxName);
    yield* box.watch();
  }

  Stream<BoxEvent> watchKey(String boxName, String key) async* {
    await _ensureInitialized();
    final box = await _getOrCreateBox(boxName);
    yield* box.watch(key: key);
  }

  Future<void> dispose() async {
    await closeAllBoxes();
    await Hive.close();
    _isInitialized = false;
    print('✅ LocalStorageService disposed');
  }
}
