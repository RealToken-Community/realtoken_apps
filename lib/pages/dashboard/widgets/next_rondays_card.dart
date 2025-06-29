import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class NextRondaysCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const NextRondaysCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final theme = Theme.of(context);

    return UIUtils.buildCard(
      S.of(context).nextRondays,
      Icons.calendar_today_rounded,
      _buildCumulativeRentHeader(context, dataManager),
      _buildCumulativeRentList(context, dataManager),
      dataManager,
      context,
      hasGraph: true,
      rightWidget: _buildMiniGraphForNextRondays(dataManager, context),
    );
  }

  Widget _buildCumulativeRentHeader(BuildContext context, DataManager dataManager) {
    final theme = Theme.of(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();

    // Filtrer pour n'afficher que les dates futures
    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    if (futureRentEvolution.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          S.of(context).noScheduledRonday,
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    // Trouver la prochaine date
    DateTime nextDate = futureRentEvolution.first['rentStartDate'];
    double nextAmount = futureRentEvolution.first['cumulativeRent'];

    for (var entry in futureRentEvolution) {
      DateTime entryDate = entry['rentStartDate'];
      if (entryDate.isBefore(nextDate)) {
        nextDate = entryDate;
        nextAmount = entry['cumulativeRent'];
      }
    }

    // Calculer le nombre de jours restants
    int daysRemaining = nextDate.difference(today).inDays;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).nextRondayInDays(daysRemaining),
                style: TextStyle(
                  fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "${DateFormat('dd MMM yyyy').format(nextDate)} · ${currencyUtils.getFormattedAmount(currencyUtils.convert(nextAmount), currencyUtils.currencySymbol, showAmounts)}",
                style: TextStyle(
                  fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                  color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGraphForNextRondays(DataManager dataManager, BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);
    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();

    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    // Trier par date
    futureRentEvolution.sort((a, b) {
      DateTime dateA = a['rentStartDate'];
      DateTime dateB = b['rentStartDate'];
      return dateA.compareTo(dateB);
    });

    Set<DateTime> displayedDates = <DateTime>{};
    List<Map<String, dynamic>> graphData = [];

    for (var entry in futureRentEvolution) {
      DateTime rentStartDate = entry['rentStartDate'];
      if (!displayedDates.contains(rentStartDate)) {
        displayedDates.add(rentStartDate);
        graphData.add({
          'date': DateFormat('dd MMM').format(rentStartDate),
          'amount': entry['cumulativeRent'],
        });
      }
    }

    // Limiter à 5 événements pour une meilleure lisibilité
    if (graphData.length > 5) {
      graphData = graphData.sublist(0, 5);
    }

    // Si aucune donnée, afficher un placeholder
    if (graphData.isEmpty) {
      return SizedBox(
        height: 100,
        width: 120,
        child: Center(
          child: Icon(
            Icons.event_busy_rounded,
            size: 40,
            color: theme.brightness == Brightness.light ? Colors.black12 : Colors.white10,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 120,
        width: 120,
        margin: EdgeInsets.only(top: 0), // Aligné avec le titre "Calendrier"
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= graphData.length || value.toInt() < 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        graphData[value.toInt()]['date'],
                        style: TextStyle(
                          fontSize: 9 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                          color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.center,
            groupsSpace: 10,
            barGroups: List.generate(graphData.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: 40.0 + (index * 5), // Hauteur fixe pour éviter les erreurs
                    color: theme.primaryColor,
                    width: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
                showingTooltipIndicators: [],
              );
            }),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.black87,
                tooltipPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex >= 0 && groupIndex < graphData.length) {
                    double amount = currencyUtils.convert(graphData[groupIndex]['amount']);
                    return BarTooltipItem(
                      '${amount.toStringAsFixed(2)} ${currencyUtils.currencySymbol}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCumulativeRentList(BuildContext context, dataManager) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);
    final cumulativeRentEvolution = dataManager.getCumulativeRentEvolution();
    DateTime today = DateTime.now();
    final appState = Provider.of<AppState>(context);

    // Filtrer pour n'afficher que les dates futures
    final futureRentEvolution = cumulativeRentEvolution.where((entry) {
      DateTime rentStartDate = entry['rentStartDate'];
      return rentStartDate.isAfter(today);
    }).toList();

    // Trier par date (plus proche au plus éloigné)
    futureRentEvolution.sort((a, b) {
      DateTime dateA = a['rentStartDate'];
      DateTime dateB = b['rentStartDate'];
      return dateA.compareTo(dateB);
    });

    // Utiliser un Set pour ne garder que des dates uniques
    Set<DateTime> displayedDates = <DateTime>{};
    List<Widget> rentItems = [];

    if (futureRentEvolution.isEmpty) {
      return [SizedBox.shrink()];
    }

    // Titre de section
    rentItems.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Row(
          children: [
            Container(
              height: 16,
              width: 4,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).calendar,
              style: TextStyle(
                fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );

    // Liste des dates
    for (var entry in futureRentEvolution) {
      DateTime rentStartDate = entry['rentStartDate'];

      if (displayedDates.contains(rentStartDate)) {
        continue;
      }

      displayedDates.add(rentStartDate);

      String displayDate = rentStartDate == DateTime(3000, 1, 1) ? S.of(context).dateNotCommunicated : DateFormat('dd MMM yyyy').format(rentStartDate);

      // Calculer le nombre de jours restants
      int daysRemaining = rentStartDate.difference(today).inDays;

      rentItems.add(
        Container(
          margin: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Color(0xFFF2F2F7) : Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      letterSpacing: -0.3,
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    S.of(context).daysShort(daysRemaining),
                    style: TextStyle(
                      fontSize: 11 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      letterSpacing: -0.3,
                      color: theme.brightness == Brightness.light ? Colors.black38 : Colors.white54,
                    ),
                  ),
                ],
              ),
              Text(
                currencyUtils.getFormattedAmount(currencyUtils.convert(entry['cumulativeRent']), currencyUtils.currencySymbol, showAmounts),
                style: TextStyle(
                  fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return rentItems;
  }
}
