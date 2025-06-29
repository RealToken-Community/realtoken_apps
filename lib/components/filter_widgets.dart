import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

/// Factory pour construire les widgets de filtres de manière standardisée
/// Réduit la duplication entre portfolio_page.dart et realtokens_page.dart
class FilterWidgets {
  
  /// Construit un bouton de filtre simple standardisé
  static Widget buildFilterButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit un popup menu de filtre standardisé
  static Widget buildFilterPopupMenu({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<String>> items,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Extrait les villes uniques depuis une liste de tokens/portfolio
  static List<String> getUniqueCities(List<Map<String, dynamic>> items) {
    final cities = items
        .map((item) {
          List<String> parts = item['fullName'].split(',');
          return parts.length >= 2 ? parts[1].trim() : S.current.unknownCity;
        })
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  /// Extrait les régions uniques depuis une liste de tokens/portfolio
  static List<String> getUniqueRegions(List<Map<String, dynamic>> items) {
    final regions = items
        .map((item) => item['regionCode'] ?? "Unknown Region")
        .where((region) => region != null)
        .toSet()
        .cast<String>()
        .toList();
    regions.sort();
    return regions;
  }

  /// Extrait les pays uniques depuis une liste de tokens/portfolio
  static List<String> getUniqueCountries(List<Map<String, dynamic>> items) {
    final countries = items
        .map((item) {
          String country = item['country'] ?? "Unknown Country";
          // Regrouper les tokens factoring_profitshare avec des séries sous "Series XX"
          if ((item['productType']?.toString().toLowerCase() == 'factoring_profitshare') && 
              country.toLowerCase().startsWith('series ')) {
            return "Series XX";
          }
          return country;
        })
        .where((country) => country != null)
        .toSet()
        .cast<String>()
        .toList();
    countries.sort();
    return countries;
  }

  /// Construit un PopupMenuItem pour les villes avec l'option "Toutes les villes"
  static List<PopupMenuEntry<String>> buildCityMenuItems(
    BuildContext context, 
    List<String> cities
  ) {
    return [
      PopupMenuItem(
        value: S.of(context).allCities,
        child: Text(S.of(context).allCities),
      ),
      ...cities.map((city) => PopupMenuItem(
        value: city,
        child: Text(city),
      )),
    ];
  }

  /// Construit un PopupMenuItem pour les régions avec l'option "Toutes les régions"
  static List<PopupMenuEntry<String>> buildRegionMenuItems(
    BuildContext context, 
    List<String> regions
  ) {
    return [
      PopupMenuItem(
        value: S.of(context).allRegions,
        child: Text(S.of(context).allRegions),
      ),
      ...regions.map((region) => PopupMenuItem(
        value: region,
        child: Text(region),
      )),
    ];
  }

  /// Construit un PopupMenuItem pour les pays avec l'option "Tous les pays"
  static List<PopupMenuEntry<String>> buildCountryMenuItems(
    BuildContext context, 
    List<String> countries
  ) {
    return [
      PopupMenuItem(
        value: S.of(context).allCountries,
        child: Text(S.of(context).allCountries),
      ),
      ...countries.map((country) => PopupMenuItem(
        value: country,
        child: Text(country),
      )),
    ];
  }

  /// Construit un filtre de ville standardisé
  static Widget buildCityFilter({
    required BuildContext context,
    required List<String> cities,
    required String? selectedCity,
    required Function(String?) onCitySelected,
  }) {
    return buildFilterPopupMenu(
      context: context,
      icon: Icons.location_city,
      label: selectedCity ?? S.of(context).city,
      items: buildCityMenuItems(context, cities),
      onSelected: (String value) {
        onCitySelected(value == S.of(context).allCities ? null : value);
      },
    );
  }

  /// Construit un filtre de région standardisé
  static Widget buildRegionFilter({
    required BuildContext context,
    required List<String> regions,
    required String? selectedRegion,
    required Function(String?) onRegionSelected,
  }) {
    return buildFilterPopupMenu(
      context: context,
      icon: Icons.map,
      label: selectedRegion ?? S.of(context).region,
      items: buildRegionMenuItems(context, regions),
      onSelected: (String value) {
        onRegionSelected(value == S.of(context).allRegions ? null : value);
      },
    );
  }

  /// Construit un filtre de pays standardisé
  static Widget buildCountryFilter({
    required BuildContext context,
    required List<String> countries,
    required String? selectedCountry,
    required Function(String?) onCountrySelected,
  }) {
    return buildFilterPopupMenu(
      context: context,
      icon: Icons.flag,
      label: selectedCountry ?? S.of(context).country,
      items: buildCountryMenuItems(context, countries),
      onSelected: (String value) {
        onCountrySelected(value == S.of(context).allCountries ? null : value);
      },
    );
  }
} 