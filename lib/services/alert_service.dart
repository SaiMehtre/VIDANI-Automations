import '../models/alert_model.dart';

class AlertService {
  static final List<AlertModel> _alerts = [];

  static List<AlertModel> get alerts => _alerts;

  static void add(AlertModel alert) {
    _alerts.insert(0, alert);
  }

  static int unreadCount() {
    return _alerts.where((a) => !a.read).length;
  }

  static void markAllRead() {
    for (var a in _alerts) {
      a.read = true;
    }
  }
}
