import 'package:flutter/material.dart';

class InAppAlertNotifier {

  static void show(
    BuildContext context, {
    required String message,
    required String severity,
  }) {

    Color bgColor = Colors.blue;
    IconData icon = Icons.info_outline;

    switch (severity.toLowerCase()) {
      case "critical":
        bgColor = Colors.red;
        icon = Icons.warning_rounded;
        break;

      case "warning":
        bgColor = Colors.orange;
        icon = Icons.error_outline;
        break;

      default:
        bgColor = Colors.blue;
        icon = Icons.info_outline;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bgColor,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}