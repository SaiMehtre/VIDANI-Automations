import 'package:flutter/material.dart';
import 'dart:async';
import '../services/device_service.dart';
import '../widgets/device_banner.dart';


class SchedulingScreen extends StatefulWidget {
  final String deviceId;

  const SchedulingScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  static const int totalSlots = 10;

  bool loading = true;
  bool commandInProgress = false;
  bool syncing = false;



  final List<Map<String, dynamic>> slots =
      List.generate(totalSlots, (_) => {});

  @override
  void initState() {
    super.initState();
    fetchLiveSchedule();
    DeviceService.fetchDeviceLocation(
      deviceId: widget.deviceId,
    );
  }

  Future<void> sendScheduleCommand(
    Map<String, dynamic> payload) async {
  if (commandInProgress) return;

  setState(() => commandInProgress = true);

  try {
    int index = (payload["slot"] as int) - 1;

    final body = {
      "cmd": "schconfig",
      "index": index,
      "slot": {
        "enable": payload["enabled"] ? 1 : 0,
        "mode": _modeToInt(payload["mode"]),
        "on_time": _timeToMinutes(payload["start"]),
        "off_time": _timeToMinutes(payload["stop"]),
        "run_time":
            payload["mode"] == "Run Time (Minutes)"
                ? payload["run_time"] ?? 0
                : 0,
        "retry_time":
            payload["mode"] == "Auto (Dry Run Retry)"
                ? payload["retry_time"] ?? 0
                : 0,
        "weekday":
            _daysToBitmask(payload["days"]),
      }
    };

    await DeviceService.sendScheduleCommand(
        widget.deviceId, body);

    await Future.delayed(
        const Duration(seconds: 3));
  } catch (e) {
    debugPrint("Schedule error: $e");
  } finally {
    setState(() => commandInProgress = false);
  }
}

// ====================fetch Schedule From Device ================================

Future<void> fetchLiveSchedule() async {
  if (!mounted) return;

  setState(() => loading = true);

  try {
    final decoded =
        await DeviceService.fetchScheduleSlots(
            widget.deviceId);

    for (var item in decoded) {
      final index = item["slot_index"];

      if (index >= 0 && index < totalSlots) {
        slots[index] = {
          "enabled": item["enable"],
          "mode": _intToMode(item["mode"]),
          "start":
              _hhmmToAmPm(item["on_time"]),
          "stop":
              _hhmmToAmPm(item["off_time"]),
          "retry":
              item["run_time"],
          "days":
              _weekdayFromBitmask(
                  item["weekday"]),
        };
      }
    }
  } catch (e) {
    debugPrint("Fetch error: $e");
  } finally {
    if (!mounted) return;
    setState(() => loading = false);
  }
}


// ====================sync Schedule From Device ================================

Future<void> syncFromDevice() async {
  if (syncing) return;

  setState(() => syncing = true);

  try {
    await DeviceService.syncScheduleFromDevice(
        widget.deviceId);

    await Future.delayed(
        const Duration(seconds: 3));

    await fetchLiveSchedule();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Schedule synced from device"),
      ),
    );
  } catch (e) {
    debugPrint("Sync error: $e");
  } finally {
    setState(() => syncing = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = w < 400 ? 0.9 : w > 900 ? 1.1 : 1.0;

    return Scaffold(
      backgroundColor: Color(0xFFEEF0FF),

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        // leadingWidth: 40,      
        titleSpacing: 0,        

        ///  BACK BUTTON (separate)
        leading: IconButton(
           padding: EdgeInsets.zero, 
          icon: const Icon(Icons.arrow_back, color: Colors.white70,),
          onPressed: () => Navigator.pop(context),
        ),

        /// TITLE + SUBTITLE
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Device Schedule",
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      // fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Mode-aware slot scheduling",
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        ),


        ///  SYNC BUTTON 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (!syncing) {
                    syncFromDevice();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 360 ? 8 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: syncing
                      ? Row(
                          key: const ValueKey("syncing"),                    
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Syncing…",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Sync From Device",
                          key: ValueKey("text"),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),

      /// ✅ BODY (UNCHANGED GRID)
      body: SafeArea(
  child: Column(
    children: [

      /// 🔥 DEVICE BANNER (ADD HERE)
      DeviceBanner(deviceId: widget.deviceId),

      /// 👇 EXISTING BODY
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16 * scale),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 1100;
                        final isTablet = constraints.maxWidth >= 600;

                        final cardWidth = isDesktop
                            ? (constraints.maxWidth / 3) - 20
                            : isTablet
                                ? (constraints.maxWidth / 2) - 20
                                : constraints.maxWidth;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: List.generate(totalSlots, (index) {
                            return SizedBox(
                              width: cardWidth,
                              child: ScheduleSlot(
                                slotNumber: index + 1,
                                slotData: slots[index],
                                onApply: sendScheduleCommand,
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    ],
  ),
),

    );
  }
}

class ScheduleSlot extends StatefulWidget {
  final int slotNumber;
  final Map<String, dynamic> slotData;
  final Function(Map<String, dynamic>) onApply;

  const ScheduleSlot({
    super.key,
    required this.slotNumber,
    required this.slotData,
    required this.onApply,
  });

  @override
  State<ScheduleSlot> createState() => _ScheduleSlotState();
}

class _ScheduleSlotState extends State<ScheduleSlot> {
  bool isApplying = false;
  bool isSuccess = false;
  bool isError = false;
  int waitSeconds = 10;
  Timer? _timer;

  
  late bool enabled;
  late String mode;
  late String start;
  late String stop;
  
  int runTimeMinutes = 0;   // For Run Time (Minutes)
  int retryMinutes = 0;     // For Auto (Dry Run Retry)
  late Set<String> days;

  
  final List<String> allDays = [
    "Sun","Mon","Tue","Wed","Thu","Fri","Sat","All"
  ];

  @override
  void didUpdateWidget(covariant ScheduleSlot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.slotData != widget.slotData) {
      setState(() {
        enabled = widget.slotData["enabled"] ?? false;
        mode = widget.slotData["mode"] ?? "RTC (Fixed Start-Stop)";
        start = widget.slotData["start"] ?? "10:00 AM";
        stop = widget.slotData["stop"] ?? "10:10 AM";
        runTimeMinutes = widget.slotData["retry"] ?? 0;
        retryMinutes = widget.slotData["retry"] ?? 0;
        days = Set<String>.from(widget.slotData["days"] ?? ["All"]);
      });
    }
  }


  @override
  void initState() {
    super.initState();
    enabled = widget.slotData["enabled"] ?? false;
    mode = widget.slotData["mode"] ?? "RTC (Fixed Start-Stop)";
    start = widget.slotData["start"] ?? "10:00 AM";
    stop = widget.slotData["stop"] ?? "10:10 AM";
    runTimeMinutes = widget.slotData["retry"] ?? 0;
    retryMinutes = widget.slotData["retry"] ?? 0;

    days = Set<String>.from(widget.slotData["days"] ?? ["All"]);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = w < 400 ? 0.9 : w > 900 ? 1.1 : 1.0;

    return Container(
      padding: EdgeInsets.all(16 * scale),
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
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: enabled ? Color(0xFF22C55E) : Colors.red,width: 1.4),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          style: const TextStyle(
                            color: Colors.black,
                            // fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          "SLOT ${widget.slotNumber}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: enabled ? Color(0xFF22C55E) : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          enabled ? "ACTIVE" : "DISABLED",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                  activeThumbColor: const Color.fromARGB(255, 240, 232, 232),
                  activeTrackColor: Color(0xFF8B5CF6),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade600,
                ),
              ],
            ),

            //  ===== timepicker for start/end Time ====================

            const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 260;

                  if (isNarrow) {
                    // 📱 MOBILE / VERY SMALL WIDTH
                    return Column(
                      children: [
                        _timePickerField(
                          label: "Start Time",
                          value: start,
                          onPicked: (v) => setState(() => start = v),
                        ),
                        const SizedBox(height: 10),
                        _timePickerField(
                          label: "Stop Time",
                          value: stop,
                          onPicked: (v) => setState(() => stop = v),
                        ),
                      ],
                    );
                  }

                  // 💻 NORMAL WIDTH
                  return Row(
                    children: [
                      Expanded(
                        child: _timePickerField(
                          label: "Start Time",
                          value: start, 
                          onPicked: (v) => setState(() => start = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _timePickerField(
                          label: "Stop Time",
                          value: stop,
                          onPicked: (v) => setState(() => stop = v),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: mode,
                    isExpanded: true, // ✅ IMPORTANT
                    isDense: true,    // ✅ IMPORTANT
                    dropdownColor: const Color.fromARGB(255, 138, 195, 245),
                    decoration: _decor("Mode").copyWith(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.black),
                    items: const [
                      "RTC (Fixed Start-Stop)",
                      "Run Time (Minutes)",
                      "Restricted",
                      "Auto (Dry Run Retry)"
                    ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis, // ✅ prevents overflow
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => mode = v!),
                  ),
                ),
              ],
            ),


            if (mode == "Run Time (Minutes)") ...[
              const SizedBox(height: 8),
              _input(
                "Run Time Duration (Minutes)",
                runTimeMinutes.toString(),
                (v) => setState(() {
                  runTimeMinutes = int.tryParse(v) ?? runTimeMinutes;
                }),
              ),
            ],

            if (mode == "Auto (Dry Run Retry)") ...[
              const SizedBox(height: 8),
              _input(
                "Dry Run Retry Time (Minutes)",
                retryMinutes.toString(),
                (v) => setState(() {
                  retryMinutes = int.tryParse(v) ?? retryMinutes;
                }),
              ),
            ],
            
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allDays.map((d) {
                return ChoiceChip(
                    label: Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    selected: enabled &&
                    (
                      days.contains(d) ||
                      (days.contains("All") && d != "All")
                    ),

                    selectedColor: !enabled
                      ? Colors.grey.shade900
                      : d == "All"
                          ? Colors.green
                          : Colors.blue,

                    backgroundColor: Colors.grey.shade400,

                    onSelected: (_) {
                      setState(() {
                        if (d == "All") {
                          if (days.contains("All")) {
                            days.clear();
                          } else {
                            days = {
                              "Sun","Mon","Tue","Wed","Thu","Fri","Sat","All"
                            };
                          }
                        } else {
                          days.remove("All");

                          if (days.contains(d)) {
                            days.remove(d);
                          } else {
                            days.add(d);
                          }

                          if (days.containsAll(
                            ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],
                          )) {
                            days.add("All");
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: LayoutBuilder(
                builder: (context, constraints) {

                  final screenWidth = MediaQuery.of(context).size.width;

                  // 👇 responsive width calculation
                  final maxWidth = screenWidth < 360 ? 160.0 : 200.0;
                  final normalWidth = screenWidth < 360 ? 120.0 : 140.0;
                  // final maxWidth = screenWidth * 0.45;
                  // final normalWidth = screenWidth * 0.32;


                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 36,
                      width: isApplying ? maxWidth : normalWidth,
                      child: ElevatedButton(
                        onPressed: (!isApplying) ? _onApplyPressed : null,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: isSuccess
                          //     ? const Color(0xFF22C55E)
                          //     : isError
                          //         ? Colors.red
                          //         : const Color.fromARGB(255, 67, 133, 233),
                          backgroundColor: isSuccess
                          ? Colors.green
                          : isError
                              ? Colors.red
                              : enabled
                                  ? Colors.green
                                  : Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _buildButtonChild(),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
    Future<void> _onApplyPressed() async {
    setState(() {
      isApplying = true;
      isSuccess = false;
      isError = false;
      waitSeconds = 10;
    });

    // ⏱ Countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (waitSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => waitSeconds--);
      }
    });


    try {
      await widget.onApply({
        "slot": widget.slotNumber,
        "enabled": enabled,
        "mode": mode,
        "start": start,
        "stop": stop,
        "run_time": runTimeMinutes,
        "retry_time": retryMinutes,
        "days": days.toList(),
      });


      _timer?.cancel();
        if (!mounted) return;

        setState(() {
          isApplying = false;
          isSuccess = true;
        });

    } catch (e) {
      _timer?.cancel();
        if (!mounted) return;

        setState(() {
          isApplying = false;
          isError = true;
        });

    }

    // 🔄 Reset after 2s
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isSuccess = false;
        isError = false;
      });
    }
  }



  Widget _buildButtonChild() {
    if (isApplying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Waiting ${waitSeconds}s",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (isSuccess) {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "Applied ✓",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isError) {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "Failed ✕",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        enabled ? "Apply Slot" : "Disable Slot",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _input(String label, String value, Function(String) onChanged) {
    return TextFormField(
      initialValue: value,
      style: const TextStyle(color: Colors.black),
      decoration: _decor(label),
      onChanged: onChanged,
    );
  }


//  =========== Time Picker Field =====================================
  Widget _timePickerField({
  required String label,
  required String value,
  required Function(String) onPicked,
}) {
  return InkWell(
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _parseTime(value),
        initialEntryMode: TimePickerEntryMode.dial, // ⏰ Alarm style
      );

      if (picked != null) {
        final formatted = picked.format(context);
        onPicked(formatted);
      }
    },
    child: InputDecorator(
      decoration: _decor(label),
      child: Text(
        value,
        style: const TextStyle(color: Colors.black,fontSize :13),
        
      ),
    ),
  );
}

// ============= Time parse helper ===============================
TimeOfDay _parseTime(String time) {
  final parts = time.split(RegExp(r'[: ]'));
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  bool pm = time.toUpperCase().contains("PM");

  if (pm && hour != 12) hour += 12;
  if (!pm && hour == 12) hour = 0;

  return TimeOfDay(hour: hour, minute: minute);
}

// =============================current input value===============
  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
// ===========commad working==================================
int _timeToMinutes(String time) {
  final parts = time.split(RegExp(r'[: ]'));
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  bool pm = time.toUpperCase().contains("PM");

  if (pm && hour != 12) hour += 12;
  if (!pm && hour == 12) hour = 0;

  return hour * 60 + minute;
}

int _modeToInt(String mode) {
  switch (mode) {
    case "RTC (Fixed Start-Stop)":
      return 0;
    case "Run Time (Minutes)":
      return 1;
    case "Restricted":
      return 2;
    case "Auto (Dry Run Retry)":
      return 3;
    default:
      return 0;
  }
}

int _daysToBitmask(List days) {
  final map = {
    "Sun": 1,
    "Mon": 2,
    "Tue": 4,
    "Wed": 8,
    "Thu": 16,
    "Fri": 32,
    "Sat": 64,
  };


  if (days.contains("All")) return 127;

  int mask = 0;
  for (var d in days) {
    mask |= map[d] ?? 0;
  }
  return mask;
  
}

String _intToMode(int m) {
  switch (m) {
    case 0: return "RTC (Fixed Start-Stop)";
    case 1: return "Run Time (Minutes)";
    case 2: return "Restricted";
    case 3: return "Auto (Dry Run Retry)";
    default: return "RTC (Fixed Start-Stop)";
  }
}

String _hhmmToAmPm(String t) {
  final parts = t.split(":");
  int h = int.parse(parts[0]);
  final m = parts[1];
  final suffix = h >= 12 ? "PM" : "AM";
  h = h % 12;
  if (h == 0) h = 12;
  return "$h:$m $suffix";
}

List<String> _weekdayFromBitmask(int mask) {
  final map = {
    1: "Sun",
    2: "Mon",
    4: "Tue",
    8: "Wed",
    16: "Thu",
    32: "Fri",
    64: "Sat",
  };

  // 👇 If all days or empty → treat as "All"
  if (mask == 127 || mask == 0) {
    return ["All"];
  }

  

  return map.entries
      .where((e) => mask & e.key != 0)
      .map((e) => e.value)
      .toList();
      
}
