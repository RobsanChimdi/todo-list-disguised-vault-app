// lib/features/disguise/services/disguise_service.dart

import 'package:get/get.dart';
import '../../../core/services/local_storage_service.dart';

class DisguiseService extends GetxService {
  final LocalStorageService _storage = LocalStorageService();

  Future<bool> isDisguiseMode() async {
    final isActive = await _storage.getSetting('disguise_active');
    return isActive == true;
  }

  Future<void> setDisguiseMode(bool active) async {
    await _storage.saveSetting('disguise_active', active);
  }

  Future<void> activateDisguise() async {
    await setDisguiseMode(true);
  }

  Future<void> deactivateDisguise() async {
    await setDisguiseMode(false);
  }
}
