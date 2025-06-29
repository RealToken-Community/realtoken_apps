import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:provider/provider.dart';

void showOtherDetailsModal(BuildContext context, dataManager, List<Map<String, dynamic>> othersDetails, String key) {
  // S'assurer que la liste n'est pas vide pour éviter les erreurs de rendu
  if (othersDetails.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).noDataAvailable)),
    );
    return;
  }

  // ValueNotifier pour suivre l'élément sélectionné
  final ValueNotifier<int?> selectedIndexNotifier = ValueNotifier<int?>(null);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: MediaQuery.of(context).size.height * 0.8,
        child: SafeArea(
          child: Column(
            children: [
              // Barre de drag en haut
              Container(
                margin: EdgeInsets.only(top: 10),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        S.of(context).othersTitle,
                        style: TextStyle(
                          fontSize: 22 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Graphique avec sélection
                      SizedBox(
                        height: 250,
                        child: ValueListenableBuilder<int?>(
                            valueListenable: selectedIndexNotifier,
                            builder: (context, selectedIndex, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sections: _buildOtherDetailsDonutData(othersDetails, key, selectedIndex),
                                      centerSpaceRadius: 55,
                                      sectionsSpace: 3,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, PieTouchResponse? touchResponse) {
                                          if (touchResponse != null && touchResponse.touchedSection != null) {
                                            final touchedIndex = touchResponse.touchedSection!.touchedSectionIndex;
                                            if (event is FlTapUpEvent) {
                                              selectedIndexNotifier.value = selectedIndex == touchedIndex ? null : touchedIndex;
                                            }
                                          }
                                        },
                                      ),
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                                  _buildCenterText(context, othersDetails, key, selectedIndex),
                                ],
                              );
                            }),
                      ),

                      SizedBox(height: 10),

                      // Titre pour la légende
                      Text(
                        S.of(context).legend,
                        style: TextStyle(
                          fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(height: 10),

                      // Légende avec défilement
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.all(12),
                          child: ValueListenableBuilder<int?>(
                              valueListenable: selectedIndexNotifier,
                              builder: (context, selectedIndex, _) {
                                return _buildLegendGrid(othersDetails, key, selectedIndex, (index) {
                                  selectedIndexNotifier.value = selectedIndex == index ? null : index;
                                });
                              }),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Widget pour afficher le texte au centre du donut
Widget _buildCenterText(BuildContext context, List<Map<String, dynamic>> othersDetails, String key, int? selectedIndex) {
  if (selectedIndex == null) {
    // Afficher le total quand rien n'est sélectionné
    final int totalCount = othersDetails.fold(0, (sum, item) {
      final count = item['count'] is int ? item['count'] as int : (item['count'] as double).round();
      return sum + count;
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.of(context).total,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$totalCount',
          style: TextStyle(
            fontSize: 22 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  } else {
    // Afficher le détail de l'élément sélectionné
    if (selectedIndex < othersDetails.length) {
      final selectedItem = othersDetails[selectedIndex];
      final String name = selectedItem[key] ?? S.of(context).unknown;
      final count = selectedItem['count'] is int ? selectedItem['count'] as int : (selectedItem['count'] as double).round();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: _getColorForIndex(selectedIndex),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      );
    }

    // En cas d'index invalide
    return Container();
  }
}

List<PieChartSectionData> _buildOtherDetailsDonutData(List<Map<String, dynamic>> othersDetails, String key, int? selectedIndex) {
  // Couleurs iOS
  final List<Color> sectionColors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
    CupertinoColors.systemTeal,
    CupertinoColors.systemYellow,
    Color(0xFF66E0E5),
    Color(0xFF5D5FEE),
    Color(0xFFAF7CEF),
  ];

  // Calculer la valeur totale
  double totalValue = 0;
  for (var item in othersDetails) {
    double itemValue = (item['count'] is int) ? (item['count'] as int).toDouble() : (item['count'] as double);
    totalValue += itemValue;
  }

  // Créer les sections
  List<PieChartSectionData> sections = [];

  for (int i = 0; i < othersDetails.length; i++) {
    final item = othersDetails[i];
    final double value = (item['count'] is int) ? (item['count'] as int).toDouble() : (item['count'] as double);

    final double percentage = (value / totalValue) * 100;
    final bool isSelected = selectedIndex == i;
    final double radius = isSelected ? 65 : 55;
    final Color color = sectionColors[i % sectionColors.length];

    sections.add(PieChartSectionData(
      value: value,
      title: '${percentage.toStringAsFixed(1)}%',
      color: color.withValues(alpha: selectedIndex != null && !isSelected ? 0.5 : 1.0),
      radius: radius,
      titleStyle: TextStyle(
        fontSize: isSelected ? 14 : 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
      badgeWidget: isSelected ? _buildSelectedIndicator(color) : null,
      badgePositionPercentageOffset: 0.98,
    ));
  }

  return sections;
}

Widget _buildLegendGrid(List<Map<String, dynamic>> othersDetails, String key, int? selectedIndex, Function(int) onTap) {
  // Couleurs iOS
  final List<Color> sectionColors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
    CupertinoColors.systemTeal,
    CupertinoColors.systemYellow,
    Color(0xFF66E0E5),
    Color(0xFF5D5FEE),
    Color(0xFFAF7CEF),
  ];

  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: othersDetails.length,
    shrinkWrap: true,
    physics: BouncingScrollPhysics(),
    itemBuilder: (context, index) {
      final item = othersDetails[index];
      final String name = item[key] ?? 'Inconnu';
      final double value = (item['count'] is int) ? (item['count'] as int).toDouble() : (item['count'] as double);
      final Color color = sectionColors[index % sectionColors.length];
      final bool isSelected = selectedIndex == index;

      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                spreadRadius: 0,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                    color: isSelected ? color : CupertinoColors.label,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSelectedIndicator(Color color) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(
        color: color,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
  );
}

Color _getColorForIndex(int index) {
  final List<Color> sectionColors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
    CupertinoColors.systemTeal,
    CupertinoColors.systemYellow,
    Color(0xFF66E0E5),
    Color(0xFF5D5FEE),
    Color(0xFFAF7CEF),
  ];

  return sectionColors[index % sectionColors.length];
}
