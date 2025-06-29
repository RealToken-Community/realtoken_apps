/// Constantes pour toutes les clés utilisées dans SharedPreferences
/// Centralisation pour éviter les erreurs de typo et faciliter la maintenance
class PreferenceKeys {
  // === PARAMÈTRES DE THÈME ===
  static const String isDarkTheme = 'isDarkTheme';
  static const String themeMode = 'themeMode';
  static const String primaryColor = 'primaryColor';

  // === PARAMÈTRES D'AFFICHAGE ===
  static const String textSize = 'textSize';
  static const String language = 'language';
  static const String showAmounts = 'showAmounts';

  // === PARAMÈTRES DU PORTFOLIO ===
  static const String showTotalInvested = 'showTotalInvested';
  static const String showNetTotal = 'showNetTotal';
  static const String manualAdjustment = 'manualAdjustment';
  static const String showYamProjection = 'showYamProjection';
  static const String initialInvestmentAdjustment =
      'initialInvestmentAdjustment';

  // === ADRESSES ET WALLETS ===
  static const String evmAddresses = 'evmAddresses';

  // === STATISTIQUES D'UTILISATION ===
  static const String appOpenCount = 'appOpenCount';
  static const String lastDonationPopupTimestamp = 'lastDonationPopupTimestamp';

  // === AUTHENTIFICATION BIOMÉTRIQUE ===
  static const String biometricEnabled = 'biometricEnabled';
  static const String biometricType = 'biometricType';

  // === CACHE ET PRÉFÉRENCES API ===
  static const String lastApiUpdate = 'lastApiUpdate';
  static const String cacheTimeout = 'cacheTimeout';

  // === NOTIFICATIONS ===
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String notificationTime = 'notificationTime';
  static const String hasRefusedNotifications = 'hasRefusedNotifications';
  static const String hasAskedNotifications = 'hasAskedNotifications';

  // === PARAMÈTRES AVANCÉS ===
  static const String debugMode = 'debugMode';
  static const String analyticsEnabled = 'analyticsEnabled';
  static const String crashReportsEnabled = 'crashReportsEnabled';

  // === PRÉFÉRENCES DE DEVISE ===
  static const String selectedCurrency = 'selectedCurrency';
  static const String currencyUpdateFrequency = 'currencyUpdateFrequency';

  // === PRÉFÉRENCES D'EXPORT ===
  static const String lastExportPath = 'lastExportPath';
  static const String exportFormat = 'exportFormat';

  // === MÉTHODES UTILITAIRES ===

  /// Retourne toutes les clés de thème
  static List<String> get themeKeys => [
        isDarkTheme,
        themeMode,
        primaryColor,
      ];

  /// Retourne toutes les clés d'affichage
  static List<String> get displayKeys => [
        textSize,
        language,
        showAmounts,
      ];

  /// Retourne toutes les clés de portfolio
  static List<String> get portfolioKeys => [
        showTotalInvested,
        showNetTotal,
        manualAdjustment,
        showYamProjection,
        initialInvestmentAdjustment,
      ];

  /// Retourne toutes les clés de sécurité
  static List<String> get securityKeys => [
        biometricEnabled,
        biometricType,
      ];

  /// Retourne toutes les clés de données utilisateur
  static List<String> get userDataKeys => [
        evmAddresses,
        selectedCurrency,
      ];

  /// Retourne toutes les clés critiques (ne pas supprimer lors d'un reset)
  static List<String> get criticalKeys => [
        evmAddresses,
        biometricEnabled,
        selectedCurrency,
      ];

  /// Retourne toutes les clés existantes
  static List<String> get allKeys => [
        ...themeKeys,
        ...displayKeys,
        ...portfolioKeys,
        ...securityKeys,
        ...userDataKeys,
        appOpenCount,
        lastDonationPopupTimestamp,
        lastApiUpdate,
        cacheTimeout,
        notificationsEnabled,
        notificationTime,
        debugMode,
        analyticsEnabled,
        crashReportsEnabled,
        currencyUpdateFrequency,
        lastExportPath,
        exportFormat,
      ];

  /// Vérifie si une clé est valide
  static bool isValidKey(String key) {
    return allKeys.contains(key);
  }

  /// Retourne la catégorie d'une clé
  static String getKeyCategory(String key) {
    if (themeKeys.contains(key)) return 'Thème';
    if (displayKeys.contains(key)) return 'Affichage';
    if (portfolioKeys.contains(key)) return 'Portfolio';
    if (securityKeys.contains(key)) return 'Sécurité';
    if (userDataKeys.contains(key)) return 'Données utilisateur';
    return 'Autres';
  }
}
