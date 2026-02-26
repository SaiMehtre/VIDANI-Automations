import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'scheduling_screen.dart';
import 'dart:ui';
import 'alert_screen.dart';
import '../services/alert_state.dart';
import 'insights_screen.dart';
import '../widgets/device_banner.dart';
import '../services/device_service.dart';

const double MIN_VOLTAGE = 180;
const double MAX_VOLTAGE = 280;

enum VoltageStatus {
  normal,
  low,
  high,
  lost,
}


final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with RouteAware, TickerProviderStateMixin {
  Timer? timer;

  bool loading = true;
  bool commandInProgress = false;

  // for pop up
  bool isRtcRunning = false;

  double vR = 0, vY = 0, vB = 0;
  double iR = 0, iY = 0, iB = 0;

  bool pumpOn = false;
  bool phaseOk = true;
  bool vHealthy = true;
  bool iHealthy = true;
  bool systemOnline = true;
  late AnimationController _pageAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _needleController;
  late Animation<double> _needleAnim;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // String deviceLocation = "";

  String? deviceLocation;





  @override
  void initState() {
    super.initState();

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _pageAnim,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fadeAnim);

    fetchLive();

    // 🔔 ALERT BADGE FETCH
    fetchAlertsForBadge();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchLive();
      fetchAlertsForBadge();
    });

    _pageAnim.forward();

    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _needleAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _needleController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    fetchDeviceLocation();

    _needleController.forward();

   
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    timer?.cancel();
  }

  @override
  void didPopNext() {
    if (!mounted) return;

    fetchLive();
    fetchAlertsForBadge();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      fetchLive();
      fetchAlertsForBadge();
    });
  }


  @override
  void dispose() {
    timer?.cancel();
    routeObserver.unsubscribe(this);
    _pageAnim.dispose();
    _needleController.dispose();
     _pulseController.dispose();
    super.dispose();
  }

  // ============alert featch ====================
Future<void> fetchAlertsForBadge() async {
  final alerts =
      await DeviceService.fetchLatestAlerts(
          widget.deviceId);

  if (!mounted) return;

  AlertState.updateFromServer(
    widget.deviceId,
    alerts,
  );
}

  // ================= LIVE DATA =================
 Future<void> fetchLive() async {
  final d =
      await DeviceService.fetchDeviceLive(widget.deviceId);

  if (d == null) {
    if (!mounted) return;
    setState(() {
      systemOnline = false;
      loading = false;
    });
    return;
  }

  bool deviceOnline = true;

  if (d['ts'] != null) {
    final lastTs =
        DateTime.tryParse(d['ts'].toString());
    if (lastTs != null) {
      final diffSeconds =
          DateTime.now().toUtc().difference(lastTs).inSeconds;
      if (diffSeconds > 60) deviceOnline = false;
    }
  } else {
    deviceOnline = false;
  }

  if (!mounted) return;

  setState(() {
    systemOnline = deviceOnline;

    vR = double.tryParse(d['vr']?.toString() ?? '') ?? vR;
    vY = double.tryParse(d['vy']?.toString() ?? '') ?? vY;
    vB = double.tryParse(d['vb']?.toString() ?? '') ?? vB;

    iR = double.tryParse(d['ir']?.toString() ?? '') ?? iR;
    iY = double.tryParse(d['iy']?.toString() ?? '') ?? iY;
    iB = double.tryParse(d['ib']?.toString() ?? '') ?? iB;

    phaseOk = d['phase_seq_ok'] == 1;
    vHealthy = d['vphase_healthy'] == 1;
    iHealthy = d['iphase_healthy'] == 1;

    if (!commandInProgress &&
        d['pump_on'] != null) {
      pumpOn = d['pump_on'] == 1;
    }

    isRtcRunning =
        (d['pump_on'] == 1 &&
            d['manual_ovrd'].toString() == '0');

    loading = false;
  });
}

  // ================= PUMP =================
  Future<void> togglePump(bool value) async {
  if (commandInProgress) return;

  setState(() {
    commandInProgress = true;
    pumpOn = value;
  });

  try {
    await DeviceService.sendPumpCommand(
      widget.deviceId,
      value,
    );

    await Future.delayed(
        const Duration(seconds: 3));
  } catch (_) {
    if (!mounted) return;
    setState(() {
      pumpOn = !value;
    });
  } finally {
    if (!mounted) return;
    setState(() {
      commandInProgress = false;
    });
  }
}

Future<void> fetchDeviceLocation() async {
  final location =
      await DeviceService.fetchDeviceLocation(
  deviceId: widget.deviceId,
);

  if (!mounted) return;

  setState(() {
    deviceLocation = location;
  });
}

  


//========Popup text on RTC on=========================


 void _showRtcPopup() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      final w = MediaQuery.of(context).size.width;

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            SizedBox(width: 6),
            Text("Scheduled Operation",style: TextStyle(
            fontSize: w < 360 ? 18 : 20, // responsive
          ),),
          ],
        ),
        content: Text(
          "Pump is currently running via RTC (Timer).\n\n"
          "Manual OFF is not allowed until schedule completes.",

          style: TextStyle(
            fontSize: w < 360 ? 11 : 13, // responsive
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}


  // ================= UI =================
 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF3F7FF),
    appBar: AppBar(
      // leadingWidth: 40,        
      titleSpacing: 0,         
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      elevation: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "VI / IOT PHMC",
          maxLines: 1,
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w800,
            fontSize: 22, // base size
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              tooltip: "alerts",
              icon: const Icon(
                Icons.notifications,
                color: Colors.orangeAccent,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertScreen(
                      deviceId: widget.deviceId,
                    ),
                  ),
                );
              },
            ),

            // unread badge
            // Positioned(
            //   right: 8,
            //   top: 8,
            //   child: ValueListenableBuilder<int>(
            //     valueListenable: AlertState.unreadOf(widget.deviceId),
            //     builder: (_, count, __) {
            //       if (count == 0) return const SizedBox();

            //       return ValueListenableBuilder<bool>(
            //         valueListenable: AlertState.animateOf(widget.deviceId),
            //         builder: (_, animate, __) {
            //           return GestureDetector(
            //             onTap: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (_) => AlertScreen(
            //                     token: widget.token,
            //                     deviceId: widget.deviceId,
            //                   ),
            //                 ),
            //               );
            //             },
            //             child: AnimatedScale(
            //               scale: animate ? 1.4 : 1.0,
            //               duration: const Duration(milliseconds: 200),
            //               curve: Curves.elasticOut,
            //               child: AnimatedContainer(
            //                 duration: const Duration(milliseconds: 200),
            //                 padding: const EdgeInsets.all(2),
            //                 decoration: const BoxDecoration(
            //                   color: Colors.red,
            //                   shape: BoxShape.circle,
            //                 ),
            //                 constraints: const BoxConstraints(
            //                   minWidth: 14,
            //                   minHeight: 14,
            //                 ),
            //                 child: Center(
            //                   child: Text(
            //                     count.toString(),
            //                     style: const TextStyle( 
            //                       fontSize: 8.5,
            //                       color: Colors.white,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ),
            
            Positioned(
              right: 8,
              top: 8,
              child: ValueListenableBuilder<int>(
                valueListenable: AlertState.unreadOf(widget.deviceId),
                builder: (_, count, __) {
                  if (count == 0) return const SizedBox();

                  return ValueListenableBuilder<bool>(
                    valueListenable: AlertState.animateOf(widget.deviceId),
                    builder: (_, animate, __) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlertScreen(
                                deviceId: widget.deviceId,
                              ),
                            ),
                          );
                        },
                        child: AnimatedScale(
                          scale: animate ? 1.4 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                count.toString(),
                                style: const TextStyle( 
                                  fontSize: 8.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // INSIGHTS ICON (MIDDLE)
        IconButton(
          tooltip: "Insights",
          icon: const Icon(
            Icons.insights_rounded,
            color: Colors.greenAccent,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsightsScreen(
                  deviceId: widget.deviceId,
                ),
              ),
            );
          },
        ),

        IconButton(
          tooltip: "Schedulling",
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SchedulingScreen(
                  deviceId: widget.deviceId,
                ),
              ),
            );
          },
        ),
      ],
      
    ),

    
    body:Column(
      children: [ 
        DeviceBanner(deviceId: widget.deviceId),
        Expanded(
          child: loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _topStatusBar(),
                        // const SizedBox(height: 10),
                        _voltageWarningBanner(),
                        const SizedBox(height: 10),
                        _statusCards(),
                        const SizedBox(height: 10),
                        _rybSection(),
                        const SizedBox(height: 10),
                        _rybLedIndicator(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ],
    ),
  );
  
}


  // ================= TOP BAR =================
  Widget _topStatusBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(8),
      height: screenWidth < 400
      ? 105
      : screenWidth < 800
          ? 110
          : 125,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: pumpOn
                  ? Image.asset(
                      "assets/gif/flow.gif",
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF001233),
                            Color(0xFF000814),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          /// Light overlay only when pump is ON (for readability)
          if (pumpOn)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  // color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: Row(
              
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 👈 CENTER EVERYTHING
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// 🔹 Pump Status Icon
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: pumpOn
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                                ),
                                child: Icon(
                                  pumpOn ? Icons.play_circle_fill : Icons.stop_circle,
                                  color: pumpOn ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                              ),

                              const SizedBox(width: 8),

                              /// 🔹 Pump Status Text (Responsive Safe)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Pump Status",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: pumpOn ? Colors.black : Colors.white70,
                                          fontWeight:
                                              pumpOn ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        pumpOn ? "RUNNING" : "STOPPED",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: pumpOn
                                              ? (pumpOn
                                                  ? const Color.fromARGB(255, 3, 165, 63)
                                                  : Colors.greenAccent)
                                              : Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(right: 6), // 👈 adjust value here
                          child: SizedBox(
                            // width: 135,
                            child: Column(
                              
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Chip(
                                //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                //   padding: const EdgeInsets.symmetric(horizontal: 4),
                                //   label: Text(
                                //     pumpOn ? "PUMP ON" : "PUMP OFF",
                                //     maxLines: 1,
                                //     overflow: TextOverflow.ellipsis,
                                //     style: const TextStyle(
                                //       color: Colors.black,
                                //       fontSize: 11,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),
                                //   backgroundColor: pumpOn ? Colors.green : Colors.red,
                                // ),

                                // const SizedBox(height: 1),

                                Transform.scale(
                                  scale: 0.95,
                                  child: Switch(
                                    value: pumpOn,
                                    onChanged: (value) {
                                      if (isRtcRunning && value == false) {
                                        _showRtcPopup();
                                        return;
                                      }
                                      togglePump(value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),           
                      ],
              ),  
            ),    
        ],
      ),    
    );
  }


VoltageStatus _getVoltageStatus(double v) {
  if (!systemOnline || v <= 10) {
    return VoltageStatus.lost;
  }
  if (v < MIN_VOLTAGE) {
    return VoltageStatus.low;
  }
  if (v > MAX_VOLTAGE) {
    return VoltageStatus.high;
  }
  return VoltageStatus.normal;
}

  // ================= LED =================
  Widget _rybLedIndicator() {
  Widget buildLed(String label, Color baseColor, double voltage) {
    final status = _getVoltageStatus(voltage);

    Color ledColor;
    String text;

    switch (status) {
      case VoltageStatus.normal:
        ledColor = baseColor;
        text = "NORMAL";
        break;
      case VoltageStatus.low:
        ledColor = Colors.redAccent;
        text = "LOW";
        break;
      case VoltageStatus.high:
        ledColor = Colors.orangeAccent;
        text = "HIGH";
        break;
      case VoltageStatus.lost:
        ledColor = Colors.grey;
        text = "OFF";
        break;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ledColor,
            boxShadow: status == VoltageStatus.normal
                ? [
                    BoxShadow(
                      color: ledColor.withOpacity(0.6),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: baseColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: ledColor,
          ),
        ),
      ],
    );
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFEAF6FF),
          Color(0xFFFFFFFF),
          Color(0xFFE8FFF5),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildLed("R", Colors.redAccent, vR),
        buildLed("Y", Colors.orangeAccent, vY),
        buildLed("B", Colors.blueAccent, vB),
      ],
    ),
  );
}



Widget _voltageWarningBanner() {
  bool low = vR < MIN_VOLTAGE || vY < MIN_VOLTAGE || vB < MIN_VOLTAGE;
  bool high = vR > MAX_VOLTAGE || vY > MAX_VOLTAGE || vB > MAX_VOLTAGE;

  if (!systemOnline || (!low && !high)) return const SizedBox();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: low ? Colors.redAccent : Colors.orangeAccent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.warning, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            low
                ? "LOW VOLTAGE DETECTED – Pump may trip"
                : "HIGH VOLTAGE DETECTED – Risk to equipment",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _statusCards() {
  final screenWidth = MediaQuery.of(context).size.width;

  // same logic like filter cards
  final scale = (screenWidth / 400).clamp(0.85, 1.1);

  return Row(
    children: [
      _statusCard("System", systemOnline, scale),
      _statusCard("Phase Seq", phaseOk, scale),
      _statusCard("Voltage", vHealthy, scale),
      _statusCard("Current", iHealthy, scale),
    ],
  );
}


  Widget _statusCard(String title, bool ok, double scale) {
  // final String statusText = ok ? "HEALTHY" : "FAULT";
  // final Color statusColor = ok ? Colors.green : Colors.red;
  final bool isSystem = title.toLowerCase() == "system";

  final String statusText = isSystem
      ? (ok ? "ONLINE" : "OFFLINE")
      : (ok ? "HEALTHY" : "FAULT");

  final Color statusColor = ok ? Colors.green : Colors.red;

  final IconData icon = _getStatusIcon(title);
  final Color iconColor = _getStatusIconColor(title,ok);

  final Color baseColor = iconColor;

  final bool isFault = !ok;
  final bool isOnlineSystem =
      title.toLowerCase() == "system" && ok;

  Widget animatedIcon = Icon(
    icon,
    size: 16 * scale,
    color: iconColor,
  );

  if (isFault || isOnlineSystem) {
    animatedIcon = ScaleTransition(
      scale: _pulseAnimation,
      child: animatedIcon,
    );
  }


  final List<Color> gradientColors = [
    baseColor.withOpacity(0.08),
    baseColor.withOpacity(0.20),
  ];

  return Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(
        vertical: 12 * scale,
        horizontal: 6 * scale,
      ),
      decoration: BoxDecoration(
        // color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: Colors.black12,
          width: 1.4,
        ),
        // border: Border.all(
        //   color: baseColor.withOpacity(0.5),
        //   width: 1.4,
        // ),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// TITLE + ICON (FILTER STYLE)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 6 * scale),

              FittedBox(
                fit: BoxFit.scaleDown,
                // child: Icon(
                //   icon,
                //   size: 16 * scale,
                //   color: iconColor,
                // ),
                child : Container(
                  padding: EdgeInsets.all(4 * scale),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // gradient: LinearGradient(
                    //   colors: [
                    //     iconColor.withOpacity(0.15),
                    //     iconColor.withOpacity(0.30),
                    //   ],
                    // ),
                    color: iconColor.withOpacity(0.15),
                  ),
                  // child: Icon(
                  //   icon,
                  //   size: 16 * scale,
                  //   color: iconColor,
                  // ),
                  child: animatedIcon,
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),

          /// CENTER STATUS
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14.5 * scale,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


IconData _getStatusIcon(String title) {
  switch (title.toLowerCase()) {

    

    case "system":
    return Icons.monitor_heart;

    case "phase seq":
      return Icons.sync_alt_rounded;

    case "voltage":
      return Icons.flash_on_rounded;

    case "current":
      return Icons.electrical_services_rounded;

    default:
      return Icons.devices;
  }
}

Color _getStatusIconColor(String title, bool ok) {
  switch (title.toLowerCase()) {

    case "system":
      return ok ? Colors.green : Colors.red;

    case "phase seq":
      return ok ? Colors.deepPurple : Colors.red;

    case "voltage":
      return ok ? Colors.orange : Colors.red;

    case "current":
      return ok ? Colors.blue : Colors.red;

    default:
      return Colors.grey;
  }
}



  // ================= new widget =================
Widget _sectionHeader({
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  required String subtitle,
}) {
  final size = MediaQuery.of(context).size;

  final iconBoxSize = (size.width * 0.8).clamp(30.0, 40.0);
  final iconSize = (size.width * 0.045).clamp(15.0, 20.0);

  return LayoutBuilder(
    builder: (context, constraints) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed-size icon box (NO overflow ever)
          SizedBox(
            width: iconBoxSize,
            height: iconBoxSize,
            child: Container(
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // Flexible text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (constraints.maxWidth * 0.10).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                        (constraints.maxWidth * 0.095).clamp(11.0, 13.0),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}



  // ================= GAUGES =================
   // Import this for the glass effect
Widget _rybSection() {
  final size = MediaQuery.of(context).size;
  final screenH = size.height;

  final verticalGap = (screenH * 0.04).clamp(18.0, 30.0);
  final innerGap = (screenH * 0.018).clamp(14.0, 22.0);

  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 12, // stronger glass blur
        sigmaY: 12,
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: screenH * 0.55,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          (screenH * 0.045).clamp(22.0, 34.0),
        ),
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.55), // glass edge
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sectionHeader(
              icon: Icons.flash_on_rounded,
              iconColor: Colors.blue,
              iconBg: Colors.blue.withOpacity(0.12),
              title: "Phase Voltage",
              subtitle: "3-Phase AC Supply",
            ),

            SizedBox(height: innerGap),

            _gaugeRow("",vR, vY, vB, 400), // "Voltage"

            SizedBox(height: verticalGap),

            Divider(
              thickness: 1,
              color: Colors.blueGrey.withOpacity(0.25),
            ),

            SizedBox(height: verticalGap),

            _sectionHeader(
              icon: Icons.trending_up_rounded,
              iconColor: Colors.green,
              iconBg: Colors.green.withOpacity(0.12),
              title: "Phase Current",
              subtitle: "Load Measurement",
            ),

            SizedBox(height: innerGap),

            _gaugeRow("", iR, iY, iB, 100), //Current
          ],
        ),
      ),
    ),
  );
}



  Widget _gaugeRow(
    String title, double r, double y, double b, double max) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      const SizedBox(height: 6),

      LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Expanded(child: _semiBarMeter("R", r, max, Colors.red)),
              const SizedBox(width: 2),
              Expanded(child: _semiBarMeter("Y", y, max, Colors.orange)),
              const SizedBox(width: 2),
              Expanded(child: _semiBarMeter("B", b, max, Colors.blue)),
            ],
          );
        },
      ),
    ],
  );
}



 Widget _semiBarMeter(
  String label,
  double value,
  double max,
  Color color,
) {
  final bool offline = !systemOnline;
  final percent = offline ? 0.0 : (value / max).clamp(0.0, 1.0);
  final unit = max > 100 ? "V" : "A";

  final displayValue =
    unit == "A"
        ? value.toStringAsFixed(1)   // Current → 1 decimal
        : value.toStringAsFixed(0);  // Voltage → no decimal


  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth.clamp(80.0, 200.0);
      final h = w * 0.5;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w,
            height: h,
            child: AnimatedBuilder(
              animation: _needleAnim,
              builder: (_, __) {
                return CustomPaint(
                  painter: _SemiBarPainter(
                    percent: percent * _needleAnim.value,
                    color: offline ? Colors.grey : color,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "$label PHASE",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: offline ? Colors.grey : color,
              ),
            ),
          ),


          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              // "${value.toStringAsFixed(1)} $unit",
              "$displayValue $unit",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: offline ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      );
    },
  );
}
  
}

// ================= GAUGE PAINTER WITH NEEDLE =================
class _SemiBarPainter extends CustomPainter {
  final double percent;
  final Color color;

  _SemiBarPainter({
    required this.percent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // SAFETY CHECK — prevents CanvasKit crash
    if (percent > 0.001) {
      final sweep = pi * percent;

      // GLOW ARC (draw FIRST)
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: pi,
          endAngle: pi + sweep,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.6),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        sweep,
        false,
        glowPaint,
      );

      //  MAIN ARC
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        sweep,
        false,
        activePaint,
      );


      // Needle
      final needleAngle = pi + sweep;
      final needleEnd = Offset(
        center.dx + cos(needleAngle) * (radius - 8),
        center.dy + sin(needleAngle) * (radius - 8),
      );

      canvas.drawLine(
        center,
        needleEnd,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center dot (always safe)
    canvas.drawCircle(
      center,
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiBarPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color;
  }
}

