import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

/// Factory pour construire les éléments de graphiques en secteurs de manière standardisée
/// Réduit la duplication dans les cartes de distribution de tokens
class PieChartBuilders {
  /// Construit un graphique en secteurs standardisé avec gestion du touch
  static Widget buildStandardPieChart({
    required BuildContext context,
    required String title,
    required List<PieChartSectionData> sections,
    required ValueNotifier<int?> selectedIndexNotifier,
    double centerSpaceRadius = 65,
    double sectionsSpace = 3,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);

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
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
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
                valueListenable: selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: centerSpaceRadius,
                          sectionsSpace: sectionsSpace,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                selectedIndexNotifier.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      if (selectedIndex != null &&
                          selectedIndex < sections.length)
                        buildCenterText(
                          context: context,
                          title:
                              _extractTitleFromSection(sections[selectedIndex]),
                          value: sections[selectedIndex].value,
                          appState: appState,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une section de graphique en secteurs standardisée
  static PieChartSectionData buildStandardSection({
    required double value,
    required String title,
    required Color color,
    required BuildContext context,
    required AppState appState,
    bool isSelected = false,
    int? selectedIndex,
    double selectedRadius = 52,
    double normalRadius = 45,
    double selectedFontSize = 14,
    double normalFontSize = 10,
    bool showBadge = true,
  }) {
    final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;
    final radius = isSelected ? selectedRadius : normalRadius;
    final fontSize = isSelected ? selectedFontSize : normalFontSize;

    return PieChartSectionData(
      value: value,
      title: title,
      color: color.withValues(alpha: opacity),
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize + appState.getTextSizeOffset(),
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
      badgeWidget:
          isSelected && showBadge ? buildSelectedIndicator(context) : null,
      badgePositionPercentageOffset: 1.1,
    );
  }

  /// Construit l'indicateur de sélection standardisé
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

  /// Construit le texte central du graphique en secteurs
  static Widget buildCenterText({
    required BuildContext context,
    required String title,
    required double value,
    required AppState appState,
    String? subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Construit une section "Autres" standardisée
  static PieChartSectionData buildOthersSection({
    required BuildContext context,
    required AppState appState,
    required double othersValue,
    required double totalCount,
    required int sectionIndex,
    int? selectedIndex,
    Color color = Colors.grey,
  }) {
    final double othersPercentage = (othersValue / totalCount) * 100;
    final bool isOthersSelected = selectedIndex == sectionIndex;

    return buildStandardSection(
      value: othersValue,
      title: '${S.of(context).others} ${othersPercentage.toStringAsFixed(1)}%',
      color: color,
      context: context,
      appState: appState,
      isSelected: isOthersSelected,
      selectedIndex: selectedIndex,
    );
  }

  /// Génère une couleur basée sur un index
  static Color generateColor(int index) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.pink.shade400,
      Colors.amber.shade400,
      Colors.cyan.shade400,
      Colors.lime.shade400,
      Colors.deepOrange.shade400,
      Colors.lightBlue.shade400,
      Colors.lightGreen.shade400,
      Colors.deepPurple.shade400,
    ];
    return colors[index % colors.length];
  }

  /// Extrait le titre d'une section pour l'affichage central
  static String _extractTitleFromSection(PieChartSectionData section) {
    // Extraire le nom avant le pourcentage
    final title = section.title ?? '';
    final percentageIndex = title.lastIndexOf(' ');
    if (percentageIndex > 0 &&
        title.substring(percentageIndex + 1).contains('%')) {
      return title.substring(0, percentageIndex);
    }
    return title;
  }

  /// Construit une légende horizontale pour les graphiques en secteurs
  static Widget buildHorizontalLegend({
    required List<LegendItem> items,
    required AppState appState,
    int maxItemsPerRow = 3,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map((item) => buildLegendItem(
                label: item.label,
                color: item.color,
                appState: appState,
              ))
          .toList(),
    );
  }

  /// Construit un élément de légende
  static Widget buildLegendItem({
    required String label,
    required Color color,
    required AppState appState,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Classe pour représenter un élément de légende
class LegendItem {
  final String label;
  final Color color;

  const LegendItem({
    required this.label,
    required this.color,
  });
}
