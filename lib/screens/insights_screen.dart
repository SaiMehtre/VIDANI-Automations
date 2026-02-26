import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import '../widgets/device_banner.dart';
import '../services/device_service.dart';



class InsightsScreen extends StatefulWidget {
  final String deviceId;

  const InsightsScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with TickerProviderStateMixin{
  bool loading = true;
  Timer? refreshTimer;        // first load only
  bool refreshing = false;   // background refresh

  // ===== API DATA =====
  int pumpRunningSec = 0;

  int todayRuntimeSec = 0;
  double todayEnergy = 0.0;


  int totalRuntimeSec = 0;
  double totalEnergy = 0.0;
  double avgPowerKw = 0.0;
  double efficiencyPf = 0.0;

  double totalPowerKw = 0;
  double powerFactor = 0;

  late AnimationController _liveController;
  late Animation<double> _liveAnimation;
  late AnimationController _runtimeBorderController;
  bool isPumpOn = false;


  // double scale = 1.0;
  // double s(double v) => (v * scale).clamp(v * 0.75, v);

  double s(double size) {
    final w = MediaQuery.of(context).size.width;
    return size * (w / 375).clamp(0.85, 1.05);
  }

  double safeDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) {
    if (v.isNaN || v.isInfinite) return 0.0;
    return v.toDouble();
  }
  if (v is String) {
    final d = double.tryParse(v);
    if (d == null || d.isNaN || d.isInfinite) return 0.0;
    return d;
  }
  return 0.0;
}


// ============POWER FACTOR COLOR===============

Color getPfColor(double pf) {
  if (pf < 0.80) {
    return const Color(0xFFD50000); // Poor
  } else if (pf < 0.90) {
    return Colors.orange; // 🟠 Good
  } else {
    return const Color(0xFF00C853); // Excellent
  }
}

String getPfLabel(double pf) {
  if (pf < 0.80) {
    return "POOR";
  } else if (pf < 0.90) {
    return "GOOD";
  } else {
    return "EXCELLENT";
  }
}


  @override
  void initState() {
    super.initState();

    firstLoad();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => silentRefresh(),
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark,
    );

    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _liveAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _liveController,
        curve: Curves.easeInOut,
      ),
    );

    _liveController.repeat(reverse: true);

    _runtimeBorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (pumpRunningSec > 0) {
      _runtimeBorderController.repeat();
    }

    DeviceService.fetchDeviceLocation(
      deviceId: widget.deviceId,
    );

  }

  Future<void> firstLoad() async {
    setState(() => loading = true);

    await Future.wait([
      fetchLiveData(),
      fetchTodayPerformance(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> silentRefresh() async {
    if (refreshing) return; // overlap avoid

    refreshing = true;

    try {
      await Future.wait([
        fetchLiveData(),
        fetchTodayPerformance(),
      ]);

      if (mounted) setState(() {});
    } finally {
      refreshing = false;
    }
  }


  // ================= LIVE =================
  Future<void> fetchLiveData() async {
  final data = await DeviceService.fetchInsightsLive(widget.deviceId);

  if (data == null) return;

  isPumpOn = data["pump_on"] == 1;

  final int apiRuntime =
      int.tryParse(data['curr_runtime']?.toString() ?? '0') ?? 0;

  if (isPumpOn) {
    pumpRunningSec = apiRuntime;

    if (!_runtimeBorderController.isAnimating) {
      _runtimeBorderController.repeat();
    }
  } else {
    pumpRunningSec = 0;
    _runtimeBorderController.stop();
  }

  avgPowerKw = safeDouble(data['totalpower']) / 1000;
  efficiencyPf = safeDouble(data['totalpf']) * 100;

  totalRuntimeSec =
      int.tryParse(data['total_runtime']?.toString() ?? '0') ?? 0;

  totalEnergy = safeDouble(data['energy']);

  totalPowerKw = safeDouble(data["totalpower"]) / 1000;
  powerFactor = safeDouble(data["totalpf"]);
}


  // ================= TODAY =================
  Future<void> fetchTodayPerformance() async {
  final data =
      await DeviceService.fetchTodayPerformance(widget.deviceId);

  if (data == null) return;

  todayEnergy = safeDouble(data['energy_kwh']);
  todayRuntimeSec =
      int.tryParse(data['runtime_seconds']?.toString() ?? '0') ?? 0;
}

  // ================= HOURLY (TOTAL + RUNNING) =================
  Future<void> fetchHourlyData() async {
  final now = DateTime.now().toUtc();
  final from =
      now.subtract(const Duration(days: 30)).toIso8601String();
  final to = now.toIso8601String();

  final list = await DeviceService.fetchHourlyEnergy(
    widget.deviceId,
    from,
    to,
  );

  for (final h in list) {
    totalEnergy += safeDouble(h['energy_kwh']);
    final rt =
        int.tryParse(h['runtime_seconds']?.toString() ?? '0') ?? 0;
    totalRuntimeSec += rt;
  }

  setState(() => loading = false);
}

  @override
  void dispose() {
    refreshTimer?.cancel();
    _liveController.dispose();
    _runtimeBorderController.dispose();
    super.dispose();
  }

  // ================= HELPERS =================
  String formatTime(int? sec) {
    final s = sec ?? 0;

    if (s <= 0) return "0 hr 0 min";

    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;

    return "$h hr $m min";
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.045;
    // base design ~390 (Pixel / normal Android)
    // final scale = (w / 390).clamp(0.85, 1.0);


    return Scaffold(
      // backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 0, 
        iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Insights",style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent), ),
        centerTitle: true,
      ),
      body: Column(
      children: [
        DeviceBanner(deviceId: widget.deviceId),
      Expanded(
        child: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE6FAFF), // very light blue
                  Color(0xFFF6FFFB), // soft white
                  Color(0xFFE8FFF1), // light mint green
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= Pump Running Since =================
                 
                  _outerCard(
                    child: isPumpOn
                        ? animatedInnerMetric(
                            child: _luxuryMetric(
                              icon: Icons.monitor_heart,
                              label: "Current Runtime",
                              iconColor: Colors.greenAccent,
                              value: Container(
                                // padding: EdgeInsets.all(s(10)),
                                // decoration: BoxDecoration(
                                //   shape: BoxShape.circle,
                                //   color: const Color(0xFF2979FF).withOpacity(0.08),
                                // ),
                                child: dashboardRuntime(
                                  seconds: pumpRunningSec,
                                  fontSize: s(22),
                                  numberColor: const Color(0xFF2979FF),
                                ),
                              ),
                            ),
                          )
                        : _luxuryMetric(
                            icon: Icons.monitor_heart,
                            label: "Current Runtime",
                            iconColor: Colors.greenAccent,
                            value: Container(
                              padding: EdgeInsets.all(s(10)),
                              // decoration: BoxDecoration(
                              //   shape: BoxShape.circle,
                              //   color: const Color(0xFF2979FF).withOpacity(0.08),
                              // ),
                              child: dashboardRuntime(
                                seconds: pumpRunningSec,
                                fontSize: s(22),
                                numberColor: const Color(0xFF2979FF),
                              ),
                            ),
                          ),
                  ),

                  // SizedBox(height: pad),
                  SizedBox(height: s(10)),

                  // ================= Power Metrics" =================

                  _outerCard(
                    centerHeader: _centerHeader(
                      icon: Icons.bolt,
                      iconColor: const Color(0xFF2979FF),
                      title: "Power Metrics",
                      subtitle: "Real-time monitoring",
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            /// Continuous Pulse Icon
                            AnimatedBuilder(
                              animation: _liveAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _liveAnimation.value,
                                  child: Opacity(
                                    opacity: 1 - (_liveAnimation.value - 0.8),
                                    child: const Icon(
                                      Icons.sensors,
                                      size: 16,
                                      color: Color(0xFF00C853),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 6),

                            /// Stable Text
                            Text(
                              "LIVE",
                              style: TextStyle(
                                fontSize: s(10),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: const Color(0xFF00C853),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    child: Row(
                      children: [

                        /// ================= TOTAL POWER DRAW =================
                          Expanded(
                            child: _luxuryMetric(
                              icon: Icons.flash_on,
                              label: "Total Power Draw",
                              iconColor: const Color(0xFF2979FF),
                              value: odometerNumber(
                                value: totalPowerKw,
                                fraction: 3,
                                suffix: " kW",
                                duration: const Duration(milliseconds: 700),
                                style: TextStyle(
                                  fontSize: s(20),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: const Color(0xFF2979FF),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: pad),

                          /// ================= POWER FACTOR =================
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(s(16)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: (powerFactor < 0.80
                                        ? const Color(0xFFD50000)
                                        : powerFactor < 0.90
                                            ? Colors.orange
                                            : const Color(0xFF00C853))
                                    .withOpacity(0.08), // 🔥 Dynamic premium bg
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  /// HEADER
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.show_chart,
                                        size: 16,
                                        color: powerFactor < 0.80
                                            ? const Color(0xFFD50000)
                                            : powerFactor < 0.90
                                                ? Colors.orange
                                                : const Color(0xFF00C853),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "POWER FACTOR",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: s(10),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: s(10)),

                                  /// VALUE
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: odometerNumber(
                                      value: powerFactor,
                                      fraction: 3,
                                      duration: const Duration(milliseconds: 700),
                                      style: TextStyle(
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                        color: powerFactor < 0.80
                                            ? const Color(0xFFD50000)
                                            : powerFactor < 0.90
                                                ? Colors.orange
                                                : const Color(0xFF00C853),
                                      ),
                                    ),
                                  ),
                                ),


                                  SizedBox(height: s(10)),

                                  /// PROGRESS + SCALE + BADGE
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: powerFactor.clamp(0.0, 1.0),
                                    ),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, value, __) {
                                      final Color pfColor = value < 0.80
                                          ? const Color(0xFFD50000)
                                          : value < 0.90
                                              ? Colors.orange
                                              : const Color(0xFF00C853);

                                      // final String pfLabel = value < 0.8
                                      //     ? "POOR"
                                      //     : value < 0.95
                                      //         ? "GOOD"
                                      //         : "EXCELLENT";

                                      return Column(
                                        children: [

                                          /// Progress Bar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Stack(
                                              children: [
                                                // Background Track
                                                Container(
                                                  height: 6,
                                                  width: double.infinity,
                                                  color: Colors.grey.shade300,
                                                ),

                                                // Progress
                                                FractionallySizedBox(
                                                  widthFactor: value,
                                                  child: Container(
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          pfColor.withOpacity(0.7),
                                                          pfColor,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.horizontal(
                                                        left: const Radius.circular(8),
                                                        right: value > 0.02
                                                            ? const Radius.circular(8)
                                                            : Radius.zero,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          SizedBox(height: s(6)),

                                          /// 0.0 --- 1.0
                                          Row(
                                            children: [
                                              /// 0.0
                                              Text(
                                                "0.0",
                                                style: TextStyle(
                                                  fontSize: s(9),
                                                  color: Colors.grey,
                                                ),
                                              ),

                                              /// CENTER BADGE (auto center)
                                              Expanded(
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: (powerFactor < 0.80
                                                              ? const Color(0xFFD50000)
                                                              : powerFactor < 0.90
                                                                  ? Colors.orange
                                                                  : const Color(0xFF00C853))
                                                          .withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: Text(
                                                      powerFactor < 0.80
                                                          ? "POOR"
                                                          : powerFactor < 0.90
                                                              ? "GOOD"
                                                              : "EXCELLENT",
                                                      style: TextStyle(
                                                        fontSize: s(9),
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 1,
                                                        color: powerFactor < 0.80
                                                            ? const Color(0xFFD50000)
                                                            : powerFactor < 0.90
                                                                ? Colors.orange
                                                                : const Color(0xFF00C853),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              /// 1.0
                                              Text(
                                                "1.0",
                                                style: TextStyle(
                                                  fontSize: s(9),
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: s(10)),

                  // ================= Today's Performance =================
                  
                  _outerCard(
                    centerHeader: _centerHeader(
                      icon: Icons.calendar_today,
                      iconColor: Colors.redAccent,
                      title: "Today's Performance",
                      subtitle: "Running & energy consumption",
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _luxuryMetric(
                                icon: Icons.access_time,
                                label: "Runtime",
                                iconColor: Colors.blue,
                                // value: animatedRuntime(
                                //   seconds: todayRuntimeSec,
                                //   style: TextStyle(
                                //     fontSize: s(16),
                                //     fontWeight: FontWeight.w900,
                                //     letterSpacing: 0.5,
                                //   ),
                                // ),
                                value: Container(
                                  // padding: EdgeInsets.all(s(10)),
                                  // decoration: BoxDecoration(
                                  //   shape: BoxShape.circle,
                                  //   color: Colors.blue.withOpacity(0.08),
                                  // ),
                                  child: animatedRuntime(
                                    seconds: todayRuntimeSec,
                                    style: TextStyle(
                                      fontSize: s(18),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: pad),
                            Expanded(
                              child: _luxuryMetric(
                                icon: Icons.flash_on,
                                label: "Energy Consumed",
                                iconColor: const Color(0xFF00C853),
                                isEnergy: true,
                                value: odometerNumber(
                                  value: todayEnergy,
                                  fraction: 3,
                                  suffix: " kWh",
                                  duration: const Duration(milliseconds: 900),
                                  style: TextStyle(
                                    fontSize: s(22),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: Colors.white, // required for gradient mask
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // SizedBox(height: s(16)),

                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _smallStat(
                        //         "Avg Power",
                        //         "${avgPowerKw.toStringAsFixed(2)} kW",
                        //       ),
                        //     ),
                        //     SizedBox(width: s(12)),
                        //     Expanded(
                        //       child: _smallStat(
                        //         "Efficiency",
                        //         "${efficiencyPf.toStringAsFixed(2)} %",
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),

                  // SizedBox(height: pad),
                  SizedBox(height: s(10)),

                  // ================= Total Performance =================
                  
                  _outerCard(
                    centerHeader: _centerHeader(
                      icon: Icons.bar_chart,
                      iconColor: Colors.purple,
                      title: "Total Performance",
                      subtitle: "Running & energy consumption",
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _luxuryMetric(
                            icon: Icons.timer,
                            label: "Total Runtime",
                            iconColor: Colors.deepPurple,
                            // value: animatedRuntime(
                            //   seconds: totalRuntimeSec,
                            //   style: TextStyle(
                            //     fontSize: s(16),
                            //     fontWeight: FontWeight.w900,
                            //     letterSpacing: 0.5,
                            //   ),
                            // ),
                            value: Container(
                              // padding: EdgeInsets.all(s(10)),
                              // decoration: BoxDecoration(
                              //   shape: BoxShape.circle,
                              //   color: Colors.deepPurple.withOpacity(0.08),
                              // ),
                              child: animatedRuntime(
                                seconds: totalRuntimeSec,
                                style: TextStyle(
                                  fontSize: s(18),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),

                          ),
                        ),
                        SizedBox(width: pad),
                        Expanded(
                          child: _luxuryMetric(
                            icon: Icons.bolt,
                            label: "Total Energy",
                            iconColor: const Color(0xFF0BA360),
                            isEnergy: true,
                            value: odometerNumber(
                              value: totalEnergy,
                              fraction: 3,
                              suffix: " kWh",
                              duration: const Duration(milliseconds: 900),
                              style: TextStyle(
                                fontSize: s(22),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Colors.white, // required for gradient mask
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
      ],
      
      ),
    );
  }

  // ================= OUTER CARD =================
  Widget _outerCard({
  String? title,
  Widget? centerHeader,
  required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3FAFF),
            Color(0xFFF2FFF8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (centerHeader != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: centerHeader,
            ),

            const SizedBox(height: 16),
          ] else if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

Widget _centerHeader({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),

        Expanded( // prevents overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: s(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: s(10),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,  //  ADD THIS
      ],
    );

  }

  Widget _luxuryMetric({
  required IconData icon,
  required String label,
  required Color iconColor,
  required Widget value,
  bool isEnergy = false,
}) {
  return Container(
    padding: EdgeInsets.all(s(16)),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [
          Colors.white,
          iconColor.withOpacity(0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: iconColor.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(s(7)),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: s(13),
                color: iconColor,
              ),
            ),
            SizedBox(width: s(8)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: s(11),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(12)),

        // Premium Value Display
        Center(
          child: isEnergy
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF00C853),
                      Color(0xFF0BA360),
                    ],
                  ).createShader(bounds),
                  child: value,
                )
              : value,
        ),

        SizedBox(height: s(12)),

        Container(
          height: s(4),
          width: s(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(0.6),
                iconColor.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    ),
  );
}



Widget runtimeText(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;

  return RichText(
    text: TextSpan(
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Colors.black,
      ),
      children: [
        TextSpan(
          text: "$h",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const TextSpan(
          text: " hr ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: "$m",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const TextSpan(
          text: " min",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}


Widget energyText(double energyKwh) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(
        fontFamily: 'Inter',
        color: Colors.green,
      ),
      children: [
        TextSpan(
          text: energyKwh.toStringAsFixed(4),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const TextSpan(
          text: " kWh",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

  Widget animatedNumber({
  required double value,
  required TextStyle style,
  int fraction = 0,
  String suffix = "",
  Duration duration = const Duration(milliseconds: 600),
}) {
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: value),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, val, _) {
      return Text(
        "${val.toStringAsFixed(fraction)}$suffix",
        style: style,
        textAlign: TextAlign.center,
      );
    },
  );
}



Widget animatedRuntime({
  required int seconds,
  required TextStyle style,
}) {
  return TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: seconds),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
    builder: (_, val, __) {
      final h = val ~/ 3600;
      final m = (val % 3600) ~/ 60;

      return Text(
        "$h hr $m min", // seconds intentionally hidden
        style: style,
        textAlign: TextAlign.center,
      );
    },
  );
}

Widget dashboardRuntime({
  required int seconds,
  required double fontSize,
  Color numberColor = const Color(0xFF1E88E5), // same blue tone
}) {
  final d = Duration(seconds: seconds);

  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);

  Widget buildUnit(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: numberColor,
            height: 0.9,
    letterSpacing: -0.5, // tighter = thicker feel
    fontFeatures: const [
    FontFeature.tabularFigures(), // uniform digit width
  ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize * 0.45,   // small unit text
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        buildUnit(hours.toString(), "hr"),
        buildUnit(minutes.toString(), "min"),
      ],
    ),
  );
}



Widget odometerNumber({
  required double value,
  required TextStyle style,
  int fraction = 0,
  String suffix = "",
  Duration duration = const Duration(milliseconds: 600),
}) {
  return FittedBox(   // IMPORTANT
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedFlipCounter(
          value: value,
          fractionDigits: fraction,
          duration: duration,
          curve: Curves.easeOutCubic,
          textStyle: style,
        ),
        if (suffix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              suffix,
              style: style.copyWith(
                fontSize: style.fontSize! * 0.65,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

Widget animatedInnerMetric({required Widget child}) {
  return AnimatedBuilder(
    animation: _runtimeBorderController,
    builder: (context, _) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: SweepGradient(
            transform: GradientRotation(
              _runtimeBorderController.value * 6.2832,
            ),
            colors: const [
              Color(0xFF2979FF),
              Color(0xFF00C853),
              Color.fromARGB(255, 255, 255, 255),
              Color(0xFF2979FF),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(5), // border thickness
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
          ),
          child: child,
        ),
      );
    },
  );
}

}
