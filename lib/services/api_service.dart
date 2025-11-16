import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/contracts_constants.dart';
import 'package:realtoken_asset_tracker/utils/performance_utils.dart';
import 'package:realtoken_asset_tracker/utils/cache_constants.dart';
import 'package:realtoken_asset_tracker/services/api_service_helpers.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire de santé des wallets avec circuit breaker pattern
class WalletHealthManager {
  static final WalletHealthManager _instance = WalletHealthManager._internal();
  factory WalletHealthManager() => _instance;
  WalletHealthManager._internal();

  // État de santé des wallets
  final Map<String, WalletHealthStatus> _walletHealth = {};
  
  // Configuration du circuit breaker
  static const int maxConsecutiveErrors = 3;
  static const Duration circuitBreakerDuration = Duration(minutes: 15);
  static const Duration backoffBase = Duration(seconds: 2);
  static const Duration maxBackoff = Duration(minutes: 5);

  /// Obtient le statut de santé d'un wallet
  WalletHealthStatus getWalletHealth(String wallet) {
    return _walletHealth[wallet] ?? WalletHealthStatus(wallet);
  }

  /// Met à jour le statut après une tentative
  void recordAttempt(String wallet, bool success, {String? errorType, Duration? responseTime}) {
    final status = getWalletHealth(wallet);
    final now = DateTime.now();
    
    if (success) {
      status.lastSuccess = now;
      status.consecutiveErrors = 0;
      status.totalSuccesses++;
      status.isInCircuitBreaker = false;
      if (responseTime != null) {
        status.averageResponseTime = status.averageResponseTime == null 
          ? responseTime 
          : Duration(milliseconds: (status.averageResponseTime!.inMilliseconds * 0.7 + responseTime.inMilliseconds * 0.3).round());
      }
      debugPrint("✅ Wallet $wallet: Succès (${status.totalSuccesses} succès, temps moyen: ${status.averageResponseTime?.inMilliseconds}ms)");
    } else {
      status.lastError = now;
      status.consecutiveErrors++;
      status.totalErrors++;
      status.lastErrorType = errorType ?? 'unknown';
      
      // Activer le circuit breaker si trop d'erreurs consécutives
      if (status.consecutiveErrors >= maxConsecutiveErrors) {
        status.isInCircuitBreaker = true;
        status.circuitBreakerUntil = now.add(circuitBreakerDuration);
        debugPrint("🚨 Circuit breaker activé pour wallet $wallet (${status.consecutiveErrors} erreurs consécutives)");
      }
      
      debugPrint("❌ Wallet $wallet: Erreur $errorType (${status.consecutiveErrors} consécutives, ${status.totalErrors} total)");
    }
    
    status.lastAttempt = now;
    _walletHealth[wallet] = status;
  }

  /// Vérifie si un wallet peut être traité (circuit breaker)
  bool canProcessWallet(String wallet) {
    final status = getWalletHealth(wallet);
    final now = DateTime.now();
    
    if (status.isInCircuitBreaker) {
      if (status.circuitBreakerUntil != null && now.isAfter(status.circuitBreakerUntil!)) {
        // Réinitialiser le circuit breaker
        status.isInCircuitBreaker = false;
        status.circuitBreakerUntil = null;
        status.consecutiveErrors = 0;
        debugPrint("🔄 Circuit breaker réinitialisé pour wallet $wallet");
        return true;
      }
      debugPrint("🚫 Wallet $wallet en circuit breaker jusqu'à ${status.circuitBreakerUntil}");
      return false;
    }
    
    return true;
  }

  /// Calcule le délai de backoff adaptatif
  Duration getBackoffDelay(String wallet) {
    final status = getWalletHealth(wallet);
    if (status.consecutiveErrors == 0) return Duration.zero;
    
    // Backoff exponentiel avec jitter
    final baseDelay = backoffBase.inMilliseconds * (1 << (status.consecutiveErrors - 1));
    final jitter = (baseDelay * 0.1).round(); // 10% de jitter
    final finalDelay = baseDelay + (DateTime.now().millisecondsSinceEpoch % jitter);
    
    return Duration(milliseconds: finalDelay.clamp(0, maxBackoff.inMilliseconds));
  }

  /// Trie les wallets par priorité (succès rate, temps de réponse, etc.)
  List<String> prioritizeWallets(List<String> wallets) {
    final List<MapEntry<String, double>> walletScores = [];
    
    for (String wallet in wallets) {
      final status = getWalletHealth(wallet);
      double score = 0.0;
      
      // Score basé sur le taux de succès
      final totalAttempts = status.totalSuccesses + status.totalErrors;
      if (totalAttempts > 0) {
        score += (status.totalSuccesses / totalAttempts) * 50; // 0-50 points
      } else {
        score += 25; // Score neutre pour les nouveaux wallets
      }
      
      // Bonus pour les temps de réponse rapides
      if (status.averageResponseTime != null) {
        final responseTimeScore = (5000 - status.averageResponseTime!.inMilliseconds).clamp(0, 2500) / 50;
        score += responseTimeScore; // 0-50 points
      }
      
      // Pénalité pour les erreurs récentes
      if (status.lastError != null) {
        final hoursSinceLastError = DateTime.now().difference(status.lastError!).inHours;
        if (hoursSinceLastError < 24) {
          score -= (24 - hoursSinceLastError) * 2; // Pénalité décroissante
        }
      }
      
      // Pénalité pour le circuit breaker
      if (status.isInCircuitBreaker) {
        score -= 100;
      }
      
      walletScores.add(MapEntry(wallet, score));
    }
    
    // Trier par score décroissant
    walletScores.sort((a, b) => b.value.compareTo(a.value));
    final prioritizedWallets = walletScores.map((e) => e.key).toList();
    
    debugPrint("📊 Priorisation des wallets : ${prioritizedWallets.take(3).join(', ')} (top 3)");
    return prioritizedWallets;
  }

  /// Obtient les statistiques globales
  Map<String, dynamic> getHealthStats() {
    if (_walletHealth.isEmpty) return {};
    
    final stats = <String, dynamic>{};
    final statuses = _walletHealth.values.toList();
    
    stats['totalWallets'] = statuses.length;
    stats['healthyWallets'] = statuses.where((s) => !s.isInCircuitBreaker && s.consecutiveErrors == 0).length;
    stats['inCircuitBreaker'] = statuses.where((s) => s.isInCircuitBreaker).length;
    stats['withErrors'] = statuses.where((s) => s.consecutiveErrors > 0).length;
    
    final totalSuccesses = statuses.fold<int>(0, (sum, s) => sum + s.totalSuccesses);
    final totalErrors = statuses.fold<int>(0, (sum, s) => sum + s.totalErrors);
    final totalAttempts = totalSuccesses + totalErrors;
    
    if (totalAttempts > 0) {
      stats['globalSuccessRate'] = (totalSuccesses / totalAttempts * 100).toStringAsFixed(1);
    }
    
    return stats;
  }
}

/// Status de santé d'un wallet individuel
class WalletHealthStatus {
  final String wallet;
  
  // Statistiques temporelles
  DateTime? lastAttempt;
  DateTime? lastSuccess;
  DateTime? lastError;
  
  // Compteurs
  int consecutiveErrors = 0;
  int totalSuccesses = 0;
  int totalErrors = 0;
  
  // Performance
  Duration? averageResponseTime;
  
  // Circuit breaker
  bool isInCircuitBreaker = false;
  DateTime? circuitBreakerUntil;
  
  // Diagnostic
  String? lastErrorType;
  
  WalletHealthStatus(this.wallet);
}

/// Classification des erreurs pour un traitement adapté
enum ErrorType {
  temporary, // 429, timeout, network issues
  permanent, // 404, invalid wallet
  server,    // 500, 502, 503
  unknown
}

class ErrorClassifier {
  static ErrorType classifyError(dynamic error, int? statusCode) {
    if (statusCode != null) {
      switch (statusCode) {
        case 429: // Rate limit
        case 503: // Service unavailable
        case 502: // Bad gateway
          return ErrorType.temporary;
        case 404: // Not found
        case 400: // Bad request
          return ErrorType.permanent;
        case 500: // Internal server error
          return ErrorType.server;
        default:
          if (statusCode >= 500) return ErrorType.server;
          if (statusCode >= 400) return ErrorType.permanent;
      }
    }
    
    if (error is TimeoutException) return ErrorType.temporary;
    if (error is SocketException) return ErrorType.temporary;
    if (error is HttpException) return ErrorType.temporary;
    if (error is FormatException) return ErrorType.permanent;
    
    return ErrorType.unknown;
  }
  
  static bool shouldRetry(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.temporary:
      case ErrorType.server:
      case ErrorType.unknown:
        return true;
      case ErrorType.permanent:
        return false;
    }
  }
  
  static Duration getRetryDelay(ErrorType errorType, int attemptNumber) {
    switch (errorType) {
      case ErrorType.temporary:
        return Duration(seconds: [1, 3, 8, 20][attemptNumber.clamp(0, 3)]);
      case ErrorType.server:
        return Duration(seconds: [2, 5, 15, 45][attemptNumber.clamp(0, 3)]);
      case ErrorType.unknown:
        return Duration(seconds: [1, 2, 5, 10][attemptNumber.clamp(0, 3)]);
      case ErrorType.permanent:
        return Duration.zero;
    }
  }
}

class ApiService {
  // Constantes pour les timeouts améliorés
  static const Duration _shortTimeout = Duration(seconds: 15);  // Augmenté de 10 à 15 secondes
  static const Duration _mediumTimeout = Duration(seconds: 30); // Augmenté de 20 à 30 secondes
  static const Duration _longTimeout = Duration(seconds: 45);   // Augmenté de 30 à 45 secondes
  static const Duration _veryLongTimeout = Duration(minutes: 2);
  
  // Nouvelles constantes pour la stratégie de retry
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Pool de clients HTTP réutilisables
  static final http.Client _httpClient = http.Client();

  /// Méthode pour effectuer une requête HTTP avec retry automatique et gestion intelligente des erreurs
  static Future<http.Response> _httpGetWithRetry(String url, {
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
    String? debugContext,
    String? walletAddress, // Nouveau paramètre pour tracking
  }) async {
    int attempt = 0;
    final startTime = DateTime.now();
    final healthManager = WalletHealthManager();
    
    while (attempt <= maxRetries) {
      try {
        // Appliquer le backoff adaptatif si un wallet est spécifié
        if (attempt > 0) {
          Duration delay = retryDelay * attempt; // Délai de base
          
          if (walletAddress != null) {
            // Utiliser le délai adaptatif basé sur l'historique du wallet
            final adaptiveDelay = healthManager.getBackoffDelay(walletAddress);
            delay = adaptiveDelay.inMilliseconds > 0 ? adaptiveDelay : delay;
          }
          
          debugPrint("🔄 Tentative ${attempt + 1}/${maxRetries + 1} pour ${debugContext ?? 'requête'} (délai: ${delay.inSeconds}s)");
          await Future.delayed(delay);
        }
        
        final attemptStartTime = DateTime.now();
        final response = await _httpClient.get(Uri.parse(url))
            .timeout(timeout, onTimeout: () {
          throw TimeoutException('Timeout après ${timeout.inSeconds}s pour ${debugContext ?? url}');
        });
        
        final responseTime = DateTime.now().difference(attemptStartTime);
        
        // Enregistrer le succès si wallet spécifié
        if (walletAddress != null) {
          healthManager.recordAttempt(walletAddress, true, responseTime: responseTime);
        }
        
        // Log de performance pour surveillance
        if (responseTime.inMilliseconds > 5000) {
          debugPrint("⚠️ Réponse lente pour ${debugContext ?? 'requête'}: ${responseTime.inMilliseconds}ms");
        }
        
        return response;
        
      } catch (e) {
        attempt++;
        final errorType = ErrorClassifier.classifyError(e, null);
        
        // Enregistrer l'erreur si wallet spécifié
        if (walletAddress != null) {
          healthManager.recordAttempt(walletAddress, false, errorType: errorType.toString());
        }
        
        // Déterminer si on doit continuer les tentatives
        final shouldRetry = attempt <= maxRetries && ErrorClassifier.shouldRetry(errorType);
        
        if (!shouldRetry) {
          final totalTime = DateTime.now().difference(startTime);
          debugPrint("❌ Échec définitif ${debugContext ?? 'requête'} après $attempt tentatives (${totalTime.inMilliseconds}ms): $e");
          rethrow;
        }
        
        debugPrint("⚠️ Tentative $attempt échouée pour ${debugContext ?? 'requête'} (type: $errorType): $e");
      }
    }
    
    throw Exception('Nombre maximum de tentatives atteint');
  }
  
  /// Détermine si une erreur est récupérable avec un retry (méthode legacy, utiliser ErrorClassifier maintenant)
  static bool _isRetryableError(dynamic error) {
    final errorType = ErrorClassifier.classifyError(error, null);
    return ErrorClassifier.shouldRetry(errorType);
  }

  /// Accès public aux statistiques de santé des wallets
  static Map<String, dynamic> getWalletHealthStats() {
    return WalletHealthManager().getHealthStats();
  }

  /// Accès public pour vérifier si un wallet peut être traité
  static bool canProcessWallet(String wallet) {
    return WalletHealthManager().canProcessWallet(wallet);
  }

  /// Accès public pour obtenir les statistiques d'un wallet spécifique
  static WalletHealthStatus getWalletStatus(String wallet) {
    return WalletHealthManager().getWalletHealth(wallet);
  }

  /// Méthode pour réinitialiser le circuit breaker d'un wallet (utile pour debug/admin)
  static void resetWalletCircuitBreaker(String wallet) {
    final healthManager = WalletHealthManager();
    final status = healthManager.getWalletHealth(wallet);
    status.isInCircuitBreaker = false;
    status.circuitBreakerUntil = null;
    status.consecutiveErrors = 0;
    debugPrint("🔄 Circuit breaker réinitialisé manuellement pour wallet $wallet");
  }

  /// Traite plusieurs wallets en parallèle avec un pool de tâches concurrentes
  static Future<List<T>> _processWalletsInParallel<T>({
    required List<String> wallets,
    required Future<T?> Function(String wallet) processWallet,
    required String debugName,
    int maxConcurrentRequests = 3, // Limite conservatrice pour éviter les 429
  }) async {
    if (wallets.isEmpty) return [];

    List<T> results = [];
    int processedCount = 0;
    int successCount = 0;
    int errorCount = 0;

    debugPrint("🚀 Traitement parallèle $debugName pour ${wallets.length} wallets (max $maxConcurrentRequests simultanés)");

    // Traiter les wallets par chunks pour éviter de surcharger le serveur
    for (int i = 0; i < wallets.length; i += maxConcurrentRequests) {
      final chunk = wallets.skip(i).take(maxConcurrentRequests).toList();
      
      // Traitement parallèle du chunk actuel
      final futures = chunk.map((wallet) async {
        try {
          final result = await processWallet(wallet);
          if (result != null) {
            successCount++;
            return result;
          } else {
            errorCount++;
            debugPrint("⚠️ Aucune donnée pour wallet $wallet");
            return null;
          }
        } catch (e) {
          errorCount++;
          debugPrint("❌ Erreur traitement wallet $wallet: $e");
          return null;
        }
      });

      // Attendre que tous les wallets du chunk soient traités
      final chunkResults = await Future.wait(futures);
      
      // Ajouter les résultats non-null à la liste finale
      results.addAll(chunkResults.where((result) => result != null).cast<T>());
      
      processedCount += chunk.length;
      debugPrint("📊 Progression $debugName: ${processedCount}/${wallets.length} wallets traités");

      // Petite pause entre les chunks pour être gentil avec le serveur
      if (i + maxConcurrentRequests < wallets.length) {
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    debugPrint("✅ Traitement parallèle $debugName terminé: $successCount réussis, $errorCount erreurs");
    return results;
  }

  /// Méthode générique optimisée pour gérer le cache avec fallback automatique
  /// Support des types: List<dynamic>, Map<String, dynamic>, String, etc.
  static Future<T> _fetchWithCache<T>({
    required String cacheKey,
    required Future<T> Function() apiCall,
    required String debugName,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    required T emptyValue,
    bool forceFetch = false,
    String? alternativeCacheKey,
    Duration? customCacheDuration,
    Future<bool> Function()? shouldUpdate,
  }) async {
    final box = Hive.box('realTokens');
    final DateTime now = DateTime.now();
    final lastFetchTime = box.get('lastFetchTime_$cacheKey');
    final cacheDuration = customCacheDuration ?? Parameters.apiCacheDuration;

    // 1. Toujours tenter de charger le cache d'abord
    T? cachedResult;
    try {
      var cachedData = box.get(cacheKey);
      if (cachedData == null && alternativeCacheKey != null) {
        cachedData = box.get(alternativeCacheKey);
      }
      
      if (cachedData != null) {
        cachedResult = fromJson(cachedData is String ? jsonDecode(cachedData) : cachedData);
        debugPrint("🔵 Cache $debugName disponible");
      }
    } catch (e) {
      debugPrint("⚠️ Erreur décodage cache $debugName: $e");
    }

    // 2. Vérifier si une mise à jour est nécessaire
    bool needsUpdate = forceFetch;
    if (!needsUpdate && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      needsUpdate = now.difference(lastFetch) >= cacheDuration;
    } else if (lastFetchTime == null) {
      needsUpdate = true;
    }

    // 3. Vérifier les conditions personnalisées de mise à jour
    if (!needsUpdate && shouldUpdate != null) {
      try {
        needsUpdate = await shouldUpdate();
      } catch (e) {
        debugPrint("⚠️ Erreur vérification shouldUpdate pour $debugName: $e");
      }
    }

    // 4. Si pas besoin de mise à jour et cache disponible, retourner le cache
    if (!needsUpdate && cachedResult != null) {
      debugPrint("✅ Cache $debugName valide utilisé");
      return cachedResult;
    }

    // 5. Tentative de mise à jour via API
    try {
      debugPrint("🔄 Mise à jour $debugName depuis l'API...");
      final apiResult = await apiCall();
      
      if (apiResult != null && apiResult != emptyValue) {
        // Sauvegarder le nouveau cache
        final jsonData = toJson(apiResult);
        await box.put(cacheKey, jsonData is String ? jsonData : jsonEncode(jsonData));
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        await box.put('lastExecutionTime_$debugName', now.toIso8601String());
        debugPrint("💾 $debugName mis à jour depuis l'API");
        return apiResult;
      } else {
        debugPrint("⚠️ API $debugName a retourné des données vides");
      }
    } catch (e) {
      debugPrint("❌ Erreur API $debugName: $e");
    }

    // 6. Fallback sur le cache si disponible
    if (cachedResult != null) {
      debugPrint("🔄 Utilisation du cache $debugName suite à erreur API");
      return cachedResult;
    }

    // 7. Dernier recours : valeur par défaut
    debugPrint("❌ Aucune donnée disponible pour $debugName, utilisation valeur par défaut");
    return emptyValue;
  }

  /// Version simplifiée pour les listes (compatibilité descendante)
  static Future<List<dynamic>> _fetchWithCacheList({
    required String cacheKey,
    required Future<List<dynamic>> Function() apiCall,
    required String debugName,
    bool forceFetch = false,
    String? alternativeCacheKey,
    Duration? customCacheDuration,
    Future<bool> Function()? shouldUpdate,
  }) async {
    return _fetchWithCache<List<dynamic>>(
      cacheKey: cacheKey,
      apiCall: apiCall,
      debugName: debugName,
      fromJson: (data) => List<dynamic>.from(data),
      toJson: (data) => data,
      emptyValue: <dynamic>[],
      forceFetch: forceFetch,
      alternativeCacheKey: alternativeCacheKey,
      customCacheDuration: customCacheDuration,
      shouldUpdate: shouldUpdate,
    );
  }

  /// Récupère toutes les adresses associées à une adresse Ethereum via FastAPI
  static Future<Map<String, dynamic>?> fetchUserAndAddresses(String address) async {
    final apiUrl = "${Parameters.mainApiUrl}/wallet_userId/$address";

    debugPrint("📡 Envoi de la requête à FastAPI: $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("📩 Réponse reçue: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("📝 Données reçues: $data");

        if (data['status'] == "success") {
          return {
            "userId": data['userId'],
            "addresses": List<String>.from(data['addresses']),
          };
        } else {
          debugPrint("⚠️ Aucun userId trouvé pour l'adresse $address");
          return null;
        }
      } else {
        debugPrint("❌ Erreur HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception dans fetchUserAndAddresses: $e");
      return null;
    }
  }

  // Méthode factorisée pour fetch les tokens depuis The Graph avec cache optimisé
  static Future<List<dynamic>> fetchWalletTokens({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTokenData_wallet_tokens',
      alternativeCacheKey: 'cachedTokenData_tokens',
      debugName: "Wallet Tokens",
      forceFetch: forceFetch,
      apiCall: () async {
        // Utiliser le traitement parallèle pour réduire le temps de récupération
        final allTokenResults = await _processWalletsInParallel<List<dynamic>>(
          wallets: evmAddresses,
          debugName: "récupération tokens",
          maxConcurrentRequests: 2, // Limite conservatrice pour l'API tokens
          processWallet: (wallet) async {
            final apiUrl = '${Parameters.mainApiUrl}/wallet_tokens/$wallet';
            debugPrint("🔄 Récupération des tokens pour le wallet: $wallet");

            final response = await _httpGetWithRetry(
              apiUrl,
              timeout: _shortTimeout,
              debugContext: "tokens wallet $wallet",
            );

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              if (walletData is List && walletData.isNotEmpty) {
                debugPrint("✅ ${walletData.length} tokens récupérés pour le wallet $wallet");
                return walletData;
              } else {
                debugPrint("⚠️ Aucun token trouvé pour le wallet $wallet");
                return <dynamic>[];
              }
            } else {
              debugPrint("❌ Erreur récupération tokens wallet $wallet: Code HTTP ${response.statusCode}");
              return null; // Sera filtré par _processWalletsInParallel
            }
          },
        );

        // Fusionner tous les résultats
        List<dynamic> allWalletTokens = [];
        for (var tokenList in allTokenResults) {
          allWalletTokens.addAll(tokenList);
        }

        debugPrint("📊 Récapitulatif: ${allWalletTokens.length} tokens récupérés au total");
        return allWalletTokens;
      },
    );
  }

  // Récupérer la liste complète des RealTokens depuis l'API pitswap avec cache optimisé
  static Future<List<dynamic>> fetchRealTokens({bool forceFetch = false}) async {
    debugPrint("🚀 apiService: fetchRealTokens -> Lancement de la requête");

    final box = Hive.box('realTokens');
    
    return _fetchWithCacheList(
      cacheKey: 'cachedRealTokens',
      debugName: "RealTokens",
      forceFetch: forceFetch,
      shouldUpdate: () async {
        // Logique spécifique : vérifier les timestamps serveur
        if (forceFetch) return true;
        
        try {
          final lastUpdateTime = box.get('lastUpdateTime_RealTokens');
          if (lastUpdateTime == null) return true;

          // Vérification de la dernière mise à jour sur le serveur
          final lastUpdateResponse = await http.get(
            Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens_mobileapps')
          ).timeout(Duration(seconds: 10));

          if (lastUpdateResponse.statusCode == 200) {
            final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
            final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);
            final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
            
            bool needsUpdate = !lastExecutionDate.isAtSameMomentAs(lastUpdateDate);
            if (!needsUpdate) {
              debugPrint("✅ Données RealTokens déjà à jour selon le serveur");
            }
            return needsUpdate;
          }
        } catch (e) {
          debugPrint("⚠️ Erreur vérification timestamp serveur RealTokens: $e");
        }
        return false; // En cas d'erreur, ne pas forcer la mise à jour
      },
      apiCall: () async {
        // Récupérer les nouvelles données
        final response = await http.get(
          Uri.parse('${Parameters.realTokensUrl}/realTokens_mobileapps')
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Sauvegarder le timestamp serveur spécifique à RealTokens
          try {
            final lastUpdateResponse = await http.get(
              Uri.parse('${Parameters.realTokensUrl}/last_get_realTokens_mobileapps')
            ).timeout(Duration(seconds: 5));
            
            if (lastUpdateResponse.statusCode == 200) {
              final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
              await box.put('lastUpdateTime_RealTokens', lastUpdateDateString);
            }
          } catch (e) {
            debugPrint("⚠️ Erreur sauvegarde timestamp RealTokens: $e");
          }
          
          debugPrint("💾 RealTokens mis à jour: ${data.length} tokens");
          return data;
        } else {
          throw Exception("Erreur HTTP ${response.statusCode} lors de la récupération des RealTokens");
        }
      },
    );
  }

  // Récupérer la liste complète des offres YAM depuis l'API avec cache optimisé
  static Future<List<dynamic>> fetchYamMarket({bool forceFetch = false}) async {
    final box = Hive.box('realTokens');
    
    return _fetchWithCacheList(
      cacheKey: 'cachedYamMarket',
      debugName: "YAM Market",
      forceFetch: forceFetch,
      shouldUpdate: () async {
        // Logique spécifique : vérifier les timestamps serveur YAM
        if (forceFetch) return true;
        
        try {
          final lastUpdateTime = box.get('lastUpdateTime_YamMarket');
          if (lastUpdateTime == null) return true;

          // Vérification de la dernière mise à jour sur le serveur
          final lastUpdateResponse = await http.get(
            Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers_mobileapps')
          ).timeout(Duration(seconds: 10));

          if (lastUpdateResponse.statusCode == 200) {
            final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
            final DateTime lastUpdateDate = DateTime.parse(lastUpdateDateString);
            final DateTime lastExecutionDate = DateTime.parse(lastUpdateTime);
            
            bool needsUpdate = !lastExecutionDate.isAtSameMomentAs(lastUpdateDate);
            if (!needsUpdate) {
              debugPrint("✅ Données YAM Market déjà à jour selon le serveur");
            }
            return needsUpdate;
          }
        } catch (e) {
          debugPrint("⚠️ Erreur vérification timestamp serveur YAM Market: $e");
        }
        return false; // En cas d'erreur, ne pas forcer la mise à jour
      },
      apiCall: () async {
        // Récupérer les nouvelles données YAM
        final response = await http.get(
          Uri.parse('${Parameters.realTokensUrl}/get_yam_offers_mobileapps')
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Sauvegarder le timestamp serveur spécifique à YAM Market
          try {
            final lastUpdateResponse = await http.get(
              Uri.parse('${Parameters.realTokensUrl}/last_update_yam_offers_mobileapps')
            ).timeout(Duration(seconds: 5));
            
            if (lastUpdateResponse.statusCode == 200) {
              final String lastUpdateDateString = json.decode(lastUpdateResponse.body);
              await box.put('lastUpdateTime_YamMarket', lastUpdateDateString);
            }
          } catch (e) {
            debugPrint("⚠️ Erreur sauvegarde timestamp YAM Market: $e");
          }
          
          debugPrint("💾 YAM Market mis à jour: ${data.length} offres");
          return data;
        } else {
          throw Exception("Erreur HTTP ${response.statusCode} lors de la récupération du YAM Market");
        }
      },
    );
  }
  // Récupérer les données de loyer pour chaque wallet et les fusionner avec cache et gestion intelligente

  static Future<List<Map<String, dynamic>>> fetchRentData({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Ne pas exécuter si la liste des wallets est vide
    }

    final box = Hive.box('realTokens');
    final DateTime now = DateTime.now();
    final healthManager = WalletHealthManager();
    
    // Calculer le début de la semaine actuelle (lundi)
    final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime startOfCurrentWeekMidnight = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
    
    // TOUJOURS commencer par charger les données existantes de tous les wallets
    debugPrint("📦 Chargement des données existantes pour tous les wallets");
    List<Map<String, dynamic>> mergedRentData = [];
    await _loadRentDataFromCache(box, wallets).then((cachedData) {
      mergedRentData.addAll(cachedData);
      debugPrint("📦 ${mergedRentData.length} entrées chargées depuis le cache");
      
      // Diagnostic anti-doublons : vérifier les totaux
      double totalRentFromCache = 0;
      for (var entry in mergedRentData) {
        totalRentFromCache += (entry['rent'] ?? 0).toDouble();
      }
      debugPrint("📊 Total rent depuis cache: \$${totalRentFromCache.toStringAsFixed(2)}");
    });
    
    // Vérifier si une réponse 429 a été reçue récemment
    final last429Time = box.get('lastRent429Time');
    if (last429Time != null && !forceFetch) {
      final DateTime last429 = DateTime.parse(last429Time);
      if (now.difference(last429) < Duration(minutes: 5)) {
        debugPrint('⚠️ 429 reçu récemment, utilisation des données existantes');
        return mergedRentData;
      }
    }

    // Filtrer les wallets selon leur état de santé (circuit breaker)
    final List<String> healthyWallets = wallets.where((wallet) => 
      healthManager.canProcessWallet(wallet)
    ).toList();
    
    final int unhealthyCount = wallets.length - healthyWallets.length;
    if (unhealthyCount > 0) {
      debugPrint("🚫 $unhealthyCount wallets en circuit breaker, traitement de ${healthyWallets.length} wallets sains");
    }

    // Vérifier si tous les wallets sains ont été traités cette semaine ET ont un cache valide
    bool allHealthyWalletsProcessed = true;
    for (String wallet in healthyWallets) {
      final lastSuccessKey = 'lastRentSuccess_$wallet';
      final lastSuccessTime = box.get(lastSuccessKey);
      final cacheKey = 'cachedRentData_$wallet';
      final cachedData = box.get(cacheKey);
      
      if (lastSuccessTime == null || cachedData == null) {
        debugPrint("❌ Wallet $wallet: pas de succès récent ou cache manquant");
        allHealthyWalletsProcessed = false;
        break;
      } else {
        final DateTime lastSuccess = DateTime.parse(lastSuccessTime);
        if (!lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
          debugPrint("❌ Wallet $wallet: succès trop ancien");
          allHealthyWalletsProcessed = false;
          break;
        }
        
        // Vérifier que le cache n'est pas vide ou corrompu
        try {
          final List<dynamic> cacheContent = json.decode(cachedData);
          if (cacheContent.isEmpty) {
            debugPrint("❌ Wallet $wallet: cache vide");
            allHealthyWalletsProcessed = false;
            break;
          }
        } catch (e) {
          debugPrint("❌ Wallet $wallet: cache corrompu - $e");
          allHealthyWalletsProcessed = false;
          break;
        }
      }
    }
    
    // Vérifier si la dernière mise à jour réussie est trop ancienne (plus de 7 jours)
    final lastSuccessfulFetch = box.get('lastSuccessfulRentFetch');
    bool isDataTooOld = false;
    if (lastSuccessfulFetch != null) {
      final DateTime lastSuccess = DateTime.parse(lastSuccessfulFetch);
      isDataTooOld = now.difference(lastSuccess) > Duration(days: 7);
    } else {
      isDataTooOld = true; // Pas de fetch réussi enregistré
    }
    
    // Si tous les wallets sains sont traités ET qu'on n'est pas mardi ET pas de forceFetch ET que les données ne sont pas trop anciennes, utiliser le cache
    final bool isTuesday = now.weekday == DateTime.tuesday;
    if (allHealthyWalletsProcessed && !isTuesday && !forceFetch && !isDataTooOld) {
      debugPrint("🛑 Tous les wallets sains traités cette semaine, utilisation des données existantes");
      
      // Afficher les statistiques de santé
      final healthStats = healthManager.getHealthStats();
      if (healthStats.isNotEmpty) {
        debugPrint("📊 Santé des wallets: ${healthStats['healthyWallets']}/${healthStats['totalWallets']} sains, ${healthStats['globalSuccessRate'] ?? 'N/A'}% succès global");
      }
      
      return mergedRentData;
    }
    
    if (isDataTooOld) {
      debugPrint("⏰ Données trop anciennes (>7 jours), forçage de la mise à jour");
    }
    
    debugPrint("🔄 Certains wallets non traités ou c'est mardi, traitement nécessaire");

    // Sauvegarder les données existantes comme backup
    final Map<String, List<Map<String, dynamic>>> existingDataByWallet = {};
    for (String wallet in healthyWallets) {
      existingDataByWallet[wallet] = await _loadRentDataFromCacheForWallet(box, wallet);
    }

    // Prioriser les wallets selon leur historique de performance
    final List<String> prioritizedWallets = healthManager.prioritizeWallets(healthyWallets);
    
    List<String> walletsToProcess = [];
    List<String> successfulWallets = [];

    // Identifier les wallets à traiter parmi les wallets priorisés
    for (String wallet in prioritizedWallets) {
      final lastSuccessKey = 'lastRentSuccess_$wallet';
      final lastSuccessTime = box.get(lastSuccessKey);
      final cacheKey = 'cachedRentData_$wallet';
      final cachedData = box.get(cacheKey);
      
      if (lastSuccessTime != null && cachedData != null && !forceFetch) {
        final DateTime lastSuccess = DateTime.parse(lastSuccessTime);
        if (lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
          // Vérifier que le cache est valide
          try {
            final List<dynamic> cacheContent = json.decode(cachedData);
            if (cacheContent.isNotEmpty) {
              debugPrint("✅ Wallet $wallet déjà traité cette semaine avec cache valide");
              successfulWallets.add(wallet);
              continue;
            } else {
              debugPrint("⚠️ Wallet $wallet: cache vide, retraitement nécessaire");
            }
          } catch (e) {
            debugPrint("⚠️ Wallet $wallet: cache corrompu, retraitement nécessaire - $e");
          }
        }
      }
      walletsToProcess.add(wallet);
    }

    debugPrint("🚀 ${walletsToProcess.length} wallets à traiter, ${successfulWallets.length} déjà traités");

    // Traiter les wallets un par un avec gestion intelligente des erreurs
    int processedCount = 0;
    int errorCount = 0;
    
    for (String wallet in walletsToProcess) {
      final url = '${Parameters.rentTrackerUrl}/rent_holder/$wallet';
      
      try {
        debugPrint("🔄 Traitement du wallet: $wallet (${processedCount + 1}/${walletsToProcess.length})");
        
        final response = await _httpGetWithRetry(
          url,
          timeout: _mediumTimeout,
          debugContext: "données de loyer wallet $wallet",
          walletAddress: wallet, // Nouveau paramètre pour tracking
        );

        if (response.statusCode == 429) {
          debugPrint('⚠️ 429 Too Many Requests pour le wallet $wallet - conservation des données existantes');
          await box.put('lastRent429Time', now.toIso8601String());
          break; // Arrêter le traitement mais conserver les données existantes
        }

        if (response.statusCode == 200) {
          debugPrint("✅ RentTracker, requête réussie pour $wallet");

          List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(
            json.decode(response.body)
          );
          
          // Retirer TOUTES les anciennes données de ce wallet du merge global
          Set<String> walletDates = Set<String>();
          if (existingDataByWallet[wallet] != null) {
            for (var existing in existingDataByWallet[wallet]!) {
              walletDates.add(existing['date']);
            }
          }
          
          // Supprimer toutes les entrées correspondant aux dates de ce wallet
          mergedRentData.removeWhere((entry) => walletDates.contains(entry['date']));
          
          // Traiter et ajouter les nouvelles données
          List<Map<String, dynamic>> processedData = [];
          Map<String, double> walletDateRentMap = {}; // Éviter les doublons pour ce wallet
          
          for (var rentEntry in rentData) {
            DateTime rentDate = DateTime.parse(rentEntry['date']);
            rentDate = rentDate.add(Duration(days: 1));
            String updatedDate = "${rentDate.year}-${rentDate.month.toString().padLeft(2, '0')}-${rentDate.day.toString().padLeft(2, '0')}";

            // Cumuler les rents pour la même date dans ce wallet
            double rentAmount = (rentEntry['rent'] ?? 0).toDouble();
            walletDateRentMap[updatedDate] = (walletDateRentMap[updatedDate] ?? 0) + rentAmount;
          }
          
          // Ajouter les nouvelles données consolidées au merge global
          for (var entry in walletDateRentMap.entries) {
            String date = entry.key;
            double walletRentForDate = entry.value;
            
            // Vérifier s'il existe déjà une entrée pour cette date (autres wallets)
            final existingEntry = mergedRentData.firstWhere(
              (entry) => entry['date'] == date,
              orElse: () => <String, dynamic>{},
            );

            if (existingEntry.isNotEmpty) {
              // Ajouter le rent de ce wallet au total existant (autres wallets)
              existingEntry['rent'] = (existingEntry['rent'] ?? 0) + walletRentForDate;
            } else {
              // Créer une nouvelle entrée pour cette date
              mergedRentData.add({
                'date': date,
                'rent': walletRentForDate,
              });
            }
            
            // Sauvegarder les données brutes pour le cache par wallet
            processedData.add({
              'date': date,
              'rent': walletRentForDate,
            });
          }

          // Sauvegarder le cache pour ce wallet avec vérification
          final saveSuccess = await _safeCacheSave(box, 'cachedRentData_$wallet', processedData);
          if (saveSuccess) {
            await box.put('lastRentSuccess_$wallet', now.toIso8601String());
          } else {
            debugPrint('⚠️ Échec sauvegarde cache pour $wallet, tentative de repli');
            try {
              await box.put('cachedRentData_$wallet', json.encode(processedData));
              await box.put('lastRentSuccess_$wallet', now.toIso8601String());
            } catch (e) {
              debugPrint('❌ Échec total sauvegarde pour $wallet: $e');
            }
          }
          successfulWallets.add(wallet);
          
        } else {
          errorCount++;
          final errorType = ErrorClassifier.classifyError(null, response.statusCode);
          debugPrint('❌ Erreur HTTP ${response.statusCode} pour le wallet: $wallet (type: $errorType) - conservation des données existantes');
        }
      } catch (e) {
        errorCount++;
        final errorType = ErrorClassifier.classifyError(e, null);
        debugPrint('❌ Exception pour le wallet $wallet (type: $errorType): $e - conservation des données existantes');
      }
      
      processedCount++;
      
      // Pause adaptative entre les wallets pour être gentil avec le serveur
      if (processedCount < walletsToProcess.length) {
        await Future.delayed(Duration(milliseconds: 300 + (errorCount * 100))); // Plus de délai si plus d'erreurs
      }
    }

    // Trier les données par date
    mergedRentData.sort((a, b) => a['date'].compareTo(b['date']));

    // Sauvegarder le cache global TOUJOURS (même en cas d'erreur partielle)
    await box.put('cachedRentData', json.encode(mergedRentData));
    await box.put('lastRentFetchTime', now.toIso8601String());
    
    // Marquer comme succès complet seulement si tous les wallets traités ont réussi
    final totalWalletsToProcess = healthyWallets.length;
    if (successfulWallets.length == totalWalletsToProcess) {
      await box.put('lastSuccessfulRentFetch', now.toIso8601String());
      debugPrint("✅ Succès complet: ${mergedRentData.length} entrées (${successfulWallets.length}/$totalWalletsToProcess wallets)");
    } else {
      debugPrint("⚠️ Succès partiel: ${mergedRentData.length} entrées (${successfulWallets.length}/$totalWalletsToProcess wallets, $errorCount erreurs)");
    }

    // Afficher les statistiques finales de santé
    final healthStats = healthManager.getHealthStats();
    if (healthStats.isNotEmpty) {
      debugPrint("📊 Statistiques finales: ${healthStats['healthyWallets']}/${healthStats['totalWallets']} wallets sains, ${healthStats['inCircuitBreaker']} en circuit breaker, ${healthStats['globalSuccessRate'] ?? 'N/A'}% succès global");
    }

    // Diagnostic final anti-doublons
    double totalRentFinal = 0;
    for (var entry in mergedRentData) {
      totalRentFinal += (entry['rent'] ?? 0).toDouble();
    }
    debugPrint("📊 Total rent final: \$${totalRentFinal.toStringAsFixed(2)}");

    return mergedRentData;
  }

  /// Charge les données de loyer depuis le cache pour tous les wallets
  static Future<List<Map<String, dynamic>>> _loadRentDataFromCache(Box box, List<String> wallets) async {
    // Essayer le cache global d'abord
    final globalCache = box.get('cachedRentData');
    if (globalCache != null) {
      try {
        return List<Map<String, dynamic>>.from(json.decode(globalCache));
      } catch (e) {
        debugPrint('⚠️ Erreur cache global rent data: $e');
      }
    }

    // Sinon, fusionner les caches individuels
    List<Map<String, dynamic>> mergedData = [];
    for (String wallet in wallets) {
      final cachedData = await _loadRentDataFromCacheForWallet(box, wallet);
      mergedData.addAll(cachedData);
    }

    // Fusionner les données par date
    Map<String, double> dateRentMap = {};
    for (var entry in mergedData) {
      String date = entry['date'];
      double rent = (entry['rent'] ?? 0).toDouble();
      dateRentMap[date] = (dateRentMap[date] ?? 0) + rent;
    }

    List<Map<String, dynamic>> result = dateRentMap.entries
        .map((entry) => {'date': entry.key, 'rent': entry.value})
        .toList();
    result.sort((a, b) => a['date'].compareTo(b['date']));

    return result;
  }

  /// Charge les données de loyer depuis le cache pour un wallet spécifique
  static Future<List<Map<String, dynamic>>> _loadRentDataFromCacheForWallet(Box box, String wallet) async {
    return await _safeLoadWalletCache(box, wallet);
  }

  static Future<List<Map<String, dynamic>>> fetchWhitelistTokens({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wallets = prefs.getStringList('evmAddresses') ?? [];

    if (wallets.isEmpty) {
      return []; // Pas d'exécution si aucun wallet n'est renseigné
    }

    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedWhitelistData',
      debugName: "Whitelist Tokens",
      forceFetch: forceFetch,
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        final box = Hive.box('realTokens');
        final DateTime now = DateTime.now();
        List<Map<String, dynamic>> mergedWhitelistTokens = [];

        debugPrint("🚀 Récupération des tokens whitelistés pour ${wallets.length} wallets");

        // Parcourir chaque wallet pour récupérer ses tokens whitelistés
        for (String wallet in wallets) {
          final url = '${Parameters.rentTrackerUrl}/whitelist2/$wallet';
          
          try {
            final response = await http.get(Uri.parse(url))
                .timeout(Duration(seconds: 15));

            // En cas de code 429, sauvegarder l'heure et interrompre la boucle
            if (response.statusCode == 429) {
              debugPrint('⚠️ 429 Too Many Requests pour wallet: $wallet');
              await box.put('lastWhitelistFetchTime', now.toIso8601String());
              throw Exception("Limite de requêtes atteinte pour les tokens whitelistés");
            }

            if (response.statusCode == 200) {
              debugPrint("✅ Requête réussie pour wallet: $wallet");
              List<Map<String, dynamic>> whitelistData = List<Map<String, dynamic>>.from(
                json.decode(response.body)
              );
              mergedWhitelistTokens.addAll(whitelistData);
            } else {
              debugPrint('❌ Erreur HTTP ${response.statusCode} pour wallet: $wallet');
              throw Exception('Impossible de récupérer les tokens whitelistés pour wallet: $wallet');
            }
          } catch (e) {
            debugPrint('❌ Exception pour wallet $wallet: $e');
            throw e;
          }
        }

        // Sauvegarder le timestamp spécifique pour les tokens whitelistés
        await box.put('lastWhitelistFetchTime', now.toIso8601String());
        debugPrint("✅ ${mergedWhitelistTokens.length} tokens whitelistés récupérés");

        return mergedWhitelistTokens;
      },
    );
  }

  static Future<Map<String, dynamic>> fetchCurrencies({bool forceFetch = false}) async {
    return _fetchWithCache<Map<String, dynamic>>(
      cacheKey: 'cachedCurrencies',
      debugName: "Currencies",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 1), // 1 heure pour les devises
      fromJson: (data) => Map<String, dynamic>.from(data),
      toJson: (data) => data,
      emptyValue: <String, dynamic>{},
      apiCall: () async {
        debugPrint("🔄 Récupération des devises depuis CoinGecko");
        
        final response = await http.get(Uri.parse(Parameters.coingeckoUrl))
            .timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final currencies = data['market_data']['current_price'] as Map<String, dynamic>;
          
          debugPrint("✅ ${currencies.length} devises récupérées");
          return currencies;
        } else {
          throw Exception('Erreur HTTP ${response.statusCode} lors de la récupération des devises');
        }
      },
    );
  }
  // Récupérer le userId associé à une adresse Ethereum

  static Future<List<Map<String, dynamic>>> fetchRmmBalances({bool forceFetch = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour RMM Balances");
      return [];
    }

    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedRmmBalances',
      debugName: "RMM Balances",
      forceFetch: forceFetch,
      customCacheDuration: Duration(minutes: 15), // Cache plus court pour les balances
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        // Utilisation des constantes centralisées
        const String usdcDepositContract = ContractsConstants.usdcDepositContract;
        const String usdcBorrowContract = ContractsConstants.usdcBorrowContract;
        const String xdaiDepositContract = ContractsConstants.xdaiDepositContract;
        const String xdaiBorrowContract = ContractsConstants.xdaiBorrowContract;
        const String gnosisUsdcContract = ContractsConstants.gnosisUsdcContract;
        const String gnosisRegContract = ContractsConstants.gnosisRegContract;
        const String gnosisVaultRegContract = ContractsConstants.gnosisVaultRegContract;

        List<Map<String, dynamic>> allBalances = [];

        debugPrint("🔄 Récupération des balances RMM pour ${evmAddresses.length} wallets");

        for (var address in evmAddresses) {
          try {
            // Requêtes pour tous les contrats
            final futures = await Future.wait([
              _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch),
              _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch),
              _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch),
              _fetchBalance(xdaiBorrowContract, address, forceFetch: forceFetch),
              _fetchBalance(gnosisUsdcContract, address, forceFetch: forceFetch),
              _fetchBalance(gnosisRegContract, address, forceFetch: forceFetch),
              _fetchVaultBalance(gnosisVaultRegContract, address, forceFetch: forceFetch),
              _fetchNativeBalance(address, forceFetch: forceFetch),
            ]);

            final [
              usdcDepositResponse,
              usdcBorrowResponse,
              xdaiDepositResponse,
              xdaiBorrowResponse,
              gnosisUsdcResponse,
              gnosisRegResponse,
              gnosisVaultRegResponse,
              gnosisXdaiResponse,
            ] = futures;

            // Vérification que toutes les requêtes ont retourné une valeur
            if (usdcDepositResponse != null && usdcBorrowResponse != null && 
                xdaiDepositResponse != null && xdaiBorrowResponse != null && 
                gnosisUsdcResponse != null && gnosisXdaiResponse != null) {
              
              final timestamp = DateTime.now().toIso8601String();

              // Conversion optimisée des balances en double
              double usdcDepositBalance = PerformanceUtils.bigIntToDouble(usdcDepositResponse, 6);
              double usdcBorrowBalance = PerformanceUtils.bigIntToDouble(usdcBorrowResponse, 6);
              double xdaiDepositBalance = PerformanceUtils.bigIntToDouble(xdaiDepositResponse, 18);
              double xdaiBorrowBalance = PerformanceUtils.bigIntToDouble(xdaiBorrowResponse, 18);
              double gnosisUsdcBalance = PerformanceUtils.bigIntToDouble(gnosisUsdcResponse, 6);
              double gnosisRegBalance = PerformanceUtils.bigIntToDouble(gnosisRegResponse ?? BigInt.zero, 18);
              double gnosisVaultRegBalance = PerformanceUtils.bigIntToDouble(gnosisVaultRegResponse ?? BigInt.zero, 18);
              double gnosisXdaiBalance = PerformanceUtils.bigIntToDouble(gnosisXdaiResponse, 18);

              // Ajout des données dans la liste
              allBalances.add({
                'address': address,
                'usdcDepositBalance': usdcDepositBalance,
                'usdcBorrowBalance': usdcBorrowBalance,
                'xdaiDepositBalance': xdaiDepositBalance,
                'xdaiBorrowBalance': xdaiBorrowBalance,
                'gnosisUsdcBalance': gnosisUsdcBalance,
                'gnosisRegBalance': gnosisRegBalance,
                'gnosisVaultRegBalance': gnosisVaultRegBalance,
                'gnosisXdaiBalance': gnosisXdaiBalance,
                'timestamp': timestamp,
              });

              debugPrint("✅ Balances RMM récupérées pour wallet: $address");
            } else {
              debugPrint("❌ Échec récupération balances pour wallet: $address");
              throw Exception('Failed to fetch balances for address: $address');
            }
          } catch (e) {
            debugPrint("❌ Exception balances pour wallet $address: $e");
            throw e;
          }
        }

        debugPrint("✅ ${allBalances.length} balances RMM récupérées au total");
        return allBalances;
      },
    );
  }

  /// Fonction pour récupérer le solde d'un token ERC20 (via eth_call)
  static Future<BigInt?> _fetchBalance(String contract, String address, {bool forceFetch = false}) async {
    final String cacheKey = 'cachedBalance_${contract}_$address';
    final box = await Hive.openBox('balanceCache'); // Remplacez par le système de stockage persistant que vous utilisez
    final now = DateTime.now();

    // Récupérer l'heure de la dernière requête dans le cache
    final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

    // Vérifier si on doit utiliser le cache ou forcer une nouvelle requête
    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        // Vérifier si le résultat est mis en cache
        final cachedData = box.get(cacheKey);
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchBallance -> Requete annulée, temps minimum pas atteint");
          return BigInt.tryParse(cachedData);
        }
      }
    }

    // Effectuer la requête si les données ne sont pas en cache ou expirées
    final response = await http.post(
      Uri.parse('https://rpc.gnosischain.com'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "jsonrpc": "2.0",
        "method": "eth_call",
        "params": [
          {"to": contract, "data": "0x70a08231000000000000000000000000${address.substring(2)}"},
          "latest"
        ],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      debugPrint("🚀 apiService: RPC gnosis -> requête lancée");

      if (result != null && result != "0x") {
        final balance = BigInt.parse(result.substring(2), radix: 16);

        // Sauvegarder le résultat dans le cache
        debugPrint("🚀 apiService: RPC gnosis -> $contract balance récupérée: $balance");
        await box.put(cacheKey, balance.toString());
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        box.put('lastExecutionTime_Balances', now.toIso8601String());

        return balance;
      } else {
         debugPrint("apiService: RPC gnosis -> Invalid response for contract $contract: $result");
      }
    } else {
       debugPrint('apiService: RPC gnosis -> Failed to fetch balance for contract $contract. Status code: ${response.statusCode}');
    }

    return null;
  }

  /// Fonction pour récupérer le solde du token natif (xDAI) via eth_getBalance
  static Future<BigInt?> _fetchNativeBalance(String address, {bool forceFetch = false}) async {
    final String cacheKey = 'cachedNativeBalance_$address';
    final box = await Hive.openBox('balanceCache');
    final now = DateTime.now();

    final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

    if (!forceFetch && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
        final cachedData = box.get(cacheKey);
        if (cachedData != null) {
          debugPrint("🛑 apiService: fetchNativeBalance -> Cache utilisé");
          return BigInt.tryParse(cachedData);
        }
      }
    }

    final response = await http.post(
      Uri.parse('https://rpc.gnosischain.com'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [address, "latest"],
        "id": 1
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final result = responseBody['result'];
      debugPrint("🚀 apiService: RPC Gnosis -> Requête eth_getBalance lancée");

      if (result != null && result != "0x") {
        final balance = BigInt.parse(result.substring(2), radix: 16);
        await box.put(cacheKey, balance.toString());
        await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        return balance;
      }
    }
    return null;
  }

static Future<BigInt?> _fetchVaultBalance(String contract, String address, {bool forceFetch = false}) async {
  final String cacheKey = 'cachedVaultBalance_${contract}_$address';
  final box = await Hive.openBox('balanceCache');
  final now = DateTime.now();

  final String? lastFetchTime = box.get('lastFetchTime_$cacheKey');

  if (!forceFetch && lastFetchTime != null) {
    final DateTime lastFetch = DateTime.parse(lastFetchTime);
    if (now.difference(lastFetch) < Parameters.apiCacheDuration) {
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        debugPrint("🛑 apiService: fetchVaultBalance -> Requête annulée, cache valide");
        return BigInt.tryParse(cachedData);
      }
    }
  }

  // Construire la data : 0xf262a083 + adresse paddée (sans '0x', alignée sur 32 bytes)
  final String functionSelector = 'f262a083';
  final String paddedAddress = address.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
  final String data = '0x$functionSelector$paddedAddress';

  final response = await http.post(
    Uri.parse('https://rpc.gnosischain.com'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {"to": contract, "data": data},
        "latest"
      ],
      "id": 1
    }),
  );

  if (response.statusCode == 200) {
    final responseBody = json.decode(response.body);
    final result = responseBody['result'];

    debugPrint("🚀 apiService: fetchVaultBalance -> Requête lancée");

    if (result != null && result != "0x" && result.length >= 66) {
      // On suppose que le solde est dans le 1er mot (64 caractères hex après le "0x")
      final String balanceHex = result.substring(2, 66);
      final balance = BigInt.parse(balanceHex, radix: 16);

      debugPrint("✅ apiService: fetchVaultBalance -> Balance récupérée: $balance");
      await box.put(cacheKey, balance.toString());
      await box.put('lastFetchTime_$cacheKey', now.toIso8601String());
      box.put('lastExecutionTime_Balances', now.toIso8601String());

      return balance;
    } else {
      debugPrint("⚠️ apiService: fetchVaultBalance -> Résultat invalide pour $contract: $result");
    }
  } else {
    debugPrint('❌ apiService: fetchVaultBalance -> Échec HTTP. Code: ${response.statusCode}');
  }

  return null;
}

  // Nouvelle méthode pour récupérer les détails des loyers avec gestion intelligente
  static Future<List<Map<String, dynamic>>> fetchDetailedRentDataForAllWallets({bool forceFetch = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    debugPrint("📋 ${evmAddresses.length} wallets à consulter: ${evmAddresses.join(', ')}");

    if (evmAddresses.isEmpty) {
      debugPrint("⚠️ Aucun wallet renseigné pour les données détaillées de loyer");
      return [];
    }

    final box = await Hive.openBox('detailedRentData');
    final DateTime now = DateTime.now();
    final healthManager = WalletHealthManager();
    
    // Calculer le début de la semaine actuelle (lundi)
    final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime startOfCurrentWeekMidnight = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
    
    // TOUJOURS commencer par charger les données existantes de tous les wallets
    debugPrint("📦 Chargement des données détaillées existantes pour tous les wallets");
    List<Map<String, dynamic>> allRentData = [];
    await _loadDetailedRentDataFromCache(box, evmAddresses).then((cachedData) {
      allRentData.addAll(cachedData);
      debugPrint("📦 ${allRentData.length} entrées détaillées chargées depuis le cache");
    });
    
    // Vérifier si une réponse 429 a été reçue récemment
    final last429Time = box.get('lastDetailedRent429Time');
    if (last429Time != null && !forceFetch) {
      final DateTime last429 = DateTime.parse(last429Time);
      if (now.difference(last429) < Duration(minutes: 5)) {
        debugPrint('⚠️ 429 reçu récemment pour les données détaillées, utilisation des données existantes');
        return allRentData;
      }
    }

    // Filtrer les wallets selon leur état de santé (circuit breaker)
    final List<String> healthyWallets = evmAddresses.where((wallet) => 
      healthManager.canProcessWallet(wallet)
    ).toList();
    
    final int unhealthyCount = evmAddresses.length - healthyWallets.length;
    if (unhealthyCount > 0) {
      debugPrint("🚫 $unhealthyCount wallets en circuit breaker pour données détaillées, traitement de ${healthyWallets.length} wallets sains");
    }

    // Vérifier si tous les wallets sains ont été traités cette semaine pour les données détaillées ET ont un cache valide
    bool allHealthyWalletsProcessedDetailed = true;
    for (String walletAddress in healthyWallets) {
      final lastSuccessKey = 'lastDetailedRentSuccess_$walletAddress';
      final lastSuccessTime = box.get(lastSuccessKey);
      final cacheKey = 'cachedDetailedRentData_$walletAddress';
      final cachedData = box.get(cacheKey);
      
      if (lastSuccessTime == null || cachedData == null) {
        debugPrint("❌ Wallet $walletAddress: pas de succès récent ou cache détaillé manquant");
        allHealthyWalletsProcessedDetailed = false;
        break;
      } else {
        final DateTime lastSuccess = DateTime.parse(lastSuccessTime);
        if (!lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
          debugPrint("❌ Wallet $walletAddress: succès détaillé trop ancien");
          allHealthyWalletsProcessedDetailed = false;
          break;
        }
        
        // Vérifier que le cache n'est pas vide ou corrompu
        try {
          final List<dynamic> cacheContent = json.decode(cachedData);
          if (cacheContent.isEmpty) {
            debugPrint("❌ Wallet $walletAddress: cache détaillé vide");
            allHealthyWalletsProcessedDetailed = false;
            break;
          }
        } catch (e) {
          debugPrint("❌ Wallet $walletAddress: cache détaillé corrompu - $e");
          allHealthyWalletsProcessedDetailed = false;
          break;
        }
      }
    }
    
    // Vérifier si la dernière mise à jour réussie des données détaillées est trop ancienne (plus de 7 jours)
    final lastSuccessfulDetailedFetch = box.get('lastSuccessfulDetailedRentFetch');
    bool isDetailedDataTooOld = false;
    if (lastSuccessfulDetailedFetch != null) {
      final DateTime lastDetailedSuccess = DateTime.parse(lastSuccessfulDetailedFetch);
      isDetailedDataTooOld = now.difference(lastDetailedSuccess) > Duration(days: 7);
    } else {
      isDetailedDataTooOld = true; // Pas de fetch réussi enregistré
    }
    
    // Si tous les wallets sains sont traités ET qu'on n'est pas mardi ET pas de forceFetch ET que les données ne sont pas trop anciennes, utiliser le cache
    final bool isTuesday = now.weekday == DateTime.tuesday;
    if (allHealthyWalletsProcessedDetailed && !isTuesday && !forceFetch && !isDetailedDataTooOld) {
      debugPrint("🛑 Tous les wallets sains traités cette semaine pour les données détaillées, utilisation des données existantes");
      
      // Afficher les statistiques de santé
      final healthStats = healthManager.getHealthStats();
      if (healthStats.isNotEmpty) {
        debugPrint("📊 Santé des wallets (détaillées): ${healthStats['healthyWallets']}/${healthStats['totalWallets']} sains, ${healthStats['globalSuccessRate'] ?? 'N/A'}% succès global");
      }
      
      return allRentData;
    }
    
    if (isDetailedDataTooOld) {
      debugPrint("⏰ Données détaillées trop anciennes (>7 jours), forçage de la mise à jour");
    }
    
    debugPrint("🔄 Certains wallets non traités pour les données détaillées ou c'est mardi, traitement nécessaire");

    // Sauvegarder les données existantes comme backup
    final Map<String, List<Map<String, dynamic>>> existingDetailedDataByWallet = {};
    for (String walletAddress in healthyWallets) {
      final cachedData = box.get('cachedDetailedRentData_$walletAddress');
      if (cachedData != null) {
        try {
          final List<Map<String, dynamic>> walletData = List<Map<String, dynamic>>.from(json.decode(cachedData));
          existingDetailedDataByWallet[walletAddress] = walletData;
        } catch (e) {
          debugPrint('⚠️ Erreur lecture cache pour wallet $walletAddress: $e');
          existingDetailedDataByWallet[walletAddress] = [];
        }
      } else {
        existingDetailedDataByWallet[walletAddress] = [];
      }
    }

    // Prioriser les wallets selon leur historique de performance
    final List<String> prioritizedWallets = healthManager.prioritizeWallets(healthyWallets);

    List<String> walletsToProcess = [];
    List<String> successfulWallets = [];

    // Identifier les wallets à traiter parmi les wallets priorisés
    for (String walletAddress in prioritizedWallets) {
      final lastSuccessKey = 'lastDetailedRentSuccess_$walletAddress';
      final lastSuccessTime = box.get(lastSuccessKey);
      final cacheKey = 'cachedDetailedRentData_$walletAddress';
      final cachedData = box.get(cacheKey);
      
      if (lastSuccessTime != null && cachedData != null && !forceFetch) {
        final DateTime lastSuccess = DateTime.parse(lastSuccessTime);
        if (lastSuccess.isAfter(startOfCurrentWeekMidnight)) {
          // Vérifier que le cache est valide
          try {
            final List<dynamic> cacheContent = json.decode(cachedData);
            if (cacheContent.isNotEmpty) {
              debugPrint("✅ Wallet $walletAddress déjà traité cette semaine avec cache détaillé valide");
              successfulWallets.add(walletAddress);
              continue;
            } else {
              debugPrint("⚠️ Wallet $walletAddress: cache détaillé vide, retraitement nécessaire");
            }
          } catch (e) {
            debugPrint("⚠️ Wallet $walletAddress: cache détaillé corrompu, retraitement nécessaire - $e");
          }
        }
      }
      walletsToProcess.add(walletAddress);
    }

    debugPrint("🚀 ${walletsToProcess.length} wallets à traiter pour les données détaillées, ${successfulWallets.length} déjà traités");

    // Traiter les wallets un par un avec gestion intelligente des erreurs
    int processedCount = 0;
    int errorCount = 0;
    
    for (var walletAddress in walletsToProcess) {
      debugPrint("🔄 Traitement détaillé du wallet: $walletAddress (${processedCount + 1}/${walletsToProcess.length})");
      
      try {
        final url = '${Parameters.rentTrackerUrl}/detailed_rent_holder/$walletAddress';
        debugPrint("🌐 Tentative de requête API détaillée pour $walletAddress");

        final response = await _httpGetWithRetry(
          url,
          timeout: Duration(minutes: 2),
          debugContext: "données détaillées wallet $walletAddress",
          walletAddress: walletAddress, // Tracking du wallet
        );

        // Si on reçoit un code 429, conserver les données existantes et arrêter
        if (response.statusCode == 429) {
          debugPrint('⚠️ 429 Too Many Requests pour le wallet $walletAddress - conservation des données existantes');
          await box.put('lastDetailedRent429Time', now.toIso8601String());
          break;
        }

        // Si la requête réussit
        if (response.statusCode == 200) {
          final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(
            json.decode(response.body)
          );

          // Retirer les anciennes données de ce wallet du merge
          allRentData.removeWhere((entry) => entry['wallet'] == walletAddress);

          // Ajouter l'adresse du wallet à chaque entrée
          for (var entry in rentData) {
            entry['wallet'] = walletAddress;
          }

          // Sauvegarder dans le cache spécifique du wallet avec vérification
          final saveSuccess = await _safeCacheSave(box, 'cachedDetailedRentData_$walletAddress', rentData);
          if (saveSuccess) {
            await box.put('lastDetailedRentSuccess_$walletAddress', now.toIso8601String());
          } else {
            debugPrint('⚠️ Échec sauvegarde cache pour $walletAddress, tentative de repli');
            try {
              await box.put('cachedDetailedRentData_$walletAddress', json.encode(rentData));
              await box.put('lastDetailedRentSuccess_$walletAddress', now.toIso8601String());
            } catch (e) {
              debugPrint('❌ Échec total sauvegarde pour $walletAddress: $e');
            }
          }
          
          debugPrint("✅ Requête détaillée réussie pour $walletAddress, ${rentData.length} entrées obtenues");
          allRentData.addAll(rentData);
          successfulWallets.add(walletAddress);
        } else {
          errorCount++;
          final errorType = ErrorClassifier.classifyError(null, response.statusCode);
          debugPrint('❌ Échec requête détaillée pour $walletAddress: ${response.statusCode} (type: $errorType) - conservation des données existantes');
        }
      } catch (e) {
        errorCount++;
        final errorType = ErrorClassifier.classifyError(e, null);
        debugPrint('❌ Erreur requête HTTP détaillée pour $walletAddress (type: $errorType): $e - conservation des données existantes');
      }
      
      processedCount++;
      
      // Pause adaptative entre les wallets (plus longue pour les données détaillées)
      if (processedCount < walletsToProcess.length) {
        await Future.delayed(Duration(milliseconds: 500 + (errorCount * 200))); // Plus de délai si plus d'erreurs
      }
    }

    // Vérification finale pour s'assurer que toutes les entrées ont un wallet
    int entriesSansWallet = 0;
    for (var entry in allRentData) {
      if (!entry.containsKey('wallet') || entry['wallet'] == null) {
        entry['wallet'] = 'unknown';
        entriesSansWallet++;
      }
    }
    if (entriesSansWallet > 0) {
      debugPrint('⚠️ $entriesSansWallet entrées sans wallet assignées à "unknown"');
    }

    await box.put('lastExecutionTime_Rents', now.toIso8601String());

    // Sauvegarder le cache global TOUJOURS (même en cas d'erreur partielle)
    await box.put('cachedDetailedRentDataAll', json.encode(allRentData));
    
    // Marquer comme succès complet seulement si tous les wallets traités ont réussi
    final totalWalletsToProcess = healthyWallets.length;
    if (successfulWallets.length == totalWalletsToProcess) {
      await box.put('lastSuccessfulDetailedRentFetch', now.toIso8601String());
      debugPrint('✅ Succès complet détaillé: ${allRentData.length} entrées (${successfulWallets.length}/$totalWalletsToProcess wallets)');
    } else {
      debugPrint('⚠️ Succès partiel détaillé: ${allRentData.length} entrées (${successfulWallets.length}/$totalWalletsToProcess wallets, $errorCount erreurs)');
    }

    // Afficher les statistiques finales de santé
    final healthStats = healthManager.getHealthStats();
    if (healthStats.isNotEmpty) {
      debugPrint("📊 Statistiques finales (détaillées): ${healthStats['healthyWallets']}/${healthStats['totalWallets']} wallets sains, ${healthStats['inCircuitBreaker']} en circuit breaker, ${healthStats['globalSuccessRate'] ?? 'N/A'}% succès global");
    }

    // Comptage des entrées par wallet
    Map<String, int> entriesPerWallet = {};
    for (var entry in allRentData) {
      String wallet = entry['wallet'];
      entriesPerWallet[wallet] = (entriesPerWallet[wallet] ?? 0) + 1;
    }
    entriesPerWallet.forEach((wallet, count) {
      debugPrint('📊 Wallet $wallet - $count entrées détaillées');
    });

    return allRentData;
  }

  /// Charge les données détaillées de loyer depuis le cache pour tous les wallets
  static Future<List<Map<String, dynamic>>> _loadDetailedRentDataFromCache(Box box, List<String> wallets) async {
    // Essayer le cache global d'abord
    final globalCache = box.get('cachedDetailedRentDataAll');
    if (globalCache != null) {
      try {
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(json.decode(globalCache));
        if (data.isNotEmpty) {
          return data;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur cache global detailed rent data: $e');
      }
    }

    // Sinon, fusionner les caches individuels
    List<Map<String, dynamic>> allData = [];
    for (String walletAddress in wallets) {
      await _loadFromCacheOptimized(box, walletAddress, allData);
    }

    return allData;
  }

  // Méthode utilitaire pour charger les données du cache (version optimisée async)
  static Future<void> _loadFromCacheOptimized(Box box, String walletAddress, List<Map<String, dynamic>> allRentData) async {
    debugPrint('🔄 Tentative de chargement du cache pour $walletAddress');
    final cachedData = box.get('cachedDetailedRentData_$walletAddress');
    if (cachedData != null) {
      try {
        final List<Map<String, dynamic>> rentData = List<Map<String, dynamic>>.from(json.decode(cachedData));

        // Vérifier et ajouter l'adresse du wallet si nécessaire
        for (var entry in rentData) {
          if (!entry.containsKey('wallet') || entry['wallet'] == null) {
            entry['wallet'] = walletAddress;
          }
        }

        allRentData.addAll(rentData);
        debugPrint("✅ Données de loyer chargées du cache pour $walletAddress (${rentData.length} entrées)");
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement des données en cache pour $walletAddress: $e');
      }
    } else {
      debugPrint('⚠️ Pas de données en cache pour le wallet $walletAddress');
    }
  }

  /// Méthode sécurisée pour sauvegarder des données dans le cache avec vérification
  static Future<bool> _safeCacheSave(Box box, String key, dynamic data) async {
    try {
      final String jsonData = json.encode(data);
      await box.put(key, jsonData);
      
      // Vérifier que les données ont été sauvegardées correctement
      final savedData = box.get(key);
      if (savedData == jsonData) {
        debugPrint("✅ Cache sauvegardé avec succès: $key");
        return true;
      } else {
        debugPrint("❌ Erreur de vérification cache pour: $key");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Erreur sauvegarde cache pour $key: $e");
      return false;
    }
  }

  /// Méthode sécurisée pour charger des données depuis le cache avec vérification
  static Future<List<Map<String, dynamic>>> _safeLoadWalletCache(Box box, String walletAddress) async {
    try {
      final cachedData = box.get('cachedDetailedRentData_$walletAddress') ?? 
                        box.get('cachedRentData_$walletAddress');
      
      if (cachedData != null) {
        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
          json.decode(cachedData)
        );
        
        // Vérifier l'intégrité des données
        for (var entry in data) {
          if (!entry.containsKey('wallet') || entry['wallet'] == null) {
            entry['wallet'] = walletAddress;
          }
        }
        
        debugPrint("✅ Cache chargé avec succès pour $walletAddress (${data.length} entrées)");
        return data;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache pour $walletAddress: $e');
    }
    
    debugPrint('⚠️ Pas de cache valide pour le wallet $walletAddress');
    return [];
  }

  /// Fonction de diagnostic pour examiner l'état du cache des wallets
  static Future<Map<String, dynamic>> diagnoseCacheStatus(List<String> walletAddresses) async {
    final rentBox = Hive.box('realTokens');
    final detailedBox = await Hive.openBox('detailedRentData');
    
    Map<String, dynamic> diagnostics = {
      'timestamp': DateTime.now().toIso8601String(),
      'walletDiagnostics': <String, dynamic>{},
      'globalCacheStatus': <String, dynamic>{},
    };
    
    // Vérifier le cache global
    diagnostics['globalCacheStatus'] = {
      'cachedRentData': rentBox.get('cachedRentData') != null,
      'cachedDetailedRentDataAll': detailedBox.get('cachedDetailedRentDataAll') != null,
      'lastRentFetchTime': rentBox.get('lastRentFetchTime'),
      'lastSuccessfulRentFetch': rentBox.get('lastSuccessfulRentFetch'),
      'lastSuccessfulDetailedRentFetch': detailedBox.get('lastSuccessfulDetailedRentFetch'),
      'lastRent429Time': rentBox.get('lastRent429Time'),
      'lastDetailedRent429Time': detailedBox.get('lastDetailedRent429Time'),
    };
    
    // Vérifier chaque wallet individuellement
    for (String walletAddress in walletAddresses) {
      try {
        final rentCacheExists = rentBox.get('cachedRentData_$walletAddress') != null;
        final detailedCacheExists = detailedBox.get('cachedDetailedRentData_$walletAddress') != null;
        
        int rentCacheEntries = 0;
        int detailedCacheEntries = 0;
        
        if (rentCacheExists) {
          try {
            final rentData = await _safeLoadWalletCache(rentBox, walletAddress);
            rentCacheEntries = rentData.length;
          } catch (e) {
            debugPrint('❌ Erreur lecture cache rent pour diagnostic $walletAddress: $e');
          }
        }
        
        if (detailedCacheExists) {
          try {
            final detailedData = await _safeLoadWalletCache(detailedBox, walletAddress);
            detailedCacheEntries = detailedData.length;
          } catch (e) {
            debugPrint('❌ Erreur lecture cache detailed pour diagnostic $walletAddress: $e');
          }
        }
        
        diagnostics['walletDiagnostics'][walletAddress] = {
          'rentCacheExists': rentCacheExists,
          'detailedCacheExists': detailedCacheExists,
          'rentCacheEntries': rentCacheEntries,
          'detailedCacheEntries': detailedCacheEntries,
          'lastRentSuccess': rentBox.get('lastRentSuccess_$walletAddress'),
          'lastDetailedRentSuccess': detailedBox.get('lastDetailedRentSuccess_$walletAddress'),
        };
      } catch (e) {
        diagnostics['walletDiagnostics'][walletAddress] = {
          'error': 'Erreur lors du diagnostic: $e',
        };
      }
    }
    
    debugPrint('📊 Diagnostic cache terminé pour ${walletAddresses.length} wallets');
    return diagnostics;
  }

  // Nouvelle méthode pour récupérer les propriétés en cours de vente
  static Future<List<Map<String, dynamic>>> fetchPropertiesForSale({bool forceFetch = false}) async {
    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedPropertiesForSale',
      debugName: "Properties For Sale",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 6), // Cache de 6 heures pour les propriétés en vente
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        const url = 'https://realt.co/wp-json/realt/v1/products/for_sale';
        
        debugPrint("🔄 Récupération des propriétés en vente");

        final response = await http.get(Uri.parse(url))
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          // Décoder la réponse JSON
          final data = json.decode(response.body);
          
          // Extraire la liste de produits
          final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(data['products']);
          
          debugPrint("✅ ${properties.length} propriétés en vente récupérées");
          return properties;
        } else {
          throw Exception('Échec de la requête propriétés. Code: ${response.statusCode}');
        }
      },
    );
  }

  static Future<List<dynamic>> fetchTokenVolumes({bool forceFetch = false}) async {
    return _fetchWithCacheList(
      cacheKey: 'cachedTokenVolumesData',
      debugName: "Token Volumes",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 4), // Cache de 4 heures pour les volumes
      apiCall: () async {
        final apiUrl = '${Parameters.mainApiUrl}/tokens_volume/';
        debugPrint("🔄 Récupération des volumes de tokens");
        
        final response = await http.get(Uri.parse(apiUrl))
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint("✅ Volumes de tokens récupérés");
          return data;
        } else {
          throw Exception("Échec de la récupération depuis FastAPI: ${response.statusCode}");
        }
      },
    );
  }

  static Future<List<dynamic>> fetchTransactionsHistory({bool forceFetch = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTransactionsData_transactions_history',
      debugName: "Transactions History",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 3), // Cache de 3 heures pour l'historique
      apiCall: () async {
        // Utiliser le traitement parallèle pour l'historique des transactions
        final allTransactionResults = await _processWalletsInParallel<List<dynamic>>(
          wallets: evmAddresses,
          debugName: "historique transactions",
          maxConcurrentRequests: 3, // Plus de concurrence pour l'historique
          processWallet: (wallet) async {
            final apiUrl = '${Parameters.mainApiUrl}/transactions_history/$wallet';
            
            final response = await _httpGetWithRetry(
              apiUrl,
              timeout: _mediumTimeout,
              debugContext: "historique transactions wallet $wallet",
            );

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              debugPrint("✅ Transactions récupérées pour wallet: $wallet");
              return walletData;
            } else {
              debugPrint("⚠️ Erreur récupération transactions pour wallet: $wallet (HTTP ${response.statusCode})");
              return null;
            }
          },
        );

        // Fusionner tous les résultats
        List<dynamic> allTransactions = [];
        for (var transactionList in allTransactionResults) {
          allTransactions.addAll(transactionList);
        }

        debugPrint("✅ ${allTransactions.length} transactions récupérées au total");
        return allTransactions;
      },
    );
  }

  static Future<List<dynamic>> fetchYamWalletsTransactions({bool forceFetch = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> evmAddresses = prefs.getStringList('evmAddresses') ?? [];

    if (evmAddresses.isEmpty) {
      return [];
    }

    return _fetchWithCacheList(
      cacheKey: 'cachedTransactionsData_yam_wallet_transactions',
      debugName: "YAM Wallets Transactions",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 3), // Cache de 3 heures pour les transactions YAM
      apiCall: () async {
        // Utiliser le traitement parallèle pour les transactions YAM
        final allYamTransactionResults = await _processWalletsInParallel<List<dynamic>>(
          wallets: evmAddresses,
          debugName: "transactions YAM",
          maxConcurrentRequests: 3,
          processWallet: (wallet) async {
            final apiUrl = '${Parameters.mainApiUrl}/YAM_transactions_history/$wallet';
            
            final response = await _httpGetWithRetry(
              apiUrl,
              timeout: _mediumTimeout,
              debugContext: "transactions YAM wallet $wallet",
            );

            if (response.statusCode == 200) {
              final walletData = jsonDecode(response.body);
              debugPrint("✅ Transactions YAM récupérées pour wallet: $wallet");
              return walletData;
            } else {
              debugPrint("⚠️ Erreur récupération transactions YAM pour wallet: $wallet (HTTP ${response.statusCode})");
              return null;
            }
          },
        );

        // Fusionner tous les résultats
        List<dynamic> allYamTransactions = [];
        for (var transactionList in allYamTransactionResults) {
          allYamTransactions.addAll(transactionList);
        }

        debugPrint("✅ ${allYamTransactions.length} transactions YAM récupérées au total");
        return allYamTransactions;
      },
    );
  }

  static Future<List<Map<String, dynamic>>> fetchRmmBalancesForAddress(String address, {bool forceFetch = false}) async {
    return _fetchWithCache<List<Map<String, dynamic>>>(
      cacheKey: 'cachedRmmBalancesForAddress_$address',
      debugName: "RMM Balances for $address",
      forceFetch: forceFetch,
      customCacheDuration: Duration(minutes: 15), // Cache court pour les balances individuelles
      fromJson: (data) => List<Map<String, dynamic>>.from(data),
      toJson: (data) => data,
      emptyValue: <Map<String, dynamic>>[],
      apiCall: () async {
        // Contrats pour USDC & XDAI (dépôt et emprunt)
        const String usdcDepositContract = ContractsConstants.usdcDepositContract;
        const String usdcBorrowContract = ContractsConstants.usdcBorrowContract;
        const String xdaiDepositContract = ContractsConstants.xdaiDepositContract;
        const String xdaiBorrowContract = ContractsConstants.xdaiBorrowContract;
        const String gnosisUsdcContract = ContractsConstants.gnosisUsdcContract;
        const String gnosisRegContract = ContractsConstants.gnosisRegContract;
        const String gnosisVaultRegContract = ContractsConstants.gnosisVaultRegContract;

        debugPrint("🔄 Récupération des balances RMM pour l'adresse: $address");

        // Requêtes parallèles pour tous les contrats
        final futures = await Future.wait([
          _fetchBalance(usdcDepositContract, address, forceFetch: forceFetch),
          _fetchBalance(usdcBorrowContract, address, forceFetch: forceFetch),
          _fetchBalance(xdaiDepositContract, address, forceFetch: forceFetch),
          _fetchBalance(xdaiBorrowContract, address, forceFetch: forceFetch),
          _fetchBalance(gnosisUsdcContract, address, forceFetch: forceFetch),
          _fetchBalance(gnosisRegContract, address, forceFetch: forceFetch),
          _fetchVaultBalance(gnosisVaultRegContract, address, forceFetch: forceFetch),
          _fetchNativeBalance(address, forceFetch: forceFetch),
        ]);

        final [
          usdcDepositResponse,
          usdcBorrowResponse,
          xdaiDepositResponse,
          xdaiBorrowResponse,
          gnosisUsdcResponse,
          gnosisRegResponse,
          gnosisVaultRegResponse,
          gnosisXdaiResponse,
        ] = futures;

        if (usdcDepositResponse != null && usdcBorrowResponse != null && 
            xdaiDepositResponse != null && xdaiBorrowResponse != null && 
            gnosisUsdcResponse != null && gnosisXdaiResponse != null) {
          
          final timestamp = DateTime.now().toIso8601String();
          double usdcDepositBalance = PerformanceUtils.bigIntToDouble(usdcDepositResponse, 6);
          double usdcBorrowBalance = PerformanceUtils.bigIntToDouble(usdcBorrowResponse, 6);
          double xdaiDepositBalance = PerformanceUtils.bigIntToDouble(xdaiDepositResponse, 18);
          double xdaiBorrowBalance = PerformanceUtils.bigIntToDouble(xdaiBorrowResponse, 18);
          double gnosisUsdcBalance = PerformanceUtils.bigIntToDouble(gnosisUsdcResponse, 6);
          double gnosisRegBalance = PerformanceUtils.bigIntToDouble(gnosisRegResponse ?? BigInt.zero, 18);
          double gnosisVaultRegBalance = PerformanceUtils.bigIntToDouble(gnosisVaultRegResponse ?? BigInt.zero, 18);
          double gnosisXdaiBalance = PerformanceUtils.bigIntToDouble(gnosisXdaiResponse, 18);
          
          debugPrint("✅ Balances RMM récupérées pour l'adresse: $address");
          
          return [
            {
              'address': address,
              'usdcDepositBalance': usdcDepositBalance,
              'usdcBorrowBalance': usdcBorrowBalance,
              'xdaiDepositBalance': xdaiDepositBalance,
              'xdaiBorrowBalance': xdaiBorrowBalance,
              'gnosisUsdcBalance': gnosisUsdcBalance,
              'gnosisRegBalance': gnosisRegBalance,
              'gnosisVaultRegBalance': gnosisVaultRegBalance,
              'gnosisXdaiBalance': gnosisXdaiBalance,
              'timestamp': timestamp,
            }
          ];
        } else {
          throw Exception('Failed to fetch balances for address: $address');
        }
      },
    );
  }

  /// Récupère l'historique des tokens depuis l'API token_history
  static Future<List<dynamic>> fetchTokenHistory({bool forceFetch = false}) async {
    return _fetchWithCacheList(
      cacheKey: 'cachedTokenHistoryData',
      debugName: "Token History",
      forceFetch: forceFetch,
      customCacheDuration: Duration(hours: 6), // Cache de 6 heures pour l'historique
      apiCall: () async {
        const apiUrl = 'https://api.vfhome.fr/token_history/?limit=10000';
        debugPrint("🔄 Récupération de l'historique des tokens");
        
        final response = await _httpGetWithRetry(
          apiUrl,
          timeout: _longTimeout,
          debugContext: "historique des tokens",
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            debugPrint("✅ Historique des tokens récupéré: ${data.length} entrées");
            return data;
          } else {
            debugPrint("⚠️ Format de données inattendu pour l'historique des tokens");
            return [];
          }
        } else {
          debugPrint("❌ Erreur récupération historique tokens: HTTP ${response.statusCode}");
          throw Exception("Échec de la récupération de l'historique: ${response.statusCode}");
        }
      },
    );
  }
}
