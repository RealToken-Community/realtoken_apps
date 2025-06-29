import 'dart:async';
import 'package:flutter/material.dart';

/// Utilitaires pour améliorer les performances de l'application
class PerformanceUtils {
  /// Debouncer pour éviter les appels répétitifs
  static final Map<String, Timer> _debouncers = {};

  /// Debounce une fonction avec une clé unique
  static void debounce(String key, Duration delay, VoidCallback action) {
    _debouncers[key]?.cancel();
    _debouncers[key] = Timer(delay, action);
  }

  /// Throttle une fonction pour limiter sa fréquence d'exécution
  static final Map<String, DateTime> _lastExecutions = {};

  static bool throttle(String key, Duration minInterval) {
    final now = DateTime.now();
    final lastExecution = _lastExecutions[key];

    if (lastExecution == null || now.difference(lastExecution) >= minInterval) {
      _lastExecutions[key] = now;
      return true;
    }
    return false;
  }

  /// Cache en mémoire simple avec expiration
  static final Map<String, _CacheEntry> _memoryCache = {};

  static T? getFromCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry != null && !entry.isExpired) {
      return entry.value as T;
    }
    _memoryCache.remove(key);
    return null;
  }

  static void setCache<T>(String key, T value, Duration duration) {
    _memoryCache[key] = _CacheEntry(value, DateTime.now().add(duration));

    // Nettoyage du cache si trop d'entrées
    if (_memoryCache.length > 1000) {
      _cleanupCache();
    }
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    _memoryCache.removeWhere((key, entry) => entry.expiry.isBefore(now));
  }

  /// Optimise les BigInt operations courantes
  static final Map<String, BigInt> _bigIntCache = {};

  static BigInt getBigIntPower(int base, int exponent) {
    final key = '${base}_$exponent';
    return _bigIntCache.putIfAbsent(key, () => BigInt.from(base).pow(exponent));
  }

  /// Constantes BigInt couramment utilisées pour éviter les recalculs
  static final BigInt oneE6 = BigInt.from(1000000);
  static final BigInt oneE18 = BigInt.from(10).pow(18);

  /// Conversion optimisée de BigInt vers double
  static double bigIntToDouble(BigInt value, int decimals) {
    final divisor = decimals == 6 ? oneE6 : oneE18;
    return value / divisor;
  }

  /// Batch des opérations SharedPreferences
  static final Map<String, dynamic> _pendingPrefs = {};
  static Timer? _prefsTimer;

  static void batchSetPreference(String key, dynamic value) {
    _pendingPrefs[key] = value;

    _prefsTimer?.cancel();
    _prefsTimer = Timer(const Duration(milliseconds: 100), _flushPreferences);
  }

  static Future<void> _flushPreferences() async {
    if (_pendingPrefs.isEmpty) return;

    // Cette fonction devrait être appelée avec SharedPreferences.getInstance()
    // et batching des set operations
    final prefs = _pendingPrefs.entries.toList();
    _pendingPrefs.clear();

    // Notification pour que le code appelant puisse traiter le batch
    debugPrint('⚡ Batch preferences: ${prefs.length} items to flush');
  }

  /// Widget builder optimisé avec cache
  static Widget buildCachedWidget(
      String key, Duration cacheDuration, Widget Function() builder) {
    final cached = getFromCache<Widget>(key);
    if (cached != null) {
      return cached;
    }

    final widget = builder();
    setCache(key, widget, cacheDuration);
    return widget;
  }

  /// Nettoyage des ressources
  static void dispose() {
    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    _lastExecutions.clear();
    _memoryCache.clear();
    _prefsTimer?.cancel();
    _pendingPrefs.clear();
  }
}

/// Classe interne pour les entrées de cache
class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
