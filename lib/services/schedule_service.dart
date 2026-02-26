import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleService {
  static Future<List<Map<String, dynamic>>> fetchLiveSchedule({
    required String deviceId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://phmc.smart-iot.in/api/api/device/$deviceId/schedule',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch schedule");
    }

    final decoded = jsonDecode(response.body);

    // EXPECTED BACKEND FORMAT:
    // { "slots": [ {slot, enabled, mode, start, stop, days, retry} ] }

    return List<Map<String, dynamic>>.from(decoded["slots"]);
  }
}
