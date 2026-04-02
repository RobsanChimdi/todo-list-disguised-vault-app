// lib/core/services/app_icon_service.dart

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppIconService extends GetxService {
  // Change app icon dynamically (Android only, iOS requires special setup)
  static const MethodChannel _channel = MethodChannel('app_icon');

  Future<void> changeToDisguiseIcon() async {
    try {
      await _channel.invokeMethod('changeIcon', {'icon': 'disguise'});
    } catch (e) {
      print('Error changing icon: $e');
    }
  }

  Future<void> changeToNormalIcon() async {
    try {
      await _channel.invokeMethod('changeIcon', {'icon': 'normal'});
    } catch (e) {
      print('Error changing icon: $e');
    }
  }
}
