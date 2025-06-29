import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:provider/provider.dart';

/// Factory pour construire les éléments de graphiques de manière standardisée
/// Réduit la duplication dans GenericChartWidget
class ChartBuilders {
  /// Construit les données de grille standardisées pour les graphiques
  static FlGridData buildStandardGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withValues(alpha: 0.15),
          strokeWidth: 1,
        );
      },
    );
  }

  /// Construit les titres d'axes standardisés pour les graphiques à barres
  static FlTitlesData buildBarChartTitles({
    required BuildContext context,
    required AppState appState,
    required CurrencyProvider currencyUtils,
    required List<String> labels,
    required String valuePrefix,
    required String valueSuffix,
    double? maxY,
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < labels.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    labels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            String formattedValue;
            if (valuePrefix == currencyUtils.currencySymbol) {
              formattedValue = currencyUtils.formatCompactCurrency(
                value,
                currencyUtils.currencySymbol,
              );
            } else {
              formattedValue =
                  '$valuePrefix${value.toStringAsFixed(1)}$valueSuffix';
            }

            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 10 + appState.getTextSizeOffset(),
                  color: Colors.grey.shade600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construit les titres d'axes standardisés pour les graphiques linéaires
  static FlTitlesData buildLineChartTitles({
    required BuildContext context,
    required AppState appState,
    required CurrencyProvider currencyUtils,
    required List<String> labels,
    required String valuePrefix,
    required String valueSuffix,
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < labels.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    labels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            String formattedValue;
            if (valuePrefix == currencyUtils.currencySymbol) {
              formattedValue = currencyUtils.formatCompactCurrency(
                value,
                currencyUtils.currencySymbol,
              );
            } else {
              formattedValue =
                  '$valuePrefix${value.toStringAsFixed(1)}$valueSuffix';
            }

            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 10 + appState.getTextSizeOffset(),
                  color: Colors.grey.shade600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construit un tooltip standardisé pour les graphiques à barres
  static BarTooltipItem? buildBarTooltip({
    required BuildContext context,
    required String periodKey,
    required double value,
    required String valuePrefix,
    required String valueSuffix,
    required CurrencyProvider currencyUtils,
  }) {
    String valueText;
    if (valuePrefix == currencyUtils.currencySymbol) {
      valueText = currencyUtils.formatCompactCurrency(
        value,
        currencyUtils.currencySymbol,
      );
    } else {
      valueText = '$valuePrefix${value.toStringAsFixed(2)}$valueSuffix';
    }

    return BarTooltipItem(
      '$periodKey\n$valueText',
      TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12 +
            (Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
      ),
    );
  }

  /// Construit un tooltip standardisé pour les graphiques linéaires
  static LineTooltipItem buildLineTooltip({
    required String periodLabel,
    required double value,
    required String valuePrefix,
    required String valueSuffix,
    required CurrencyProvider currencyUtils,
  }) {
    String valueText;
    if (valuePrefix == currencyUtils.currencySymbol) {
      valueText = currencyUtils.formatCompactCurrency(
        value,
        currencyUtils.currencySymbol,
      );
    } else {
      valueText = '$valuePrefix${value.toStringAsFixed(2)}$valueSuffix';
    }

    return LineTooltipItem(
      '$periodLabel\n$valueText',
      const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  /// Construit une barre de graphique standardisée
  static BarChartRodData buildStandardBarRod({
    required double value,
    required Color color,
    required double maxY,
    double width = 12,
  }) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: width,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: maxY,
        color: Colors.grey.withValues(alpha: 0.1),
      ),
    );
  }

  /// Construit une ligne de graphique standardisée
  static LineChartBarData buildStandardLine({
    required List<FlSpot> spots,
    required Color color,
    bool isCurved = true,
    double curveSmoothness = 0.3,
    double barWidth = 3,
    bool showDots = true,
    bool showArea = true,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      curveSmoothness: curveSmoothness,
      barWidth: barWidth,
      color: color,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
        checkToShowDot: (spot, barData) {
          final isFirst = spot.x == 0;
          final isLast = spot.x == barData.spots.length - 1;
          final int dataLength = barData.spots.length;
          int step = 1;

          if (dataLength > 20) {
            step = (dataLength / 20).ceil();
          } else if (dataLength > 10) {
            step = 2;
          }

          final isInteresting = spot.x % step == 0;
          return isFirst || isLast || isInteresting;
        },
      ),
      belowBarData: showArea
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : BarAreaData(show: false),
    );
  }

  /// Construit un élément de légende standardisé
  static Widget buildLegendItem(String label, Color color) {
    return Row(
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Construit une clé de période standardisée pour le regroupement de données
  static String buildPeriodKey(
      DateTime date, String selectedPeriod, BuildContext context) {
    if (selectedPeriod == S.of(context).day) {
      return DateFormat('yyyy/MM/dd').format(date);
    } else if (selectedPeriod == S.of(context).week) {
      return "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
    } else if (selectedPeriod == S.of(context).month) {
      return DateFormat('yyyy/MM').format(date);
    } else {
      return date.year.toString();
    }
  }

  /// Valide et corrige les valeurs de graphique pour éviter les erreurs fl_chart
  static double validateChartValue(double value, {double minValue = 1.0}) {
    if (value.isNaN || value.isInfinite) {
      return minValue;
    }
    return value < minValue ? minValue : value;
  }

  /// Construit un widget de carte vide standardisé
  static Widget buildEmptyCard(
      BuildContext context, AppState appState, String message) {
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
            message,
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
