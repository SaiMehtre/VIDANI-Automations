class ProtectionConfig {
  final int index;
  int low;
  int high;
  bool enabled;

  ProtectionConfig({
    required this.index,
    required this.low,
    required this.high,
    required this.enabled,
  });

  factory ProtectionConfig.fromJson(Map<String, dynamic> json) {
    return ProtectionConfig(
      index: json['index'],
      low: json['lo'],
      high: json['hi'],
      enabled: json['en'] == 1,
    );
  }

  ProtectionConfig copy() {
    return ProtectionConfig(
      index: index,
      low: low,
      high: high,
      enabled: enabled,
    );
  }
}
