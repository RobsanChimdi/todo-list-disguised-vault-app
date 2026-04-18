// core/services/user_repository.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Note: BiometricService is hidden to avoid conflict
class UserRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Store user email during setup
  Future<void> saveUserEmail(String email) async {
    await _secureStorage.write(key: 'user_email', value: email);
  }

  Future<String?> getUserEmail() async {
    return await _secureStorage.read(key: 'user_email');
  }

  Future<bool> hasUserEmail() async {
    final email = await getUserEmail();
    return email != null && email.isNotEmpty;
  }

  // Find user by email
  Future<User?> findByEmail(String email) async {
    try {
      final savedEmail = await _secureStorage.read(key: 'user_email');

      // For security, you might want to compare case-insensitively
      if (savedEmail != null &&
          savedEmail.toLowerCase() == email.toLowerCase()) {
        return User(email: savedEmail);
      }

      return null;
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  // Optional: Save user's name or other details
  Future<void> saveUserDetails(String email, {String? name}) async {
    await _secureStorage.write(key: 'user_email', value: email);
    if (name != null) {
      await _secureStorage.write(key: 'user_name', value: name);
    }
  }

  Future<String?> getUserName() async {
    return await _secureStorage.read(key: 'user_name');
  }

  // Clear user data
  Future<void> clearUserData() async {
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_name');
  }
}

class User {
  final String email;
  final String? name;

  User({required this.email, this.name});
}
