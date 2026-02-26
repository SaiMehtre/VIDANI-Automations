import 'package:flutter/material.dart';
import '../state/device_state.dart';

class DeviceBanner extends StatelessWidget {
  final String deviceId;

  const DeviceBanner({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 24, // 
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // alignment: Alignment.center, // 👈 vertical center
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(16),
        borderRadius: BorderRadius.vertical(
        // top: Radius.circular(20), // Top-left and top-right corners
        bottom: Radius.circular(8), // Bottom-left and bottom-right corners
      ),
        color: Color.fromARGB(255, 241, 175, 205),  
      ),
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.center, // 👈 extra safety
        children: [
          /// LEFT → Device ID
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.memory, // 🔥 change icon if you want
                    size: screenWidth < 360 ? 12 : 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    deviceId,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: screenWidth < 360 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),


          // Expanded(
          //   child: FittedBox(
          //     fit: BoxFit.scaleDown,
          //     alignment: Alignment.centerLeft,
          //     child: Text.rich(
          //       TextSpan(
          //         children: [  
          //               fontSize: screenWidth < 360 ? 8 : 10,
          //               fontWeight: FontWeight.w600,
          //               color: Colors.black87,
          //             ),
          //           ),
          //           TextSpan(
          //             text: deviceId,
          //             style: TextStyle(
          //               fontSize: screenWidth < 360 ? 8 : 10,
          //               fontWeight: FontWeight.w800,
          //               color: Colors.blueAccent,
          //             ),
          //           ),
          //         ],
          //       ),
          //       maxLines: 1,
          //     ),
          //   ),
          // ),


          /// RIGHT → Location (AUTO)
          // Expanded(
          //   child: ValueListenableBuilder<String?>(
          //     valueListenable:
          //         DeviceState.locationOf(deviceId),
          //     builder: (_, location, __) {
          //       return FittedBox(
          //         fit: BoxFit.scaleDown,
          //         alignment: Alignment.centerRight,
          //         child: Text(
          //           location?.isNotEmpty == true
          //               ? location!
          //               : "Loading...",
          //           maxLines: 1,
          //           style: TextStyle(
          //             fontSize: screenWidth < 360 ? 8 : 10,
          //       fontWeight: FontWeight.w800,
          //       color: Colors.blueAccent,
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),

          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: DeviceState.locationOf(deviceId),
              builder: (_, location, __) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: screenWidth < 360 ? 10 : 14,
                        // color: Colors.blue,
                        color: Color(0xFF1E88E5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location?.isNotEmpty == true
                            ? location!
                            : "Loading...",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 8 : 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
