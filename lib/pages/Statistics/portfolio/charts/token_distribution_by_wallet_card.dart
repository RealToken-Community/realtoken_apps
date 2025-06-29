import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/common_functions.dart';

class TokenDistributionByWalletCard extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByWalletCard({super.key, required this.dataManager});

  @override
  _TokenDistributionByWalletCardState createState() =>
      _TokenDistributionByWalletCardState();
}

class _TokenDistributionByWalletCardState
    extends State<TokenDistributionByWalletCard> {
  int? _selectedIndexWallet;
  final ValueNotifier<int?> _selectedIndexNotifierWallet =
      ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
            Text(
              S.of(context).tokenDistributionByWallet,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifierWallet,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartDataByWallet(
                              widget.dataManager, selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifierWallet.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifierWallet.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 300),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      _buildCenterTextByWallet(
                          widget.dataManager, selectedIndex),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildLegendByWallet(widget.dataManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartDataByWallet(
      DataManager dataManager, int? selectedIndex) {
    final appState = Provider.of<AppState>(context);

    // Créer une Map qui compte les tokens par wallet
    Map<String, int> walletTokenCounts = {};

    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? S.of(context).unknown;
      // Utiliser une version abrégée de l'adresse pour l'affichage
      String walletDisplayName = _formatWalletAddress(walletAddress);

      walletTokenCounts[walletDisplayName] =
          (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }

    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens =
        walletTokenCounts.values.fold(0, (sum, count) => sum + count);

    // Trier les wallets par nombre de tokens (décroissant)
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));

    // Créer les sections du graphique à secteurs
    return sortedWallets.asMap().entries.map((entry) {
      final index = entry.key;
      final wallet = entry.value;
      final int value = walletTokenCounts[wallet]!;
      final double percentage = (value / totalWalletTokens) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      // Générer une couleur basée sur l'index
      final Color baseColor = generateColor(index);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withValues(alpha: opacity),
        radius: isSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isSelected
              ? 14 + appState.getTextSizeOffset()
              : 10 + appState.getTextSizeOffset(),
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
    }).toList();
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

  Widget _buildCenterTextByWallet(DataManager dataManager, int? selectedIndex) {
    Map<String, int> walletTokenCounts = {};

    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? S.of(context).unknown;
      String walletDisplayName = _formatWalletAddress(walletAddress);

      walletTokenCounts[walletDisplayName] =
          (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }

    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens =
        walletTokenCounts.values.fold(0, (sum, count) => sum + count);

    if (selectedIndex == null) {
      // Afficher la valeur totale si aucun segment n'est sélectionné
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
            totalWalletTokens.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Afficher les détails du segment sélectionné
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));

    if (selectedIndex >= sortedWallets.length) return Container();

    final selectedWallet = sortedWallets[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedWallet,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: generateColor(selectedIndex),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          walletTokenCounts[selectedWallet].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendByWallet(DataManager dataManager) {
    final appState = Provider.of<AppState>(context);

    // Créer une Map qui compte les tokens par wallet
    Map<String, int> walletTokenCounts = {};

    // Analyser les walletTokens pour compter les tokens dans chaque wallet
    for (var token in dataManager.walletTokens) {
      String walletAddress = token['wallet'] ?? S.of(context).unknown;
      String walletDisplayName = _formatWalletAddress(walletAddress);

      walletTokenCounts[walletDisplayName] =
          (walletTokenCounts[walletDisplayName] ?? 0) + 1;
    }

    // Calculer la somme totale des tokens dans tous les wallets
    int totalWalletTokens =
        walletTokenCounts.values.fold(0, (sum, count) => sum + count);

    // Trier les wallets par nombre de tokens (décroissant)
    final sortedWallets = walletTokenCounts.keys.toList()
      ..sort((a, b) => walletTokenCounts[b]!.compareTo(walletTokenCounts[a]!));

    return Wrap(
      spacing: 12.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedWallets.asMap().entries.map((entry) {
        final index = entry.key;
        final wallet = entry.value;
        final color = generateColor(index);
        final count = walletTokenCounts[wallet];
        final percentage = (count! / totalWalletTokens) * 100;

        return InkWell(
          onTap: () {
            _selectedIndexNotifierWallet.value =
                (_selectedIndexNotifierWallet.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifierWallet.value == index
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifierWallet.value == index
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
                Flexible(
                  child: Text(
                    '$wallet (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: _selectedIndexNotifierWallet.value == index
                          ? color
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _selectedIndexNotifierWallet.value == index
                          ? FontWeight.w600
                          : FontWeight.normal,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Formater l'adresse du wallet pour l'affichage (ex: 0x1234...5678)
  String _formatWalletAddress(String address) {
    if (address.length <= 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }
}
