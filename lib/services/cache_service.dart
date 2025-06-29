import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';

/// Service centralisé pour la gestion optimisée du cache avec fallback automatique
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box _box;

  /// Initialise le service de cache
  Future<void> initialize() async {
    _box = Hive.box('realTokens');
  }

  /// Méthode générique pour fetch avec cache optimisé et fallback automatique
  Future<List<Map<String, dynamic>>> fetchWithCache({
    required String cacheKey,
    required Future<List<dynamic>> Function() apiCall,
    required String debugName,
    bool forceFetch = false,
    String? alternativeCacheKey,
  }) async {
    final DateTime now = DateTime.now();
    final lastFetchTime = _box.get('lastFetchTime_$cacheKey');

    // 1. Toujours charger le cache en premier si disponible
    List<Map<String, dynamic>> cachedData = [];
    try {
      String? cachedJson = _box.get(cacheKey);

      // Essayer la clé alternative si la principale est vide
      if (cachedJson == null && alternativeCacheKey != null) {
        cachedJson = _box.get(alternativeCacheKey);
      }

      if (cachedJson != null) {
        cachedData = List<Map<String, dynamic>>.from(json.decode(cachedJson));
        debugPrint("🔵 Cache $debugName chargé: ${cachedData.length} éléments");
      }
    } catch (e) {
      debugPrint("⚠️ Erreur chargement cache $debugName: $e");
    }

    // 2. Vérifier si une mise à jour est nécessaire
    bool needsUpdate = forceFetch;
    if (!needsUpdate && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      needsUpdate = now.difference(lastFetch) >= Parameters.apiCacheDuration;
    } else if (lastFetchTime == null) {
      needsUpdate = true;
    }

    // 3. Si pas besoin de mise à jour et cache disponible, retourner le cache
    if (!needsUpdate && cachedData.isNotEmpty) {
      debugPrint("✅ Cache $debugName valide utilisé");
      return cachedData;
    }

    // 4. Tentative de mise à jour via API
    try {
      debugPrint("🔄 Mise à jour API $debugName...");
      final apiResult = await apiCall();

      if (apiResult.isNotEmpty) {
        // Sauvegarder le nouveau cache
        final newData = List<Map<String, dynamic>>.from(apiResult);
        await _box.put(cacheKey, json.encode(newData));
        await _box.put('lastFetchTime_$cacheKey', now.toIso8601String());
        debugPrint("💾 $debugName mis à jour: ${newData.length} éléments");
        return newData;
      } else {
        debugPrint("⚠️ API $debugName retournée vide");
      }
    } catch (e) {
      debugPrint("❌ Erreur API $debugName: $e");
    }

    // 5. Fallback sur le cache si disponible
    if (cachedData.isNotEmpty) {
      debugPrint("🔄 Utilisation du cache $debugName suite à erreur API");
      return cachedData;
    }

    // 6. Dernier recours : liste vide
    debugPrint("❌ Aucune donnée disponible pour $debugName");
    return [];
  }

  /// Méthode pour fetch avec callback de mise à jour immédiate du cache
  Future<void> fetchWithCacheAndCallback({
    required String cacheKey,
    required Future<List<dynamic>> Function() apiCall,
    required void Function(List<Map<String, dynamic>>) onDataUpdated,
    required String debugName,
    bool forceFetch = false,
    String? alternativeCacheKey,
  }) async {
    final DateTime now = DateTime.now();
    final lastFetchTime = _box.get('lastFetchTime_$cacheKey');

    // 1. Charger et notifier immédiatement avec le cache si disponible
    List<Map<String, dynamic>> cachedData = [];
    try {
      String? cachedJson = _box.get(cacheKey);

      if (cachedJson == null && alternativeCacheKey != null) {
        cachedJson = _box.get(alternativeCacheKey);
      }

      if (cachedJson != null) {
        cachedData = List<Map<String, dynamic>>.from(json.decode(cachedJson));
        onDataUpdated(cachedData); // Notification immédiate pour l'UI
        debugPrint(
            "🔵 Cache $debugName restauré et notifié: ${cachedData.length} éléments");
      }
    } catch (e) {
      debugPrint("⚠️ Erreur chargement cache $debugName: $e");
    }

    // 2. Vérifier si une mise à jour est nécessaire
    bool needsUpdate = forceFetch;
    if (!needsUpdate && lastFetchTime != null) {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      needsUpdate = now.difference(lastFetch) >= Parameters.apiCacheDuration;
    } else if (lastFetchTime == null) {
      needsUpdate = true;
    }

    if (!needsUpdate && cachedData.isNotEmpty) {
      debugPrint("✅ Cache $debugName valide, pas de mise à jour nécessaire");
      return;
    }

    // 3. Mise à jour en arrière-plan si nécessaire
    try {
      debugPrint("🔄 Mise à jour API $debugName en arrière-plan...");
      final apiResult = await apiCall();

      if (apiResult.isNotEmpty) {
        final newData = List<Map<String, dynamic>>.from(apiResult);

        // Vérifier si les données ont changé avant de notifier
        if (!_areDataListsEqual(cachedData, newData)) {
          await _box.put(cacheKey, json.encode(newData));
          await _box.put('lastFetchTime_$cacheKey', now.toIso8601String());
          onDataUpdated(newData); // Notification avec les nouvelles données
          debugPrint(
              "💾 $debugName mis à jour et notifié: ${newData.length} éléments");
        } else {
          // Mettre à jour le timestamp même si les données sont identiques
          await _box.put('lastFetchTime_$cacheKey', now.toIso8601String());
          debugPrint("📊 $debugName inchangé, timestamp mis à jour");
        }
      } else {
        debugPrint("⚠️ API $debugName retournée vide, conservation du cache");
      }
    } catch (e) {
      debugPrint("❌ Erreur API $debugName: $e");

      // En cas d'erreur, s'assurer que les données du cache sont notifiées
      if (cachedData.isEmpty) {
        try {
          String? cachedJson = _box.get(cacheKey);
          if (cachedJson != null) {
            var fallbackData =
                List<Map<String, dynamic>>.from(json.decode(cachedJson));
            onDataUpdated(fallbackData);
            debugPrint(
                "🔄 Fallback cache $debugName notifié: ${fallbackData.length} éléments");
          }
        } catch (cacheError) {
          debugPrint("❌ Erreur fallback cache $debugName: $cacheError");
        }
      }
    }
  }

  /// Compare deux listes de données pour détecter les changements
  bool _areDataListsEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    if (list1.isEmpty && list2.isEmpty) return true;

    try {
      // Comparaison rapide basée sur la taille et les premiers/derniers éléments
      if (list1.length != list2.length) return false;
      if (list1.isNotEmpty && list2.isNotEmpty) {
        return json.encode(list1.first) == json.encode(list2.first) &&
            json.encode(list1.last) == json.encode(list2.last);
      }
      return true;
    } catch (e) {
      // En cas d'erreur de comparaison, considérer comme différent
      return false;
    }
  }

  /// Méthode pour obtenir des données du cache uniquement
  List<Map<String, dynamic>> getCachedData(String cacheKey,
      {String? alternativeCacheKey}) {
    try {
      String? cachedJson = _box.get(cacheKey);

      if (cachedJson == null && alternativeCacheKey != null) {
        cachedJson = _box.get(alternativeCacheKey);
      }

      if (cachedJson != null) {
        return List<Map<String, dynamic>>.from(json.decode(cachedJson));
      }
    } catch (e) {
      debugPrint("⚠️ Erreur lecture cache $cacheKey: $e");
    }
    return [];
  }

  /// Méthode pour vérifier si le cache est valide
  bool isCacheValid(String cacheKey) {
    final lastFetchTime = _box.get('lastFetchTime_$cacheKey');
    if (lastFetchTime == null) return false;

    try {
      final DateTime lastFetch = DateTime.parse(lastFetchTime);
      return DateTime.now().difference(lastFetch) < Parameters.apiCacheDuration;
    } catch (e) {
      return false;
    }
  }

  /// Méthode pour forcer l'invalidation du cache
  Future<void> invalidateCache(String cacheKey) async {
    await _box.delete('lastFetchTime_$cacheKey');
    debugPrint("🗑️ Cache $cacheKey invalidé");
  }

  /// Méthode pour nettoyer tout le cache
  Future<void> clearAllCache() async {
    await _box.clear();
    debugPrint("🗑️ Tout le cache effacé");
  }
}
