// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';

// class PushNotificationService {

//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

//   static final FlutterLocalNotificationsPlugin _local =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {

//      if (kIsWeb) return;

//     // Permission (Android 13+)
//     await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');

//     const settings = InitializationSettings(
//       android: android,
//     );

//     await _local.initialize(
//       settings: settings,
//     );

//     // Foreground message
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {

//       debugPrint("Push received: ${message.notification?.title}");

//       if (message.notification != null) {
//         showLocalNotification(
//           message.notification!.title ?? "Device Alert",
//           message.notification!.body ?? "",
//         );
//       }

//     });

//     // Print FCM Token
//     final token = await _messaging.getToken();

//     debugPrint("FCM TOKEN: $token");
//   }

//   static Future<void> showLocalNotification(
//     String title,
//     String body,
//   ) async {

//     const androidDetails = AndroidNotificationDetails(
//       'device_alert_channel',
//       'Device Alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const details = NotificationDetails(
//       android: androidDetails,
//     );

//     await _local.show(
//       id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title: title,
//       body: body,
//       notificationDetails: details,
//     );
//   }
// }