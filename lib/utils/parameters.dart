import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class Parameters {
  // Référence statique à l'instance de AppState
  static AppState? _appState;

  // Méthode pour initialiser AppState
  static void initAppState(BuildContext context) {
    _appState = Provider.of<AppState>(context, listen: false);
  }

  static const String mainApiUrl = 'https://api.vfhome.fr';
  static const String realTokensUrl = 'https://api.pitsbi.io/api';
  static const String rentTrackerUrl =
      'https://ehpst.duckdns.org/realt_rent_tracker/api';
  static const String coingeckoUrl =
      'https://api.coingecko.com/api/v3/coins/xdai';

  static const List<String> stables = [
    "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d",
    "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83",
    "0x7349c9eaa538e118725a6130e0f8341509b9f8a0"
  ];
  static String rwaTokenAddress = '0x0675e8f4a52ea6c845cb6427af03616a2af42170';
  // 📌 Autres paramètres inchangés
  static const Duration apiCacheDuration = Duration(minutes: 1);
  static bool convertToSquareMeters = false;
  static String selectedCurrency = 'usd';
  static List<String> languages = ['en', 'fr', 'es', "zh", "it", "pt", "ru"];
  static List<String> textSizeOptions = [
    'verySmall',
    'small',
    'normal',
    'big',
    'veryBig'
  ];

  // Paramètres pour le portfolio - transformés en getters
  static bool get showTotalInvested => _appState?.showTotalInvested ?? false;
  static bool get showNetTotal => _appState?.showNetTotal ?? true;
  static double get manualAdjustment => _appState?.manualAdjustment ?? 0.0;
  static bool get showYamProjection => _appState?.showYamProjection ?? true;
  static double get initialInvestmentAdjustment =>
      _appState?.initialInvestmentAdjustment ?? 0.0;

  // Méthodes pour mettre à jour les paramètres
  static void setShowTotalInvested(bool value) {
    _appState?.updateShowTotalInvested(value);
  }

  static void setShowNetTotal(bool value) {
    _appState?.updateShowNetTotal(value);
  }

  static void setManualAdjustment(double value) {
    _appState?.updateManualAdjustment(value);
  }

  static void setShowYamProjection(bool value) {
    _appState?.updateShowYamProjection(value);
  }

  static void setInitialInvestmentAdjustment(double value) {
    _appState?.updateInitialInvestmentAdjustment(value);
  }

  static String getPropertyTypeName(int? propertyType, BuildContext context) {
    switch (propertyType) {
      case 1:
        return S.of(context).singleFamily;
      case 2:
        return S.of(context).multiFamily;
      case 3:
        return S.of(context).duplex;
      case 4:
        return S.of(context).condominium;
      case 6:
        return S.of(context).mixedUse;
      case 8:
        return S.of(context).multiFamily;
      case 9:
        return S.of(context).commercial;
      case 10:
        return S.of(context).sfrPortfolio;
      case 11:
        return S.of(context).mfrPortfolio;
      case 12:
        return S.of(context).resortBungalow;
      default:
        return S.of(context).unknown;
    }
  }

  static final Map<String, String> usStateAbbreviations = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming'
  };

  static final Map<String, String> currencySymbols = {
    'usd': '\$',
    'eur': '€',
    'gbp': '£',
    'jpy': '¥',
    'inr': '₹',
    'btc': '₿',
    'eth': 'Ξ'
  };

  // Mapping des régions spéciales
  static String getRegionDisplayName(String region) {
    switch (region) {
      case 'Ty':
        return 'Factoring';
      default:
        return usStateAbbreviations[region] ?? region;
    }
  }

  // Mapping des noms de pays vers les noms de fichiers
  static String getCountryFileName(String country) {
    switch (country.toLowerCase()) {
      case 'series xx':
        return 'series_xx';
      default:
        return country.toLowerCase();
    }
  }
}
