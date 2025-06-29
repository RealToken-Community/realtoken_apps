/// Modèle pour représenter les données de Retour sur Investissement (ROI)
library;

import 'package:flutter/foundation.dart'; // Pour debugPrint

class ROIRecord {
  final DateTime timestamp;
  final double roi;

  ROIRecord({
    required this.timestamp,
    required this.roi,
  });

  factory ROIRecord.fromJson(Map<String, dynamic> json) {
    // Gestion flexible du format de timestamp (millisecondes ou ISO8601)
    DateTime parsedTimestamp;
    var timestampValue = json['timestamp'];

    if (timestampValue is int) {
      // Format milliseconds
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue is String) {
      // Format ISO8601 string
      try {
        parsedTimestamp = DateTime.parse(timestampValue);
      } catch (e) {
        debugPrint("❌ Erreur lors du parsing de la date ROI: $e");
        parsedTimestamp = DateTime.now(); // Valeur par défaut
      }
    } else {
      // Valeur par défaut en cas d'erreur
      debugPrint("❌ Format de timestamp ROI non reconnu: $timestampValue");
      parsedTimestamp = DateTime.now();
    }

    return ROIRecord(
      timestamp: parsedTimestamp,
      roi: json['roi']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'roi': roi,
    };
  }
}
