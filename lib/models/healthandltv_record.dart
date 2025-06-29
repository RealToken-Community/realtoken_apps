class HealthAndLtvRecord {
  double healthFactor; // Correction ici
  double ltv;
  DateTime timestamp;

  HealthAndLtvRecord({
    required this.healthFactor, // Correction ici
    required this.ltv,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'healthFactor': healthFactor, // Correction ici
        'ltv': ltv,
        'timestamp': timestamp.toIso8601String(),
      };

  static HealthAndLtvRecord fromJson(Map<String, dynamic> json) {
    return HealthAndLtvRecord(
      healthFactor: (json['healthFactor'] ?? 0.0) as double, // Correction ici
      ltv: (json['ltv'] ?? 0.0) as double,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
