import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/chart_options_utils.dart';
import 'package:realtokens/utils/date_utils.dart';
import 'package:realtokens/models/apy_record.dart';

/// Widget générique pour les graphiques (Wallet Balance, ROI, APY)
class GenericChartWidget<T> extends StatelessWidget {
  final String title;
  final Color chartColor;
  final List<T> dataList;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isBarChart;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;
  final double Function(T) getYValue;
  final DateTime Function(T) getTimestamp;
  final Function(BuildContext)? onEditPressed;
  final String valuePrefix;
  final String valueSuffix;
  final double? maxY; // Valeur maximale de l'axe Y (optionnelle)
  final bool isStacked; // Nouvel attribut pour indiquer si le graphique doit être empilé
  
  // Nouveaux paramètres pour les graphiques empilés
  final List<Color>? stackColors; // Liste des couleurs pour chaque série empilée
  final List<double> Function(T)? getStackValues; // Fonction pour obtenir les valeurs des séries empilées
  final List<String>? stackLabels; // Étiquettes pour la légende des séries empilées
  
  // Nouveaux paramètres pour le switch cumulatif (utilisé pour les graphiques de loyer)
  final bool? isCumulative;
  final Function(bool)? onCumulativeChanged;
  final String? cumulativeLabel;
  final String? nonCumulativeLabel;

  const GenericChartWidget({
    super.key,
    required this.title,
    required this.chartColor,
    required this.dataList,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isBarChart,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
    required this.getYValue,
    required this.getTimestamp,
    this.onEditPressed,
    this.valuePrefix = '',
    this.valueSuffix = '',
    this.maxY,
    this.isStacked = false,
    // Nouveaux paramètres pour l'empilement
    this.stackColors,
    this.getStackValues,
    this.stackLabels,
    // Nouveaux paramètres optionnels pour le switch cumulatif
    this.isCumulative,
    this.onCumulativeChanged,
    this.cumulativeLabel,
    this.nonCumulativeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Vérifier si les données sont valides
    if (dataList.isEmpty) {
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
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intégration des titres et du navigateur de temps dans une disposition compacte
            Column(
              children: [
                // Ligne de titre et boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (title.isEmpty) const Spacer(),
                    _buildTimeFilterButtons(context),
                  ],
                ),
                // Espace minimal
                const SizedBox(height: 1),
                // Navigateur de temps directement après le titre
                _buildTimeNavigator(context),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isBarChart
                  ? BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabels(context);
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
                                } else {
                                  return const SizedBox.shrink();
                                }
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
                                // Formater la valeur en fonction du type
                                String formattedValue;
                                if (valuePrefix == currencyUtils.currencySymbol) {
                                  formattedValue = currencyUtils.formatCompactCurrency(
                                    value,
                                    currencyUtils.currencySymbol,
                                  );
                                } else {
                                  formattedValue = '$valuePrefix${value.toStringAsFixed(1)}$valueSuffix';
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
                        ),
                        borderData: FlBorderData(show: false),
                        maxY: maxY ?? _calculateMaxY(context),
                        barGroups: _buildBarChartData(context),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final List<String> labels = _buildDateLabels(context);

                              if (groupIndex >= 0 && groupIndex < labels.length) {
                                // Cas spécial pour les APY empilés
                                if (isStacked && dataList.isNotEmpty && dataList.first is APYRecord) {
                                  final periodKey = labels[groupIndex];
                                  final stackData = _getStackedValuesForPeriod(context, periodKey);
                                  
                                  if (stackData != null) {
                                    final netValue = stackData.$1;
                                    final grossValue = stackData.$2;
                                    
                                    return BarTooltipItem(
                                      '$periodKey\n${S.of(context).net}: $valuePrefix${netValue.toStringAsFixed(2)}$valueSuffix\n${S.of(context).brute}: $valuePrefix${grossValue.toStringAsFixed(2)}$valueSuffix',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                }
                                
                                // Format standard pour les autres types
                                String valueText;
                                if (valuePrefix == currencyUtils.currencySymbol) {
                                  valueText = currencyUtils.formatCompactCurrency(
                                    rod.toY,
                                    currencyUtils.currencySymbol,
                                  );
                                } else {
                                  valueText = '$valuePrefix${rod.toY.toStringAsFixed(2)}$valueSuffix';
                                }

                                return BarTooltipItem(
                                  '${labels[groupIndex]}\n$valueText',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null;
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: 1, // Valeur minimale pour éviter l'erreur fl_chart
                        maxY: maxY ?? max(_calculateMaxY(context), 10.0), // S'assurer que maxY est toujours >= 10
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabels(context);
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
                                } else {
                                  return const SizedBox.shrink();
                                }
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
                                // Formater la valeur en fonction du type
                                String formattedValue;
                                if (valuePrefix == currencyUtils.currencySymbol) {
                                  formattedValue = currencyUtils.formatCompactCurrency(
                                    value,
                                    currencyUtils.currencySymbol,
                                  );
                                } else {
                                  formattedValue = '$valuePrefix${value.toStringAsFixed(1)}$valueSuffix';
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
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: isStacked && getStackValues != null && stackColors != null 
                          ? _buildStackedLineChartData(context) 
                          : [
                            LineChartBarData(
                              spots: _buildChartData(context),
                              isCurved: true,
                              curveSmoothness: 0.3,
                              barWidth: 3,
                              color: chartColor,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: chartColor,
                                  );
                                },
                                checkToShowDot: (spot, barData) {
                                  // Montrer points aux extrémités et points intermédiaires
                                  final isFirst = spot.x == 0;
                                  final isLast = spot.x == barData.spots.length - 1;
                                  
                                  // Calcul du pas adaptatif pour l'affichage des points
                                  final int dataLength = barData.spots.length;
                                  int step = 1;
                                  
                                  // Si trop de points, n'afficher qu'un sous-ensemble
                                  if (dataLength > ChartUtils.maxBarsToDisplay) {
                                    step = (dataLength / ChartUtils.maxBarsToDisplay).ceil();
                                  } else if (dataLength > 10) {
                                    step = 2; // Afficher un point sur deux si entre 10 et 20 points
                                  }
                                  
                                  final isInteresting = spot.x % step == 0;
                                  return isFirst || isLast || isInteresting;
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    chartColor.withOpacity(0.3),
                                    chartColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              // Si on est en mode empilé, on affiche les valeurs de chaque série
                              if (isStacked && getStackValues != null && stackLabels != null) {
                                if (touchedSpots.isEmpty) return [];
                                
                                final int index = touchedSpots.first.x.toInt();
                                
                                // Obtenir le label de période à partir des étiquettes construites
                                List<String> dateLabels = _buildDateLabels(context);
                                if (index < 0 || index >= dateLabels.length) return [];
                                
                                final periodLabel = dateLabels[index];
                                
                                // Pour les graphiques linéaires empilés avec données regroupées
                                if (!isBarChart) {
                                  // Récupérer les valeurs correspondant à cette période depuis nos groupes
                                  Map<String, List<T>> groupedData = {};
                                  final filteredData = _filterDataByTimeRange(context, dataList);
                                  
                                  for (var record in filteredData) {
                                    DateTime date = getTimestamp(record);
                                    String key;
                                    
                                    if (selectedPeriod == S.of(context).day) {
                                      key = DateFormat('yyyy/MM/dd').format(date);
                                    } else if (selectedPeriod == S.of(context).week) {
                                      key = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
                                    } else if (selectedPeriod == S.of(context).month) {
                                      key = DateFormat('yyyy/MM').format(date);
                                    } else {
                                      key = date.year.toString();
                                    }
                                    
                                    groupedData.putIfAbsent(key, () => []).add(record);
                                  }
                                  
                                  // Trier les clés pour correspondre à l'ordre des étiquettes
                                  List<String> sortedKeys = groupedData.keys.toList()..sort();
                                  
                                  if (index < sortedKeys.length) {
                                    String periodKey = sortedKeys[index];
                                    List<T>? records = groupedData[periodKey];
                                    
                                    if (records != null && records.isNotEmpty) {
                                      // Calculer les moyennes des valeurs pour cette période
                                      int stackCount = stackLabels!.length;
                                      List<double> stackAverages = List.filled(stackCount, 0.0);
                                      
                                      for (var record in records) {
                                        final values = getStackValues!(record);
                                        for (int i = 0; i < stackCount && i < values.length; i++) {
                                          stackAverages[i] += values[i];
                                        }
                                      }
                                      
                                      for (int i = 0; i < stackCount; i++) {
                                        stackAverages[i] /= records.length;
                                      }
                                      
                                      // Construire le texte du tooltip
                                      String tooltipText = periodLabel;
                                      
                                      for (int i = 0; i < stackLabels!.length && i < stackAverages.length; i++) {
                                        String valueText;
                                        if (valuePrefix == currencyUtils.currencySymbol) {
                                          valueText = currencyUtils.formatCompactCurrency(
                                            stackAverages[i],
                                            currencyUtils.currencySymbol,
                                          );
                                        } else {
                                          valueText = '$valuePrefix${stackAverages[i].toStringAsFixed(2)}$valueSuffix';
                                        }
                                        tooltipText += '\n${stackLabels![i]}: $valueText';
                                      }
                                      
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          tooltipText,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        );
                                      }).toList();
                                    }
                                  }
                                }
                                
                                // Trouver l'enregistrement correspondant (pour les graphiques non linéaires ou cas de repli)
                                final filteredData = _filterDataByTimeRange(context, dataList);
                                if (index < 0 || index >= filteredData.length) return [];
                                
                                final record = filteredData[index];
                                final stackValues = getStackValues!(record);
                                
                                String tooltipText = periodLabel;
                                for (int i = 0; i < stackLabels!.length && i < stackValues.length; i++) {
                                  String valueText;
                                  if (valuePrefix == currencyUtils.currencySymbol) {
                                    valueText = currencyUtils.formatCompactCurrency(
                                      stackValues[i],
                                      currencyUtils.currencySymbol,
                                    );
                                  } else {
                                    valueText = '$valuePrefix${stackValues[i].toStringAsFixed(2)}$valueSuffix';
                                  }
                                  tooltipText += '\n${stackLabels![i]}: $valueText';
                                }
                                
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    tooltipText,
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              }
                              
                              // Format standard pour le mode non-empilé
                              return touchedSpots.map((touchedSpot) {
                                final index = touchedSpot.x.toInt();
                                final value = touchedSpot.y;
                                final periodLabel = _buildDateLabels(context)[index];

                                // Formater la valeur en fonction du type
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
                              }).toList();
                            },
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipMargin: 8,
                            tooltipHorizontalOffset: 0,
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.all(12),
                          ),
                          handleBuiltInTouches: true,
                          touchSpotThreshold: 25,
                        ),
                      ),
                    ),
            ),
            
            // Ajouter la légende si stackLabels est fourni
            if (isStacked && stackLabels != null && stackColors != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(stackLabels!.length * 2 - 1, (index) {
                    if (index % 2 == 1) {
                      return const SizedBox(width: 24); // Espace entre les éléments
                    }
                    
                    int itemIndex = index ~/ 2;
                    return _buildLegendItem(stackLabels![itemIndex], stackColors![itemIndex]);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxY(BuildContext context) {
    final data = _buildChartData(context);
    if (data.isEmpty) return 100;

    final maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Augmenter de 10% pour laisser de l'espace et garantir un minimum de 10.0
    return max(maxY * 1.1, 10.0);
  }

  List<BarChartGroupData> _buildBarChartData(BuildContext context) {
    // Cas spécial pour les données empilées avec getStackValues
    if (isStacked && getStackValues != null && stackColors != null) {
      return _buildCustomStackedBarChartData(context);
    }
    
    // Cas spécial pour les APY empilés
    if (isStacked && dataList.isNotEmpty && dataList.first is APYRecord) {
      return _buildStackedApyBarChartData(context);
    }
    
    // Cas normal pour les barres simples
    List<FlSpot> chartData = _buildChartData(context);
    
    return chartData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: chartColor,
                width: 12,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY ?? _calculateMaxY(context),
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  // Nouvelle méthode pour construire des barres empilées personnalisées
  List<BarChartGroupData> _buildCustomStackedBarChartData(BuildContext context) {
    // On filtre d'abord les données selon la plage de temps
    final filteredData = _filterDataByTimeRange(context, dataList);
    
    if (filteredData.isEmpty || getStackValues == null || stackColors == null) {
      return [];
    }
    
    // Vérifier que nous avons suffisamment de couleurs
    final stackCount = getStackValues!(filteredData.first).length;
    if (stackCount != stackColors!.length) {
      debugPrint("❌ Erreur: Le nombre de valeurs empilées ($stackCount) ne correspond pas au nombre de couleurs (${stackColors!.length})");
      return [];
    }
    
    // Regrouper les données selon la période sélectionnée pour limiter le nombre de barres
    Map<String, List<T>> groupedData = {};
    for (var record in filteredData) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(record);
    }

    // Trier les périodes
    List<String> sortedKeys = groupedData.keys.toList()..sort();
    
    // Appliquer le step pour limiter le nombre de barres si nécessaire
    List<String> displayedKeys = ChartUtils.applyStepToLabels(sortedKeys);
    
    final List<BarChartGroupData> barGroups = [];
    
    // Pour chaque période à afficher
    for (int i = 0; i < displayedKeys.length; i++) {
      String periodKey = displayedKeys[i];
      
      // Si c'est une étiquette vide (appliquée par le step), sauter cette entrée
      if (periodKey.isEmpty) continue;
      
      List<T>? periodRecords = groupedData[periodKey];
      if (periodRecords == null || periodRecords.isEmpty) continue;
      
      // Calculer les valeurs moyennes pour cette période
      List<double> stackAverages = List.filled(stackCount, 0.0);
      
      try {
        for (var record in periodRecords) {
          final stackValues = getStackValues!(record);
          for (int j = 0; j < stackCount; j++) {
            if (j < stackValues.length && !stackValues[j].isNaN && !stackValues[j].isInfinite) {
              stackAverages[j] += stackValues[j];
            }
          }
        }
        
        // Diviser par le nombre d'enregistrements pour obtenir la moyenne
        for (int j = 0; j < stackCount; j++) {
          stackAverages[j] /= periodRecords.length;
          // Vérifier les valeurs invalides
          if (stackAverages[j].isNaN || stackAverages[j].isInfinite) {
            stackAverages[j] = 1.0;
          }
        }
        
        // Créer les éléments empilés
        double cumulativeValue = 0;
        List<BarChartRodStackItem> stackItems = [];
        
        for (int j = 0; j < stackCount; j++) {
          double startValue = cumulativeValue;
          cumulativeValue += stackAverages[j];
          
          // Vérifier les valeurs invalides
          if (startValue.isNaN || startValue.isInfinite) startValue = j * 1.0;
          if (cumulativeValue.isNaN || cumulativeValue.isInfinite) cumulativeValue = (j + 1) * 1.0;
          
          stackItems.add(BarChartRodStackItem(startValue, cumulativeValue, stackColors![j]));
        }
        
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cumulativeValue,
                width: 12,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                rodStackItems: stackItems,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY ?? _calculateMaxY(context) * 1.1,
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        debugPrint("❌ Erreur lors de la création des barres empilées: $e");
      }
    }
    
    return barGroups;
  }

  // Nouvelle méthode pour construire des barres empilées pour APY
  List<BarChartGroupData> _buildStackedApyBarChartData(BuildContext context) {
    // On filtre d'abord les données selon la plage de temps
    final filteredData = _filterDataByTimeRange(context, dataList);
    
    Map<String, List<APYRecord>> groupedData = {};
    
    for (var record in filteredData) {
      if (record is APYRecord) {
        DateTime date = record.timestamp;
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

        groupedData.putIfAbsent(periodKey, () => []).add(record);
      }
    }
    
    List<BarChartGroupData> barGroups = [];
    List<String> sortedKeys = groupedData.keys.toList()..sort();
    
    // Appliquer le step pour limiter le nombre de barres si nécessaire
    List<String> displayedKeys = isBarChart ? ChartUtils.applyStepToLabels(sortedKeys) : sortedKeys;
    
    // Définir les couleurs pour les valeurs nettes et brutes
    final Color netColor = chartColor;
    final Color grossColor = Color(0xFFFF9500); // Orange pour la partie brute
    
    for (int i = 0; i < displayedKeys.length; i++) {
      String periodKey = displayedKeys[i];
      
      // Si c'est une étiquette vide (appliquée par le step), sauter cette entrée
      if (periodKey.isEmpty) continue;
      
      List<APYRecord>? records = groupedData[periodKey];
      if (records == null) continue; // Cette clé peut ne pas exister dans groupedData après le step
      
      // Calculer les moyennes des valeurs net et gross pour cette période
      double netApyAvg = 0;
      double grossApyAvg = 0;
      
      if (records.isNotEmpty) {
        for (var record in records) {
          // Assurer que nous avons les deux valeurs
          double netValue = record.netApy ?? record.apy;
          double grossValue = record.grossApy ?? record.apy;
          
          netApyAvg += netValue;
          grossApyAvg += grossValue;
        }
        
        netApyAvg /= records.length;
        grossApyAvg /= records.length;
      }
      
      // Calculer la différence entre gross et net pour empiler
      double netValue = netApyAvg;
      double grossDiff = grossApyAvg - netApyAvg;
      
      // Si la différence est négative (cas rare), on affiche juste la valeur nette
      if (grossDiff < 0) grossDiff = 0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: netValue + grossDiff, // Hauteur totale de la barre
              width: 12,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              rodStackItems: [
                BarChartRodStackItem(0, netValue, netColor), // Partie nette (fond) - couleur principale
                BarChartRodStackItem(netValue, netValue + grossDiff, grossColor), // Différence brute (haut) - couleur différente
              ],
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY ?? _calculateMaxY(context) * 1.2,
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }

  List<FlSpot> _buildChartData(BuildContext context) {
    // On filtre d'abord les données selon la plage de temps
    final filteredData = _filterDataByTimeRange(context, dataList);
    
    
    // Fonction personnalisée pour obtenir la valeur Y
    double Function(T) getYValueAdapter = (T record) {
      double value;
      try {
        // Cas spécial pour APY records - utiliser netApy si disponible
        if (record is APYRecord) {
          value = record.netApy ?? record.apy;
        } else {
          // Pour tous les autres types, utiliser la fonction getYValue fournie
          value = getYValue(record);
        }
        // Traiter les valeurs invalides
        if (value.isNaN || value.isInfinite) {
          return 1.0;
        }
        // S'assurer que la valeur est au moins 1.0 pour éviter l'erreur fl_chart
        return value < 1.0 ? 1.0 : value;
      } catch (e) {
        debugPrint("❌ Erreur lors de l'obtention de la valeur Y: $e");
        return 1.0;
      }
    };
    
    // Puis on utilise la méthode buildHistoryChartData avec applyStep selon le type de graphique
    try {
      List<FlSpot> spots = ChartUtils.buildHistoryChartData<T>(
        context,
        filteredData, 
        selectedPeriod,
        getYValueAdapter,
        getTimestamp,
        applyStep: isBarChart, // N'appliquer le step que pour les graphiques à barres
      );
      
      // Filtrer les spots pour éliminer tout point avec NaN ou Infinity
      spots = spots.where((spot) => 
        !spot.x.isNaN && 
        !spot.x.isInfinite && 
        !spot.y.isNaN && 
        !spot.y.isInfinite
      ).toList();
      
      // Vérifier que tous les spots ont y >= 1.0
      return spots.map((spot) => FlSpot(spot.x, spot.y < 1.0 ? 1.0 : spot.y)).toList();
    } catch (e) {
      debugPrint("❌ Erreur lors de la création des données du graphique: $e");
      return [];
    }
  }

  List<String> _buildDateLabels(BuildContext context) {
    // Filtrer les données selon la plage de temps sélectionnée
    List<T> filteredData = _filterDataByTimeRange(context, dataList);

    Map<String, List<double>> groupedData = {};
    for (var record in filteredData) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(getYValue(record));
    }

    List<String> sortedKeys = groupedData.keys.toList()..sort();
    
    // Appliquer le step pour limiter le nombre d'étiquettes seulement pour les graphiques à barres
    return isBarChart ? ChartUtils.applyStepToLabels(sortedKeys) : sortedKeys;
  }

  Widget _buildTimeNavigator(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Déterminer la plage actuelle à afficher
    String currentRange = "";
    
    if (selectedPeriod == S.of(context).day) {
      // Pour l'affichage par jour
      final filteredData = _filterDataByTimeRange(context, dataList);
      if (filteredData.isNotEmpty) {
        final firstDate = filteredData.map((e) => getTimestamp(e)).reduce((a, b) => a.isBefore(b) ? a : b);
        final lastDate = filteredData.map((e) => getTimestamp(e)).reduce((a, b) => a.isAfter(b) ? a : b);
        currentRange = "${DateFormat('dd/MM/yyyy').format(firstDate)} - ${DateFormat('dd/MM/yyyy').format(lastDate)}";
      }
    } else if (selectedPeriod == S.of(context).week) {
      // Pour l'affichage par semaine
      final weeks = _buildDateLabels(context);
      if (weeks.isNotEmpty) {
        currentRange = "${weeks.first} - ${weeks.last}";
      }
    } else if (selectedPeriod == S.of(context).month) {
      // Pour l'affichage par mois
      final months = _buildDateLabels(context);
      if (months.isNotEmpty) {
        currentRange = "${months.first} - ${months.last}";
      }
    } else {
      // Pour l'affichage par année
      final years = _buildDateLabels(context);
      if (years.isNotEmpty) {
        currentRange = "${years.first} - ${years.last}";
      }
    }
    
    // Si nous n'avons pas pu déterminer la plage, utiliser la plage de temps sélectionnée
    if (currentRange.isEmpty) {
      switch (selectedTimeRange) {
        case '3months':
          currentRange = "3 mois";
          break;
        case '6months':
          currentRange = "6 mois";
          break;
        case '12months':
          currentRange = "12 mois";
          break;
        default:
          currentRange = "Toutes les données";
      }
    }
    
    // Déterminer l'offset maximum selon la plage temporelle
    int maxOffset = 10; // Valeur par défaut
    
    switch (selectedTimeRange) {
      case '3months':
        maxOffset = 8; // Permet de remonter jusqu'à 2 ans
        break;
      case '6months':
        maxOffset = 4; // Permet de remonter jusqu'à 2 ans
        break;
      case '12months':
        maxOffset = 2; // Permet de remonter jusqu'à 2 ans
        break;
      default:
        maxOffset = 0; // Pas de navigation pour 'all'
    }
    
    // Vérifier si les boutons doivent être activés
    bool canGoBack = selectedTimeRange != 'all' && timeOffset < maxOffset;
    bool canGoForward = timeOffset > 0;
    
    // Ajouter l'offset au texte si offset > 0
    if (timeOffset > 0) {
      currentRange += " (offset: -${timeOffset * 3} mois)";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 25,
              color: canGoBack ? chartColor : Colors.grey.shade300,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: canGoBack ? () => _navigateTime(context, -1) : null,
          ),
          Expanded(
            child: Text(
              currentRange,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 25,
              color: canGoForward ? chartColor : Colors.grey.shade300,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: canGoForward ? () => _navigateTime(context, 1) : null,
          ),
        ],
      ),
    );
  }
  
  // Méthode pour naviguer dans le temps
  void _navigateTime(BuildContext context, int direction) {
    // -1 pour reculer (augmenter l'offset), +1 pour avancer (diminuer l'offset)
    int newOffset = timeOffset;
    
    // Déterminer l'offset maximum selon la plage temporelle
    int maxOffset = 10; // Valeur par défaut
    
    switch (selectedTimeRange) {
      case '3months':
        maxOffset = 8; // Permet de remonter jusqu'à 2 ans
        break;
      case '6months':
        maxOffset = 4; // Permet de remonter jusqu'à 2 ans
        break;
      case '12months':
        maxOffset = 2; // Permet de remonter jusqu'à 2 ans
        break;
      default:
        maxOffset = 0; // Pas de navigation pour 'all'
    }
    
    if (direction < 0) {
      // Reculer dans le temps (augmenter l'offset) avec une limite maximale
      if (timeOffset < maxOffset) {
        newOffset += 1;
      }
    } else if (direction > 0) {
      // Avancer dans le temps (diminuer l'offset)
      newOffset = max(0, timeOffset - 1);
    }
    
    // Si nous n'avons pas de changement ou si nous sommes déjà à l'offset minimum/maximum, ne rien faire
    if (newOffset == timeOffset) {
      return;
    }
    
    // Appliquer le nouvel offset et réinitialiser la vue
    onTimeOffsetChanged(newOffset);
  }

  // Fonction pour filtrer les données par plage de temps
  List<T> _filterDataByTimeRange(BuildContext context, List<T> records) {
    if (selectedTimeRange == 'all' || records.isEmpty) {
      return records;
    }
    
    // Date actuelle avec prise en compte du décalage temporel
    DateTime now = DateTime.now();
    DateTime referenceDate;
    
    // Appliquer le décalage temporel en fonction de la période sélectionnée
    if (selectedPeriod == S.of(context).day) {
      // Décalage en jours
      referenceDate = now.subtract(Duration(days: timeOffset * 30)); // 30 jours par offset
    } else if (selectedPeriod == S.of(context).week) {
      // Décalage en semaines
      referenceDate = now.subtract(Duration(days: timeOffset * 7 * 4)); // 4 semaines par offset
    } else if (selectedPeriod == S.of(context).month) {
      // Décalage en mois
      referenceDate = DateTime(now.year, now.month - timeOffset * 3, now.day); // 3 mois par offset
    } else if (selectedPeriod == S.of(context).year) {
      // Décalage en années
      referenceDate = DateTime(now.year - timeOffset, now.month, now.day);
    } else {
      referenceDate = now;
    }
    
    DateTime cutoffDate;
    
    // Déterminer la date limite selon la plage sélectionnée
    switch (selectedTimeRange) {
      case '3months':
        cutoffDate = DateTime(referenceDate.year, referenceDate.month - 3, 1);
        break;
      case '6months':
        cutoffDate = DateTime(referenceDate.year, referenceDate.month - 6, 1);
        break;
      case '12months':
        cutoffDate = DateTime(referenceDate.year - 1, referenceDate.month, 1);
        break;
      default:
        return records;
    }
    
    // Définir la date maximale (la fin de la période)
    DateTime maxDate = referenceDate.add(const Duration(days: 1));
    
    // Filtre des données selon la date calculée et la date max
    return records.where((record) {
      DateTime timestamp = getTimestamp(record);
      return (timestamp.isAfter(cutoffDate) || 
             (timestamp.year == cutoffDate.year && 
              timestamp.month == cutoffDate.month && 
              timestamp.day >= cutoffDate.day)) && 
             timestamp.isBefore(maxDate);
    }).toList();
  }

  // Méthode utilitaire pour récupérer les valeurs nettes et brutes pour une période donnée
  (double, double)? _getStackedValuesForPeriod(BuildContext context, String periodKey) {
    if (dataList.isEmpty || !(dataList.first is APYRecord)) {
      return null;
    }
    
    // On filtre d'abord les données selon la plage de temps
    final filteredData = _filterDataByTimeRange(context, dataList);
    
    List<APYRecord> periodRecords = [];
    
    for (var record in filteredData) {
      if (record is APYRecord) {
        DateTime date = record.timestamp;
        String key;

        if (selectedPeriod == S.of(context).day) {
          key = DateFormat('yyyy/MM/dd').format(date);
        } else if (selectedPeriod == S.of(context).week) {
          key = "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
        } else if (selectedPeriod == S.of(context).month) {
          key = DateFormat('yyyy/MM').format(date);
        } else {
          key = date.year.toString();
        }
        
        if (key == periodKey) {
          periodRecords.add(record);
        }
      }
    }
    
    if (periodRecords.isEmpty) {
      return null;
    }
    
    // Calculer les moyennes
    double netAvg = 0;
    double grossAvg = 0;
    
    for (var record in periodRecords) {
      netAvg += record.netApy ?? record.apy;
      grossAvg += record.grossApy ?? record.apy;
    }
    
    netAvg /= periodRecords.length;
    grossAvg /= periodRecords.length;
    
    return (netAvg, grossAvg);
  }

  // Méthode pour construire les boutons de filtre et options
  Widget _buildTimeFilterButtons(BuildContext context) {
    return Row(
      children: [
        // Si le switch est fourni, l'afficher
        if (isCumulative != null && onCumulativeChanged != null)
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: isCumulative!,
              onChanged: onCumulativeChanged!,
              activeColor: Theme.of(context).primaryColor,
              trackColor: Colors.grey.shade300,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            size: 20.0,
            color: Theme.of(context).primaryColor,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ChartOptionsUtils.showOptionsModal(
              context: context,
              isBarChart: isBarChart,
              onChartTypeChanged: onChartTypeChanged,
              selectedTimeRange: selectedTimeRange,
              onTimeRangeChanged: onTimeRangeChanged,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
              onEditPressed: onEditPressed != null ? () => onEditPressed!(context) : null,
            );
          },
        ),
      ],
    );
  }

  // Nouvelle méthode pour construire un élément de légende
  Widget _buildLegendItem(String label, Color color) {
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

  // Nouvelle méthode pour construire les données de graphique linéaire empilé
  List<LineChartBarData> _buildStackedLineChartData(BuildContext context) {
    // On filtre d'abord les données selon la plage de temps
    final filteredData = _filterDataByTimeRange(context, dataList);
    
    if (filteredData.isEmpty || getStackValues == null || stackColors == null) {
      return [];
    }
    
    // Vérifier que nous avons suffisamment de couleurs
    final stackCount = getStackValues!(filteredData.first).length;
    if (stackCount != stackColors!.length) {
      debugPrint("❌ Erreur: Le nombre de valeurs empilées ($stackCount) ne correspond pas au nombre de couleurs (${stackColors!.length})");
      return [];
    }
    
    // Regrouper les données selon la période sélectionnée
    Map<String, List<T>> groupedData = {};
    for (var record in filteredData) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(record);
    }

    // Trier les périodes
    List<String> sortedKeys = groupedData.keys.toList()..sort();
    
    // Créer les points pour chaque série avec les données regroupées
    List<List<FlSpot>> stackedSpots = List.generate(stackCount, (_) => []);
    
    for (int i = 0; i < sortedKeys.length; i++) {
      String periodKey = sortedKeys[i];
      List<T> periodRecords = groupedData[periodKey]!;
      
      // Vérifier qu'il y a des enregistrements pour éviter une division par zéro
      if (periodRecords.isEmpty) continue;
      
      // Calculer les valeurs moyennes pour cette période
      List<double> stackAverages = List.filled(stackCount, 0.0);
      
      for (var record in periodRecords) {
        try {
          final stackValues = getStackValues!(record);
          for (int j = 0; j < stackCount && j < stackValues.length; j++) {
            // Ignorer les valeurs NaN ou Infinity
            if (!stackValues[j].isNaN && !stackValues[j].isInfinite) {
              stackAverages[j] += stackValues[j];
            }
          }
        } catch (e) {
          debugPrint("❌ Erreur lors de l'obtention des valeurs empilées: $e");
        }
      }
      
      // Diviser par le nombre d'enregistrements pour obtenir la moyenne
      for (int j = 0; j < stackCount; j++) {
        stackAverages[j] /= periodRecords.length;
        // S'assurer que la valeur n'est pas NaN ou Infinity
        if (stackAverages[j].isNaN || stackAverages[j].isInfinite) {
          stackAverages[j] = 1.0;
        }
      }
      
      // Cumuler les valeurs pour l'empilement
      double cumulativeValue = 0;
      for (int j = 0; j < stackCount; j++) {
        cumulativeValue += stackAverages[j];
        // Vérifier et corriger les valeurs invalides
        if (cumulativeValue.isNaN || cumulativeValue.isInfinite) {
          cumulativeValue = (j + 1) * 1.0; // Valeur de repli simple
        }
        
        // Ajouter le point avec validation
        double xValue = i.toDouble();
        if (!xValue.isNaN && !xValue.isInfinite && !cumulativeValue.isNaN && !cumulativeValue.isInfinite) {
          stackedSpots[j].add(FlSpot(xValue, cumulativeValue));
        }
      }
    }
    
    // Créer un LineChartBarData pour chaque série (en ordre inverse pour l'empilement visuel correct)
    final List<LineChartBarData> lineBarsData = [];
    
    for (int i = stackCount - 1; i >= 0; i--) {
      final color = stackColors![i];
      
      lineBarsData.add(
        LineChartBarData(
          spots: stackedSpots[i],
          isCurved: true,
          curveSmoothness: 0.3,
          barWidth: 3,
          color: color,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
            checkToShowDot: (spot, barData) {
              // Montrer points aux extrémités et quelques points intermédiaires
              final isFirst = spot.x == 0;
              final isLast = spot.x == barData.spots.length - 1;
              
              // Calcul du pas adaptatif pour l'affichage des points
              final int dataLength = barData.spots.length;
              int step = 1;
              
              // Si trop de points, n'afficher qu'un sous-ensemble
              if (dataLength > ChartUtils.maxBarsToDisplay) {
                step = (dataLength / ChartUtils.maxBarsToDisplay).ceil();
              } else if (dataLength > 10) {
                step = 2; // Afficher un point sur deux si entre 10 et 20 points
              }
              
              final isInteresting = spot.x % step == 0;
              return isFirst || isLast || isInteresting;
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }
    
    return lineBarsData;
  }
} 