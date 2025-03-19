import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/utils/currency_utils.dart';

Widget buildInsightsTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);
  
  // Formatter pour les valeurs monétaires
  final currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '\$',
    decimalDigits: 2,
  );

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Jauge verticale du ROI de la propriété
        Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment, // Icône pour représenter le ROI
                  size: 18,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).roiPerProperties, // Titre de la jauge
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15 + appState.getTextSizeOffset(),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                          S.of(context).roiPerProperties), // Titre du popup
                      content:
                          Text(S.of(context).roiAlertInfo), // Texte explicatif
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fermer le popup
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(
                Icons.help_outline, // Icône "?"
                color: Colors.grey,
                size: 20 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),
        _buildGaugeForROI(
          token['totalRentReceived'] /
              token['initialTotalValue'] *
              100, // Calcul du ROI
          context,
        ),
        const SizedBox(height: 8),

        // Graphique du rendement (Yield)
        Row(
          children: [
            Icon(Icons.trending_up,
                size: 18, color: Colors.blueGrey), // Icône devant le texte
            const SizedBox(width: 8),
            Text(
              S.of(context).yieldEvolution, // Utilisation de la traduction
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildYieldChartOrMessage(context, token['historic']?['yields'] ?? [],
            token['historic']?['init_yield'], currencyFormat),

        const SizedBox(height: 20),

        // Graphique des prix
        Row(
          children: [
            Icon(
              Icons.attach_money, // Icône pour représenter l'évolution des prix
              size: 18,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).priceEvolution, // Texte avec traduction
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPriceChartOrMessage(
            context, token['historic']?['prices'] ?? [], token['initPrice'], currencyFormat),
            
        const SizedBox(height: 20),
        
        // Nouveau graphique : Cumul des loyers
        Row(
          children: [
            Icon(
              Icons.monetization_on, // Icône pour représenter les loyers
              size: 18,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 8),
            Text(
              "Cumul des loyers", // À traduire si nécessaire
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15 + appState.getTextSizeOffset(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRentCumulativeChartOrMessage(context, token['uuid'], dataManager, currencyFormat),
      ],
    ),
  );
}

// Méthode pour construire la jauge du ROI
Widget _buildGaugeForROI(double roiValue, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 5),
      LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth; // Largeur disponible

          return Stack(
            children: [
              // Fond gris
              Container(
                height: 15,
                width: maxWidth,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Barre bleue représentant le ROI
              Container(
                height: 15,
                width: roiValue.clamp(0, 100) / 100 * maxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Texte centré sur la jauge
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${roiValue.toStringAsFixed(1)} %", // Afficher avec 1 chiffre après la virgule
                    style: TextStyle(
                      fontSize: 14,
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
      const SizedBox(height: 5),
    ],
  );
}

// Méthode pour afficher soit le graphique du yield, soit un message
Widget _buildYieldChartOrMessage(
    BuildContext context, List<dynamic> yields, double? initYield, NumberFormat currencyFormat) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (yields.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
      text: TextSpan(
        text: "${S.of(context).noYieldEvolution} ",
        style: TextStyle(
          fontSize: 13 + appState.getTextSizeOffset(),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(
            text: yields.isNotEmpty
                ? yields.first['yield'].toStringAsFixed(2) // La valeur en gras
                : S.of(context).notSpecified,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          TextSpan(
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
        _buildYieldChart(context, yields, currencyFormat),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            text: S.of(context).yieldEvolutionPercentage,
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
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
Widget _buildYieldChart(BuildContext context, List<dynamic> yields, NumberFormat currencyFormat) {
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
      y = double.parse(
          y.toStringAsFixed(2)); // Limiter la valeur de `y` à 2 décimales

      spots.add(FlSpot(x, y));
      dateLabels.add(DateFormat('MM/yyyy').format(date));
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

  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10 + appState.getTextSizeOffset(),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            belowBarData: BarAreaData(show: false),
          ),
        ],
        // Ajouter un tooltip pour afficher les valeurs précises au survol
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final int index = touchedSpot.x.toInt();
                return LineTooltipItem(
                  '${dateLabels[index]}: ${touchedSpot.y.toStringAsFixed(2)}%',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
            // Propriétés pour éviter que le tooltip soit coupé aux bords
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 8,
            tooltipHorizontalOffset: 0,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
          ),
          // Améliorer l'interaction tactile
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
        ),
      ),
    ),
  );
}

// Méthode pour afficher soit le graphique des prix, soit un message
Widget _buildPriceChartOrMessage(
    BuildContext context, List<dynamic> prices, double? initPrice, NumberFormat currencyFormat) {
  final appState = Provider.of<AppState>(context, listen: false);

  if (prices.length <= 1) {
    // Afficher le message si une seule donnée est disponible
    return RichText(
      text: TextSpan(
        text: "${S.of(context).noPriceEvolution} ",
        style: TextStyle(
          fontSize: 13 + appState.getTextSizeOffset(),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(
            text: prices.isNotEmpty
                ? prices.first['price'].toStringAsFixed(2) // La valeur en gras
                : S.of(context).notSpecified,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          TextSpan(
            text: " \$",
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
        _buildPriceChart(context, prices, currencyFormat),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            text: S.of(context).priceEvolutionPercentage,
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
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

// Méthode pour construire le graphique des prix
Widget _buildPriceChart(BuildContext context, List<dynamic> prices, NumberFormat currencyFormat) {
  final appState = Provider.of<AppState>(context, listen: false);

  List<FlSpot> spots = [];
  List<String> dateLabels = [];

  for (int i = 0; i < prices.length; i++) {
    DateTime date = DateTime.parse(prices[i]['timsync']);
    double x = i.toDouble();
    double y = prices[i]['price']?.toDouble() ?? 0;

    spots.add(FlSpot(x, y));
    dateLabels.add(DateFormat('MM/yyyy').format(date));
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

  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  return Text(
                    dateLabels[value.toInt()],
                    style: TextStyle(
                      fontSize: 10 + appState.getTextSizeOffset(),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10 + appState.getTextSizeOffset(),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            belowBarData: BarAreaData(show: false),
          ),
        ],
        // Ajouter un tooltip pour afficher les valeurs précises au survol
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final int index = touchedSpot.x.toInt();
                return LineTooltipItem(
                  '${dateLabels[index]}: ${currencyFormat.format(touchedSpot.y)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
            // Propriétés pour éviter que le tooltip soit coupé aux bords
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 8,
            tooltipHorizontalOffset: 0,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
          ),
          // Améliorer l'interaction tactile
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
        ),
      ),
    ),
  );
}

// Méthode pour afficher soit le graphique cumulatif des loyers, soit un message
Widget _buildRentCumulativeChartOrMessage(
    BuildContext context, String tokenId, DataManager dataManager, NumberFormat currencyFormat) {
  final appState = Provider.of<AppState>(context, listen: false);
  
  // Récupérer l'historique des loyers pour ce token
  List<Map<String, dynamic>> rentHistory = dataManager.getRentHistoryForToken(tokenId);
  
  if (rentHistory.isEmpty) {
    // Afficher un message si aucune donnée n'est disponible
    return Text(
      "Aucun historique de loyer disponible pour ce token.",
      style: TextStyle(
        fontSize: 13 + appState.getTextSizeOffset(),
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  } else {
    // Calculer le montant total des loyers
    double totalRent = dataManager.cumulativeRentsByToken[tokenId.toLowerCase()] ?? 0.0;
    
    // Afficher le graphique et le montant total
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRentCumulativeChart(context, rentHistory, currencyFormat),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            text: "Total des loyers reçus: ",
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            children: [
              TextSpan(
                text: " ${currencyFormat.format(totalRent)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Méthode pour construire le graphique cumulatif des loyers
Widget _buildRentCumulativeChart(BuildContext context, List<Map<String, dynamic>> rentHistory, NumberFormat currencyFormat) {
  final appState = Provider.of<AppState>(context, listen: false);

  // Trier l'historique par date
  rentHistory.sort((a, b) {
    DateTime dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
    DateTime dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
    return dateA.compareTo(dateB);
  });

  List<FlSpot> spots = [];
  List<String> dateLabels = [];
  double cumulativeRent = 0.0;

  for (int i = 0; i < rentHistory.length; i++) {
    double x = i.toDouble();
    // Convertir la valeur de loyer en double
    double rentValue = 0.0;
    
    if (rentHistory[i]['rent'] is num) {
      rentValue = (rentHistory[i]['rent'] as num).toDouble();
    } else if (rentHistory[i]['rent'] is String) {
      rentValue = double.tryParse(rentHistory[i]['rent']) ?? 0.0;
    }
    
    cumulativeRent += rentValue;
    spots.add(FlSpot(x, cumulativeRent));
    
    // Formater la date pour l'affichage
    String dateStr = rentHistory[i]['date'];
    DateTime date = DateTime.parse(dateStr);
    dateLabels.add(DateFormat('dd/MM/yy').format(date));
  }

  // Calcul des marges
  double minXValue = spots.isNotEmpty ? spots.first.x : 0;
  double maxXValue = spots.isNotEmpty ? spots.last.x : 0;
  double maxYValue = spots.isNotEmpty ? spots.last.y : 0; // La dernière valeur est la plus élevée pour un cumul

  // Ajouter des marges autour des valeurs min et max
  const double marginX = 0.2;
  const double marginY = 0.5;

  return SizedBox(
    height: 180,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                  // N'afficher que quelques dates pour éviter la surcharge
                  if (dateLabels.length <= 5 || value.toInt() % (dateLabels.length ~/ 5 + 1) == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dateLabels[value.toInt()],
                        style: TextStyle(
                          fontSize: 10 + appState.getTextSizeOffset(),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10 + appState.getTextSizeOffset(),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: minXValue - marginX,
        maxX: maxXValue + marginX,
        minY: 0 - marginY, // Le minimum est toujours 0 pour un graphique cumulatif
        maxY: maxYValue + marginY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.green, // Couleur différente pour distinguer ce graphique
            isCurved: false, // Pas de courbe pour mieux voir les paliers
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1), // Remplissage semi-transparent
            ),
            dotData: FlDotData(show: false), // Cacher les points pour un graphique plus propre
          ),
        ],
        // Configurer le tooltip pour qu'il reste visible aux bords de l'écran
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final int index = touchedSpot.x.toInt();
                return LineTooltipItem(
                  '${dateLabels[index]}: ${currencyFormat.format(touchedSpot.y)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
            // Propriétés pour éviter que le tooltip soit coupé aux bords
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 8,
            tooltipHorizontalOffset: 0,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
          ),
          // Améliorer l'interaction tactile
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
        ),
      ),
    ),
  );
}
