import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';

class TokenDistributionCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionCard({super.key, required this.dataManager});

  @override
  _TokenDistributionCardState createState() => _TokenDistributionCardState();
}

class _TokenDistributionCardState extends State<TokenDistributionCard> {
  int? _selectedIndexToken;
  final ValueNotifier<int?> _selectedIndexNotifierToken = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Vérifier si les données sont valides
    if (widget.dataManager.propertyData.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Theme.of(context).cardColor,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              S.of(context).noDataAvailable,
              style: TextStyle(
                fontSize: 16 + appState.getTextSizeOffset(),
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

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
              S.of(context).tokenDistribution,
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
                valueListenable: _selectedIndexNotifierToken,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartData(selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierToken.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierToken.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterTextToken(selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(int? selectedIndex) {
    final appState = Provider.of<AppState>(context);

    // Vérifier si des données sont disponibles
    if (widget.dataManager.propertyData.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.withOpacity(0.3),
          radius: 45,
        )
      ];
    }

    print('Nombre de types de propriétés: ${widget.dataManager.propertyData.length}');
    for (var item in widget.dataManager.propertyData) {
      print('Type de propriété: ${item['propertyType']}, Count: ${item['count']}');
    }

    // Trier les données par 'count' dans l'ordre décroissant
    final sortedData = List<Map<String, dynamic>>.from(widget.dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    // Calculer le total pour le pourcentage
    final totalCount = widget.dataManager.propertyData.fold(0.0, (double sum, item) {
      final count = item['count'] ?? 0.0;
      return sum + (count is String ? double.tryParse(count) ?? 0.0 : count);
    });

    return sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final double percentage = (data['count'] / totalCount) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Obtenir la couleur de base pour ce type de propriété
      final Color baseColor = _getPropertyColor(data['propertyType']);

      return PieChartSectionData(
        value: data['count'].toDouble(),
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

  Widget _buildCenterTextToken(int? selectedIndex) {
    // Somme des valeurs de 'count'
    final totalCount = widget.dataManager.propertyData.fold(0.0, (double sum, item) {
      final count = item['count'] ?? 0.0; // Utiliser 0.0 si 'count' est null
      return sum + (count is String ? double.tryParse(count) ?? 0.0 : count);
    });

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
            totalCount.toStringAsFixed(0),
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
    final sortedData = List<Map<String, dynamic>>.from(widget.dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    if (selectedIndex >= sortedData.length) return Container();
    
    final selectedData = sortedData[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Parameters.getPropertyTypeName(selectedData['propertyType'], context),
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: _getPropertyColor(selectedData['propertyType']),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selectedData['count'].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final appState = Provider.of<AppState>(context);

    // Trier les données par 'count' dans l'ordre décroissant
    final sortedData = List<Map<String, dynamic>>.from(widget.dataManager.propertyData)
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = _getPropertyColor(data['propertyType']);

        return InkWell(
          onTap: () {
            _selectedIndexNotifierToken.value = (_selectedIndexNotifierToken.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifierToken.value == index ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifierToken.value == index ? color : Colors.transparent,
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
                Flexible(
                  child: Text(
                    Parameters.getPropertyTypeName(data['propertyType'], context),
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: _selectedIndexNotifierToken.value == index ? color : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _selectedIndexNotifierToken.value == index ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPropertyColor(int propertyType) {
    switch (propertyType) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.yellow;
      case 7:
        return Colors.teal;
      case 8:
        return Colors.brown;
      case 9:
        return Colors.pink;
      case 10:
        return Colors.cyan;
      case 11:
        return Colors.lime;
      case 12:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
