import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';

class ChartUtils {
  // Constante pour le nombre maximum de barres à afficher
  static const int maxBarsToDisplay = 20;

  static Widget buildPeriodSelector(
    BuildContext context, {
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
  }) {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton(S.of(context).day, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).week, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).month, context, selectedPeriod, onPeriodChanged),
            _buildPeriodButton(S.of(context).year, context, selectedPeriod, onPeriodChanged),
          ],
        ),
      ),
    );
  }

  static Widget _buildPeriodButton(String period, BuildContext context, String selectedPeriod, Function(String) onPeriodChanged) {
    final isSelected = selectedPeriod == period;
    final appState = Provider.of<AppState>(context);

    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12 + appState.getTextSizeOffset(),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  /// Calcule le pas (step) à utiliser pour limiter le nombre de barres affichées
  static int calculateStep(int dataLength) {
    if (dataLength <= maxBarsToDisplay) {
      return 1; // Pas de step si moins que le maximum
    }
    
    // Calcule le pas minimum pour ne pas dépasser maxBarsToDisplay
    return (dataLength / maxBarsToDisplay).ceil();
  }

  /// Applique un step aux données pour limiter le nombre de points affichés
  static List<FlSpot> applyStepToData(List<FlSpot> spots) {
    if (spots.isEmpty) return spots;
    
    final step = calculateStep(spots.length);
    if (step == 1) return spots; // Pas de changement nécessaire
    
    List<FlSpot> filteredSpots = [];
    
    // Toujours inclure le premier et le dernier point
    if (spots.isNotEmpty) {
      filteredSpots.add(spots.first);
    }
    
    // Ajouter les points intermédiaires selon le step
    for (int i = step; i < spots.length - 1; i += step) {
      filteredSpots.add(spots[i]);
    }
    
    // Ajouter le dernier point s'il n'est pas déjà inclus
    if (spots.length > 1 && spots.last != filteredSpots.last) {
      filteredSpots.add(spots.last);
    }
    
    // Recalculer les indices x pour qu'ils soient séquentiels
    return filteredSpots.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.y);
    }).toList();
  }

  static List<FlSpot> buildHistoryChartData<T>(
    BuildContext context, 
    List<T> history, 
    String selectedPeriod, 
    double Function(T) getValue, 
    DateTime Function(T) getTimestamp,
    {bool applyStep = true, String aggregate = "average"} // Ajout du paramètre aggregate
  ) {
    Map<String, List<double>> groupedData = {};

    for (var record in history) {
      DateTime date = getTimestamp(record);
      String periodKey;

      if (selectedPeriod == S.of(context).day) {
        periodKey = DateFormat('yyyy/MM/dd').format(date);
      } else if (selectedPeriod == S.of(context).week) {
        periodKey = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
      } else if (selectedPeriod == S.of(context).month) {
        periodKey = DateFormat('yyyy/MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      // LOG DEBUG
      // debugPrint('[CHART-DEBUG] date=$date, periodKey=$periodKey, valeur=${getValue(record)}');

      groupedData.putIfAbsent(periodKey, () => []).add(getValue(record));
    }

    List<FlSpot> spots = [];
    List<String> sortedKeys = groupedData.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length; i++) {
      String periodKey = sortedKeys[i];
      List<double> values = groupedData[periodKey]!;
      double yValue;
      if (aggregate == "sum") {
        yValue = values.reduce((a, b) => a + b);
      } else {
        yValue = values.reduce((a, b) => a + b) / values.length;
      }
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    // Appliquer le step pour limiter le nombre de barres si applyStep est true
    return applyStep ? applyStepToData(spots) : spots;
  }

  /// Applique un step aux dates pour limiter le nombre d'étiquettes affichées
  static List<String> applyStepToLabels(List<String> labels) {
    if (labels.isEmpty) return labels;
    
    final step = calculateStep(labels.length);
    if (step == 1) return labels; // Pas de changement nécessaire
    
    List<String> filteredLabels = [];
    
    // Toujours inclure la première et la dernière étiquette
    if (labels.isNotEmpty) {
      filteredLabels.add(labels.first);
    }
    
    // Ajouter les étiquettes intermédiaires selon le step
    for (int i = step; i < labels.length - 1; i += step) {
      filteredLabels.add(labels[i]);
    }
    
    // Ajouter la dernière étiquette si elle n'est pas déjà incluse
    if (labels.length > 1 && !filteredLabels.contains(labels.last)) {
      filteredLabels.add(labels.last);
    }
    
    // Compléter avec des étiquettes vides pour maintenir l'alignement
    final fullLength = filteredLabels.length;
    List<String> completeLabels = List.filled(fullLength, "");
    
    for (int i = 0; i < filteredLabels.length; i++) {
      completeLabels[i] = filteredLabels[i];
    }
    
    return completeLabels;
  }

  static Widget buildPeriodButton({
    required BuildContext context,
    required String period,
    required bool isSelected,
    bool isFirst = false,
    bool isLast = false,
    required Function() onTap,
  }) {
    final appState = Provider.of<AppState>(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
