import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/location_utils.dart';
import 'package:realtoken_asset_tracker/modals/modal_others_pie.dart'; // Assurez-vous que ce fichier existe

class TokenDistributionByRegionCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByRegionCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByRegionCardState createState() => _TokenDistributionByRegionCardState();
}

class _TokenDistributionByRegionCardState extends State<TokenDistributionByRegionCard> {
  int? _selectedIndexRegion;
  final ValueNotifier<int?> _selectedIndexNotifierRegion = ValueNotifier<int?>(null);
  List<Map<String, dynamic>> othersDetails = []; // Pour stocker les détails de la section "Autres"

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByRegion,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierRegion,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByRegion(widget.dataManager, othersDetails, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierRegion.value = touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section = response.touchedSection!.touchedSection;
                                  if (section!.title.contains(S.of(context).others)) {
                                    showOtherDetailsModal(context, widget.dataManager, othersDetails, 'region');
                                  }
                                }
                              } else {
                                _selectedIndexNotifierRegion.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterTextByRegion(widget.dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByRegion(widget.dataManager, othersDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails, int? selectedIndex) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région (utilise LocationUtils)
    for (var token in dataManager.portfolio) {
      String regionCode = token['regionCode'] ?? LocationUtils.extractRegion(token['fullName'] ?? '');
      String regionName = Parameters.getRegionDisplayName(regionCode);
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

    // Trier les régions par 'count' croissant
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear();
    int othersValue = 0;
    int indexCounter = 0;

    for (var entry in sortedRegions) {
      final region = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(indexCounter);

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == indexCounter;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
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
          badgeWidget: isSelected ? _buildSelectedIndicator() : null,
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
        badgeWidget: isOthersSelected ? _buildSelectedIndicator() : null,
        badgePositionPercentageOffset: 1.1,
      ));
    }

    return sections;
  }

  Widget _buildSelectedIndicator() {
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

  Widget _buildCenterTextByRegion(DataManager dataManager, int? selectedIndex, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};

    // Remplir le dictionnaire avec les counts par région (utilise LocationUtils)
    for (var token in dataManager.portfolio) {
      String regionCode = token['regionCode'] ?? LocationUtils.extractRegion(token['fullName'] ?? '');
      String regionName = Parameters.getRegionDisplayName(regionCode);
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

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

    // Trier les régions par 'count' croissant pour correspondre aux sections
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Filtrer les régions dont le pourcentage est < 2%
    List<MapEntry<String, int>> visibleRegions = [];
    int othersValue = 0;
    for (var entry in sortedRegions) {
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      if (percentage < 2) {
        othersValue += value;
      } else {
        visibleRegions.add(entry);
      }
    }

    // Vérifier si l'index sélectionné correspond à une région visible ou à "Autres"
    if (selectedIndex < visibleRegions.length) {
      final selectedRegion = visibleRegions[selectedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedRegion.key,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: generateColor(selectedIndex),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedRegion.value.toString(),
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

  Widget _buildLegendByRegion(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> regionCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par région
    for (var token in dataManager.portfolio) {
      String regionCode = token['regionCode'] ?? S.of(context).unknownRegion;
      String regionName = Parameters.getRegionDisplayName(regionCode);
      regionCount[regionName] = (regionCount[regionName] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = regionCount.values.fold(0, (sum, value) => sum + value);

    // Trier les régions par 'count' croissant
    final sortedRegions = regionCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;
    int indexCounter = 0;

    for (var entry in sortedRegions) {
      final region = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(indexCounter);

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({'region': region, 'count': value});
      } else {
        // Ajouter un élément de légende pour cette région
        legendItems.add(
          InkWell(
            onTap: () {
              _selectedIndexNotifierRegion.value = (_selectedIndexNotifierRegion.value == indexCounter) ? null : indexCounter;
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: _selectedIndexNotifierRegion.value == indexCounter ? color.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedIndexNotifierRegion.value == indexCounter ? color : Colors.transparent,
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
                    region,
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: _selectedIndexNotifierRegion.value == indexCounter ? color : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _selectedIndexNotifierRegion.value == indexCounter ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        indexCounter++;
      }
    }

    // Ajouter une légende pour "Autres" si nécessaire
    if (othersValue > 0) {
      final indexOthers = indexCounter;
      legendItems.add(
        InkWell(
          onTap: () {
            _selectedIndexNotifierRegion.value = (_selectedIndexNotifierRegion.value == indexOthers) ? null : indexOthers;
            if (_selectedIndexNotifierRegion.value == indexOthers) {
              // Ouvrir le modal lorsqu'on clique sur "Autres" dans la légende
              showOtherDetailsModal(context, widget.dataManager, othersDetails, 'region');
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifierRegion.value == indexOthers ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifierRegion.value == indexOthers ? Colors.grey : Colors.transparent,
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
                    color: _selectedIndexNotifierRegion.value == indexOthers ? Colors.grey.shade700 : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifierRegion.value == indexOthers ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
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

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
}
