import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

class RealEstateCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const RealEstateCard(
      {super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Filtrer les tokens de type real_estate_rental
    final realEstateTokens = dataManager.portfolio
        .where((token) =>
            (token['productType'] ?? '').toLowerCase() == 'real_estate_rental')
        .toList();

    final totalTokens = realEstateTokens.length;
    final totalUnits = realEstateTokens.fold<int>(
        0, (sum, token) => sum + ((token['totalUnits'] as num?)?.toInt() ?? 0));
    final rentedUnits = realEstateTokens.fold<int>(0,
        (sum, token) => sum + ((token['rentedUnits'] as num?)?.toInt() ?? 0));
    final totalValue = realEstateTokens.fold<double>(
        0.0,
        (sum, token) =>
            sum + ((token['totalValue'] as num?)?.toDouble() ?? 0.0));
    // Filtrer selon rentStartDate pour ne prendre que les tokens qui génèrent déjà des revenus
    final today = DateTime.now();
    final monthlyIncome = realEstateTokens.fold<double>(0.0, (sum, token) {
      final rentStartDateString = token['rentStartDate'] as String?;
      if (rentStartDateString != null) {
        final rentStartDate = DateTime.tryParse(rentStartDateString);
        if (rentStartDate != null && rentStartDate.isBefore(today)) {
          return sum + ((token['monthlyIncome'] as num?)?.toDouble() ?? 0.0);
        }
      }
      return sum;
    });

    return UIUtils.buildCard(
      'Estate',
      Icons.home_outlined,
      _buildValueWithIconSmall(
          context,
          currencyUtils.getFormattedAmount(currencyUtils.convert(monthlyIncome),
              currencyUtils.currencySymbol, showAmounts),
          Icons.attach_money_rounded,
          isLoading),
      [
        _buildTextWithShimmerSmall(
          '$totalTokens',
          S.of(context).properties,
          isLoading,
          context,
        ),
        _buildTextWithShimmerSmall(
          showAmounts
              ? _formatCurrencyWithoutDecimals(
                  currencyUtils.convert(totalValue),
                  currencyUtils.currencySymbol)
              : '*' *
                  _formatCurrencyWithoutDecimals(
                          currencyUtils.convert(totalValue),
                          currencyUtils.currencySymbol)
                      .length,
          'Total',
          isLoading,
          context,
        ),
        const SizedBox(height: 8),
        // Graphique en donut positionné en dessous
        Center(
          child: Builder(
            builder: (context) {
              double rentedPercentage =
                  totalUnits > 0 ? (rentedUnits / totalUnits * 100) : 0.0;
              if (rentedPercentage.isNaN || rentedPercentage < 0) {
                rentedPercentage = 0;
              }
              return _buildPieChart(rentedPercentage, context);
            },
          ),
        ),
      ],
      dataManager,
      context,
      hasGraph: false, // Pas de rightWidget
    );
  }

  String _formatCurrencyWithoutDecimals(double value, String symbol) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: symbol,
      decimalDigits: 0, // Pas de décimales
    );
    return formatter.format(value.round());
  }

  Widget _buildPieChart(double rentedPercentage, BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 80,
      height: 60,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  value: rentedPercentage,
                  color: Colors.green,
                  title: '',
                  radius: 18,
                  titleStyle: TextStyle(
                    fontSize: 10 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade300, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                PieChartSectionData(
                  value: 100 - rentedPercentage,
                  color: theme.primaryColor,
                  title: '',
                  radius: 13,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.6),
                      theme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ],
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 18,
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOut,
          ),
          // Texte au centre du donut
          Center(
            child: Text(
              '${rentedPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10 +
                    Provider.of<AppState>(context, listen: false)
                        .getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBeforeTextSmall(
      BuildContext context, String? value, String text, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        isLoading
            ? ShimmerUtils.originalColorShimmer(
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize:
                        14 + appState.getTextSizeOffset(), // Réduit de 16 à 14
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                    height: 1.1,
                  ),
                ),
                color: theme.textTheme.bodyLarge?.color,
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize:
                      14 + appState.getTextSizeOffset(), // Réduit de 16 à 14
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.1,
                ),
              ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11 + appState.getTextSizeOffset(), // Réduit de 13 à 11
            color: theme.textTheme.bodyLarge?.color,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextWithShimmerSmall(
      String? value, String text, bool isLoading, BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(), // Réduit de 14 à 12
              color: theme.brightness == Brightness.light
                  ? Colors.black54
                  : Colors.white70,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
          SizedBox(width: 8),
          isLoading
              ? ShimmerUtils.originalColorShimmer(
                  child: Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 13 +
                          appState.getTextSizeOffset(), // Réduit de 15 à 13
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  color: theme.textTheme.bodyLarge?.color,
                )
              : Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize:
                        13 + appState.getTextSizeOffset(), // Réduit de 15 à 13
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildValueWithIconSmall(
      BuildContext context, String? value, IconData icon, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16 + appState.getTextSizeOffset(),
            color: theme.primaryColor,
          ),
          const SizedBox(width: 4),
          isLoading
              ? ShimmerUtils.originalColorShimmer(
                  child: Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 14 + appState.getTextSizeOffset(),
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.1,
                    ),
                  ),
                  color: theme.textTheme.bodyLarge?.color,
                )
              : Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                    height: 1.1,
                  ),
                ),
        ],
      ),
    );
  }
}
