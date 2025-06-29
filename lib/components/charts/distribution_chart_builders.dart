import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/location_utils.dart';

/// Factory pour construire les graphiques de distribution standardisés
/// Factorisation des patterns répétitifs dans les graphiques en secteurs
class DistributionChartBuilders {
  
  /// Construit les données pour un graphique de distribution par ville
  static List<PieChartSectionData> buildCityDistributionData({
    required BuildContext context,
    required List<Map<String, dynamic>> portfolio,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
  }) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in portfolio) {
      String city = token['city'] ?? LocationUtils.extractCity(token['fullName'] ?? '');
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    return _buildPieChartSections(
      context: context,
      dataCount: cityCount,
      othersDetails: othersDetails,
      selectedIndex: selectedIndex,
      othersKey: 'city',
    );
  }

  /// Construit les données pour un graphique de distribution par région
  static List<PieChartSectionData> buildRegionDistributionData({
    required BuildContext context,
    required List<Map<String, dynamic>> portfolio,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
  }) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in portfolio) {
      String regionCode = token['regionCode'] ?? LocationUtils.extractRegion(token['fullName'] ?? '');
      String regionName = Parameters.getRegionDisplayName(regionCode);
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    return _buildPieChartSections(
      context: context,
      dataCount: regionCount,
      othersDetails: othersDetails,
      selectedIndex: selectedIndex,
      othersKey: 'region',
    );
  }

  /// Construit les données pour un graphique de distribution par pays
  static List<PieChartSectionData> buildCountryDistributionData({
    required BuildContext context,
    required List<Map<String, dynamic>> portfolio,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
  }) {
    Map<String, int> countryCount = {};

    // Remplir le dictionnaire avec les counts par pays
    for (var token in portfolio) {
      String country = token['country'] ?? LocationUtils.extractCountry(token['fullName'] ?? '');
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    return _buildPieChartSections(
      context: context,
      dataCount: countryCount,
      othersDetails: othersDetails,
      selectedIndex: selectedIndex,
      othersKey: 'country',
    );
  }

  /// Construit les données pour un graphique de distribution par wallet
  static List<PieChartSectionData> buildWalletDistributionData({
    required BuildContext context,
    required List<Map<String, dynamic>> portfolio,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
  }) {
    Map<String, int> walletCount = {};

    // Remplir le dictionnaire avec les counts par wallet
    for (var token in portfolio) {
      List<String> wallets = List<String>.from(token['wallets'] ?? []);
      for (String wallet in wallets) {
        String shortWallet = '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}';
        walletCount[shortWallet] = (walletCount[shortWallet] ?? 0) + 1;
      }
    }

    return _buildPieChartSections(
      context: context,
      dataCount: walletCount,
      othersDetails: othersDetails,
      selectedIndex: selectedIndex,
      othersKey: 'wallet',
    );
  }

  /// Méthode privée pour construire les sections du graphique en secteurs
  static List<PieChartSectionData> _buildPieChartSections({
    required BuildContext context,
    required Map<String, int> dataCount,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
    required String othersKey,
  }) {
    final appState = Provider.of<AppState>(context);
    
    // Calculer le total
    int totalCount = dataCount.values.fold(0, (sum, value) => sum + value);
    
    if (totalCount == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.withValues(alpha: 0.2),
          radius: 40,
        )
      ];
    }

    // Trier par count décroissant
    final sortedEntries = dataCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear();
    int othersValue = 0;
    int indexCounter = 0;

    for (var entry in sortedEntries) {
      final key = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(indexCounter);

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == indexCounter;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({othersKey: key, 'count': value});
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: baseColor.withValues(alpha: opacity),
          radius: isSelected ? 52 : 45,
          titleStyle: TextStyle(
            fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          badgeWidget: isSelected ? buildSelectedIndicator(context) : null,
          badgePositionPercentageOffset: 1.1,
        ));
        indexCounter++;
      }
    }

    // Ajouter la section "Autres" si nécessaire
    if (othersValue > 0) {
      final double othersPercentage = (othersValue / totalCount) * 100;
      final bool isOthersSelected = selectedIndex == indexCounter;
      sections.add(PieChartSectionData(
        value: othersValue.toDouble(),
        title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey.shade400.withValues(alpha: isOthersSelected ? 1.0 : (selectedIndex != null ? 0.5 : 1.0)),
        radius: isOthersSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isOthersSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        badgeWidget: isOthersSelected ? buildSelectedIndicator(context) : null,
        badgePositionPercentageOffset: 1.1,
      ));
    }

    return sections;
  }

  /// Construit le texte central du graphique
  static Widget buildCenterText({
    required BuildContext context,
    required Map<String, int> dataCount,
    required List<Map<String, dynamic>> othersDetails,
    required int? selectedIndex,
    required String othersKey,
  }) {
    // Calculer le total
    int totalCount = dataCount.values.fold(0, (sum, value) => sum + value);

    if (selectedIndex == null) {
      // Afficher la valeur totale si aucun segment n'est sélectionné
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).totalValue,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalCount.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Trier par count décroissant pour correspondre aux sections
    final sortedEntries = dataCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Filtrer les entrées dont le pourcentage est < 2%
    List<MapEntry<String, int>> visibleEntries = [];
    int othersValue = 0;
    for (var entry in sortedEntries) {
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      if (percentage < 2) {
        othersValue += value;
      } else {
        visibleEntries.add(entry);
      }
    }

    // Vérifier si l'index sélectionné correspond à une entrée visible ou à "Autres"
    if (selectedIndex < visibleEntries.length) {
      final selectedEntry = visibleEntries[selectedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedEntry.key,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: generateColor(selectedIndex),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedEntry.value.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Afficher les détails de la section "Autres"
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).others,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            othersDetails.fold<int>(0, (sum, item) => sum + (item['count'] as int)).toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  /// Construit la légende du graphique
  static Widget buildLegend({
    required BuildContext context,
    required Map<String, int> dataCount,
    required List<Map<String, dynamic>> othersDetails,
    required ValueNotifier<int?> selectedIndexNotifier,
    required String othersKey,
  }) {
    final appState = Provider.of<AppState>(context);
    
    // Calculer le total
    int totalCount = dataCount.values.fold(0, (sum, value) => sum + value);

    // Trier par count décroissant
    final sortedEntries = dataCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;
    int indexCounter = 0;

    for (var entry in sortedEntries) {
      final key = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(indexCounter);

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({othersKey: key, 'count': value});
      } else {
        // Ajouter un élément de légende pour cette entrée
        legendItems.add(
          ValueListenableBuilder<int?>(
            valueListenable: selectedIndexNotifier,
            builder: (context, selectedIndex, child) {
              return InkWell(
                onTap: () {
                  selectedIndexNotifier.value = (selectedIndexNotifier.value == indexCounter) ? null : indexCounter;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: selectedIndexNotifier.value == indexCounter ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedIndexNotifier.value == indexCounter ? color : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        key,
                        style: TextStyle(
                          fontSize: 12 + appState.getTextSizeOffset(),
                          color: selectedIndexNotifier.value == indexCounter ? color : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: selectedIndexNotifier.value == indexCounter ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
        indexCounter++;
      }
    }

    // Ajouter une légende pour "Autres" si nécessaire
    if (othersValue > 0) {
      final indexOthers = indexCounter;
      legendItems.add(
        ValueListenableBuilder<int?>(
          valueListenable: selectedIndexNotifier,
          builder: (context, selectedIndex, child) {
            return InkWell(
              onTap: () {
                selectedIndexNotifier.value = (selectedIndexNotifier.value == indexOthers) ? null : indexOthers;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: selectedIndexNotifier.value == indexOthers ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedIndexNotifier.value == indexOthers ? Colors.grey : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(1, 1),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).others,
                      style: TextStyle(
                        fontSize: 12 + appState.getTextSizeOffset(),
                        color: selectedIndexNotifier.value == indexOthers ? Colors.grey.shade700 : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: selectedIndexNotifier.value == indexOthers ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: 12.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: legendItems,
    );
  }

  /// Construit l'indicateur de sélection
  static Widget buildSelectedIndicator(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  /// Génère une couleur basée sur l'index
  static Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
} 