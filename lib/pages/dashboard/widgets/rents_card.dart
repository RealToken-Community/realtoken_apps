import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/pages/dashboard/detailsPages/rent_details_page.dart';

class RentsCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RentsCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    return UIUtils.buildCard(
      S.of(context).rents,
      Icons.attach_money,
      Row(
        children: [
          UIUtils.buildValueBeforeText(context, '${dataManager.netGlobalApy.toStringAsFixed(2)}%' as String?, S.of(context).annualYield, dataManager.isLoadingMain),
          SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(S.of(context).apy),
                    content: Text(
                      S.of(context).netApyHelp,
                      style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(S.of(context).close),
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(Icons.info_outline, size: 15),
          ),
          SizedBox(width: 8),
          Text(
            '(${dataManager.averageAnnualYield.toStringAsFixed(2)}% brut)',
            style: TextStyle(
              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      [
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.dailyRent), currencyUtils.currencySymbol, showAmounts),
          S.of(context).daily,
          isLoading || dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.weeklyRent), currencyUtils.currencySymbol, showAmounts),
          S.of(context).weekly,
          isLoading || dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(
            currencyUtils.convert(dataManager.monthlyRent),
            currencyUtils.currencySymbol,
            showAmounts,
          ),
          S.of(context).monthly,
          isLoading || dataManager.isLoadingMain,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.yearlyRent), currencyUtils.currencySymbol, showAmounts),
          S.of(context).annually,
          isLoading || dataManager.isLoadingMain,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildMiniGraphForRendement(_getLast12WeeksRent(dataManager), context, dataManager),
      headerRightWidget: SizedBox(
        height: 36,
        width: 36,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white70,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardRentsDetailsPage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGraphForRendement(List<Map<String, dynamic>> data, BuildContext context, DataManager dataManager) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Calculer les valeurs min et max des données après conversion
    List<double> convertedValues = List.generate(data.length, (index) {
      return double.parse(currencyUtils.convert(data[index]['amount']).toStringAsFixed(2));
    });

    double minY = convertedValues.isEmpty ? 0 : convertedValues.reduce((a, b) => a < b ? a : b);
    double maxY = convertedValues.isEmpty ? 0 : convertedValues.reduce((a, b) => a > b ? a : b);

    // Ajouter une petite marge en bas et en haut
    minY = minY * 0.97; // 5% de marge en bas
    maxY = maxY * 1.03; // 5% de marge en haut

    return SizedBox(
      height: 90,
      width: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(data.length, (index) {
                double roundedValue = convertedValues[index];
                return FlSpot(index.toDouble(), roundedValue);
              }),
              isCurved: true,
              barWidth: 2,
              color: Theme.of(context).primaryColor,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2,
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.4),
                    Theme.of(context).primaryColor.withOpacity(0),
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
                  final weekLabel = data[index]['week'];
                  final amount = touchedSpot.y.toStringAsFixed(2);

                  return LineTooltipItem(
                    '$weekLabel\n$amount ${currencyUtils.currencySymbol}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getLast12WeeksRent(DataManager dataManager) {
    final currentDate = DateTime.now();
    final rentData = dataManager.rentData;

    DateTime currentMonday = currentDate.subtract(Duration(days: currentDate.weekday - 1));

    Map<String, double> weeklyRent = {};

    for (var rentEntry in rentData) {
      DateTime date = DateTime.parse(rentEntry['date']);

      DateTime mondayOfWeek = date.subtract(Duration(days: date.weekday - 1));

      String weekKey = DateFormat('yyyy-MM-dd').format(mondayOfWeek);

      if (mondayOfWeek.isBefore(currentMonday)) {
        weeklyRent[weekKey] = (weeklyRent[weekKey] ?? 0) + rentEntry['rent'];
      }
    }

    List<Map<String, dynamic>> last12WeeksData = List.generate(12, (index) {
      DateTime pastMonday = currentMonday.subtract(Duration(days: (index + 1) * 7));
      String weekLabel = DateFormat('dd MMM yyyy').format(pastMonday);

      return {'week': weekLabel, 'amount': weeklyRent[DateFormat('yyyy-MM-dd').format(pastMonday)] ?? 0};
    }).reversed.toList();

    return last12WeeksData;
  }
}
