/// Modèle pour représenter les données de loyer (individuels et cumulatifs)
class RentRecord {
  final DateTime timestamp;
  final double rent;
  final double cumulativeRent;

  RentRecord({
    required this.timestamp,
    required this.rent,
    this.cumulativeRent = 0.0,
  });

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    return RentRecord(
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      rent: json['rent']?.toDouble() ?? 0.0,
      cumulativeRent: json['cumulativeRent']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'rent': rent,
      'cumulativeRent': cumulativeRent,
    };
  }
}
