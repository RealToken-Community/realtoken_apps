/// Constantes pour la gestion du cache dans toute l'application
/// Centralise les durées pour éviter la duplication et faciliter les ajustements
class CacheConstants {
  // Durées de base
  static const Duration veryShortCache = Duration(minutes: 5);
  static const Duration shortCache = Duration(minutes: 15);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(hours: 6);
  static const Duration veryLongCache = Duration(hours: 24);

  // Caches spécifiques par type de données
  static const Duration balancesCache = Duration(minutes: 15);
  static const Duration rentDataCache = Duration(hours: 1);
  static const Duration currenciesCache = Duration(hours: 1);
  static const Duration realTokensCache = Duration(hours: 3);
  static const Duration yamMarketCache = Duration(hours: 3);
  static const Duration propertiesForSaleCache = Duration(hours: 6);
  static const Duration volumesCache = Duration(hours: 4);
  static const Duration transactionsCache = Duration(hours: 3);
  static const Duration whitelistCache = Duration(hours: 2);
  static const Duration detailedRentCache = Duration(hours: 2);

  // Caches UI
  static const Duration versionCache = Duration(hours: 6);
  static const Duration donationAmountCache = Duration(hours: 1);
  static const Duration apiStatusCache = Duration(minutes: 30);

  // Délais pour éviter les requêtes répétitives
  static const Duration rateLimitDelay = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);

  // Limites de mémoire
  static const int maxCacheEntries = 1000;
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100MB
}
