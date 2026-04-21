// lib/core/services/email_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EmailService {
  final String apiKey = 'YOUR_API_KEY';
  final String emailServiceUrl = 'https://api.your-email-service.com/send';

  // For development/testing - set to true to use mock emails
  final bool useMockEmails = true; // Set to false in production

  // Send verification code for email verification
  Future<bool> sendVerificationCode(String email, String code) async {
    try {
      final subject = 'Email Verification Code';
      final body = _buildVerificationEmailBody(code);

      if (useMockEmails) {
        // For development: print to console
        print('=== EMAIL VERIFICATION ===');
        print('To: $email');
        print('Subject: $subject');
        print('Body: $body');
        print('Verification Code: $code');
        print('===========================');

        // In development, you can also show a dialog with the code
        // This is helpful for testing without a real email service
        _showMockEmailDialog(email, code, 'Verification');
        return true;
      }

      // For production: implement actual email sending
      final sent = await _sendEmail(email, subject, body);
      return sent;
    } catch (e) {
      print('Error sending verification code: $e');
      return false;
    }
  }

  // Send PIN reset code
  Future<bool> sendPinResetCode(String email, String resetCode) async {
    try {
      final subject = 'PIN Reset Code';
      final body = _buildResetEmailBody(resetCode);

      if (useMockEmails) {
        // For development: print to console
        print('=== PIN RESET ===');
        print('To: $email');
        print('Subject: $subject');
        print('Body: $body');
        print('Reset Code: $resetCode');
        print('=================');

        // In development, you can also show a dialog with the code
        _showMockEmailDialog(email, resetCode, 'Reset');
        return true;
      }

      // For production: implement actual email sending
      final sent = await _sendEmail(email, subject, body);
      return sent;
    } catch (e) {
      print('Error sending reset code: $e');
      return false;
    }
  }

  // Generic email sending method
  Future<bool> _sendEmail(String to, String subject, String body) async {
    try {
      // Example using SendGrid API
      // Replace with your actual email service provider

      /*
      final response = await http.post(
        Uri.parse(emailServiceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'to': to,
          'subject': subject,
          'body': body,
          'from': 'noreply@yourapp.com',
        }),
      );
      
      return response.statusCode == 200;
      */

      // For now, return true if using mock emails
      // In production, implement actual API call
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // Build verification email body
  String _buildVerificationEmailBody(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background-color: #4CAF50;
          color: white;
          padding: 20px;
          text-align: center;
          border-radius: 5px 5px 0 0;
        }
        .content {
          background-color: #f9f9f9;
          padding: 30px;
          border-radius: 0 0 5px 5px;
        }
        .code {
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          background-color: #e8f5e9;
          border-radius: 5px;
          margin: 20px 0;
          letter-spacing: 5px;
        }
        .footer {
          text-align: center;
          margin-top: 20px;
          font-size: 12px;
          color: #666;
        }
        .warning {
          color: #ff9800;
          font-size: 12px;
          margin-top: 20px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>Email Verification</h2>
        </div>
        <div class="content">
          <p>Hello,</p>
          <p>Thank you for signing up! Please use the verification code below to complete your email verification:</p>
          
          <div class="code">
            $code
          </div>
          
          <p>This code will expire in <strong>5 minutes</strong>.</p>
          
          <p>If you didn't request this verification, please ignore this email.</p>
          
          <div class="warning">
            <strong>⚠️ Security Note:</strong> Never share this code with anyone. Our support team will never ask for this code.
          </div>
        </div>
        <div class="footer">
          <p>This is an automated message, please do not reply to this email.</p>
          <p>&copy; ${DateTime.now().year} Your App Name. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Build reset email body
  String _buildResetEmailBody(String resetCode) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          background-color: #ff9800;
          color: white;
          padding: 20px;
          text-align: center;
          border-radius: 5px 5px 0 0;
        }
        .content {
          background-color: #f9f9f9;
          padding: 30px;
          border-radius: 0 0 5px 5px;
        }
        .code {
          font-size: 32px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          background-color: #fff3e0;
          border-radius: 5px;
          margin: 20px 0;
          letter-spacing: 5px;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background-color: #ff9800;
          color: white;
          text-decoration: none;
          border-radius: 5px;
          margin: 20px 0;
        }
        .footer {
          text-align: center;
          margin-top: 20px;
          font-size: 12px;
          color: #666;
        }
        .warning {
          background-color: #ffebee;
          color: #c62828;
          padding: 15px;
          border-radius: 5px;
          margin-top: 20px;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>PIN Reset Request</h2>
        </div>
        <div class="content">
          <p>Hello,</p>
          <p>We received a request to reset your PIN for your secure vault account. Use the reset code below:</p>
          
          <div class="code">
            $resetCode
          </div>
          
          <p>This code will expire in <strong>1 hour</strong>.</p>
          
          <div class="warning">
            <strong>⚠️ Security Alert:</strong> If you didn't request this PIN reset, please ignore this email. 
            Your account remains secure.
          </div>
          
          <p>For security reasons, never share this code with anyone.</p>
        </div>
        <div class="footer">
          <p>This is an automated message, please do not reply to this email.</p>
          <p>&copy; ${DateTime.now().year} Your App Name. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Helper method to show mock email dialog during development
  void _showMockEmailDialog(String email, String code, String type) {
    // This is only for development
    // In production, you should use a real email service
    Future.delayed(const Duration(milliseconds: 100), () {
      // Use GetX dialog or Flutter dialog
      // You can implement this if needed
      print('Mock email sent to $email with code: $code');
    });
  }

  // Method to test email configuration
  Future<bool> testEmailConfiguration() async {
    try {
      // Test your email service configuration here
      // Return true if configuration is valid
      return true;
    } catch (e) {
      print('Email configuration test failed: $e');
      return false;
    }
  }

  // Method to send a test email
  Future<bool> sendTestEmail(String to) async {
    try {
      final subject = 'Test Email';
      final body = '''
      <html>
        <body>
          <h1>Test Email</h1>
          <p>This is a test email to verify your email service configuration.</p>
          <p>If you're receiving this, your email service is working correctly!</p>
        </body>
      </html>
      ''';

      return await _sendEmail(to, subject, body);
    } catch (e) {
      print('Error sending test email: $e');
      return false;
    }
  }
}
