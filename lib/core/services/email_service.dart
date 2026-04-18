// core/services/email_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // Replace with your actual API endpoint
  final String _apiEndpoint = 'https://your-api.com/send-reset-email';

  Future<bool> sendPinResetEmail(String email, String token) async {
    try {
      // Option 1: Using your own backend API
      // final response = await http.post(
      //   Uri.parse(_apiEndpoint),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
      //     'token': token,
      //     'type': 'pin_reset',
      //   }),
      // );
      // return response.statusCode == 200;

      // Option 2: For development/testing - just log and return true
      print('========================================');
      print('PIN RESET EMAIL');
      print('To: $email');
      print('Reset Token: $token');
      print('Reset Link: yourapp://reset-pin?email=$email&token=$token');
      print('========================================');

      // Option 3: Using Firebase Cloud Functions
      // final response = await FirebaseFunctions.instance
      //     .httpsCallable('sendPinResetEmail')
      //     .call({
      //       'email': email,
      //       'token': token,
      //     });
      // return response.data['success'] == true;

      // For demo purposes, return true
      return true;
    } catch (e) {
      print('Email service error: $e');
      return false;
    }
  }

  // Optional: Send PIN reset success email
  Future<bool> sendPinResetSuccessEmail(String email) async {
    try {
      print('PIN reset successful for: $email');
      return true;
    } catch (e) {
      print('Error sending success email: $e');
      return false;
    }
  }
}
