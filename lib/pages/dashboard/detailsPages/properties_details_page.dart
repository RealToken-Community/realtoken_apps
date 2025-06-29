import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_chart.dart';
import 'package:flutter/services.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
// Nouvelle bibliothèque pour graphiques

class PropertiesDetailsPage extends StatelessWidget {
  const PropertiesDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          S.of(context).properties,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + appState.getTextSizeOffset(),
          ),
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: dataManager.portfolio.isEmpty
          ? Center(
              child: Text(
                S.of(context).noDataAvailableDot,
                style: TextStyle(
                  fontSize: 17 + appState.getTextSizeOffset(),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                            context, S.of(context).overview, appState),
                        const SizedBox(height: 12),
                        _buildOverviewCards(context, dataManager, appState),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                            context, S.of(context).occupancyRate, appState),
                        const SizedBox(height: 12),
                        _buildOccupancyChart(context, dataManager, appState),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                            context, S.of(context).tokenDistribution, appState),
                        const SizedBox(height: 12),
                        _buildTokenDistribution(context, dataManager),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                            context, S.of(context).wallets, appState),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final walletDetails =
                          _getSortedWalletDetails(dataManager);
                      if (walletDetails.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              S.of(context).noWalletsAvailable,
                              style: TextStyle(
                                fontSize: 16 + appState.getTextSizeOffset(),
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _buildWalletCard(
                            context, walletDetails[index], appState),
                      );
                    },
                    childCount: _getSortedWalletDetails(dataManager).isEmpty
                        ? 1
                        : _getSortedWalletDetails(dataManager).length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _getSortedWalletDetails(DataManager dataManager) {
    final List<Map<String, dynamic>> walletDetails = dataManager.walletStats;
    final List<Map<String, dynamic>> perWalletBalances =
        dataManager.perWalletBalances;

    // Associer les informations d'emprunt et de dépôt à chaque wallet
    for (var wallet in walletDetails) {
      final String address = wallet['address'] as String;
      final matchingBalance = perWalletBalances.firstWhere(
        (balance) => balance['address'] == address,
        orElse: () => <String, dynamic>{},
      );

      wallet['usdcDeposit'] = matchingBalance['usdcDeposit'] ?? 0.0;
      wallet['xdaiDeposit'] = matchingBalance['xdaiDeposit'] ?? 0.0;
      wallet['usdcBorrow'] = matchingBalance['usdcBorrow'] ?? 0.0;
      wallet['xdaiBorrow'] = matchingBalance['xdaiBorrow'] ?? 0.0;
    }

    // Trier par valeur totale
    walletDetails.sort((a, b) {
      final double aWalletValue = a['walletValueSum'] as double? ?? 0;
      final double aRmmValue = a['rmmValue'] as double? ?? 0;
      final double aTotalValue = aWalletValue + aRmmValue;

      final double bWalletValue = b['walletValueSum'] as double? ?? 0;
      final double bRmmValue = b['rmmValue'] as double? ?? 0;
      final double bTotalValue = bWalletValue + bRmmValue;

      return bTotalValue.compareTo(aTotalValue); // Tri décroissant
    });

    return walletDetails;
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 20 + appState.getTextSizeOffset(),
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildOverviewCards(
      BuildContext context, DataManager dataManager, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            context,
            S.of(context).properties,
            dataManager.portfolio.length.toString(),
            Icons.home_outlined,
            cardColor,
            appState,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            context,
            S.of(context).tokens,
            dataManager.totalRealtTokens.toString(),
            Icons.token_outlined,
            cardColor,
            appState,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color cardColor,
    AppState appState,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart(
      BuildContext context, DataManager dataManager, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final double rentedPercentage =
        (dataManager.rentedUnits / dataManager.totalUnits) * 100;

    // Déterminer la couleur en fonction du pourcentage
    Color progressColor;
    if (rentedPercentage < 50) {
      progressColor = Colors.redAccent;
    } else if (rentedPercentage < 80) {
      progressColor = Colors.orangeAccent;
    } else {
      progressColor = Colors.greenAccent;
    }

    // Déterminer le statut
    String status;
    if (rentedPercentage < 50) {
      status = S.of(context).occupancyStatusLow;
    } else if (rentedPercentage < 80) {
      status = S.of(context).occupancyStatusMedium;
    } else {
      status = S.of(context).occupancyStatusHigh;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rentedPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 28 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    S.of(context).rentedUnits(
                        dataManager.rentedUnits.toString(),
                        dataManager.totalUnits.toString()),
                    style: TextStyle(
                      fontSize: 14 + appState.getTextSizeOffset(),
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: rentedPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor.withValues(alpha: 0.7),
                          progressColor
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDistribution(
      BuildContext context, DataManager dataManager) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 300,
      child: TokenDistributionCard(dataManager: dataManager),
    );
  }

  Widget _buildWalletCard(
      BuildContext context, Map<String, dynamic> wallet, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final String address = wallet['address'] as String;
    final int tokenCount = wallet['tokenCount'] as int? ?? 0;
    final double walletTokensSum = wallet['walletTokensSum'] as double? ?? 0;
    final double rmmTokensSum = wallet['rmmTokensSum'] as double? ?? 0;
    final double totalTokens = walletTokensSum + rmmTokensSum;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.creditcard,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _truncateWallet(address),
                    style: TextStyle(
                      fontSize: 16 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(context, address),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_on_doc,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWalletStat(context, S.of(context).properties,
                        tokenCount.toString(), appState),
                    _buildWalletStat(context, 'Wallet',
                        walletTokensSum.toStringAsFixed(2), appState),
                    _buildWalletStat(context, 'RMM',
                        rmmTokensSum.toStringAsFixed(2), appState),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).totalTokensLabel,
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      totalTokens.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(
      BuildContext context, String label, String value, AppState appState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13 + appState.getTextSizeOffset(),
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  String _truncateWallet(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Afficher une notification iOS style
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(S.of(context).copied),
        message: Text(S.of(context).addressCopiedMessage),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }
}
