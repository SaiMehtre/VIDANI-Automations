import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dart:ui';
import '../services/secure_storage_service.dart';
import '../state/dashboard_state.dart';
import 'device_detail_screen.dart';
import '../services/device_service.dart';
import '../core/session_manager.dart';
// import 'package:shared_preferences/shared_preferences.dart';  // use only if THIS ACTION BUTTON IS FOR SIGH OUT PASSWORD AND USER NAME VANISH


enum DeviceFilter { all, online, offline, fault }

DeviceFilter selectedFilter = DeviceFilter.all;

class DashboardScreen extends StatefulWidget {
  final String username;

  const DashboardScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {

      final DashboardState dashboardState = DashboardState();
  bool showWelcome = true;
  bool loading = true;
  bool showSecondText = false;
  bool showHello = true;
  int faultCount = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String searchQuery = "";

  


bool isOnlineFromTime(String? updatedAt) {
  if (updatedAt == null) return false;

  final last = DateTime.tryParse(updatedAt)?.toLocal();
  if (last == null) return false;

  return DateTime.now().difference(last).inMinutes <= 2;
}



  List devices = [];
  Map<String, Map<String, dynamic>> deviceStatus = {};

  Timer? liveTimer;

  // WELCOME ADDITION
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  late Animation<double> _fadeAnimation;




  @override
  void initState() {
    super.initState();

    // WELCOME ADDITION
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_fade);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));


    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => showSecondText = true);
    });

    // Show Hello first
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => showHello = false);
    });

    // Hello visible (default showHello = true)

//  After 1.5 sec → hide Hello, show Welcome
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        showHello = false;
        showSecondText = true;
      });
    });

    // After 3.5 sec → close welcome screen
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      setState(() {
        showWelcome = false;
      });
    });


    _anim.forward();

    _loadInitialData();
    
    liveTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        for (var d in devices) {
          await dashboardState.loadLive(d['device_id'].toString());
        }

        if (!mounted) return;

        setState(() {
          deviceStatus = dashboardState.deviceStatus;
        });
      },
    );

    // open dashboard smoothly
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => showWelcome = false);
      // liveTimer = Timer.periodic(
      //   const Duration(seconds: 15),
      //   (_) => _loadInitialData(),
      // );
    });
  }


  Future<void> _loadInitialData() async {
    await dashboardState.loadDevices();

    devices = dashboardState.devices;
    deviceStatus = dashboardState.deviceStatus;

    // 👇 Immediately fetch live once
    for (var d in devices) {
      await dashboardState.loadLive(d['device_id'].toString());
    }

    if (!mounted) return;

    setState(() {
      loading = false;
      deviceStatus = dashboardState.deviceStatus;
    });
  }

  @override
  void dispose() {
    liveTimer?.cancel();
    _anim.dispose();
    _blinkController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================= FETCH DEVICES =================
  Future<void> fetchDevices() async {
  try {
    final newDevices = await DeviceService.fetchDevices();

    if (!mounted) return;

    setState(() {
      // Only update if data not empty
      if (newDevices.isNotEmpty) {
        devices = newDevices;
      }
    });
  } catch (e) {
    debugPrint("Fetch error: $e");
    // DO NOT clear devices on error
  }
}
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final online =
        deviceStatus.values.where((e) => e['online'] == true).length;

    // final faultCount = deviceStatus.values.where((e) {
    //   if (e['online'] != true) return false;
    //   if (e['pumpOn'] == true) return false;
    //   return e['phaseOk'] == false ||
    //       e['vHealthy'] == false ||
    //       e['iHealthy'] == false;
    // }).length;


    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      // WELCOME SCREEN
      body: showWelcome
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE6FAFF), // very light blue
                    Color(0xFFF6FFFB), // soft white (center feel)
                    Color(0xFFE8FFF1), // light mint green
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 420,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 34,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65), // transparent card
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 1200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: showHello
                              ? Text(
                                  "Hello, ${widget.username}",
                                  key: const ValueKey("hello"),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                )
                              : showSecondText
                                  ? SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.35),
                                        end: Offset.zero,
                                      ).animate(_fade),
                                      child: Column(
                                        key: const ValueKey("welcome"),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Welcome to",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blueAccent,
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // LOGO HERE
                                          Image.asset(
                                            'assets/images/vidani_logo.png',
                                            height: 72,
                                            fit: BoxFit.contain,
                                          ),

                                          const SizedBox(height: 14),

                                          const Text(
                                            "Vidani Automations",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.blueAccent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                            : const SizedBox.shrink(),
                          ),
                        ),
                      )
                    )
                  ),
                ),
              ),

          )
          // ORIGINAL DASHBOARD (UNCHANGED)
          : Scaffold(
              appBar: AppBar(
                elevation: 0,
                // backgroundColor: 
                //     Theme.of(context).scaffoldBackgroundColor,
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                toolbarHeight: 64,
                titleSpacing: 16,
                title: Row(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.green.withOpacity(0.6),
                          //     blurRadius: 6,
                          //     spreadRadius: 1,
                          //   ),
                          // ],
                        ),
                      ),
                    ),


                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "LIVE MONITORING",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: "  /  Dashboard",
                                style: TextStyle(
                                  // color: Theme.of(context)
                                  //     .textTheme
                                  //     .bodyLarge!
                                  //     .color,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: () async {
                        await SecureStorageService.deleteToken();
                        SessionManager.clear();

                        if (!mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text("Logout",style: TextStyle(fontWeight: FontWeight.w900, color:Colors.blue)),
                    ),
                  ),
                ],
                // actions: [
                //   Container(
                //     margin: const EdgeInsets.only(right: 12),
                //     child: OutlinedButton(
                //       onPressed: () async {
                //         // CLEAR REMEMBER ME DATA
                //         final prefs = await SharedPreferences.getInstance();
                //         await prefs.clear();

                //         // NAVIGATE TO LOGIN
                //         Navigator.of(context).pushAndRemoveUntil(
                //           MaterialPageRoute(
                //             builder: (_) => const LoginScreen(),
                //           ),
                //           (route) => false,
                //         );
                //       },
                //       child: const Text("Sign out"),
                //     ),
                //   ),
                // ],  // THIS ACTION BUTTON IS FOR SIGH OUT PASSWORD AND USER NAME VANISH
              ),
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _dashboardBody(online),
            ),
    );
  }

  Widget _dashboardBody(int online) {

    final faultCount = deviceStatus.values.where((e) {
      if (e['online'] != true) return false;
      if (e['pumpOn'] == true) return false;

      return e['phaseOk'] == false ||
          e['vHealthy'] == false ||
          e['iHealthy'] == false;
    }).length;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6FAFF), // very light blue
              Color(0xFFF6FFFB), // soft white (center feel)
              Color(0xFFE8FFF1), // light mint green
            ],
          ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;

                // ultra small screen safe scaling
                final scale = (w / 360).clamp(0.75, 1.0);

                return Row(
                  children: [
                    _filterCard(
                      title: "TOTAL",
                      value: devices.length,
                      color: Colors.blue,
                      active: selectedFilter == DeviceFilter.all,
                      scale: scale,
                      onTap: () => setState(() {
                        selectedFilter = DeviceFilter.all;
                      }),
                    ),
                    _filterCard(
                      title: "ONLINE",
                      value: online,
                      color: Colors.green,
                      active: selectedFilter == DeviceFilter.online,
                      scale: scale,
                      onTap: () => setState(() {
                        selectedFilter = DeviceFilter.online;
                      }),
                    ),
                    _filterCard(
                      title: "OFFLINE",
                      value: devices.length - online,
                      color: Colors.red,
                      active: selectedFilter == DeviceFilter.offline,
                      scale: scale,
                      onTap: () => setState(() {
                        selectedFilter = DeviceFilter.offline;
                      }),
                    ),
                    _filterCard(
                      title: "FAULT",
                      value: faultCount,
                      color: Colors.orange,
                      active: selectedFilter == DeviceFilter.fault,
                      scale: scale,
                      onTap: () => setState(() {
                        selectedFilter = DeviceFilter.fault;
                      }),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            _layoutSearchBar(),

            const SizedBox(height: 10),

            Expanded(child: _deviceGrid()),
          ],
        ),
      ),
    );
  }


// =========== device status card ========


Widget _deviceGrid() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;

      int crossAxisCount;
      double childAspectRatio;

      if (width < 600) {
        // MOBILE
        crossAxisCount = 1;
        childAspectRatio = 1.15; // tall card
      } else if (width < 900) {
        // TABLET
        crossAxisCount = 2;
        childAspectRatio = 0.85;
      } else if (width < 1200) {
        // SMALL DESKTOP
        crossAxisCount = 3;
        childAspectRatio = 0.78;
      } else {
        // LARGE SCREEN
        crossAxisCount = 4;
        childAspectRatio = 0.75;
      }

      final filteredDevices = devices.where((d) {
      final id = d['device_id'].toString();
      final st = deviceStatus[id];

      if (st == null) return false;

      final q = searchQuery;

      if (q.isNotEmpty) {
        final id = d['device_id']?.toString().toLowerCase() ?? "";
        final site = d['site']?.toString().toLowerCase() ?? "";

        if (!id.contains(q) && !site.contains(q)) {
          return false;
        }
      }


      switch (selectedFilter) {
        case DeviceFilter.online:
          return st['online'] == true;

        case DeviceFilter.offline:
          return st['online'] == false;

        case DeviceFilter.fault:
          // if (st['online'] != true || st['pumpOn'] == true) return false;
          if (st['online'] != true) return false;
          return st['phaseOk'] == false ||
              st['vHealthy'] == false ||
              st['iHealthy'] == false;

        case DeviceFilter.all:
        // default:
          return true;
      }
      }).toList();

      return GridView.builder(
        itemCount: filteredDevices.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 22,
          crossAxisSpacing: 22,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (_, i) {
          final index = devices.indexOf(filteredDevices[i]);
          return _deviceCard(index);
        },
      );
    },
  );
}

Widget _deviceCard(int i) {
  final d = devices[i];
  final id = d['device_id'].toString();
  final st = deviceStatus[id] ?? {};
  final lastUpdate = st['lastUpdate'] as DateTime?;
  final online = st['online'] == true;
  final pumpOn = st['pumpOn'] == true;
  final runMode = st['runMode'];


  /// FAULT LOGIC (SAFE EVEN IF KEY MISSING)
  final bool hasFault =
      online &&
      !pumpOn &&
      ((st['phaseOk'] ?? true) == false ||
      (st['vHealthy'] ?? true) == false ||
      (st['iHealthy'] ?? true) == false);


  // String fault = "";
  // if (online && !pumpOn) {
  //   if (st['phaseOk'] == false) {
  //     fault = "PHASE FAULT";
  //   } else if (st['vHealthy'] == false) {
  //     fault = "VOLTAGE FAULT";
  //   } else if (st['iHealthy'] == false) {
  //     fault = "DRY RUN";
  //   }
  // }

  String fault = "";

  if (online) {
    if (st['phaseOk'] == false) {
      fault = "PHASE FAULT";
    } else if (st['vHealthy'] == false) {
      fault = "VOLTAGE FAULT";
    } else if (st['iHealthy'] == false) {
      fault = "DRY RUN";
    }
  }


  final LinearGradient cardGradient = !online
      ? LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade600],
        )
      : pumpOn
          ? const LinearGradient(
              colors: [Color(0xFF6FFFD2), Color(0xFF1FE4B7)],
            )
          : const LinearGradient(
              colors: [Color(0xFFFFD1D1), Color(0xFFFF9E9E)],
            );

  return InkWell(
    // onTap: () => Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => DashboardScreen(
    //       username: widget.username,
    //     ),
    //   ),
    // ),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(
          deviceId: id,
        ),
      ),
    ),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),


        // OUTER BORDER (image jaisa)
        border: Border.all(
          color: Colors.black12,
          width: 1.6,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],

      ),
      
      
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  //  TOP STATUS ROW
                  _statusRow(online, pumpOn, runMode, fault),

                  const SizedBox(height: 12),

                  //  DEVICE ID ---- OLD
                  // Text(
                  //   id,
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: const TextStyle(
                  //     fontSize: 17,
                  //     fontWeight: FontWeight.w900,
                  //   ),
                  // ),


                  ///  DEVICE ID PILL (STATUS AWARE + RESPONSIVE) --- NEW
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: online
                            ? hasFault
                                ? [Colors.red.shade50, Colors.red.shade100]
                                : [Colors.green.shade50, Colors.green.shade100]
                            : [Colors.grey.shade200, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasFault
                            ? Colors.red.withOpacity(0.6)
                            : online
                                // ? Colors.green.withOpacity(0.6)
                                ? const Color.fromARGB(255, 52, 102, 54).withOpacity(0.6)
                                : const Color.fromARGB(255, 131, 131, 131).withOpacity(0.9),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (hasFault
                                  ? Colors.red
                                  : online
                                      ? Colors.green
                                      : Colors.grey)
                              .withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ///  ICON (COLOR + ANIMATION)
                        hasFault
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.9, end: 1.15),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeInOut,
                                builder: (_, scale, child) {
                                  return Transform.scale(scale: scale, child: child);
                                },
                                child: _deviceIdIcon(
                                  color: Colors.red,
                                ),
                              )
                            : _deviceIdIcon(
                                color: online ? Colors.green : Colors.grey,
                              ),

                        const SizedBox(width: 8),

                        ///  DEVICE ID TEXT (OVERFLOW SAFE)
                        Expanded(
                          child: Text(
                            id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Colors.black,

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 8),

                  //  LOCATION PILL (RESPONSIVE) -- OLD
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFDDF0FF), // light blue bg
                  //     borderRadius: BorderRadius.circular(14),
                  //     border: Border.all(
                  //       color: const Color(0xFF5AAEFF), // blue border
                  //       width: 1.4,
                  //     ),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors.blue.withOpacity(0.15),
                  //         blurRadius: 8,
                  //         offset: const Offset(0, 4),
                  //       ),
                  //     ],
                  //   ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: online
                          ? const Color.fromARGB(255, 172, 220, 255) // light blue bg
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1E88E5), // blue border
                            
                        width: 1,
                      ),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 201, 235, 255), // light blue circle
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ),

                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d['site']?.toString().toUpperCase() ?? "UNKNOWN",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:  TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _lastUpdate(lastUpdate, online, pumpOn),
                  ),
                ],
              ),
            )
          );
        },
      )
    ),
  );
}


Widget _statusRow(
    bool online, bool pumpOn, String? runMode, String fault) {
  Color dotColor;
  String text;

  if (!online) {
    dotColor = Colors.grey;
    text = "OFFLINE";
  } else if (pumpOn) {
    dotColor = Colors.green;
    text = "RUNNING (${runMode ?? 'TIMER'})";
  } else if (fault.isNotEmpty) {
    dotColor = Colors.red;
    text = fault;
  } else {
    dotColor = Colors.red;
    text = "STOPPED";
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;

      /// responsive font size
      double fontSize = screenWidth * 0.065;
      fontSize = fontSize.clamp(14.5, 15.5);

      /// responsive padding
      double hPad = screenWidth * 0.045;
      double vPad = screenWidth * 0.025;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          /// STATUS PILL (LEFT)
          Flexible(
            fit: FlexFit.loose,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: pumpOn ? 1.05 : 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (_, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 4), //  pill left side
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  constraints: const BoxConstraints(
                    minWidth: 120, //  auto grow with text
                    // minHeight: 44, //  same as other pills
                  ),
                  
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: vPad+2),
                  decoration: BoxDecoration(
                    color: !online
                        ? Colors.grey.shade300
                        : pumpOn
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dotColor.withOpacity(0.6),
                      width: 1.6,
                    ),
                    boxShadow: [
                      if (online)
                        BoxShadow(
                          color:
                              dotColor.withOpacity(pumpOn ? 0.45 : 0.35),
                          blurRadius: pumpOn ? 16 : 12,
                          spreadRadius: pumpOn ? 2 : 1,
                        ),
                    ],
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (fault.isNotEmpty) ...[
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                      ] else ...[
                        pumpOn
                            ? FadeTransition(
                                opacity: _blinkAnim,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        const SizedBox(width: 8),
                      ],

                      /// text auto adjust
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown, //  MAGIC LINE
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            maxLines: 1,               //  still single line
                            softWrap: false,
                            overflow: TextOverflow.visible, //  ellipsis hata diya
                            style: TextStyle(
                              fontSize: fontSize,      // base size
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          ///  PUMP (RIGHT)
          Flexible(
            fit: FlexFit.loose,
            child: LayoutBuilder(
              builder: (context, pumpConstraints) {
                double pumpSize = screenWidth * 0.22;
                pumpSize = pumpSize.clamp(52.0, 78.0);

                return Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(6, -6),
                    child: Container(
                      width: pumpSize,
                      height: pumpSize,
                      padding: EdgeInsets.all(pumpSize * 0.12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(pumpSize * 0.18),
                        border: Border.all(
                          color: dotColor.withOpacity(0.9),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withOpacity(0.35),
                            blurRadius: pumpSize * 0.25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        pumpOn
                            ? 'assets/gif/pump.gif'
                            : 'assets/images/pump.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}


// =============Last update function ===========================
Widget _lastUpdate(DateTime? lastUpdate, bool online, bool pumpOn) {
  if (lastUpdate == null) return const SizedBox();

  final now = DateTime.now();
  final local = lastUpdate.toLocal();

  final isToday =
      now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;

  final isYesterday =
      now.subtract(const Duration(days: 1)).day == local.day &&
      now.month == local.month &&
      now.year == local.year;

  String dayText;
  if (isToday) {
    dayText = "Today";
  } else if (isYesterday) {
    dayText = "Yesterday";
  } else {
    dayText = "${local.day}/${local.month}/${local.year}";
  }

  final timeText =
      TimeOfDay.fromDateTime(local).format(context);

  ///  STATUS COLORS
  final Color mainColor = !online
      ? Colors.black54
      : pumpOn
          ? Colors.green
          : Colors.red;

  ///  BORDER COLOR (SEPARATE)
  final Color borderColor = !online
      ? Colors.grey.shade700
      : pumpOn
          ? Colors.green.shade500
          : Colors.red.shade400;

  ///  BACKGROUND COLOR (SEPARATE)
  final Color bgColor = !online
      ? Colors.grey.shade400
      : pumpOn
          ? Colors.green.shade100
          : Colors.red.shade100;


  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: bgColor, // background
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: borderColor, // separate border
        width: 1.6,
      ),
      boxShadow: [
        if (online)
          BoxShadow(
            color: mainColor.withOpacity(pumpOn ? 0.35 : 0.25),
            blurRadius: pumpOn ? 14 : 10,
            spreadRadius: pumpOn ? 1.5 : 1,
          ),
      ],
    ),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //  ICON
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time_filled,
            size: 16,
            color: mainColor.withOpacity(0.9),
          ),
        ),
       const SizedBox(width: 8),
       ///  SAFE TEXT (NO OVERFLOW)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ Text(
                  "LAST UPDATE",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                    color: mainColor,
                  ),
                ),
              
              const SizedBox(height: 2),Text(
                  "$dayText · $timeText",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                    color: mainColor,
                  ),
                ),
              
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _filterCard({
    required String title,
    required int value,
    required Color color,
    required bool active,
    required double scale,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(
            vertical: 14 * scale,
            horizontal: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: active ? color : Colors.black12,
              width: 1.6,
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,            
            children: [
              /// TITLE + ICON (OVERFLOW SAFE)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// TEXT (SHRINKABLE)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 6 * scale),

                  /// ICON (SHRINKABLE)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _filterIcon(
                      title: title,
                      color: color,
                      scale: scale,
                      active: active,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8 * scale),

              /// COUNT (SAFE)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "$value",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],            
          ),
        ),
      ),
    );
  }  

  Widget _filterIcon({
  required String title,
  required Color color,
  required double scale,
  required bool active,
}) {
  /// ICON MAP
  final IconData icon = title == "FAULT"
      ? Icons.warning_amber_rounded
      : title == "OFFLINE"
          ? Icons.cloud_off_rounded
          : title == "ONLINE"
              ? Icons.wifi_rounded
              : Icons.memory_rounded;

  /// FAULT → RED + SHAKE + PULSE
  if (title == "FAULT") {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: active ? 1.15 : 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
      builder: (_, scaleAnim, __) {
        return Transform.translate(
          offset: Offset(active ? 2 : 0, 0),
          child: Transform.scale(
            scale: scaleAnim,
            child: Icon(
              icon,
              size: 18 * scale,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }

  // ONLINE → WIFI + BLINKING GREEN DOT
  if (title == "ONLINE") {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: 18 * scale,
          color: color,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: FadeTransition(
            opacity: _blinkAnim, // already in your code ✔
            child: Container(
              width: 6 * scale,
              height: 6 * scale,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
  /// OFFLINE / TOTAL → STATIC
  return Icon(
    icon,
    size: 18 * scale,
    color: color.withOpacity(0.9),
  );
}


  Widget _layoutSearchBar() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final scale = (w / 360).clamp(0.75, 1.0);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * scale),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 10 * scale,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon(
            //   Icons.search,
            //   size: 20 * scale,
            //   color: Colors.blueAccent,
            // ),
            // SizedBox(width: 8 * scale),

            ///  INPUT
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() {
                    searchQuery = v.trim().toLowerCase();
                  });
                },
                style: TextStyle(fontSize: 14 * scale),
                decoration: InputDecoration(
                  hintText: "Search device / location",
                  hintStyle: TextStyle(
                    fontSize: 13 * scale,
                    color: Colors.grey,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),

            ///  CLEAR BUTTON
            if (searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    searchQuery = "";
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(6 * scale),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18 * scale,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Icon(
              Icons.search,
              size: 20 * scale,
              color: Colors.blueAccent,
            ),
            SizedBox(width: 8 * scale),
          ],
        ),
      );
    },
  );
}

Widget _deviceIdIcon({required Color color}) {
  return Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.memory_rounded,
      size: 16,
      color: color,
    ),
  );
}

}

