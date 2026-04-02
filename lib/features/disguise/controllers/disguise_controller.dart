// lib/features/disguise/controllers/disguise_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/disguise_service.dart';
import '../services/secret_note_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../notebook/presentation/controllers/note_controller.dart';
import '../../notebook/data/models/note_model.dart';

class DisguiseController extends GetxController {
  final DisguiseService _disguiseService = DisguiseService();

  final RxBool isDisguiseMode = false.obs;
  final RxString fakeErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkDisguiseMode();
  }

  Future<void> _checkDisguiseMode() async {
    isDisguiseMode.value = await _disguiseService.isDisguiseMode();
  }

  void showFakeError() {
    fakeErrorMessage.value = 'Feature not available in free version';
    Get.snackbar(
      'Upgrade Required',
      fakeErrorMessage.value,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> addDecoyNotes() async {
    if (!isDisguiseMode.value) return;

    final decoyNotes = [
      'Meeting tomorrow at 3 PM',
      'Buy groceries: milk, eggs, bread',
      'Call dentist for appointment',
    ];

    final noteController = Get.find<NoteController>();
    if (noteController.notes.isEmpty) {
      for (var title in decoyNotes) {
        await noteController.addNote(
          Note.create(title: title, content: 'This is a sample note.'),
        );
      }
    }
  }
}
