class AlertModel {
  final String deviceId;
  final String title;
  final String severity; // info, warning, critical
  final DateTime time;
  bool read;

  AlertModel({
    required this.deviceId,
    required this.title,
    required this.severity,
    required this.time,
    this.read = false,
  });
}
