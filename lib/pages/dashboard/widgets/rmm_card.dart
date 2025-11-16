import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/widget_factory.dart';
import 'package:realtoken_asset_tracker/pages/dashboard/detailsPages/rmm_details_page.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';

class RmmCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RmmCard({Key? key, required this.showAmounts, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    // Récupérer la liste des wallets depuis perWalletBalances
    final List<Map<String, dynamic>> walletDetails = dataManager.perWalletBalances;

    // Calcul des montants globaux (somme de tous les wallets)
    double totalUsdcDeposit = 0;
    double totalXdaiDeposit = 0;
    double totalUsdcBorrow = 0;
    double totalXdaiBorrow = 0;

    for (var wallet in walletDetails) {
      totalUsdcDeposit += wallet['usdcDeposit'] as double? ?? 0;
      totalXdaiDeposit += wallet['xdaiDeposit'] as double? ?? 0;
      totalUsdcBorrow += wallet['usdcBorrow'] as double? ?? 0;
      totalXdaiBorrow += wallet['xdaiBorrow'] as double? ?? 0;
    }

    // Calcul des montants totaux
    final double totalDeposits = totalUsdcDeposit + totalXdaiDeposit;
    final double totalBorrows = totalUsdcBorrow + totalXdaiBorrow;

// Sélection du wallet ayant le HF le plus bas, basé sur walletRmmValue
    Map<String, dynamic>? walletWithLowestHF;
    double lowestHF = double.infinity;

    for (var wallet in walletDetails) {
      final String address = wallet['address'] ?? '';
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      final double totalBorrow = usdcBorrow + xdaiBorrow;

      // Utilise la même valeur RMM que dans l'autre page
      final double walletRmmValue = dataManager.perWalletRmmValues[address] ?? 0;

      // Calcul du Health Factor basé sur walletRmmValue
      final double hf = totalBorrow > 0 ? (walletRmmValue * 0.7) / totalBorrow : double.infinity;

      if (hf < lowestHF) {
        lowestHF = hf;
        walletWithLowestHF = wallet;
      }
    }

// Récupération des valeurs du wallet avec le HF le plus bas pour l'affichage des jauges
    final String selectedAddress = walletWithLowestHF?['address'] ?? '';
    final double worstWalletUsdcBorrow = walletWithLowestHF?['usdcBorrow'] as double? ?? 0;
    final double worstWalletXdaiBorrow = walletWithLowestHF?['xdaiBorrow'] as double? ?? 0;
    final double worstWalletBorrow = worstWalletUsdcBorrow + worstWalletXdaiBorrow;

// Récupération correcte du walletRmmValue pour le wallet avec le HF le plus bas
    final double worstWalletRmmValue = dataManager.perWalletRmmValues[selectedAddress] ?? 0;

// Récupération des taux APY
    final double usdcDepositApy = dataManager.usdcDepositApy ?? 0.0;
    final double xdaiDepositApy = dataManager.xdaiDepositApy ?? 0.0;
    final double usdcBorrowApy = dataManager.usdcBorrowApy ?? 0.0;
    final double xdaiBorrowApy = dataManager.xdaiBorrowApy ?? 0.0;

// Calcul final du Health Factor et du LTV pour le wallet le plus défavorable
    double healthFactor = worstWalletBorrow > 0 ? (worstWalletRmmValue * 0.7) / worstWalletBorrow : double.infinity;
    double currentLTV = worstWalletRmmValue > 0 ? (worstWalletBorrow / worstWalletRmmValue * 100) : 0;

// Gestion des cas particuliers pour l'affichage
    if (healthFactor.isInfinite || healthFactor.isNaN || worstWalletBorrow == 0) {
      healthFactor = 5.0; // Valeur par défaut pour un HF sûr
    }

    currentLTV = currentLTV.clamp(0.0, 100.0);

    return UIUtils.buildCard(
      S.of(context).rmm,
      Icons.account_balance_rounded,
      _buildLiquidationIndicator(
        context,
        worstWalletRmmValue,
        worstWalletUsdcBorrow,
        worstWalletXdaiBorrow,
        dataManager.usdcBorrowApy ?? 0.0,
        dataManager.xdaiBorrowApy ?? 0.0,
        isLoading,
      ),
      [
        const SizedBox(height: 4),

        // Section Dépôts avec titre
                  WidgetFactory.buildSectionHeader(context, S.of(context).depositBalance),

        _buildBalanceRowWithIcon(
          context,
          currencyUtils.getFormattedAmount(currencyUtils.convert(totalXdaiDeposit), currencyUtils.currencySymbol, showAmounts),
          S.of(context).depositBalance,
          'xdai', // Type pour l'icône
          xdaiDepositApy,
          isLoading,
          currencyUtils,
        ),

        _buildBalanceRowWithIcon(
          context,
          currencyUtils.getFormattedAmount(currencyUtils.convert(totalUsdcDeposit), currencyUtils.currencySymbol, showAmounts),
          S.of(context).depositBalance,
          'usdc', // Type pour l'icône
          usdcDepositApy,
          isLoading,
          currencyUtils,
        ),

        const SizedBox(height: 6),

        // Section Emprunts avec titre
                  WidgetFactory.buildSectionHeader(context, S.of(context).borrowBalance),

        _buildBalanceRowWithIcon(
          context,
          currencyUtils.getFormattedAmount(currencyUtils.convert(totalUsdcBorrow), currencyUtils.currencySymbol, showAmounts),
          S.of(context).borrowBalance,
          'usdc', // Type pour l'icône
          usdcBorrowApy,
          isLoading,
          currencyUtils,
        ),

        _buildBalanceRowWithIcon(
          context,
          currencyUtils.getFormattedAmount(currencyUtils.convert(totalXdaiBorrow), currencyUtils.currencySymbol, showAmounts),
          S.of(context).borrowBalance,
          'xdai', // Type pour l'icône
          xdaiBorrowApy,
          isLoading,
          currencyUtils,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      // Flèche de navigation dans l'en-tête
      headerRightWidget: Container(
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
                color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RmmWalletDetailsPage(),
                ),
              );
            },
          ),
        ),
      ),
      // Affichage des jauges uniquement à droite
      rightWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              double factor = healthFactor;
              factor = factor.isNaN || factor < 0 ? 0 : factor.clamp(0.0, 5.0);
              return _buildVerticalGauges(factor, worstWalletRmmValue, worstWalletBorrow, context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRowWithIcon(
    BuildContext context,
    String amount,
    String balanceType,
    String tokenType,
    double apy,
    bool isLoading,
    CurrencyProvider currencyUtils,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          // Ajouter un padding à gauche pour créer l'indentation
          SizedBox(width: 8),

          // Icône du token avec fond coloré
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokenType.toLowerCase() == 'usdc' ? Color(0xFF2775CA).withOpacity(0.15) : Color(0xFFEDB047).withOpacity(0.15),
            ),
            child: Center(
              child: Image.asset(
                tokenType.toLowerCase() == 'usdc' ? 'assets/icons/usdc.png' : 'assets/icons/xdai.png',
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Version simplifiée: montant + APY
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Montant
                isLoading
                    ? ShimmerUtils.originalColorShimmer(
                        child: Text(
                          amount,
                          style: TextStyle(
                            fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        color: theme.textTheme.bodyLarge?.color,
                      )
                    : Text(
                        amount,
                        style: TextStyle(
                          fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),

                // APY juste à côté du montant
                SizedBox(width: 8),
                isLoading
                    ? ShimmerUtils.originalColorShimmer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (apy >= 0 ? Color(0xFF34C759) : Color(0xFFFF3B30)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${apy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: apy >= 0 ? Color(0xFF34C759) : Color(0xFFFF3B30),
                              fontWeight: FontWeight.w500,
                              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        color: apy >= 0 ? Color(0xFF34C759) : Color(0xFFFF3B30),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (apy >= 0 ? Color(0xFF34C759) : Color(0xFFFF3B30)).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${apy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: apy >= 0 ? Color(0xFF34C759) : Color(0xFFFF3B30),
                            fontWeight: FontWeight.w500,
                            fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                            letterSpacing: -0.3,
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

  Widget _buildVerticalGauges(double factor, double walletDeposit, double walletBorrow, BuildContext context) {
    // Obtenir le wallet avec le HF le plus bas depuis le contexte
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final theme = Theme.of(context);
    final walletDetails = dataManager.perWalletBalances;

    // Retrouver l'adresse du wallet utilisé pour HF et LTV
    String walletAddress = "";
    double lowestHF = double.infinity;

    for (var wallet in walletDetails) {
      final address = wallet['address'] ?? '';
      final usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      final totalBorrow = usdcBorrow + xdaiBorrow;

      final walletRmmValue = dataManager.perWalletRmmValues[address] ?? 0;

      final hf = totalBorrow > 0 ? (walletRmmValue * 0.7) / totalBorrow : double.infinity;

      if (hf < lowestHF) {
        lowestHF = hf;
        walletAddress = address;
      }
    }

    // Adresse abrégée pour affichage (6 premiers et 4 derniers caractères)
    String shortAddress = walletAddress.length > 10 ? "${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}" : walletAddress;

    double progressHF = (factor / 5).clamp(0.0, 1.0);
    double progressLTV = walletDeposit > 0 ? ((walletBorrow / walletDeposit * 100).clamp(0.0, 100.0)) / 100 : 0;

    // Définition des couleurs pour la jauge HF en fonction du facteur
    Color getHFColor(double hfValue) {
      if (hfValue <= 1.1) {
        return Color(0xFFFF3B30); // Rouge pour valeurs dangereuses (HF proche de 1)
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
        return Color(0xFFFF3B30); // Rouge pour valeurs dangereuses (LTV proche de 70%)
      } else if (ltvPercent >= 55) {
        return Color(0xFFFF9500); // Orange pour valeurs à risque modéré
      } else if (ltvPercent >= 40) {
        return Color(0xFFFFCC00); // Jaune pour valeurs moyennes
      } else {
        return Color(0xFF34C759); // Vert pour valeurs sûres
      }
    }

    // Couleur de la jauge HF basée sur la valeur réelle
    final Color hfGaugeColor = getHFColor(factor);

    // Calculer la valeur LTV en pourcentage et déterminer sa couleur
    final double ltvPercent = progressLTV * 100;
    final Color ltvGaugeColor = getLTVColor(ltvPercent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Jauge Health Factor (HF)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HF',
                    style: TextStyle(
                      fontSize: 15 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 90,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: progressHF * 80,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: progressHF > 0.95 ? Radius.circular(13) : Radius.zero,
                                topRight: progressHF > 0.95 ? Radius.circular(13) : Radius.zero,
                                bottomLeft: Radius.circular(13),
                                bottomRight: Radius.circular(13),
                              ),
                              color: hfGaugeColor,
                            ),
                          ),
                        ),
                        // Ligne de seuil critique pour HF à 1
                        Positioned(
                          bottom: (1 / 5) * 80, // La position 1 sur l'échelle 0-5
                          left: -2,
                          right: -2,
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF3B30), // Rouge pour la ligne critique
                              borderRadius: BorderRadius.circular(1),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFF3B30).withOpacity(0.5),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hfGaugeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (progressHF * 5).toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: hfGaugeColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Jauge LTV
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LTV',
                    style: TextStyle(
                      fontSize: 15 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 90,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                    ),
                    child: Stack(
                      children: [
                        // Ligne de seuil critique pour LTV à 70%
                        Positioned(
                          bottom: 0.7 * 80, // 70% de la hauteur
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF3B30), // Rouge pour la ligne critique
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: progressLTV * 80,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: progressLTV > 0.95 ? Radius.circular(13) : Radius.zero,
                                topRight: progressLTV > 0.95 ? Radius.circular(13) : Radius.zero,
                                bottomLeft: Radius.circular(13),
                                bottomRight: Radius.circular(13),
                              ),
                              color: ltvGaugeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ltvGaugeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(progressLTV * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                        color: ltvGaugeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Affichage de l'adresse du wallet pris en compte
        if (shortAddress.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shortAddress,
                style: TextStyle(
                  fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  letterSpacing: -0.3,
                  color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  // Nouvel indicateur visuel pour le temps avant liquidation
  Widget _buildLiquidationIndicator(
    BuildContext context,
    double walletRmmValue,
    double usdcBorrow,
    double xdaiBorrow,
    double usdcBorrowApy,
    double xdaiBorrowApy,
    bool isLoading,
  ) {
    final theme = Theme.of(context);

    if (isLoading) {
      return ShimmerUtils.originalColorShimmer(
        child: Text(
          "${S.of(context).timeBeforeLiquidation}",
          style: TextStyle(
            fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
            letterSpacing: -0.3,
          ),
        ),
        color: theme.textTheme.bodyMedium?.color,
      );
    }

    final String timeStatus = _calculateTimeBeforeLiquidationStatus(
      walletRmmValue,
      usdcBorrow,
      xdaiBorrow,
      usdcBorrowApy,
      xdaiBorrowApy,
    );

    // Calculer le temps réel pour l'affichage
    final String realTime = _calculateRealTimeBeforeLiquidation(
      context,
      walletRmmValue,
      usdcBorrow,
      xdaiBorrow,
      usdcBorrowApy,
      xdaiBorrowApy,
    );

    // Configurer l'indicateur visuel avec l'icône et couleur appropriées
    IconData iconData;
    Color iconColor;
    Color bgColor;

    if (timeStatus == "danger") {
      iconData = Icons.error_rounded;
      iconColor = Color(0xFFFF3B30);
      bgColor = Color(0xFFFF3B30).withOpacity(0.15);
    } else if (timeStatus == "warning") {
      iconData = Icons.warning_rounded;
      iconColor = Color(0xFFFF9500);
      bgColor = Color(0xFFFF9500).withOpacity(0.15);
    } else {
      iconData = Icons.check_circle_rounded;
      iconColor = Color(0xFF34C759);
      bgColor = Color(0xFF34C759).withOpacity(0.15);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "${realTime.isNotEmpty ? "$realTime " : ""}${S.of(context).timeBeforeLiquidation}",
              style: TextStyle(
                fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



  // Déterminer le statut de temps avant liquidation
  String _calculateTimeBeforeLiquidationStatus(
    double walletRmmValue,
    double usdcBorrow,
    double xdaiBorrow,
    double usdcBorrowApy,
    double xdaiBorrowApy,
  ) {
    final double totalBorrow = usdcBorrow + xdaiBorrow;

    // Si pas d'emprunt, pas de risque de liquidation
    if (totalBorrow == 0) {
      return "safe";
    }

    // Calcul du health factor actuel
    final double currentHealthFactor = (walletRmmValue * 0.7) / totalBorrow;

    // Si déjà en dessous du seuil de liquidation (HF < 1)
    if (currentHealthFactor < 1) {
      return "danger";
    }

    // Calcul des taux d'intérêt journaliers
    final double usdcDailyRate = usdcBorrowApy / 365 / 100;
    final double xdaiDailyRate = xdaiBorrowApy / 365 / 100;

    // Calcul de l'augmentation journalière de la dette
    final double usdcDailyIncrease = usdcBorrow * usdcDailyRate;
    final double xdaiDailyIncrease = xdaiBorrow * xdaiDailyRate;
    final double totalDailyIncrease = usdcDailyIncrease + xdaiDailyIncrease;

    // Si l'augmentation journalière est quasi nulle, très long temps avant liquidation
    if (totalDailyIncrease < 0.000001) {
      return "safe";
    }

    // Calcul du temps avant liquidation (quand HF atteindra 1)
    final double maxBorrow = walletRmmValue * 0.7;
    final double remainingBorrowCapacity = maxBorrow - totalBorrow;
    final double timeInDays = remainingBorrowCapacity / totalDailyIncrease;

    // Détermination du statut en fonction du temps
    if (timeInDays < 30) {
      return "danger"; // Moins d'un mois
    } else if (timeInDays < 180) {
      return "warning"; // Moins de 6 mois
    } else {
      return "safe"; // Plus de 6 mois
    }
  }

  // Convertir le statut en texte formaté et calculer le temps réel
  String _getFormattedTime(String status) {
    // Pour les cas de danger imminent, pas de texte supplémentaire
    if (status == "danger") {
      return "";
    }

    // On ne peut pas calculer le temps réel ici car on n'a pas accès au contexte
    // On retourne une valeur basée sur le status
    return status == "warning" ? "< 6 mois" : "> 6 mois";
  }

  // Méthode à utiliser à la place de _getFormattedTime dans _buildLiquidationIndicator
  String _calculateRealTimeBeforeLiquidation(
    BuildContext context,
    double walletRmmValue,
    double usdcBorrow,
    double xdaiBorrow,
    double usdcBorrowApy,
    double xdaiBorrowApy,
  ) {
    // Récupérer les valeurs depuis le widget parent
    final DataManager dataManager = Provider.of<DataManager>(context, listen: false);

    // Récupérer la liste des wallets depuis perWalletBalances
    final List<Map<String, dynamic>> walletDetails = dataManager.perWalletBalances;

    // Sélection du wallet ayant le HF le plus bas
    Map<String, dynamic>? walletWithLowestHF;
    double lowestHF = double.infinity;

    for (var wallet in walletDetails) {
      final String address = wallet['address'] ?? '';
      final double usdcBorrow = wallet['usdcBorrow'] as double? ?? 0;
      final double xdaiBorrow = wallet['xdaiBorrow'] as double? ?? 0;
      final double totalBorrow = usdcBorrow + xdaiBorrow;

      // Utilise la même valeur RMM que dans l'autre page
      final double walletRmmValue = dataManager.perWalletRmmValues[address] ?? 0;

      // Calcul du Health Factor basé sur walletRmmValue
      final double hf = totalBorrow > 0 ? (walletRmmValue * 0.7) / totalBorrow : double.infinity;

      if (hf < lowestHF) {
        lowestHF = hf;
        walletWithLowestHF = wallet;
      }
    }

    // Récupération des valeurs du wallet sélectionné
    final String selectedAddress = walletWithLowestHF?['address'] ?? '';
    final double usdcBorrow = walletWithLowestHF?['usdcBorrow'] as double? ?? 0;
    final double xdaiBorrow = walletWithLowestHF?['xdaiBorrow'] as double? ?? 0;
    final double totalBorrow = usdcBorrow + xdaiBorrow;
    final double walletRmmValue = dataManager.perWalletRmmValues[selectedAddress] ?? 0;

    // Si pas d'emprunt, pas de risque de liquidation
    if (totalBorrow == 0) {
      return '∞';
    }

    // Calcul du health factor actuel
    final double currentHealthFactor = (walletRmmValue * 0.7) / totalBorrow;

    // Si déjà en dessous du seuil de liquidation (HF < 1)
    if (currentHealthFactor < 1) {
      return '';
    }

    // Taux d'emprunt
    final double usdcBorrowApy = dataManager.usdcBorrowApy ?? 0.0;
    final double xdaiBorrowApy = dataManager.xdaiBorrowApy ?? 0.0;

    // Calcul des taux d'intérêt journaliers
    final double usdcDailyRate = usdcBorrowApy / 365 / 100;
    final double xdaiDailyRate = xdaiBorrowApy / 365 / 100;

    // Calcul de l'augmentation journalière de la dette
    final double usdcDailyIncrease = usdcBorrow * usdcDailyRate;
    final double xdaiDailyIncrease = xdaiBorrow * xdaiDailyRate;
    final double totalDailyIncrease = usdcDailyIncrease + xdaiDailyIncrease;

    // Si l'augmentation journalière est quasi nulle, très long temps avant liquidation
    if (totalDailyIncrease < 0.000001) {
      return '∞';
    }

    // Calcul du temps avant liquidation (quand HF atteindra 1)
    final double maxBorrow = walletRmmValue * 0.7;
    final double remainingBorrowCapacity = maxBorrow - totalBorrow;
    final double timeInDays = remainingBorrowCapacity / totalDailyIncrease;

    // Si plus de 10 ans, afficher le symbole infini
    if (timeInDays > 3650) {
      return '> 10 ans';
    }

    // Affichage adapté en fonction de la durée
    if (timeInDays >= 365) {
      final double years = timeInDays / 365;
      return '${years.toStringAsFixed(1)} ans';
    } else if (timeInDays >= 30) {
      final double months = timeInDays / 30;
      return '${months.toStringAsFixed(1)} mois';
    } else if (timeInDays < 1) {
      return '';
    } else {
      return '${timeInDays.toStringAsFixed(1)} jours';
    }
  }
}
