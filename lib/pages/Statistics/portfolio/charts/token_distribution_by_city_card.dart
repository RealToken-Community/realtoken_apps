import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/modals/Modal_others_pie.dart';
import 'package:realtokens/pages/Statistics/portfolio/common_functions.dart';

class TokenDistributionByCityCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByCityCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByCityCardState createState() => _TokenDistributionByCityCardState();
}

class _TokenDistributionByCityCardState extends State<TokenDistributionByCityCard> {
  int? _selectedIndexCity;
  final ValueNotifier<int?> _selectedIndexNotifierCity = ValueNotifier<int?>(null);
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).tokenDistributionByCity,
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
                valueListenable: _selectedIndexNotifierCity,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByCity(widget.dataManager, othersDetails, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierCity.value = touchedIndex >= 0 ? touchedIndex : null;

                                if (event is FlTapUpEvent) {
                                  final section = response.touchedSection!.touchedSection;
                                  if (section!.title.contains(S.of(context).others)) {
                                    showOtherDetailsModal(context, widget.dataManager, othersDetails, 'city');
                                  }
                                }
                              } else {
                                _selectedIndexNotifierCity.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterTextByCity(widget.dataManager, selectedIndex, othersDetails),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCity(widget.dataManager, othersDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails, int? selectedIndex) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par 'count' croissant
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    othersDetails.clear(); // Clear previous details of "Autres"
    int othersValue = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final baseColor = generateColor(sortedCities.indexOf(entry)); // Utiliser la fonction commune

      // Appliquer l'opacité uniquement si un segment est sélectionné
      final bool isSelected = selectedIndex == sortedCities.indexOf(entry);
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      if (percentage < 2) {
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        sections.add(PieChartSectionData(
          value: value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: baseColor.withOpacity(opacity),
          radius: isSelected ? 52 : 45,
          titleStyle: TextStyle(
            fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          badgeWidget: isSelected ? _buildSelectedIndicator() : null,
          badgePositionPercentageOffset: 1.1,
        ));
      }
    }

    // Ajouter la section "Autres" si nécessaire
    if (othersValue > 0) {
      final double othersPercentage = (othersValue / totalCount) * 100;
      sections.add(PieChartSectionData(
        value: othersValue.toDouble(),
        title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
        color: Colors.grey.shade400.withOpacity(selectedIndex != null && selectedIndex == sections.length ? 1.0 : 0.5),
        radius: selectedIndex != null && selectedIndex == sections.length ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: selectedIndex != null && selectedIndex == sections.length ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        badgeWidget: selectedIndex != null && selectedIndex == sections.length ? _buildSelectedIndicator() : null,
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTextByCity(DataManager dataManager, int? selectedIndex, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

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

    // Afficher les détails du segment sélectionné
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex < sortedCities.length) {
      final selectedCity = sortedCities[selectedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCity.key,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: generateColor(selectedIndex),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedCity.value.toString(),
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

  Widget _buildLegendByCity(DataManager dataManager, List<Map<String, dynamic>> othersDetails) {
    Map<String, int> cityCount = {};
    final appState = Provider.of<AppState>(context);

    // Remplir le dictionnaire avec les counts par ville
    for (var token in dataManager.portfolio) {
      String city = token['city'];
      cityCount[city] = (cityCount[city] ?? 0) + 1;
    }

    // Calculer le total des tokens
    int totalCount = cityCount.values.fold(0, (sum, value) => sum + value);

    // Trier les villes par 'count' croissant
    final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<Widget> legendItems = [];
    int othersValue = 0;
    int indexCounter = 0;

    // Parcourir les villes et regrouper celles avec < 2%
    for (var entry in sortedCities) {
      final city = entry.key;
      final value = entry.value;
      final double percentage = (value / totalCount) * 100;
      final color = generateColor(indexCounter);

      if (percentage < 2) {
        // Ajouter aux "Autres" si < 2%
        othersValue += value;
        othersDetails.add({'city': city, 'count': value}); // Stocker les détails de "Autres"
      } else {
        final index = sortedCities.indexOf(entry);
        // Ajouter un élément de légende pour cette ville
        legendItems.add(
          InkWell(
            onTap: () {
              _selectedIndexNotifierCity.value = (_selectedIndexNotifierCity.value == index) ? null : index;
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: _selectedIndexNotifierCity.value == index ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedIndexNotifierCity.value == index ? color : Colors.transparent,
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    city,
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: _selectedIndexNotifierCity.value == index ? color : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _selectedIndexNotifierCity.value == index ? FontWeight.w600 : FontWeight.normal,
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
            _selectedIndexNotifierCity.value = (_selectedIndexNotifierCity.value == indexOthers) ? null : indexOthers;
            if (_selectedIndexNotifierCity.value == indexOthers) {
              // Optionnellement, ouvrir le modal lorsqu'on clique sur "Autres" dans la légende
              showOtherDetailsModal(context, widget.dataManager, othersDetails, 'city');
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifierCity.value == indexOthers ? Colors.grey.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifierCity.value == indexOthers ? Colors.grey : Colors.transparent,
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
                        color: Colors.black.withOpacity(0.1),
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
                    color: _selectedIndexNotifierCity.value == indexOthers ? Colors.grey.shade700 : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifierCity.value == indexOthers ? FontWeight.w600 : FontWeight.normal,
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
}
