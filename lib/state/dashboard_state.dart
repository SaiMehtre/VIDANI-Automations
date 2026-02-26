import '../services/device_service.dart';
import '../state/device_state.dart'; // 👈 ADD THIS IMPORT

class DashboardState {
  List devices = [];
  Map<String, Map<String, dynamic>> deviceStatus = {};


Future<void> loadDevices() async {
  devices = await DeviceService.fetchDevices();

  for (final d in devices) {
    final id = d['device_id'].toString();
    final location = d['site']; // 👈 API me site aa raha hai

    // 👇 LOCATION SET KARO YAHI
    DeviceState.setLocation(id, location);

    deviceStatus[id] = {
      'online': false,
      'pumpOn': false,
    };
  }
}

  Future<void> loadLive(String id) async {
  final live = await DeviceService.fetchLive(id);

  final updatedAt = live['updated_at']; // <-- check actual key

  DateTime? lastUpdate;

  if (updatedAt != null) {
    lastUpdate = DateTime.tryParse(updatedAt)?.toLocal();
  }

  bool isOnline = false;

  if (lastUpdate != null) {
    final diff = DateTime.now().difference(lastUpdate).inMinutes;
    isOnline = diff <= 2; // 2 min threshold
  }

  deviceStatus[id] = {
    'online': isOnline,
    'pumpOn': live['pump_on'] == 1,
    'phaseOk': live['phase_seq_ok'] == 1,
    'vHealthy': live['vphase_healthy'] == 1,
    'iHealthy': live['iphase_healthy'] == 1,
    'lastUpdate': lastUpdate,
  };
  // print("LIVE DATA => $live");
}
}