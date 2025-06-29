import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/models/rented_record.dart';
import 'package:realtoken_asset_tracker/utils/chart_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';

class RentedHistoryGraph extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool rentedIsBarChart;
  final Function(bool) onChartTypeChanged;

  const RentedHistoryGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.rentedIsBarChart,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);

    // Vérifier si les données sont valides
    final List<FlSpot> spots = _buildRentedChartData(context);
    if (spots.isEmpty) {
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
                fontSize: 16 +
                    Provider.of<AppState>(context, listen: false)
                        .getTextSizeOffset(),
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

    // Récupérer les données pour les graphiques
    List<FlSpot> rentedHistoryData =
        _buildRentedHistoryChartData(context, dataManager, selectedPeriod);
    List<BarChartGroupData> barChartData =
        _buildRentedHistoryBarChartData(context, dataManager, selectedPeriod);
    List<String> dateLabels =
        _buildDateLabelsForRented(context, dataManager, selectedPeriod);

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
            Row(
              children: [
                Text(
                  S.of(context).rented, // Titre principal
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 24.0,
                            horizontal: 16.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 12.0, left: 8.0),
                                child: Text(
                                  "Type de graphique",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.bar_chart_rounded,
                                  color: const Color(0xFF007AFF),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).barChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: rentedIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF007AFF),
                                      )
                                    : null,
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.show_chart_rounded,
                                  color: const Color(0xFF34C759),
                                  size: 28,
                                ),
                                title: Text(
                                  S.of(context).lineChart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: !rentedIsBarChart
                                    ? Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF34C759),
                                      )
                                    : null,
                                onTap: () {
                                  onChartTypeChanged(false);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return rentedIsBarChart
                      ? BarChart(
                          BarChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '${value.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < dateLabels.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            dateLabels[value.toInt()],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: barChartData.map((group) {
                              return BarChartGroupData(
                                x: group.x,
                                barRods: [
                                  BarChartRodData(
                                    toY: group.barRods.first.toY,
                                    color: const Color(0xFF007AFF),
                                    width: 12,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(6)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 100,
                                      color: Colors.grey.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final periodLabel = dateLabels[groupIndex];
                                  return BarTooltipItem(
                                    '$periodLabel\n${rod.toY.toStringAsFixed(1)}%',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  );
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
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    final highestValue = rentedHistoryData
                                        .map((e) => e.y)
                                        .reduce((a, b) => a > b ? a : b);

                                    if (value == highestValue) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '${value.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> labels =
                                        _buildDateLabelsForRented(context,
                                            dataManager, selectedPeriod);

                                    if (value.toInt() >= 0 &&
                                        value.toInt() < labels.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            labels[value.toInt()],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: rentedHistoryData,
                                isCurved: true,
                                curveSmoothness: 0.3,
                                barWidth: 3,
                                color: const Color(0xFF34C759),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 3,
                                      color: Colors.white,
                                      strokeWidth: 2,
                                      strokeColor: const Color(0xFF34C759),
                                    );
                                  },
                                  checkToShowDot: (spot, barData) {
                                    // Montrer les points uniquement aux extrémités et points intermédiaires
                                    final isFirst = spot.x == 0;
                                    final isLast =
                                        spot.x == barData.spots.length - 1;
                                    final isInteresting = spot.x %
                                            (barData.spots.length > 10
                                                ? 5
                                                : 2) ==
                                        0;
                                    return isFirst || isLast || isInteresting;
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF34C759)
                                          .withValues(alpha: 0.3),
                                      const Color(0xFF34C759)
                                          .withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems:
                                    (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final index = touchedSpot.x.toInt();
                                    final value = touchedSpot.y;
                                    final String periodLabel =
                                        _buildDateLabelsForRented(context,
                                            dataManager, selectedPeriod)[index];

                                    return LineTooltipItem(
                                      '$periodLabel\n${value.toStringAsFixed(1)}%',
                                      TextStyle(
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
                              touchSpotThreshold: 20,
                            ),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildRentedHistoryChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    return ChartUtils.buildHistoryChartData<RentedRecord>(
      context,
      dataManager.rentedHistory,
      selectedPeriod,
      (record) => record.percentage,
      (record) => record.timestamp,
    );
  }

  List<BarChartGroupData> _buildRentedHistoryBarChartData(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<FlSpot> rentedHistoryData =
        _buildRentedHistoryChartData(context, dataManager, selectedPeriod);
    return rentedHistoryData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: const Color(0xFF007AFF),
                width: 12,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  List<String> _buildDateLabelsForRented(
      BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<RentedRecord> rentedHistory = dataManager.rentedHistory;

    // Grouper les données en fonction de la période sélectionnée
    Map<String, List<double>> groupedData = {};
    for (var record in rentedHistory) {
      DateTime date = record.timestamp;
      String periodKey;

      if (selectedPeriod == S.of(context).day) {
        periodKey = DateFormat('yyyy/MM/dd').format(date); // Grouper par jour
      } else if (selectedPeriod == S.of(context).week) {
        periodKey =
            "${date.year}-S${CustomDateUtils.weekNumber(date).toString().padLeft(2, '0')}";
      } else if (selectedPeriod == S.of(context).month) {
        periodKey = DateFormat('yyyy/MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      groupedData.putIfAbsent(periodKey, () => []).add(record.percentage);
    }

    // Trier les clés en ordre chronologique
    List<String> sortedKeys = groupedData.keys.toList()..sort();
    return sortedKeys;
  }

  List<FlSpot> _buildRentedChartData(BuildContext context) {
    List<FlSpot> spots = [];
    int index = 0;
    final dataManager = Provider.of<DataManager>(context, listen: false);

    for (var token in dataManager.portfolio) {
      // Vérifier si le token a un revenu mensuel positif
      if (token['monthlyIncome'] != null) {
        double monthlyIncome = (token['monthlyIncome'] ?? 0.0).toDouble();

        // Vérifier si la valeur est valide
        if (monthlyIncome > 0) {
          spots.add(FlSpot(index.toDouble(), monthlyIncome));
          index++;
        }
      }
    }

    return spots;
  }

  double _calculateMaxY(BuildContext context) {
    final List<FlSpot> spots = _buildRentedChartData(context);
    if (spots.isEmpty) return 100;

    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Augmenter de 10% pour laisser de l'espace
    return maxY * 1.1;
  }

  List<BarChartGroupData> _buildBarChartData(BuildContext context) {
    final List<FlSpot> spots = _buildRentedChartData(context);
    if (spots.isEmpty) return [];

    return spots.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.y,
            color: const Color(0xFF5856D6),
            width: 8,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxY(context),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ],
      );
    }).toList();
  }
}
