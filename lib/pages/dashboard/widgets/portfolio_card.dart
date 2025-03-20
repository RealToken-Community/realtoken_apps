import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/utils/currency_utils.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/utils/ui_utils.dart';
import 'package:realtokens/utils/parameters.dart';
import 'package:shimmer/shimmer.dart';
import 'package:realtokens/settings/personalization_settings_page.dart';
import 'package:realtokens/pages/dashboard/detailsPages/portfolio_details_page.dart';

class PortfolioCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;
  final BuildContext context;

  const PortfolioCard({
    super.key,
    required this.showAmounts,
    required this.isLoading,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    // Calcul des totaux en tenant compte des paramètres
    double totalPortfolioValue = Parameters.showNetTotal 
        ? dataManager.walletValue +
          dataManager.rmmValue + 
          dataManager.rwaHoldingsValue +
          dataManager.totalUsdcDepositBalance +
          dataManager.totalXdaiDepositBalance -
          dataManager.totalUsdcBorrowBalance -
          dataManager.totalXdaiBorrowBalance +
          Parameters.manualAdjustment
        : dataManager.walletValue +
          dataManager.rmmValue + 
          dataManager.rwaHoldingsValue +
          Parameters.manualAdjustment;
    
    // Calcul du total sans les dépôts et emprunts si showNetTotal est false
    double portfolioDisplayValue = Parameters.showNetTotal 
        ? dataManager.yamTotalValue +
          dataManager.rwaHoldingsValue +
          dataManager.totalUsdcDepositBalance +
          dataManager.totalXdaiDepositBalance -
          dataManager.totalUsdcBorrowBalance -
          dataManager.totalXdaiBorrowBalance +
          Parameters.manualAdjustment
        : dataManager.yamTotalValue +
          dataManager.rwaHoldingsValue +
          Parameters.manualAdjustment;

    // Calcul du pourcentage de rendement par rapport à l'investissement total
    double percentageYam = ((portfolioDisplayValue / totalPortfolioValue - 1) * 100);
    String percentageYamDisplay = percentageYam.isNaN || percentageYam.isInfinite ? '0' : percentageYam.toStringAsFixed(0);

    // Calculer le nombre d'éléments visibles pour estimer la hauteur minimale
    int visibleSections = 2; // Toujours afficher la section "Actifs"
    if (Parameters.showNetTotal) visibleSections++; // Section "Dépôts & Emprunts"
    if (Parameters.manualAdjustment != 0) visibleSections++; // Section "Ajustements"
    if (Parameters.showTotalInvested) visibleSections++; // Total investi

    // Hauteur minimale basée sur le nombre de sections visibles
    double minHeight = 220.0; // Hauteur de base
    if (visibleSections <= 2) minHeight = 220.0; // Hauteur minimale pour peu de contenu
    else if (visibleSections == 3) minHeight = 240.0;
    else minHeight = 260.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: UIUtils.buildCard(
        S.of(context).portfolio,
        Icons.pie_chart_rounded,
        Parameters.showYamProjection 
          ? UIUtils.buildValueBeforeText(
              context,
              currencyUtils.getFormattedAmount(
                  currencyUtils.convert(portfolioDisplayValue),
                  currencyUtils.currencySymbol,
                  showAmounts),
              'projection YAM ($percentageYamDisplay%)',
              isLoading,
              highlightPercentage: true,
            )
          : const SizedBox.shrink(),
        [
          // Section des totaux - mise en évidence avec un style particulier
          _buildSectionTitle(context, S.of(context).totalPortfolio, theme),
          _buildTotalValue(
              context,
              currencyUtils.getFormattedAmount(
                  currencyUtils.convert(totalPortfolioValue),
                  currencyUtils.currencySymbol,
                  showAmounts),
              isLoading,
              theme,
              showNetLabel: Parameters.showNetTotal),
              
          // Ajout du total investi si l'option est activée
          if (Parameters.showTotalInvested)
            _buildSubtotalValue(
                context,
                currencyUtils.getFormattedAmount(
                    currencyUtils.convert(dataManager.initialTotalValue + Parameters.initialInvestmentAdjustment),
                    currencyUtils.currencySymbol,
                    showAmounts),
                S.of(context).initialInvestment,
                isLoading,
                theme),
                
          const SizedBox(height: 3), // Réduit de 6 à 3
          
          // Section des actifs - avec titre de section
          _buildSectionTitle(context, "Actifs", theme),
          _buildIndentedBalance(
              S.of(context).wallet,
              currencyUtils.convert(dataManager.walletValue),
              currencyUtils.currencySymbol,
              true,
              context,
              isLoading),
          _buildIndentedBalance(
              S.of(context).rmm,
              currencyUtils.convert(dataManager.rmmValue),
              currencyUtils.currencySymbol,
              true,
              context,
              isLoading),
          _buildIndentedBalance(
              S.of(context).rwaHoldings,
              currencyUtils.convert(dataManager.rwaHoldingsValue),
              currencyUtils.currencySymbol,
              true,
              context,
              isLoading),
              
          if (Parameters.showNetTotal) ...[
            const SizedBox(height: 3), // Réduit de 6 à 3
            // Section des dépôts et emprunts - avec titre de section
            _buildSectionTitle(context, "Dépôts & Emprunts", theme),
            _buildIndentedBalance(
                S.of(context).depositBalance,
                currencyUtils.convert(dataManager.totalUsdcDepositBalance +
                    dataManager.totalXdaiDepositBalance),
                currencyUtils.currencySymbol,
                true,
                context,
                isLoading),
            _buildIndentedBalance(
                S.of(context).borrowBalance,
                currencyUtils.convert(dataManager.totalUsdcBorrowBalance +
                    dataManager.totalXdaiBorrowBalance),
                currencyUtils.currencySymbol,
                false,
                context,
                isLoading),
          ],
          
          // Affichage de l'ajustement manuel si différent de zéro
          if (Parameters.manualAdjustment != 0) ...[
            const SizedBox(height: 3), // Réduit de 6 à 3
            _buildSectionTitle(context, "Ajustements", theme),
            _buildIndentedBalance(
                S.of(context).manualAdjustment,
                currencyUtils.convert(Parameters.manualAdjustment),
                currencyUtils.currencySymbol,
                Parameters.manualAdjustment > 0,
                context,
                isLoading),
          ],
          
          // Ajouter un espace pour assurer une hauteur minimale si nécessaire
          if (visibleSections <= 2)
            SizedBox(height: 10), // Réduit de 20 à 10
        ],
        dataManager,
        context,
        hasGraph: true,
        rightWidget: _buildVerticalGauge(dataManager.roiGlobalValue, context, visibleSections),
        headerRightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 36,
              margin: EdgeInsets.only(right: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: theme.brightness == Brightness.light 
                          ? Colors.black54
                          : Colors.white70,
                    ),
                  ),
                  onTap: () {
                    _showPersonalizationModal(context);
                  },
                ),
              ),
            ),
            Container(
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
                      color: theme.brightness == Brightness.light 
                          ? Colors.black54
                          : Colors.white70,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PortfolioDetailsPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalizationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const Expanded(
                child: PersonalizationSettingsPage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.0, bottom: 2.0),
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
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalValue(BuildContext context, String formattedAmount, bool isLoading, ThemeData theme, {bool showNetLabel = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 1, bottom: 2),
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                  highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey[100]!,
                  child: Container(
                    width: 120,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: theme.primaryColor,
                  ),
                ),
          if (showNetLabel)
            Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "net",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtotalValue(BuildContext context, String formattedAmount, String label, bool isLoading, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 1, bottom: 1),
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ?? Colors.grey[300]!,
                  highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: -0.2,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndentedBalance(String label, double value, String symbol,
      bool isPositive, BuildContext context, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    String formattedAmount = showAmounts
        ? (isPositive
            ? "+ ${currencyUtils.formatCurrency(value, symbol)}"
            : "- ${currencyUtils.formatCurrency(value, symbol)}")
        : (isPositive ? "+ " : "- ") + ('*' * 10);

    Color valueColor = isPositive 
        ? Color(0xFF34C759) // Vert iOS
        : Color(0xFFFF3B30); // Rouge iOS

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 1.0, bottom: 1.0),
      child: Row(
        children: [
          isLoading
              ? Shimmer.fromColors(
                  baseColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ??
                      Colors.grey[300]!,
                  highlightColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ??
                      Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: valueColor,
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13 + appState.getTextSizeOffset(),
              letterSpacing: -0.2,
              color: theme.brightness == Brightness.light 
                ? Colors.black54 
                : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalGauge(double value, BuildContext context, int visibleSections) {
    // Récupérer directement du DataManager pour les calculs
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final theme = Theme.of(context);
    
    // Utiliser la méthode d'origine qui calcule le ROI basé sur les loyers reçus
    // ROI = (Total des loyers reçus / Investissement initial) * 100
    double totalRentReceived = dataManager.getTotalRentReceived();
    double initialInvestment = dataManager.initialTotalValue + Parameters.initialInvestmentAdjustment;
    
    // Vérifier si l'investissement initial est valide pour éviter la division par zéro
    double displayValue = 0.0;
    if (initialInvestment > 0) {
      displayValue = (totalRentReceived / initialInvestment) * 100;
      
      // S'assurer que le ROI n'est jamais négatif
      displayValue = displayValue < 0 ? 0.0 : displayValue;
    }
    
    // S'assurer que la valeur est valide
    displayValue = displayValue.isNaN || displayValue.isInfinite ? 0.0 : displayValue;
    
    // Pourcentage limité entre 0% et 100% pour l'affichage (mais on peut avoir un ROI > 100%)
    double progress = (displayValue / 100).clamp(0.0, 1.0);

    // Couleur unique pour la jauge
    final Color gaugeColor = theme.primaryColor;

    // Ajuster la hauteur de la jauge en fonction du nombre de sections visibles
    double gaugeHeight = 90.0; // Hauteur par défaut
    if (visibleSections <= 2) gaugeHeight = 75.0;
    else if (visibleSections == 3) gaugeHeight = 85.0;
    else gaugeHeight = 120.0;

    double containerHeight = gaugeHeight + 50; // Ajouter de l'espace pour le texte et les marges

    return Container(
      width: 90,
      height: containerHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ROI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(S.of(context).roiPerProperties),
                        content: Text(S.of(context).roiAlertInfo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.brightness == Brightness.light 
                      ? Colors.black38
                      : Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: gaugeHeight,
            width: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: theme.brightness == Brightness.light 
                  ? Colors.black.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: progress * gaugeHeight,
                width: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: gaugeColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayValue > 3650 ? "∞" : "${displayValue.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
