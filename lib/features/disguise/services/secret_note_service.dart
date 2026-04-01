// lib/features/disguise/services/secret_note_service.dart

import 'package:get/get.dart';

class SecretNoteService extends GetxService {
  // List of secret titles that will trigger vault access
  static const List<String> secretTriggers = [
    'My Secret',
    'Secret Vault',
    'Hidden',
    'Private',
    'Confidential',
    'Locked',
    'Secure Notes',
    'Vault Access',
    'Top Secret',
    'Classified',
    'My Private',
    'Hidden Vault',
    'Secret Key',
    'Master Key',
    'Access Code',
    'Pin Code',
    'Vault Key',
  ];

  // Alternative trigger words (if title contains these words)
  static const List<String> triggerKeywords = [
    'secret',
    'vault',
    'hidden',
    'private',
    'secure',
    'confidential',
    'classified',
    'locker',
    'safe',
  ];

  // Check if a note title should trigger vault access
  static bool isSecretTrigger(String title) {
    final trimmedTitle = title.trim();

    // Exact match check
    if (secretTriggers.contains(trimmedTitle)) {
      return true;
    }

    // Contains keyword check (case insensitive)
    final lowerTitle = trimmedTitle.toLowerCase();
    return triggerKeywords.any((keyword) => lowerTitle.contains(keyword));
  }

  // Get a disguised title for secret notes (to avoid suspicion)
  static String getDisguisedTitle(String originalTitle) {
    if (isSecretTrigger(originalTitle)) {
      // Replace with a random mundane title
      final mundaneTitles = [
        'Shopping List',
        'Meeting Notes',
        'To-Do List',
        'Quick Reminder',
        'Daily Tasks',
        'Ideas',
        'Draft',
        'Read Later',
        'Important',
        'Notes',
      ];
      return mundaneTitles[originalTitle.length % mundaneTitles.length];
    }
    return originalTitle;
  }

  // Generate a warning message based on note title
  static String getWarningMessage(String title) {
    if (title.toLowerCase().contains('vault')) {
      return 'This note contains vault access credentials. PIN required.';
    } else if (title.toLowerCase().contains('secret')) {
      return 'This is a secret note. Authentication required.';
    } else if (title.toLowerCase().contains('private')) {
      return 'Private note. Please authenticate to view content.';
    } else {
      return 'This note is locked. Enter PIN to unlock.';
    }
  }
}
