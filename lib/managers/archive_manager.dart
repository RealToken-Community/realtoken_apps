import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/balance_record.dart';
import '../models/roi_record.dart';
import '../models/apy_record.dart';
import '../models/healthandltv_record.dart';
import '../models/rented_record.dart';
import 'data_manager.dart';
import 'dart:convert';

class ArchiveManager {
  static final ArchiveManager _instance = ArchiveManager._internal();
  factory ArchiveManager() => _instance;
  ArchiveManager._internal();

  DataManager? _dataManager;

  void setDataManager(DataManager dataManager) {
    _dataManager = dataManager;
  }

  DateTime? lastArchiveTime;

  Future<void> archiveTotalWalletValue(double totalWalletValue) async {
    debugPrint("📊 Début de l'archivage totalWalletValue");

    // 1. D'abord, lire les données existantes dans balanceHistory
    var boxBalance = Hive.box('balanceHistory');
    List<dynamic>? balanceHistoryJson = boxBalance.get('balanceHistory_totalWalletValue');
    List<BalanceRecord> balanceHistory = balanceHistoryJson != null ? balanceHistoryJson.map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList() : [];

    debugPrint("📊 Historique balanceHistory: ${balanceHistory.length} enregistrements");

    // 2. Ensuite, lire les données existantes dans walletValueArchive
    var boxWalletValue = Hive.box('walletValueArchive');
    List<dynamic>? walletValueArchiveJson = boxWalletValue.get('balanceHistory_totalWalletValue');
    List<BalanceRecord> walletValueArchive = walletValueArchiveJson != null ? walletValueArchiveJson.map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList() : [];

    debugPrint("📊 Historique walletValueArchive: ${walletValueArchive.length} enregistrements");

    // Si l'historique existe, vérifier si on doit ajouter un nouvel enregistrement
    if (balanceHistory.isNotEmpty) {
      BalanceRecord lastRecord = balanceHistory.last;
      DateTime lastTimestamp = lastRecord.timestamp;

      if (DateTime.now().difference(lastTimestamp).inHours < 1) {
        debugPrint("⏱️ Dernière archive trop récente (< 1h), aucun nouvel enregistrement ajouté");
        return;
      }
    }

    // Créer un nouvel enregistrement
    BalanceRecord newRecord = BalanceRecord(
      tokenType: 'totalWalletValue',
      balance: double.parse(totalWalletValue.toStringAsFixed(3)),
      timestamp: DateTime.now(),
    );

    // Ajouter le nouvel enregistrement aux deux listes
    balanceHistory.add(newRecord);

    // S'assurer que walletValueArchive contient tous les enregistrements de balanceHistory
    // Pour cela, on réinitialise walletValueArchive avec le contenu de balanceHistory
    walletValueArchive = List.from(balanceHistory);

    // Maintenant sauvegarder les deux listes
    List<Map<String, dynamic>> balanceHistoryJsonToSave = balanceHistory.map((record) => record.toJson()).toList();

    List<Map<String, dynamic>> walletValueArchiveJsonToSave = walletValueArchive.map((record) => record.toJson()).toList();

    // Sauvegarder dans les deux boîtes Hive
    await boxBalance.put('balanceHistory_totalWalletValue', balanceHistoryJsonToSave);
    await boxWalletValue.put('balanceHistory_totalWalletValue', walletValueArchiveJsonToSave);

    debugPrint("✅ Archivage terminé - Nouvel enregistrement ajouté, total: ${balanceHistory.length} enregistrements");

  }

  Future<void> archiveRentedValue(double rentedValue) async {
    try {
      var box = Hive.box('rentedArchive');

      List<dynamic>? rentedHistoryJson = box.get('rented_history');
      List<RentedRecord> rentedHistory = rentedHistoryJson != null ? rentedHistoryJson.map((recordJson) => RentedRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList() : [];

      if (rentedHistory.isNotEmpty) {
        RentedRecord lastRecord = rentedHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint('Dernière archive récente, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      RentedRecord newRecord = RentedRecord(
        percentage: double.parse(rentedValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      rentedHistory.add(newRecord);

      List<Map<String, dynamic>> rentedHistoryJsonToSave = rentedHistory.map((record) => record.toJson()).toList();
      await box.put('rented_history', rentedHistoryJsonToSave);
      debugPrint('Nouvel enregistrement ROI ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage de la valeur ROI : $e');
    }
  }

  Future<void> archiveRoiValue(double roiValue) async {
    debugPrint("🗃️ Début archivage ROI: valeur=${roiValue.toStringAsFixed(3)}%");
    try {
      debugPrint('🗃️ Début archivage ROI: valeur=${roiValue.toStringAsFixed(3)}%');
      var box = Hive.box('roiValueArchive');

      List<dynamic>? roiHistoryJson = box.get('roi_history');
      
      // Vérifier si les données sont nulles et initialiser avec une liste vide si nécessaire
      if (roiHistoryJson == null) {
        debugPrint('🗃️ ROI: Aucun historique trouvé, initialisation d\'une nouvelle liste');
        roiHistoryJson = [];
      } else {
        debugPrint('🗃️ ROI: Historique existant trouvé avec ${roiHistoryJson.length} entrées');
      }
      
      List<ROIRecord> roiHistory = roiHistoryJson.map((recordJson) => 
        ROIRecord.fromJson(Map<String, dynamic>.from(recordJson))
      ).toList();

      if (roiHistory.isNotEmpty) {
        ROIRecord lastRecord = roiHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;
        Duration timeSinceLastRecord = DateTime.now().difference(lastTimestamp);

        debugPrint('🗃️ ROI: Dernier enregistrement du ${lastTimestamp.toIso8601String()} (il y a ${timeSinceLastRecord.inHours}h)');
        
        if (timeSinceLastRecord.inHours < 1) {
          debugPrint('🗃️ ROI: Dernière archive trop récente (<1h), aucun nouvel enregistrement ajouté');
          return;
        }
      } else {
        debugPrint('🗃️ ROI: Aucun enregistrement existant');
      }

      ROIRecord newRecord = ROIRecord(
        roi: double.parse(roiValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      roiHistory.add(newRecord);

      List<Map<String, dynamic>> roiHistoryJsonToSave = roiHistory.map((record) => record.toJson()).toList();
      await box.put('roi_history', roiHistoryJsonToSave);
      debugPrint('🗃️ ROI: Nouvel enregistrement ajouté avec succès, total: ${roiHistory.length} enregistrements');
      
      // Afficher quelques enregistrements pour le débogage
      if (roiHistory.isNotEmpty) {
        debugPrint('🗃️ ROI: Dernier enregistrement: ${roiHistory.last.roi}% (${roiHistory.last.timestamp.toIso8601String()})');
      }
      if (roiHistory.length > 1) {
        debugPrint('🗃️ ROI: Avant-dernier enregistrement: ${roiHistory[roiHistory.length-2].roi}% (${roiHistory[roiHistory.length-2].timestamp.toIso8601String()})');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'archivage de la valeur ROI : $e');
    }
  }

  Future<void> archiveApyValue(double netApyValue, double grossApyValue) async {
    try {
      // Utiliser la boîte correcte qui est ouverte dans main.dart
      var box = Hive.box('apyValueArchive');

      List<dynamic>? apyHistoryJson = box.get('apy_history');
      List<APYRecord> apyHistory = [];
      
      // Chargement robuste des données existantes
      if (apyHistoryJson != null) {
        for (var recordJson in apyHistoryJson) {
          try {
            // S'assurer que recordJson est bien un Map
            Map<String, dynamic> recordMap;
            if (recordJson is Map<String, dynamic>) {
              recordMap = recordJson;
            } else if (recordJson is Map) {
              recordMap = Map<String, dynamic>.from(recordJson);
            } else {
              debugPrint("⚠️ Enregistrement APY ignoré (format invalide): $recordJson");
              continue;
            }

            // Créer l'APYRecord avec gestion d'erreur
            final apyRecord = APYRecord.fromJson(recordMap);
            apyHistory.add(apyRecord);
          } catch (e) {
            debugPrint("⚠️ Erreur lors du décodage d'un enregistrement APY: $e");
            debugPrint("📄 Données problématiques: $recordJson");
            continue; // Ignorer cet enregistrement et continuer
          }
        }
      }

      // Créer le nouvel enregistrement avec timestamp actuel
      final now = DateTime.now();
      final newRecord = APYRecord.fromLegacy(
        timestamp: now,
        netApy: netApyValue,
        grossApy: grossApyValue,
      );

      // Ajouter le nouvel enregistrement
      apyHistory.add(newRecord);

      // Trier par timestamp pour maintenir l'ordre chronologique
      apyHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Convertir en JSON avec gestion sécurisée
      final apyHistoryJsonList = apyHistory.map((record) {
        try {
          return record.toJson();
        } catch (e) {
          debugPrint("⚠️ Erreur lors de la conversion JSON d'un enregistrement APY: $e");
          return null;
        }
      }).where((json) => json != null).toList();

      // Sauvegarder dans la boîte Hive
      await box.put('apy_history', apyHistoryJsonList);

      // Marquer la dernière mise à jour
      await box.put('lastApyArchiveTime', now.toIso8601String());

      debugPrint("✅ Valeur APY archivée avec succès: Net $netApyValue%, Gross $grossApyValue%");
      debugPrint("📊 Total des enregistrements APY: ${apyHistoryJsonList.length}");
      
    } catch (e) {
      debugPrint("❌ Erreur lors de l'archivage des valeurs APY : $e");
      rethrow; // Relancer l'erreur pour que le code appelant puisse la gérer
    }
  }

  Future<void> archiveBalance(String tokenType, double balance, String timestamp) async {
    try {
      var box = Hive.box('balanceHistory');

      dynamic rawData = box.get('balanceHistory_$tokenType');
      List<BalanceRecord> balanceHistory = [];

      if (rawData != null) {
        if (rawData is List) {
          balanceHistory = rawData.map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList();
        } else if (rawData is String) {
          // Si les données sont une chaîne JSON, on essaie de les parser
          try {
            List<dynamic> parsedData = json.decode(rawData);
            balanceHistory = parsedData.map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList();
          } catch (e) {
            debugPrint("⚠️ Erreur lors du parsing des données JSON pour $tokenType: $e");
          }
        }
      }

      // Conversion sécurisée de la date
      DateTime parsedTimestamp;
      try {
        parsedTimestamp = DateTime.parse(timestamp);
      } catch (e) {
        debugPrint("⚠️ Format de timestamp invalide '$timestamp', utilisation de l'heure actuelle: $e");
        parsedTimestamp = DateTime.now();
      }

      BalanceRecord newRecord = BalanceRecord(
        tokenType: tokenType,
        balance: double.parse(balance.toStringAsFixed(3)),
        timestamp: parsedTimestamp,
      );

      balanceHistory.add(newRecord);

      List<Map<String, dynamic>> balanceHistoryJsonToSave = balanceHistory.map((record) => record.toJson()).toList();
      await box.put('balanceHistory_$tokenType', balanceHistoryJsonToSave);

      debugPrint("📊 Archivage de la balance - Token: $tokenType, Balance: ${balance.toStringAsFixed(3)}, Timestamp: ${parsedTimestamp.toIso8601String()}");
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'archivage de la balance pour $tokenType : $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> archiveHealthAndLtvValue(double healtFactorValue, double ltvValue) async {
    try {
      var box = Hive.box('HealthAndLtvValueArchive');

      List<dynamic>? healthAndLtvHistoryJson = box.get('healthAndLtv_history');
      List<HealthAndLtvRecord> healthAndLtvHistory =
          healthAndLtvHistoryJson != null ? healthAndLtvHistoryJson.map((recordJson) => HealthAndLtvRecord.fromJson(Map<String, dynamic>.from(recordJson))).toList() : [];

      if (healthAndLtvHistory.isNotEmpty) {
        HealthAndLtvRecord lastRecord = healthAndLtvHistory.last;
        DateTime lastTimestamp = lastRecord.timestamp;

        if (DateTime.now().difference(lastTimestamp).inHours < 1) {
          debugPrint('Dernier enregistrement récent, aucun nouvel enregistrement ajouté.');
          return;
        }
      }

      HealthAndLtvRecord newRecord = HealthAndLtvRecord(
        healthFactor: double.parse(healtFactorValue.toStringAsFixed(3)),
        ltv: double.parse(ltvValue.toStringAsFixed(3)),
        timestamp: DateTime.now(),
      );
      healthAndLtvHistory.add(newRecord);

      List<Map<String, dynamic>> healthAndLtvHistoryJsonToSave = healthAndLtvHistory.map((record) => record.toJson()).toList();
      await box.put('healthAndLtv_history', healthAndLtvHistoryJsonToSave);

      debugPrint('Nouvel enregistrement APY ajouté et sauvegardé avec succès.');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage des valeurs APY : $e');
    }
  }

  Future<List<BalanceRecord>> getBalanceHistory(String tokenType) async {
    var box = Hive.box('balanceHistory');

    List<dynamic>? balanceHistoryJson = box.get('balanceHistory_$tokenType');
    return balanceHistoryJson!.map((recordJson) => BalanceRecord.fromJson(Map<String, dynamic>.from(recordJson))).where((record) => record.tokenType == tokenType).toList();
  }

  /// Archive la valeur de loyer actuelle
  Future<void> archiveRentValue(double percentage) async {
    // Vérifier si la boîte est ouverte ou l'ouvrir si nécessaire
    if (!Hive.isBoxOpen('rentData')) {
      await Hive.openBox('rentData');
    }
    var box = Hive.box('rentData');
    
    final timestamp = DateTime.now();
    
    // Créer un nouvel enregistrement RentRecord
    final rentRecord = RentedRecord(
      percentage: percentage,
      timestamp: timestamp,
    );
    
    // Récupérer les données existantes
    List<dynamic> existingData = box.get('rentHistory', defaultValue: []);
    List<Map<String, dynamic>> rentHistory = List<Map<String, dynamic>>.from(existingData);
    
    // Calculer le temps écoulé depuis le dernier enregistrement
    bool shouldArchive = rentHistory.isEmpty;
    if (!shouldArchive && rentHistory.isNotEmpty) {
      final lastRecord = RentedRecord.fromJson(rentHistory.last);
      final daysSinceLastRecord = timestamp.difference(lastRecord.timestamp).inDays;
      
      // Déterminer si l'archivage doit avoir lieu en fonction du nombre d'enregistrements
      if (rentHistory.length < 30) {
        // Moins de 30 enregistrements, archiver quotidiennement
        shouldArchive = daysSinceLastRecord >= 1;
      } else if (rentHistory.length < 90) {
        // Entre 30 et 90 enregistrements, archiver tous les 3 jours
        shouldArchive = daysSinceLastRecord >= 3;
      } else if (rentHistory.length < 180) {
        // Entre 90 et 180 enregistrements, archiver chaque semaine
        shouldArchive = daysSinceLastRecord >= 7;
      } else {
        // Plus de 180 enregistrements, archiver tous les 15 jours
        shouldArchive = daysSinceLastRecord >= 15;
      }
    }
    
    // Archiver la valeur si nécessaire
    if (shouldArchive) {
     // debugPrint("📊 Archivage de la valeur de loyer: $rent, cumulatif: $cumulativeRent");
      rentHistory.add(rentRecord.toJson());
      await box.put('rentHistory', rentHistory);
    }
  }
}
