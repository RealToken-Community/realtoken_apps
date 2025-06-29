import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:flutter/services.dart'; // Pour Clipboard
import 'dart:ui'; // Pour les effets de flou

class PortfolioDetailsPage extends StatelessWidget {
  const PortfolioDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Récupérer les données par wallet depuis la nouvelle structure
    final List<Map<String, dynamic>> walletDetails = dataManager.walletStats;
    final List<Map<String, dynamic>> perWalletBalances = dataManager.perWalletBalances;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          S.of(context).portfolio,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: walletDetails.isEmpty
          ? Center(
              child: Text(
                S.of(context).noDataAvailable,
                style: theme.textTheme.bodyLarge,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(), // Style iOS de défilement
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  sliver: SliverToBoxAdapter(
                    child: _buildGlobalInfo(context, dataManager, appState, currencyUtils),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildWalletCard(context, walletDetails[index], dataManager, appState, currencyUtils),
                      ),
                      childCount: walletDetails.length,
                    ),
                  ),
                ),
                // Espace en bas pour éviter que le dernier élément ne soit caché par la barre de navigation
                const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
              ],
            ),
    );
  }

  Widget _buildGlobalInfo(BuildContext context, DataManager dataManager, AppState appState, CurrencyProvider currencyUtils) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.9),
            theme.primaryColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.2, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).portfolioGlobal,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                S.of(context).totalPortfolio,
                                currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.totalWalletValue), currencyUtils.currencySymbol, true),
                                context,
                                appState,
                                isWhite: true,
                                isBold: true,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                S.of(context).wallet,
                                currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.walletValue), currencyUtils.currencySymbol, true),
                                context,
                                appState,
                                isWhite: true,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                S.of(context).rmm,
                                currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.rmmValue), currencyUtils.currencySymbol, true),
                                context,
                                appState,
                                isWhite: true,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                S.of(context).depositBalance,
                                currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.totalUsdcDepositBalance + dataManager.totalXdaiDepositBalance), currencyUtils.currencySymbol, true),
                                context,
                                appState,
                                isWhite: true,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                S.of(context).borrowBalance,
                                currencyUtils.getFormattedAmount(currencyUtils.convert(dataManager.totalUsdcBorrowBalance + dataManager.totalXdaiBorrowBalance), currencyUtils.currencySymbol, true),
                                context,
                                appState,
                                isWhite: true,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                S.of(context).netApy,
                                "${dataManager.netGlobalApy.toStringAsFixed(2)}%",
                                context,
                                appState,
                                isWhite: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(height: 1, color: Colors.white38),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoWithIcon(
                            S.of(context).tokens,
                            dataManager.totalRealtTokens.toStringAsFixed(2),
                            Icons.token_outlined,
                            context,
                            appState,
                            isWhite: true,
                          ),
                          _buildInfoWithIcon(
                            S.of(context).properties,
                            dataManager.totalTokenCount.toString(),
                            Icons.home_outlined,
                            context,
                            appState,
                            isWhite: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Map<String, dynamic> wallet, DataManager dataManager, AppState appState, CurrencyProvider currencyUtils) {
    final theme = Theme.of(context);

    final String address = wallet['address'] as String;
    final double walletValue = wallet['walletValueSum'] as double? ?? 0;
    final double rmmValue = wallet['rmmValue'] as double? ?? 0;
    final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
    final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
    final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
    final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;

    // Récupérer les statistiques supplémentaires sur les tokens
    final int tokenCount = wallet['tokenCount'] as int? ?? 0;
    final double walletTokensSum = wallet['walletTokensSum'] as double? ?? 0;
    final double rmmTokensSum = wallet['rmmTokensSum'] as double? ?? 0;

    // Calculer le total pour ce wallet
    final double totalWalletValue = walletValue + rmmValue + usdcDeposit + xdaiDeposit - usdcBorrow - xdaiBorrow;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _truncateWallet(address),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: theme.brightness == Brightness.light ? Colors.grey : Colors.grey.shade400),
                  onPressed: () {
                    _copyToClipboard(context, address);
                  },
                  tooltip: S.of(context).copyAddress,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.light ? Colors.grey.withOpacity(0.1) : Colors.grey.shade800.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.grey.shade50 : theme.cardColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.light ? Colors.grey.shade200 : theme.dividerColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.02) : Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    S.of(context).totalValue,
                    currencyUtils.getFormattedAmount(currencyUtils.convert(totalWalletValue), currencyUtils.currencySymbol, true),
                    context,
                    appState,
                    isBold: true,
                    textSize: 18,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoWithIcon(
                        S.of(context).wallet,
                        currencyUtils.getFormattedAmount(currencyUtils.convert(walletValue), currencyUtils.currencySymbol, true),
                        Icons.account_balance_wallet,
                        context,
                        appState,
                      ),
                      _buildInfoWithIcon(
                        S.of(context).rmm,
                        currencyUtils.getFormattedAmount(currencyUtils.convert(rmmValue), currencyUtils.currencySymbol, true),
                        Icons.pie_chart_outline,
                        context,
                        appState,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Section statistiques de tokens
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.grey.shade50 : theme.cardColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.light ? Colors.grey.shade200 : theme.dividerColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.02) : Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Statistiques des Tokens",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Statistiques des tokens
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            "Properties",
                            tokenCount.toString(),
                            context,
                            appState,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            "Total Tokens",
                            (walletTokensSum + rmmTokensSum).toStringAsFixed(2),
                            context,
                            appState,
                          ),
                        ],
                      ),
                      // Statistiques par type de token
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            "Wallet Tokens",
                            walletTokensSum.toStringAsFixed(2),
                            context,
                            appState,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            "RMM Tokens",
                            rmmTokensSum.toStringAsFixed(2),
                            context,
                            appState,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Section soldes dépôt/emprunt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.grey.shade50 : theme.cardColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.light ? Colors.grey.shade200 : theme.dividerColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.02) : Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Soldes de Dépôt et Emprunt",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            "USDC Dépôt",
                            currencyUtils.getFormattedAmount(currencyUtils.convert(usdcDeposit), currencyUtils.currencySymbol, true),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            "XDAI Dépôt",
                            currencyUtils.getFormattedAmount(currencyUtils.convert(xdaiDeposit), currencyUtils.currencySymbol, true),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            "USDC Emprunt",
                            currencyUtils.getFormattedAmount(currencyUtils.convert(usdcBorrow), currencyUtils.currencySymbol, true),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            "XDAI Emprunt",
                            currencyUtils.getFormattedAmount(currencyUtils.convert(xdaiBorrow), currencyUtils.currencySymbol, true),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour tronquer l'adresse du wallet
  String _truncateWallet(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Méthode pour copier dans le presse-papier
  void _copyToClipboard(BuildContext context, String text) {
    final theme = Theme.of(context);

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.of(context).addressCopied,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context, AppState appState, {bool isBold = false, bool isWhite = false, Color? valueColor, double textSize = 14}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: textSize + appState.getTextSizeOffset(),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? (isWhite ? Colors.white : theme.textTheme.bodyLarge?.color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: (textSize - 2) + appState.getTextSizeOffset(),
            color: isWhite ? Colors.white70 : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoWithIcon(String label, String value, IconData icon, BuildContext context, AppState appState, {bool isWhite = false}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isWhite ? Colors.white24 : theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isWhite ? Colors.white : theme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isWhite ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isWhite ? Colors.white70 : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
