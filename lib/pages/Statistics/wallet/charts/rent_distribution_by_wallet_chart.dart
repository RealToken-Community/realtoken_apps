import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

class RentDistributionByWalletChart extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionByWalletChart({super.key, required this.dataManager});

  @override
  _RentDistributionByWalletChartState createState() =>
      _RentDistributionByWalletChartState();
}

class _RentDistributionByWalletChartState
    extends State<RentDistributionByWalletChart> {
  int? _selectedIndex;
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Vérifier si les données sont valides
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    if (walletRentTotals.isEmpty) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).rentDistributionByWallet,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildRentDonutChartData(selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifier.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterText(selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildRentLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildRentDonutChartData(int? selectedIndex) {
    // Obtenir les données de loyers par wallet
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();

    // Vérifier si les données sont valides
    if (walletRentTotals.isEmpty) {
      return [];
    }

    // Calculer le total des loyers
    final double totalRent =
        walletRentTotals.values.fold(0.0, (sum, value) => sum + value);

    // Vérifier si le total est valide
    if (totalRent <= 0) {
      return [];
    }

    // Trier les entrées par montant décroissant
    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Créer les sections du donut chart avec des vérifications de sécurité
    return sortedEntries
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final data = entry.value;

          // Vérifier si la valeur est valide
          if (data.value <= 0) {
            return null;
          }

          final percentage = (data.value / totalRent) * 100;
          final bool isSelected = selectedIndex == index;
          final double opacity =
              selectedIndex != null && !isSelected ? 0.5 : 1.0;

          return PieChartSectionData(
            value: data.value,
            title: '${percentage.toInt()}%',
            color: _generateColor(index).withValues(alpha: opacity),
            radius: isSelected ? 52 : 45,
            titleStyle: TextStyle(
              fontSize: isSelected
                  ? 14 + Provider.of<AppState>(context).getTextSizeOffset()
                  : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            badgeWidget: isSelected ? _buildSelectedIndicator() : null,
            badgePositionPercentageOffset: 1.1,
          );
        })
        .whereType<PieChartSectionData>()
        .toList();
  }

  Widget _buildSelectedIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterText(int? selectedIndex) {
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    final double totalRent =
        walletRentTotals.values.fold(0.0, (sum, value) => sum + value);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    if (selectedIndex == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).totalValue,
            style: TextStyle(
              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyUtils.formatCompactCurrency(
              currencyUtils.convert(totalRent),
              currencyUtils.currencySymbol,
            ),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selectedEntry = sortedEntries[selectedIndex];

    // Raccourcir l'adresse du wallet pour l'affichage
    String displayWallet = _formatWalletAddress(selectedEntry.key);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayWallet,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: _generateColor(selectedIndex),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyUtils.formatCompactCurrency(
            currencyUtils.convert(selectedEntry.value),
            currencyUtils.currencySymbol,
          ),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRentLegend() {
    final Map<String, double> walletRentTotals = _calculateWalletRentTotals();
    final appState = Provider.of<AppState>(context);

    final sortedEntries = walletRentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.map((entry) {
        final index = sortedEntries.indexOf(entry);
        final color = _generateColor(index);

        // Raccourcir l'adresse du wallet pour l'affichage
        String displayWallet = _formatWalletAddress(entry.key);

        return InkWell(
          onTap: () {
            _selectedIndexNotifier.value = index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifier.value == index
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifier.value == index
                    ? color
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayWallet,
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: _selectedIndexNotifier.value == index
                        ? color
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifier.value == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Méthode pour calculer le total des loyers par wallet
  Map<String, double> _calculateWalletRentTotals() {
    Map<String, double> result = {};

    // Obtenir les données de loyers par wallet depuis le DataManager
    Map<String, Map<String, double>> rentsByWallet =
        widget.dataManager.getRentsByWallet();

    // Calculer le total des loyers pour chaque wallet
    for (var walletEntry in rentsByWallet.entries) {
      String wallet = walletEntry.key;
      Map<String, double> tokenRents = walletEntry.value;

      // Somme des loyers pour tous les tokens de ce wallet
      double totalForWallet =
          tokenRents.values.fold(0.0, (sum, rent) => sum + rent);
      result[wallet] = totalForWallet;
    }

    return result;
  }

  // Méthode pour générer une couleur basée sur l'index
  Color _generateColor(int index) {
    final List<Color> colorPalette = [
      const Color(0xFF007AFF), // iOS blue
      const Color(0xFF34C759), // iOS green
      const Color(0xFFFF9500), // iOS orange
      const Color(0xFFFF2D55), // iOS red
      const Color(0xFF5856D6), // iOS purple
      const Color(0xFFAF52DE), // iOS pink
      const Color(0xFF5AC8FA), // iOS light blue
      const Color(0xFFFF3B30), // iOS red alternative
      const Color(0xFFFFCC00), // iOS yellow
      const Color(0xFF4CD964), // iOS green alternative
    ];

    // Utiliser la palette de couleurs iOS-like de manière cyclique
    return colorPalette[index % colorPalette.length];
  }

  // Méthode pour formater l'adresse du wallet
  String _formatWalletAddress(String address) {
    if (address == 'unknown') return S.of(context).unknown;
    if (address.length <= 8) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
