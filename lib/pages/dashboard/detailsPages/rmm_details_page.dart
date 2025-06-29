import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/text_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class RmmWalletDetailsPage extends StatelessWidget {
  const RmmWalletDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final List<Map<String, dynamic>> walletDetails =
        dataManager.perWalletBalances;

    // Séparer les wallets avec utilisation de ceux sans utilisation
    final List<Map<String, dynamic>> walletsWithUsage =
        walletDetails.where((wallet) {
      final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
      final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      return !(usdcDeposit == 0 &&
          xdaiDeposit == 0 &&
          usdcBorrow == 0 &&
          xdaiBorrow == 0);
    }).toList();

    final List<Map<String, dynamic>> walletsNoUsage =
        walletDetails.where((wallet) {
      final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
      final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      return (usdcDeposit == 0 &&
          xdaiDeposit == 0 &&
          usdcBorrow == 0 &&
          xdaiBorrow == 0);
    }).toList();

    // Trier les wallets avec utilisation par HealthFactor croissant
    walletsWithUsage.sort((a, b) {
      final double aUsdcBorrow = a['usdcBorrow'] as double? ?? 0;
      final double aXdaiBorrow = a['xdaiBorrow'] as double? ?? 0;
      final double bUsdcBorrow = b['usdcBorrow'] as double? ?? 0;
      final double bXdaiBorrow = b['xdaiBorrow'] as double? ?? 0;
      final double aBorrowSum = aUsdcBorrow + aXdaiBorrow;
      final double bBorrowSum = bUsdcBorrow + bXdaiBorrow;

      final double aRmm = dataManager.perWalletRmmValues[a['address']] ?? 0;
      final double bRmm = dataManager.perWalletRmmValues[b['address']] ?? 0;

      // Calcul du HealthFactor (HF)
      final double aHF = aBorrowSum > 0 ? (aRmm * 0.7 / aBorrowSum) : 10;
      final double bHF = bBorrowSum > 0 ? (bRmm * 0.7 / bBorrowSum) : 10;

      return aHF.compareTo(bHF);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          S.of(context).rmmDetails,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: walletsWithUsage.isEmpty && walletsNoUsage.isEmpty
          ? Center(
              child: Text(
                S.of(context).noDataAvailable,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: index < walletsWithUsage.length
                            ? _WalletDetailCard(
                                wallet: walletsWithUsage[index],
                                currencyUtils: currencyUtils)
                            : _NoUsageWalletsCard(
                                noUsageWallets: walletsNoUsage),
                      ),
                      childCount: walletsWithUsage.length +
                          (walletsNoUsage.isNotEmpty ? 1 : 0),
                    ),
                  ),
                ),
                // Espace en bas pour éviter que le dernier élément ne soit caché par la barre de navigation
                const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
              ],
            ),
    );
  }
}

class _WalletDetailCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  final CurrencyProvider currencyUtils;

  const _WalletDetailCard({required this.wallet, required this.currencyUtils});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    // Récupération des informations du wallet
    final String address = wallet['address'];
    final double usdcDeposit = wallet['usdcDeposit'] as double? ?? 0;
    final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
    final double xdaiDeposit = wallet['xdaiDeposit'] as double? ?? 0;
    final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;

    // Récupération de la valeur RMM propre à ce wallet
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final double walletRmmValue = dataManager.perWalletRmmValues[address] ?? 0;

    // Calcul du Health Factor (HF) et du LTV
    final double walletBorrowSum = usdcBorrow + xdaiBorrow;
    final double walletHF =
        walletBorrowSum > 0 ? (walletRmmValue * 0.7 / walletBorrowSum) : 10;
    final double walletLTV =
        walletRmmValue > 0 ? (walletBorrowSum / walletRmmValue * 100) : 0;

    // Couleurs pour les health factors
    final Color hfColor = walletHF < 1.5
        ? Colors.red
        : walletHF < 3
            ? Colors.orange
            : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      TextUtils.truncateWallet(address),
                      style: TextStyle(
                        fontSize: 15 +
                            Provider.of<AppState>(context, listen: false)
                                .getTextSizeOffset(),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne de gauche avec les informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        S.of(context).deposits,
                        [
                          _buildInfoItem(
                            "XDAI",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(xdaiDeposit),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            "USDC",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(usdcDeposit),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                        ],
                        context,
                        appState,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        S.of(context).loans,
                        [
                          _buildInfoItem(
                            "USDC",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(usdcBorrow),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            "XDAI",
                            currencyUtils.getFormattedAmount(
                              currencyUtils.convert(xdaiBorrow),
                              currencyUtils.currencySymbol,
                              true,
                            ),
                            context,
                            appState,
                            valueColor: Colors.red.shade700,
                          ),
                        ],
                        context,
                        appState,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        S.of(context).rmmValue,
                        currencyUtils.getFormattedAmount(
                          currencyUtils.convert(walletRmmValue),
                          currencyUtils.currencySymbol,
                          true,
                        ),
                        context,
                        appState,
                        isBold: true,
                        textSize: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Colonne de droite avec les jauges
                _buildVerticalGauges(walletHF, walletLTV, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children,
      BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, BuildContext context, AppState appState,
      {bool isBold = false, Color? valueColor, double textSize = 14}) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: textSize + appState.getTextSizeOffset(),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: (textSize - 2) + appState.getTextSizeOffset(),
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalGauges(double hf, double ltv, BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    // Limiter et calculer les valeurs pour l'affichage
    double progressHF = (hf / 5).clamp(0.0, 1.0);
    double progressLTV = (ltv / 100).clamp(0.0, 1.0);
    double ltvPercent = progressLTV * 100;

    // Définition des couleurs pour la jauge HF en fonction du facteur
    Color getHFColor(double hfValue) {
      if (hfValue <= 1.1) {
        return Color(
            0xFFFF3B30); // Rouge pour valeurs dangereuses (HF proche de 1)
      } else if (hfValue <= 1.5) {
        return Color(0xFFFF9500); // Orange pour valeurs à risque modéré
      } else if (hfValue <= 2.5) {
        return Color(0xFFFFCC00); // Jaune pour valeurs moyennes
      } else {
        return Color(0xFF34C759); // Vert pour valeurs sûres
      }
    }

    // Fonction pour déterminer la couleur de la jauge LTV en fonction de sa valeur
    Color getLTVColor(double ltvPercent) {
      if (ltvPercent >= 65) {
        return Color(
            0xFFFF3B30); // Rouge pour valeurs dangereuses (LTV proche de 70%)
      } else if (ltvPercent >= 55) {
        return Color(0xFFFF9500); // Orange pour valeurs à risque modéré
      } else if (ltvPercent >= 40) {
        return Color(0xFFFFCC00); // Jaune pour valeurs moyennes
      } else {
        return Color(0xFF34C759); // Vert pour valeurs sûres
      }
    }

    // Couleur de la jauge HF basée sur la valeur réelle
    final Color hfGaugeColor = getHFColor(hf);
    final Color ltvGaugeColor = getLTVColor(ltvPercent);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryHeaderColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Jauge Health Factor (HF)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HF',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 2),
              Stack(
                children: [
                  // Fond de la jauge
                  Container(
                    height: 120,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Niveau de la jauge
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: progressHF * 120,
                      width: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: progressHF > 0.95
                              ? Radius.circular(12)
                              : Radius.zero,
                          topRight: progressHF > 0.95
                              ? Radius.circular(12)
                              : Radius.zero,
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        color: hfGaugeColor,
                      ),
                    ),
                  ),
                  // Marqueurs de niveau
                  for (int i = 0; i < 5; i++)
                    Positioned(
                      bottom: i * 24.0,
                      left: 0,
                      child: Container(
                        height: 1,
                        width: 20,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hfGaugeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hf.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hfGaugeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 40),
          // Jauge LTV
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LTV',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 2),
              Stack(
                children: [
                  // Fond de la jauge
                  Container(
                    height: 120,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Niveau de la jauge
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: progressLTV * 120,
                      width: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: progressLTV > 0.95
                              ? Radius.circular(12)
                              : Radius.zero,
                          topRight: progressLTV > 0.95
                              ? Radius.circular(12)
                              : Radius.zero,
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        color: ltvGaugeColor,
                      ),
                    ),
                  ),
                  // Marqueurs de niveau
                  for (int i = 0; i < 5; i++)
                    Positioned(
                      bottom: i * 24.0,
                      left: 0,
                      child: Container(
                        height: 1,
                        width: 20,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ltvGaugeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${ltvPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ltvGaugeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoUsageWalletsCard extends StatelessWidget {
  final List<Map<String, dynamic>> noUsageWallets;
  const _NoUsageWalletsCard({required this.noUsageWallets});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Récupérer les adresses complètes sans tronquage, chaque adresse sur une nouvelle ligne
    final List<String> addresses = noUsageWallets
        .map((wallet) =>
            TextUtils.truncateWallet(wallet['address']) as String? ??
            S.of(context).unknown)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context).walletsWithoutRmmUsage,
                  style: TextStyle(
                    fontSize: 16 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: addresses
                    .map((address) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appState.showAmounts
                                    ? address
                                    : TextUtils.truncateWallet(address),
                                style: TextStyle(
                                  fontSize: 14 +
                                      Provider.of<AppState>(context,
                                              listen: false)
                                          .getTextSizeOffset(),
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
