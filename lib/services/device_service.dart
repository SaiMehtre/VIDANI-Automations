import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_config.dart'; 

class DeviceService {

  static Future<List<dynamic>> fetchDevices() async {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/devices",  // ✅ FIXED
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      "Failed to load devices | ${res.statusCode} | ${res.body}",
    );
  }

  static Future<Map<String, dynamic>> fetchLive(String id) async {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$id/live", // ✅ FIXED
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception(
      "Failed to load live data | ${res.statusCode} | ${res.body}",
    );
  }

  static Future<List<Map<String, dynamic>>> fetchLatestAlerts(
      String deviceId) async {
    try {
      final res = await ApiClient.get(
        "${ApiConfig.baseUrl}/api/device/$deviceId/alerts/latest",
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String?> fetchDeviceLocation({
    required String deviceId,
  }) async {
    try {
      final res = await ApiClient.get(
        "${ApiConfig.baseUrl}/api/device/$deviceId/location", // ✅ FIXED
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded["location"]?.toString();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchInsightsLive(
    String deviceId) async {
  try {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$deviceId/live",
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  } catch (e) {
    return null;
  }
}

static Future<Map<String, dynamic>?> fetchTodayPerformance(
    String deviceId) async {
  try {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$deviceId/today",
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  } catch (e) {
    return null;
  }
}

static Future<List<dynamic>> fetchHourlyEnergy(
    String deviceId,
    String from,
    String to,
  ) async {
  try {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$deviceId/energy/hourly?from=$from&to=$to",
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  } catch (e) {
    return [];
  }
}

static Future<Map<String, dynamic>?> fetchDeviceLive(
    String deviceId) async {
  try {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$deviceId/live",
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  } catch (e) {
    return null;
  }
}

static Future<void> sendPumpCommand(
    String deviceId,
    bool value,
  ) async {
  try {
    await ApiClient.post(
      "${ApiConfig.baseUrl}/api/device/$deviceId/command",
      body: {
        "cmd": "control",
        "value": value ? 1 : 0,
      },
    );
  } catch (_) {}
}

// ================= SCHEDULE =================

static Future<List<dynamic>> fetchScheduleSlots(
    String deviceId) async {
  try {
    final res = await ApiClient.get(
      "${ApiConfig.baseUrl}/api/device/$deviceId/schedule-slots",
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  } catch (_) {
    return [];
  }
}

static Future<void> sendScheduleCommand(
  String deviceId,
  Map<String, dynamic> body,
) async {
  try {
    await ApiClient.post(
      "${ApiConfig.baseUrl}/api/device/$deviceId/command",
      body: body,
    );
  } catch (_) {}
}

static Future<void> syncScheduleFromDevice(
    String deviceId) async {
  try {
    await ApiClient.post(
      "${ApiConfig.baseUrl}/api/device/$deviceId/command",
      body: {
        "cmd": "GET_SCH_CONFIG",
      },
    );
  } catch (_) {}
}

}