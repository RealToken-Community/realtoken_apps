class BalanceRecord {
  final double balance;
  final DateTime timestamp;

  BalanceRecord({
    required this.balance,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BalanceRecord.fromJson(Map<String, dynamic> json) {
    return BalanceRecord(
      balance: json['balance'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
