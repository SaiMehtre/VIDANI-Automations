import 'package:flutter/material.dart';

class DeviceState {
  static final Map<String, ValueNotifier<String?>> _locations = {};

  static ValueNotifier<String?> locationOf(String deviceId) {
    return _locations.putIfAbsent(
      deviceId,
      () => ValueNotifier<String?>(null),
    );
  }

  static void setLocation(String deviceId, String? location) {
    locationOf(deviceId).value = location;
  }
}
