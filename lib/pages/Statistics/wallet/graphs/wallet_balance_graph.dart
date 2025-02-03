import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/models/balance_record.dart';
import 'package:realtokens/utils/chart_utils.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/utils/date_utils.dart';

class WalletBalanceGraph extends StatelessWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool isBarChart;
  final Function(bool) onChartTypeChanged;

  const WalletBalanceGraph({super.key, 
    required this.dataManager,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isBarChart, 
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  S.of(context).walletBalanceHistory,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings,size: 20.0),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.bar_chart, color: Colors.blue),
                                title: Text(S.of(context).barChart),
                                onTap: () {
                                  onChartTypeChanged(true);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.show_chart, color: Colors.green),
                                title: Text(S.of(context).lineChart),
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
            ChartUtils.buildPeriodSelector(
              context,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: isBarChart
                  ? BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                final displayValue = value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                                    : CurrencyUtils.formatCurrency(value, dataManager.currencySymbol);
                                return Text(
                                  displayValue,
                                  style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabelsForWallet(context, dataManager, selectedPeriod);
                                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
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
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.transparent),
                            bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                            right: BorderSide(color: Colors.transparent),
                            top: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        barGroups: _buildWalletBalanceBarChartData(context, dataManager, selectedPeriod),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              getTitlesWidget: (value, meta) {
                                final displayValue = value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(1)} k${dataManager.currencySymbol}'
                                    : CurrencyUtils.formatCurrency(value, dataManager.currencySymbol);
                                return Text(
                                  displayValue,
                                  style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels = _buildDateLabelsForWallet(context, dataManager, selectedPeriod);
                                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(fontSize: 10 + appState.getTextSizeOffset()),
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
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.transparent),
                            bottom: BorderSide(color: Colors.blueGrey.shade700, width: 0.5),
                            right: BorderSide(color: Colors.transparent),
                            top: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildWalletBalanceChartData(context, dataManager, selectedPeriod),
                            isCurved: false,
                            barWidth: 2,
                            color: Colors.purple,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withOpacity(0.4),
                                  Colors.purple.withOpacity(0),
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
                              return touchedSpots.map((touchedSpot) {
                                final index = touchedSpot.x.toInt();
                                final averageBalance = touchedSpot.y;
                                final periodLabel = _buildDateLabelsForWallet(context, dataManager, selectedPeriod)[index];

                                return LineTooltipItem(
                                  '$periodLabel\n${CurrencyUtils.formatCurrency(averageBalance, dataManager.currencySymbol)}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }


  List<BarChartGroupData> _buildWalletBalanceBarChartData(BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<FlSpot> walletBalanceData = _buildWalletBalanceChartData(context, dataManager, selectedPeriod);
    return walletBalanceData
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: Colors.purple,
                width: 8,
              ),
            ],
          ),
        )
        .toList();
  }

 List<FlSpot> _buildWalletBalanceChartData(BuildContext context, DataManager dataManager, String selectedPeriod) {
  return ChartUtils.buildHistoryChartData<BalanceRecord>(
    context,
    dataManager.walletBalanceHistory,
    selectedPeriod,
    (record) => record.balance,
    (record) => record.timestamp,
  );
}

  List<String> _buildDateLabelsForWallet(BuildContext context, DataManager dataManager, String selectedPeriod) {
    List<BalanceRecord> walletHistory = dataManager.walletBalanceHistory;

    Map<String, List<double>> groupedData = {};
    for (var record in walletHistory) {
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

      groupedData.putIfAbsent(periodKey, () => []).add(record.balance);
    }

    List<String> sortedKeys = groupedData.keys.toList()..sort();
    return sortedKeys;
  }

}