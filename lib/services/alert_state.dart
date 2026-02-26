import 'package:flutter/foundation.dart';

class AlertState {
  ///  unread count per device
  static final Map<String, ValueNotifier<int>> _unread = {};

  ///  badge animation trigger
  static final Map<String, ValueNotifier<bool>> _animate = {};

  ///  already seen alert IDs (per device)
  static final Map<String, Set<String>> _seenIds = {};

  /// cache last computed unread (optional but useful)
  static final Map<String, int> _lastUnread = {};

  static final Set<String> _initialized = {};


  // -------------------------------
  // PUBLIC NOTIFIERS
  // -------------------------------

  static ValueNotifier<int> unreadOf(String deviceId) {
    return _unread.putIfAbsent(deviceId, () => ValueNotifier<int>(0));
  }

  static ValueNotifier<bool> animateOf(String deviceId) {
    return _animate.putIfAbsent(deviceId, () => ValueNotifier<bool>(false));
  }

  // -------------------------------
  // SERVER UPDATE
  // -------------------------------

  // static void updateFromServer(
  //   String deviceId,
  //   List<dynamic> alerts,
  // ) {
  //   if (alerts.isEmpty) return;

  //   final seen = _seenIds.putIfAbsent(deviceId, () => <String>{});

  //   int unread = 0;

  //   for (final a in alerts) {
  //     final id = a['id']?.toString();
  //     if (id == null) continue;

  //     if (!seen.contains(id)) {
  //       unread++;
  //     }
  //   }

  //   final prevUnread = _lastUnread[deviceId] ?? 0;

  //   //  new unread arrived → animate badge
  //   if (unread > prevUnread) {
  //     _animate[deviceId]?.value = true;

  //     Future.delayed(const Duration(milliseconds: 400), () {
  //       _animate[deviceId]?.value = false;
  //     });
  //   }

  //   _lastUnread[deviceId] = unread;
  //   _unread[deviceId]?.value = unread;
  // }


  static void updateFromServer(
  String deviceId,
  List<dynamic> alerts,
) {
  if (alerts.isEmpty) return;

  final seen = _seenIds.putIfAbsent(deviceId, () => <String>{});

  int unread = 0;

  for (final a in alerts) {
    final id = a['id']?.toString();
    if (id == null) continue;

    if (!seen.contains(id)) {
      unread++;
    }
  }

  //  FIRST LOAD → BASELINE ONLY
  if (!_initialized.contains(deviceId)) {
    _initialized.add(deviceId);
    _lastUnread[deviceId] = unread;
    _unread[deviceId]?.value = unread;
    return; //  NO ANIMATION, NO NOTIFICATION
  }

  final prevUnread = _lastUnread[deviceId] ?? 0;

  //  ONLY REAL NEW ALERTS
  if (unread > prevUnread) {
    _animate[deviceId]?.value = true;

    Future.delayed(const Duration(milliseconds: 400), () {
      _animate[deviceId]?.value = false;
    });
  }

  _lastUnread[deviceId] = unread;
  _unread[deviceId]?.value = unread;
}


  // -------------------------------
  // ALERT SCREEN OPEN
  // -------------------------------

  static void markAllSeen(
    String deviceId,
    List<dynamic> alerts,
  ) {
    final seen = _seenIds.putIfAbsent(deviceId, () => <String>{});

    for (final a in alerts) {
      final id = a['id']?.toString();
      if (id != null) {
        seen.add(id);
      }
    }

    _lastUnread[deviceId] = 0;
    _unread[deviceId]?.value = 0;
  }
}
