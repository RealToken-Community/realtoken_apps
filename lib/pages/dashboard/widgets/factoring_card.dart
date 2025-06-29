import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';

class FactoringCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const FactoringCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Filtrer les tokens de type factoring_profitshare
    final factoringTokens = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'factoring_profitshare'
    ).toList();

    final totalTokens = factoringTokens.length;
    final totalValue = factoringTokens.fold<double>(0.0, (sum, token) => 
      sum + ((token['totalValue'] as num?)?.toDouble() ?? 0.0)
    );
    // Filtrer selon rentStartDate pour ne prendre que les tokens qui génèrent déjà des revenus
    final today = DateTime.now();
    final monthlyIncome = factoringTokens.fold<double>(0.0, (sum, token) {
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
      'Factoring',
      Icons.business_center_outlined,
      _buildValueWithIconSmall(
        context, 
        currencyUtils.getFormattedAmount(
          currencyUtils.convert(monthlyIncome), 
          currencyUtils.currencySymbol, 
          showAmounts
        ), 
        Icons.attach_money_rounded,
        isLoading
      ),
      [
        _buildTextWithShimmerSmall(
          '$totalTokens',
          'Factoring',
          isLoading,
          context,
        ),
        _buildTextWithShimmerSmall(
          showAmounts 
            ? _formatCurrencyWithoutDecimals(currencyUtils.convert(totalValue), currencyUtils.currencySymbol)
            : '*' * _formatCurrencyWithoutDecimals(currencyUtils.convert(totalValue), currencyUtils.currencySymbol).length,
          'Total',
          isLoading,
          context,
        ),
        const SizedBox(height: 8),
        // Graphique en donut positionné en dessous
        Center(
          child: _buildPieChart(totalTokens, totalValue, context),
        ),
      ],
      dataManager,
      context,
      hasGraph: false,
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

  Widget _buildPieChart(int totalTokens, double totalValue, BuildContext context) {
    // Donut désactivé (gris) pour maintenir la cohérence visuelle
    // mais indiquer qu'il ne représente pas d'information utile
    return SizedBox(
      width: 80,
      height: 60,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          sections: [
            PieChartSectionData(
              value: 100,
              color: Colors.grey.shade300,
              title: '—',
              radius: 18,
              titleStyle: TextStyle(
                fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 18,
        ),
      ),
    );
  }

  Widget _buildValueBeforeTextSmall(BuildContext context, String? value, String text, bool isLoading) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Row(
      children: [
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
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11 + appState.getTextSizeOffset(),
            color: theme.textTheme.bodyLarge?.color,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextWithShimmerSmall(String? value, String text, bool isLoading, BuildContext context) {
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
              fontSize: 12 + appState.getTextSizeOffset(),
              color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
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
                      fontSize: 13 + appState.getTextSizeOffset(),
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
                    fontSize: 13 + appState.getTextSizeOffset(),
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

  Widget _buildValueWithIconSmall(BuildContext context, String? value, IconData icon, bool isLoading) {
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