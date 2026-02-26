import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alert_state.dart';
import '../widgets/device_banner.dart';
import '../services/device_service.dart';

class AlertScreen extends StatefulWidget {
  final String deviceId;

  const AlertScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  List<Map<String, dynamic>> alerts = [];
  bool loading = true;
  Timer? timer;


 @override
void initState() {
  super.initState();

  _initialize();
}

Future<void> _initialize() async {
  await fetchAlerts();

  timer = Timer.periodic(
    const Duration(seconds: 5),
    (_) => fetchAlerts(),
  );

  await DeviceService.fetchDeviceLocation(
    deviceId: widget.deviceId,
  );
}

@override
void dispose() {
  timer?.cancel();
  super.dispose();
}

// ================= FETCH ALERTS =================
Future<void> fetchAlerts() async {
  if (!mounted) return;

  try {
    final data = await DeviceService.fetchLatestAlerts(widget.deviceId);

    if (!mounted) return;

    setState(() {
      alerts = data;
      loading = false;
    });

    AlertState.markAllSeen(widget.deviceId, alerts);
  } catch (e) {
    if (!mounted) return;
    setState(() => loading = false);
  }
}

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        titleSpacing: 0, 
        iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: const Text(
          "Alerts",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueAccent), //color: Colors.blueAccent
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          DeviceBanner(deviceId: widget.deviceId),
          Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchAlerts,
                      child: alerts.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: alerts.length,
                              itemBuilder: (_, i) =>
                                  _alertCard(alerts[i]),
                            ),
                    ),
          ),
        ],  
      ),
    );
  }

  // ================= EMPTY =================
  Widget _emptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.notifications_off,
            size: 60, color: Colors.grey),
        SizedBox(height: 12),
        Center(
          child: Text(
            "No alerts available",
            style:
                TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ================= ALERT CARD =================
  Widget _alertCard(Map<String, dynamic> a) {
  final severity = (a['severity'] ?? 'info').toString().toLowerCase();

  late Color color;
  late IconData icon;
  late String label;

  switch (severity) {
    case 'critical':
      color = Colors.red;
      icon = Icons.warning_rounded;
      label = 'CRITICAL';
      break;
    case 'warning':
      color = Colors.orange;
      icon = Icons.error_outline_rounded;
      label = 'WARNING';
      break;
    default:
      color = Colors.blue;
      icon = Icons.info_outline_rounded;
      label = 'INFO';
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6FAFF), // very light blue
              Color(0xFFF6FFFB), // soft white (center feel)
              Color(0xFFE8FFF1), // light mint green
            ],
          ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLOR STRIP
        Container(
          width: 5,
          height: 96,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 ICON WITH SOFT BACKGROUND (LIKE IMAGE)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),

                    const SizedBox(width: 10),

                    // TEXT (FLEXIBLE)
                    Expanded(
                      child: Text(
                        a['msg']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // SEVERITY CHIP (NO OVERFLOW)
                    Container(
                      constraints: const BoxConstraints(minWidth: 62),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // TIME ROW
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a['event_time']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


}
