import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

Widget buildInsightsTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

  // Formatter pour les valeurs monétaires - désormais inutilisé
  final currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '\$',
    decimalDigits: 2,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section ROI
        _buildSectionCard(
          context,
          title: S.of(context).roiPerProperties,
          helpCallback: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S.of(context).roiPerProperties),
                  content: Text(S.of(context).roiAlertInfo),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: _buildGaugeForROI(
                token['totalRentReceived'] / token['initialTotalValue'] * 100,
                context,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section Évolution du Rendement
        _buildSectionCard(
          context,
          title: S.of(context).yieldEvolution,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: _buildYieldChartOrMessage(
                  context,
                  token['historic']?['yields'] ?? [],
                  token['historic']?['init_yield'],
                  currencyUtils),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section Évolution des Prix
        _buildSectionCard(
          context,
          title: S.of(context).priceEvolution,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: _buildPriceChartOrMessage(
                  context,
                  token['historic']?['prices'] ?? [],
                  token['initPrice'],
                  currencyUtils),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section Cumul des Loyers
        _buildSectionCard(
          context,
          title: S.of(context).cumulativeRentGraph,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: _buildRentCumulativeChartOrMessage(
                  context, token['uuid'], dataManager, currencyUtils),
            ),
          ],
        ),
      ],
    ),
  );
}

// Widget pour construire une section, comme dans property_tab.dart
Widget _buildSectionCard(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  Function()? helpCallback,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize:
                      18 + Provider.of<AppState>(context).getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (helpCallback != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: helpCallback,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Column(children: children),
      ],
    ),
  );
}

// Méthode pour construire la jauge du ROI
Widget _buildGaugeForROI(double roiValue, BuildContext context) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;

          return Stack(
            children: [
              // Fond gris
              Container(
                height: 14,
                width: maxWidth,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 78, 78, 78)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              // Barre bleue représentant le ROI
              Container(
                height: 14,
                width: roiValue.clamp(0, 100) / 100 * maxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              // Texte centré sur la jauge
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${roiValue.toStringAsFixed(1)} %",
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 6),
      Text(
        "Retour sur investissement basé sur les loyers perçus",
        style: TextStyle(
          fontSize: 12 + appState.getTextSizeOffset(),
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withValues(alpha: 0.8),
        ),
      ),
    ],
  );
}

// Méthode pour afficher soit le graphique du yield, soit un message
Widget _buildYieldChartOrMessage(BuildContext context, List<dynamic> yields,
    double? initYield, CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (yields.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
      text: TextSpan(
        text: "${S.of(context).noYieldEvolution} ",
        style: TextStyle(
          fontSize: 14 + appState.getTextSizeOffset(),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(
            text: yields.isNotEmpty
                ? yields.first['yield'].toStringAsFixed(2)
                : S.of(context).notSpecified,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const TextSpan(
            text: " %",
          ),
        ],
      ),
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastYield = yields.last['yield']?.toDouble() ?? 0;
    double percentageChange =
        ((lastYield - (initYield ?? lastYield)) / (initYield ?? lastYield)) *
            100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: _buildYieldChart(context, yields, currencyUtils),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            text: S.of(context).yieldEvolutionPercentage,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            children: [
              TextSpan(
                text: " ${percentageChange.toStringAsFixed(2)} %",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentageChange < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique du yield
Widget _buildYieldChart(BuildContext context, List<dynamic> yields,
    CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < yields.length; i++) {
    if (yields[i]['timsync'] != null && yields[i]['timsync'] is String) {
      DateTime date = DateTime.parse(yields[i]['timsync']);
      double x = i.toDouble();
      double y = yields[i]['yield'] != null
          ? double.tryParse(yields[i]['yield'].toString()) ?? 0
          : 0;
      y = double.parse(y.toStringAsFixed(2));

      spots.add(FlSpot(x, y));
      dateLabels.add(DateFormat('MM/yy').format(date));
    }
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
      : 0;
  double maxYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
      : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.2;
  const double marginY = 0.5;

  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                // N'afficher que quelques étiquettes pour éviter l'encombrement
                if (dateLabels.length <= 4 ||
                    value.toInt() % (dateLabels.length ~/ 4 + 1) == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      dateLabels[value.toInt()],
                      style: TextStyle(
                        fontSize: 9 + appState.getTextSizeOffset(),
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 9 + appState.getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              );
            },
            interval: 1,
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      minX: minXValue - marginX,
      maxX: maxXValue + marginX,
      minY: minYValue - marginY,
      maxY: maxYValue + marginY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: Theme.of(context).primaryColor,
          isCurved: true,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 3,
              color: Theme.of(context).primaryColor,
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final int index = touchedSpot.x.toInt();
              return LineTooltipItem(
                '${dateLabels[index]}: ${touchedSpot.y.toStringAsFixed(2)}%',
                TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 + appState.getTextSizeOffset()),
              );
            }).toList();
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 8,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
        ),
        handleBuiltInTouches: true,
        touchSpotThreshold: 20,
      ),
    ),
  );
}

// Méthode pour afficher soit le graphique des prix, soit un message
Widget _buildPriceChartOrMessage(BuildContext context, List<dynamic> prices,
    double? initPrice, CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (prices.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
      text: TextSpan(
        text: "${S.of(context).noPriceEvolution} ",
        style: TextStyle(
          fontSize: 14 + appState.getTextSizeOffset(),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(
            text: prices.isNotEmpty
                ? currencyUtils.formatCurrency(
                    currencyUtils.convert(prices.first['price']),
                    currencyUtils.currencySymbol)
                : S.of(context).notSpecified,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  } else {
    // Calculer l'évolution en pourcentage
    double lastPrice = prices.last['price']?.toDouble() ?? 0;
    double percentageChange =
        ((lastPrice - (initPrice ?? lastPrice)) / (initPrice ?? lastPrice)) *
            100;

    // Afficher le graphique et le % d'évolution
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: _buildPriceChart(context, prices, currencyUtils),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: S.of(context).priceEvolutionPercentage,
                style: TextStyle(
                  fontSize: 14 + appState.getTextSizeOffset(),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                children: [
                  TextSpan(
                    text: " ${percentageChange.toStringAsFixed(2)} %",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: percentageChange < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: "Prix actuel: ",
                style: TextStyle(
                  fontSize: 14 + appState.getTextSizeOffset(),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                children: [
                  TextSpan(
                    text: currencyUtils.formatCurrency(
                        currencyUtils.convert(lastPrice),
                        currencyUtils.currencySymbol),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique des prix
Widget _buildPriceChart(BuildContext context, List<dynamic> prices,
    CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < prices.length; i++) {
    DateTime date = DateTime.parse(prices[i]['timsync']);
    double x = i.toDouble();
    double y = prices[i]['price']?.toDouble() ?? 0;

    spots.add(FlSpot(x, y));
    dateLabels.add(DateFormat('MM/yy').format(date));
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double minYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b)
      : 0;
  double maxYValue = spots.isNotEmpty
      ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
      : 0;

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.1;
  const double marginY = 0.2;

  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                // N'afficher que quelques étiquettes pour éviter l'encombrement
                if (dateLabels.length <= 4 ||
                    value.toInt() % (dateLabels.length ~/ 4 + 1) == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      dateLabels[value.toInt()],
                      style: TextStyle(
                        fontSize: 9 + appState.getTextSizeOffset(),
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              // Formater les valeurs monétaires de manière compacte
              final convertedValue = currencyUtils.convert(value);
              return Text(
                currencyUtils.formatCurrency(convertedValue, ''),
                style: TextStyle(
                  fontSize: 9 + appState.getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      minX: minXValue - marginX,
      maxX: maxXValue + marginX,
      minY: minYValue - marginY,
      maxY: maxYValue + marginY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: Theme.of(context).primaryColor,
          isCurved: true,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 3,
              color: Theme.of(context).primaryColor,
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final int index = touchedSpot.x.toInt();
              final convertedValue = currencyUtils.convert(touchedSpot.y);
              return LineTooltipItem(
                '${dateLabels[index]}: ${currencyUtils.formatCurrency(convertedValue, currencyUtils.currencySymbol)}',
                TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 + appState.getTextSizeOffset()),
              );
            }).toList();
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 8,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
        ),
        handleBuiltInTouches: true,
        touchSpotThreshold: 20,
      ),
    ),
  );
}

// Méthode pour afficher soit le graphique cumulatif des loyers, soit un message
Widget _buildRentCumulativeChartOrMessage(BuildContext context, String tokenId,
    DataManager dataManager, CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  // Récupérer l'historique des loyers pour ce token
  List<Map<String, dynamic>> rentHistory =
      dataManager.getRentHistoryForToken(tokenId);

  // Récupérer le nombre de wallets qui possèdent ce token
  int walletCount = dataManager.getWalletCountForToken(tokenId);

  if (rentHistory.isEmpty) {
    // Afficher un message si aucune donnée n'est disponible
    return Text(
      "Aucun historique de loyer disponible pour ce token",
      style: TextStyle(
        fontSize: 14 + appState.getTextSizeOffset(),
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  } else {
    // Calculer le montant total des loyers
    double totalRent =
        dataManager.cumulativeRentsByToken[tokenId.toLowerCase()] ?? 0.0;

    // Afficher le graphique et le montant total
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: _buildRentCumulativeChart(context, rentHistory, currencyUtils),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Loyers depuis ${walletCount > 1 ? '$walletCount wallets' : '1 wallet'}",
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            RichText(
              text: TextSpan(
                text: "Total: ",
                style: TextStyle(
                  fontSize: 14 + appState.getTextSizeOffset(),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                children: [
                  TextSpan(
                    text: currencyUtils.getFormattedAmount(
                        currencyUtils.convert(totalRent),
                        currencyUtils.currencySymbol,
                        appState.showAmounts),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique cumulatif des loyers
Widget _buildRentCumulativeChart(BuildContext context,
    List<Map<String, dynamic>> rentHistory, CurrencyProvider currencyUtils) {
  final appState = Provider.of<AppState>(context, listen: false);

  // Trier l'historique par date
  rentHistory.sort((a, b) {
    DateTime dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
    DateTime dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
    return dateA.compareTo(dateB);
  });

  // Regrouper les loyers par date (car il peut y avoir plusieurs wallets pour la même date)
  Map<String, double> rentByDate = {};
  for (var entry in rentHistory) {
    String date = entry['date'];
    double rent = 0.0;

    if (entry['rent'] is num) {
      rent = (entry['rent'] as num).toDouble();
    } else if (entry['rent'] is String) {
      rent = double.tryParse(entry['rent']) ?? 0.0;
    }

    rentByDate[date] = (rentByDate[date] ?? 0.0) + rent;
  }

  // Convertir en liste pour le graphique
  List<FlSpot> spots = [];
  List<String> dateLabels = [];
  double cumulativeRent = 0.0;

  // Trier les dates
  List<String> sortedDates = rentByDate.keys.toList()
    ..sort((a, b) {
      DateTime dateA = DateFormat('yyyy-MM-dd').parse(a);
      DateTime dateB = DateFormat('yyyy-MM-dd').parse(b);
      return dateA.compareTo(dateB);
    });

  for (int i = 0; i < sortedDates.length; i++) {
    String date = sortedDates[i];
    double x = i.toDouble();
    double rentValue = rentByDate[date] ?? 0.0;

    cumulativeRent += rentValue;
    spots.add(FlSpot(x, cumulativeRent));

    // Formater la date pour l'affichage
    DateTime dateObj = DateTime.parse(date);
    dateLabels.add(DateFormat('MM/yy').format(dateObj));
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double maxYValue = spots.isNotEmpty
      ? spots.last.y
      : 0; // La dernière valeur est la plus élevée pour un cumul

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.2;
  const double marginY = 0.5;

  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 0.5,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                // N'afficher que quelques dates pour éviter la surcharge
                if (dateLabels.length <= 4 ||
                    value.toInt() % (dateLabels.length ~/ 4 + 1) == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      dateLabels[value.toInt()],
                      style: TextStyle(
                        fontSize: 9 + appState.getTextSizeOffset(),
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
              }
              return const Text('');
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) {
              final convertedValue = currencyUtils.convert(value);
              return Text(
                currencyUtils.formatCurrency(convertedValue, ''),
                style: TextStyle(
                  fontSize: 9 + appState.getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      minX: minXValue - marginX,
      maxX: maxXValue + marginX,
      minY: 0 -
          marginY / 2, // Le minimum est toujours 0 pour un graphique cumulatif
      maxY: maxYValue + marginY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: Colors.green[700],
          isCurved: true,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final int index = touchedSpot.x.toInt();
              final convertedValue = currencyUtils.convert(touchedSpot.y);
              return LineTooltipItem(
                '${dateLabels[index]}: ${currencyUtils.formatCurrency(convertedValue, currencyUtils.currencySymbol)}',
                TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 + appState.getTextSizeOffset()),
              );
            }).toList();
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 8,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
        ),
        handleBuiltInTouches: true,
        touchSpotThreshold: 20,
      ),
    ),
  );
}
