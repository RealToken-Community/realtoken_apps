import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/chart_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';

class HealthAndLtvHistoryGraph extends StatefulWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final bool healthAndLtvIsBarChart;
  final Function(String) onPeriodChanged;
  final Function(bool) onChartTypeChanged;

  const HealthAndLtvHistoryGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.healthAndLtvIsBarChart,
    required this.onPeriodChanged,
    required this.onChartTypeChanged,
  });

  @override
  _HealthAndLtvHistoryGraphState createState() => _HealthAndLtvHistoryGraphState();
}

class _HealthAndLtvHistoryGraphState extends State<HealthAndLtvHistoryGraph> {
  /// true : afficher le healthFactor (échelle de 10)
  /// false : afficher le LTV (en pourcentage)
  bool showHealthFactor = true;

  // Variable pour suivre le point sélectionné
  int? _selectedSpotIndex;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Regroupement des données selon la période sélectionnée.
    Map<String, Map<String, double>> groupedData = _groupHealthAndLtvByDate(
      context,
      widget.dataManager,
      widget.selectedPeriod,
    );

    // Préparation des données pour le graphique linéaire.
    List<LineChartBarData> lineChartData = [];
    List<FlSpot> spots = [];
    int index = 0;
    groupedData.forEach((date, values) {
      // Vérification que les valeurs ne sont pas nulles et pas NaN
      if (values.containsKey('healtFactor') && values.containsKey('ltv')) {
        double? hf = values['healtFactor'];
        double? ltv = values['ltv'];

        if (hf != null && !hf.isNaN && ltv != null && !ltv.isNaN) {
          double metricValue = showHealthFactor ? hf : ltv;
          if (!metricValue.isNaN) {
            spots.add(FlSpot(index.toDouble(), metricValue));
          }
        }
      }
      index++;
    });

    // Définition de la valeur maxY en fonction du métrique affiché.
    double maxY = showHealthFactor ? 10 : 100;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête et réglages
                Row(
                  children: [
                    Text(
                      S.of(context).rmmHealth,
                      style: TextStyle(
                        fontSize: 20 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            S.of(context).ltv,
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(),
                              color: showHealthFactor ? Colors.grey : Colors.black,
                              fontWeight: showHealthFactor ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch.adaptive(
                              value: showHealthFactor,
                              onChanged: (val) {
                                setState(() {
                                  showHealthFactor = val;
                                  _selectedSpotIndex = null;
                                });
                              },
                              activeColor: const Color(0xFF007AFF), // Bleu iOS
                              trackColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected) ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          Text(
                            S.of(context).hf,
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(),
                              color: showHealthFactor ? Colors.black : Colors.grey,
                              fontWeight: showHealthFactor ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bouton pour changer de type de graphique
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.healthAndLtvIsBarChart ? Icons.show_chart : Icons.bar_chart,
                          size: 20.0,
                          color: const Color(0xFF007AFF),
                        ),
                        onPressed: () {
                          widget.onChartTypeChanged(!widget.healthAndLtvIsBarChart);
                          setState(() {
                            _selectedSpotIndex = null;
                          });
                        },
                        tooltip: widget.healthAndLtvIsBarChart ? S.of(context).lineChart : S.of(context).barChart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sélecteur de période
                ChartUtils.buildPeriodSelector(
                  context,
                  selectedPeriod: widget.selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() {
                      _selectedSpotIndex = null;
                    });
                    widget.onPeriodChanged(period);
                  },
                ),
                const SizedBox(height: 20),
                // Affichage du graphique (barres ou lignes)
                Expanded(
                  child: widget.healthAndLtvIsBarChart
                      ? _buildBarChart(context, appState, groupedData, _buildDateLabelsForHealthAndLtv(context, widget.dataManager, widget.selectedPeriod))
                      : _buildLineChart(context, appState, groupedData, spots, maxY),
                ),
                // Indicateur de la métrique actuelle
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: showHealthFactor
                          ? const Color(0xFF34C759).withValues(alpha: 0.1) // Vert iOS
                          : const Color(0xFFFF9500).withValues(alpha: 0.1), // Orange iOS
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      showHealthFactor ? S.of(context).healthFactorSafer : S.of(context).ltvSafer,
                      style: TextStyle(
                        fontSize: 12 + appState.getTextSizeOffset(),
                        color: showHealthFactor
                            ? const Color(0xFF34C759) // Vert iOS
                            : const Color(0xFFFF9500), // Orange iOS
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    AppState appState,
    Map<String, Map<String, double>> groupedData,
    List<String> labels,
  ) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        minY: 1.0, // Définir minY à 1.0 pour éviter l'erreur d'assertion
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= labels.length) {
                return null;
              }

              final date = labels[groupIndex];

              // Récupérer la valeur réelle pour l'affichage dans le tooltip
              final realValue = showHealthFactor ? groupedData[date]!['healtFactor']! : groupedData[date]!['ltv']!;

              return BarTooltipItem(
                '$date\n${showHealthFactor ? 'Health Factor' : 'LTV'}: ${showHealthFactor ? realValue.toInt() : realValue.toInt()}${showHealthFactor ? '' : '%'}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12 + appState.getTextSizeOffset(),
                ),
              );
            },
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(12),
            tooltipMargin: 8,
            direction: TooltipDirection.top,
            tooltipHorizontalOffset: 0,
          ),
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            setState(() {
              if (event is FlTapUpEvent || event is FlPanDownEvent) {
                if (response?.spot != null) {
                  _selectedSpotIndex = response!.spot!.touchedBarGroupIndex;
                }
              } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                _selectedSpotIndex = null;
              }
            });
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
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
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    showHealthFactor ? value.toInt().toString() : '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: List.generate(
          labels.length,
          (index) {
            final date = labels[index];
            final values = groupedData[date];
            if (values == null) return BarChartGroupData(x: index);

            double metricValue = showHealthFactor ? values['healtFactor']! : values['ltv']!;

            // Assurer que la valeur de la barre est au moins 1.0 pour le graphique,
            // tout en conservant la valeur réelle pour l'affichage dans le tooltip
            double barValue = metricValue;
            if (barValue < 1.0) {
              barValue = 1.0;
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: barValue, // Utiliser la valeur ajustée qui est au moins 1.0
                  gradient: LinearGradient(
                    colors: showHealthFactor
                        ? [
                            const Color(0xFF34C759), // Vert iOS
                            const Color(0xFF34C759).withValues(alpha: 0.7),
                          ]
                        : [
                            const Color(0xFFFF9500), // Orange iOS
                            const Color(0xFFFF9500).withValues(alpha: 0.7),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: showHealthFactor ? 3.0 : 100,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ],
              showingTooltipIndicators: _selectedSpotIndex == index ? [0] : [],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    AppState appState,
    Map<String, Map<String, double>> groupedData,
    List<FlSpot> spots,
    double maxY,
  ) {
    // Pour le graphique linéaire, on doit aussi vérifier les valeurs
    // et créer de nouveaux spots avec des valeurs minimales de 1.0 si nécessaire
    List<FlSpot> adjustedSpots = [];
    int index = 0;
    List<String> dates = _buildDateLabelsForHealthAndLtv(
      context,
      widget.dataManager,
      widget.selectedPeriod,
    );

    // Vérifier si la liste des spots est vide
    if (spots.isEmpty) {
      // Retourner un graphique vide avec un message
      return Center(
        child: Text(S.of(context).noDataAvailable),
      );
    }

    for (var spot in spots) {
      // Vérifier si x ou y sont NaN
      if (spot.x.isNaN || spot.y.isNaN) {
        continue; // Sauter ce spot s'il contient NaN
      }

      double y = spot.y;
      if (y < 1.0) {
        y = 1.0; // Assurer une valeur minimum de 1.0
      }
      adjustedSpots.add(FlSpot(spot.x, y));
    }

    // Vérifier si tous les spots ont été filtrés car ils contenaient NaN
    if (adjustedSpots.isEmpty) {
      return Center(
        child: Text(S.of(context).invalidDataForChart),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                List<String> labels = _buildDateLabelsForHealthAndLtv(
                  context,
                  widget.dataManager,
                  widget.selectedPeriod,
                );
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
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    showHealthFactor ? value.toInt().toString() : '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        maxY: maxY,
        minY: 1.0, // Définir minY à 1.0 pour éviter l'erreur d'assertion
        lineBarsData: [
          LineChartBarData(
            spots: adjustedSpots, // Utiliser les spots ajustés
            isCurved: true,
            curveSmoothness: 0.3,
            color: showHealthFactor
                ? const Color(0xFF34C759) // Vert iOS
                : const Color(0xFFFF9500), // Orange iOS
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: showHealthFactor
                      ? const Color(0xFF34C759) // Vert iOS
                      : const Color(0xFFFF9500), // Orange iOS
                );
              },
              checkToShowDot: (spot, barData) {
                // Afficher les points aux extrémités et quelques points intermédiaires
                return spot.x == 0 || spot.x == barData.spots.length - 1 || spot.x % (barData.spots.length > 8 ? 4 : 2) == 0 || _selectedSpotIndex == spot.x.toInt();
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: showHealthFactor
                    ? [
                        const Color(0xFF34C759).withValues(alpha: 0.3), // Vert iOS
                        const Color(0xFF34C759).withValues(alpha: 0.0),
                      ]
                    : [
                        const Color(0xFFFF9500).withValues(alpha: 0.3), // Orange iOS
                        const Color(0xFFFF9500).withValues(alpha: 0.0),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              if (touchedBarSpots.isEmpty) return [];
              final spot = touchedBarSpots.first;
              final spotIndex = spot.spotIndex;

              List<String> dates = _buildDateLabelsForHealthAndLtv(
                context,
                widget.dataManager,
                widget.selectedPeriod,
              );
              if (spotIndex < 0 || spotIndex >= dates.length) {
                return [];
              }
              final date = dates[spotIndex];

              // Récupérer la valeur réelle pour l'affichage
              final realValue = showHealthFactor ? groupedData[date]!['healtFactor']! : groupedData[date]!['ltv']!;

              return [
                LineTooltipItem(
                  '$date\n${showHealthFactor ? 'Health Factor' : 'LTV'}: ${showHealthFactor ? realValue.toInt() : realValue.toInt()}${showHealthFactor ? '' : '%'}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12 + appState.getTextSizeOffset(),
                  ),
                ),
              ];
            },
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 8,
            tooltipHorizontalOffset: 0,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipColor: (group) => Colors.black87,
          ),
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            setState(() {
              if (event is FlTapUpEvent || event is FlPanDownEvent) {
                if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                  _selectedSpotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                }
              } else if (event is FlPanEndEvent || event is FlLongPressEnd) {
                _selectedSpotIndex = null;
              }
            });
          },
        ),
      ),
    );
  }

  Map<String, Map<String, double>> _groupHealthAndLtvByDate(
    BuildContext context,
    DataManager dataManager,
    String selectedPeriod,
  ) {
    Map<String, Map<String, double>> groupedData = {};
    List sortedRecords = List.from(dataManager.healthAndLtvHistory);
    sortedRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var record in sortedRecords) {
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

      // Vérifier que les valeurs ne sont pas NaN
      double healthFactor = record.healthFactor;
      double ltv = record.ltv;

      if (!healthFactor.isNaN && !ltv.isNaN) {
        if (!groupedData.containsKey(periodKey)) {
          groupedData[periodKey] = {'healtFactor': 0.0, 'ltv': 0.0};
        }
        groupedData[periodKey]!['healtFactor'] = healthFactor;
        groupedData[periodKey]!['ltv'] = ltv;
      }
    }
    return groupedData;
  }

  List<String> _buildDateLabelsForHealthAndLtv(
    BuildContext context,
    DataManager dataManager,
    String selectedPeriod,
  ) {
    final groupedData = _groupHealthAndLtvByDate(context, dataManager, selectedPeriod);
    return groupedData.keys.toList();
  }
}
