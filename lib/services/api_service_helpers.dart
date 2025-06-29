import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Helpers pour factoriser les patterns répétitifs dans ApiService
class ApiServiceHelpers {
  /// Pattern générique pour fetch des données depuis plusieurs wallets
  /// Réduit la duplication de code dans fetchWalletTokens, fetchTransactionsHistory, etc.
  static Future<List<dynamic>> fetchFromMultipleWallets({
    required String debugName,
    required String Function(String wallet) urlBuilder,
    required Duration timeout,
    List<String>? customWallets,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> wallets =
        customWallets ?? prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour $debugName");
      return [];
    }

    List<dynamic> allData = [];
    int successCount = 0;
    int errorCount = 0;

    debugPrint("🔄 Récupération $debugName pour ${wallets.length} wallets");

    for (String wallet in wallets) {
      final apiUrl = urlBuilder(wallet);

      try {
        final response =
            await http.get(Uri.parse(apiUrl)).timeout(timeout, onTimeout: () {
          throw TimeoutException(
              'Délai dépassé pour $debugName du wallet $wallet');
        });

        if (response.statusCode == 200) {
          final walletData = jsonDecode(response.body);
          if (walletData is List && walletData.isNotEmpty) {
            allData.addAll(walletData);
            successCount++;
            debugPrint(
                "✅ $debugName récupéré pour wallet: $wallet (${walletData.length} éléments)");
          } else {
            debugPrint("⚠️ Aucune donnée $debugName pour wallet: $wallet");
          }
        } else {
          errorCount++;
          debugPrint(
              "❌ Erreur $debugName pour wallet $wallet: HTTP ${response.statusCode}");
        }
      } catch (e) {
        errorCount++;
        debugPrint("❌ Exception $debugName pour wallet $wallet: $e");
      }
    }

    debugPrint(
        "📊 Récapitulatif $debugName: $successCount wallets réussis, $errorCount en erreur");
    debugPrint("✅ ${allData.length} éléments $debugName récupérés au total");

    return allData;
  }

  /// Pattern générique pour fetch avec gestion des erreurs 429 et cache par wallet
  /// Utilisé pour fetchRentData, fetchDetailedRentDataForAllWallets, etc.
  static Future<List<Map<String, dynamic>>> fetchFromMultipleWalletsWithCache({
    required String debugName,
    required String Function(String wallet) urlBuilder,
    required Duration timeout,
    required Function(String wallet, List<Map<String, dynamic>> allData)
        onCacheLoad,
    required Function(String wallet, List<Map<String, dynamic>> data)
        onDataProcess,
    List<String>? customWallets,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> wallets =
        customWallets ?? prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour $debugName");
      return [];
    }

    List<Map<String, dynamic>> allData = [];
    bool hasError = false;

    debugPrint("🔄 Récupération $debugName pour ${wallets.length} wallets");

    for (String wallet in wallets) {
      final url = urlBuilder(wallet);

      try {
        debugPrint("🌐 Tentative de requête $debugName pour $wallet");

        final response =
            await http.get(Uri.parse(url)).timeout(timeout, onTimeout: () {
          throw TimeoutException('Timeout pour $debugName du wallet $wallet');
        });

        // Gestion spéciale des erreurs 429
        if (response.statusCode == 429) {
          debugPrint(
              '⚠️ 429 Too Many Requests pour $debugName du wallet $wallet');
          onCacheLoad(wallet, allData);
          hasError = true;
          break;
        }

        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> walletData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          onDataProcess(wallet, walletData);
          allData.addAll(walletData);
          debugPrint(
              "✅ $debugName récupéré pour $wallet: ${walletData.length} entrées");
        } else {
          debugPrint(
              '❌ Erreur $debugName pour $wallet: HTTP ${response.statusCode}');
          onCacheLoad(wallet, allData);
          hasError = true;
        }
      } catch (e) {
        debugPrint('❌ Exception $debugName pour $wallet: $e');
        onCacheLoad(wallet, allData);
        hasError = true;
      }
    }

    if (hasError) {
      throw Exception(
          "Erreurs rencontrées lors de la récupération de $debugName");
    }

    debugPrint('✅ $debugName terminé - ${allData.length} entrées au total');
    return allData;
  }

  /// Helper pour construire des URLs standardisées
  static String buildApiUrl(String baseUrl, String endpoint, String wallet) {
    return '$baseUrl/$endpoint/$wallet';
  }

  /// Helper pour gérer les timeouts standardisés
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration mediumTimeout = Duration(seconds: 20);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration veryLongTimeout = Duration(minutes: 2);

  /// Helper pour formater les messages de debug standardisés
  static void logApiStart(String operation, int walletCount) {
    debugPrint("🚀 Lancement $operation pour $walletCount wallets");
  }

  static void logApiSuccess(String operation, String wallet, int itemCount) {
    debugPrint("✅ $operation réussi pour $wallet: $itemCount éléments");
  }

  static void logApiError(String operation, String wallet, String error) {
    debugPrint("❌ Erreur $operation pour $wallet: $error");
  }

  static void logApiSummary(
      String operation, int successCount, int errorCount, int totalItems) {
    debugPrint(
        "📊 Récapitulatif $operation: $successCount réussis, $errorCount erreurs, $totalItems éléments total");
  }
}
