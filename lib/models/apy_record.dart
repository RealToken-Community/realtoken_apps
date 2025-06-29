/// Modèle pour représenter les données de Rendement Annuel (APY)
class APYRecord {
  final DateTime timestamp;
  final double apy;
  final double? netApy;
  final double? grossApy;

  APYRecord({
    required this.timestamp,
    required this.apy,
    this.netApy,
    this.grossApy,
  });

  /// Crée une instance avec les anciens champs netApy et grossApy
  factory APYRecord.fromLegacy({
    required DateTime timestamp,
    required double netApy,
    required double grossApy,
  }) {
    return APYRecord(
      timestamp: timestamp,
      apy: netApy, // On utilise netApy comme valeur principale
      netApy: netApy,
      grossApy: grossApy,
    );
  }

  factory APYRecord.fromJson(Map<String, dynamic> json) {
    // Fonction helper pour convertir de manière sécurisée
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Vérifier si on est dans l'ancien format ou le nouveau
    if (json.containsKey('netApy') && json.containsKey('grossApy')) {
      // Ancien format
      return APYRecord(
        timestamp: json['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
            : DateTime.parse(json['timestamp'].toString()),
        apy:
            safeToDouble(json['netApy']), // Utiliser netApy comme apy principal
        netApy: safeToDouble(json['netApy']),
        grossApy: safeToDouble(json['grossApy']),
      );
    } else {
      // Nouveau format
      return APYRecord(
        timestamp: json['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
            : DateTime.parse(json['timestamp'].toString()),
        apy: safeToDouble(json['apy']),
        netApy: safeToDouble(json['netApy']),
        grossApy: safeToDouble(json['grossApy']),
      );
    }
  }

  Map<String, dynamic> toJson() {
    // Toujours enregistrer dans le format compatible
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'apy': apy,
      'netApy': netApy ?? apy,
      'grossApy': grossApy ?? apy,
    };
  }
}
