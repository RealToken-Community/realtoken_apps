import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class TokenDistributionByCountryCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByCountryCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByCountryCardState createState() => _TokenDistributionByCountryCardState();
}

class _TokenDistributionByCountryCardState extends State<TokenDistributionByCountryCard> {
  int? _selectedIndexCountry;
  final ValueNotifier<int?> _selectedIndexNotifierCountry = ValueNotifier<int?>(null);

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
              S.of(context).tokenDistributionByCountry,
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
                valueListenable: _selectedIndexNotifierCountry,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByCountry(widget.dataManager, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierCountry.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierCountry.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterTextByCountry(widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByCountry(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByCountry(DataManager dataManager, int? selectedIndex) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    print('Nombre de tokens dans le portfolio: ${dataManager.portfolio.length}');

    // Remplir le dictionnaire avec les counts par pays
    for (var token in dataManager.portfolio) {
      String country = token['country'] ?? S.of(context).unknownCountry;
      print('Token: ${token['id']}');
      print('Pays: $country');

      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    print('Nombre de pays trouvés: ${countryCount.length}');
    print('Pays et leurs counts: $countryCount');

    // Trier les pays par ordre alphabétique pour garantir un ordre constant
    final sortedCountries = countryCount.keys.toList()..sort();

    // Créer les sections du graphique à secteurs avec des gradients
    return sortedCountries.asMap().entries.map((entry) {
      final index = entry.key;
      final country = entry.value;
      final int value = countryCount[country]!;
      final double percentage = (value / countryCount.values.reduce((a, b) => a + b)) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Utiliser generateColor avec l'index
      final Color baseColor = generateColor(index);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
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
      );
    }).toList();
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

  Widget _buildCenterTextByCountry(DataManager dataManager, int? selectedIndex) {
    Map<String, int> countryCount = {};

    // Remplir le dictionnaire avec les counts par pays
    for (var token in dataManager.portfolio) {
      String country = token['country'] ?? S.of(context).unknownCountry;
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    final totalCount = countryCount.values.reduce((a, b) => a + b);

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
    final sortedCountries = countryCount.keys.toList()..sort();
    final selectedCountry = sortedCountries[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedCountry,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: generateColor(selectedIndex),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          countryCount[selectedCountry].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendByCountry(DataManager dataManager) {
    Map<String, int> countryCount = {};
    final appState = Provider.of<AppState>(context);

    // Compter les occurrences par pays
    for (var token in dataManager.portfolio) {
      String country = token['country'] ?? S.of(context).unknownCountry;
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }

    // Utiliser le même tri que pour le graphique
    final sortedCountries = countryCount.keys.toList()..sort();

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedCountries.asMap().entries.map((entry) {
        final index = entry.key;
        final country = entry.value;
        final color = generateColor(index);

        return InkWell(
          onTap: () {
            _selectedIndexNotifierCountry.value = (_selectedIndexNotifierCountry.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifierCountry.value == index ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifierCountry.value == index ? color : Colors.transparent,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  country,
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: _selectedIndexNotifierCountry.value == index ? color : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifierCountry.value == index ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color generateColor(int index) {
    final hue = ((index * 57) + 193 * (index % 3)) % 360;
    final saturation = (0.7 + (index % 5) * 0.06).clamp(0.4, 0.7);
    final brightness = (0.8 + (index % 3) * 0.2).clamp(0.6, 0.9);
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, brightness).toColor();
  }
}
