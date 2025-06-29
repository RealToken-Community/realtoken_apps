import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class RealtPage extends StatefulWidget {
  const RealtPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<RealtPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Center(
          child: Image.asset(
            'assets/RealT_Logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildIOSStyleCard(
                  context,
                  'investment',
                  CupertinoIcons.money_dollar_circle,
                  currencyUtils.formatCurrency(
                      currencyUtils.convert(dataManager.totalRealtInvestment),
                      currencyUtils.currencySymbol),
                  S.of(context).totalInvestment,
                  [
                    _buildIOSValueRow(
                      context,
                      currencyUtils.formatCurrency(
                          currencyUtils.convert(dataManager.netRealtRentYear),
                          currencyUtils.currencySymbol),
                      'net rent',
                    ),
                  ],
                  CupertinoColors.systemGreen,
                ),
                const SizedBox(height: 16),
                _buildIOSStyleCard(
                  context,
                  S.of(context).properties,
                  CupertinoIcons.home,
                  '${dataManager.totalRealtTokens}',
                  S.of(context).tokens,
                  [
                    _buildIOSValueRow(
                      context,
                      '${dataManager.totalRealtUnits}',
                      S.of(context).units,
                    ),
                    _buildIOSValueRow(
                      context,
                      '${dataManager.rentedRealtUnits}',
                      S.of(context).rentedUnits(
                          dataManager.rentedUnits.toString(),
                          dataManager.totalUnits.toString()),
                    ),
                    _buildIOSValueRow(
                      context,
                      '${(dataManager.rentedRealtUnits / dataManager.totalRealtUnits * 100).toStringAsFixed(1)}%',
                      S.of(context).rented,
                      valueColor: CupertinoColors.systemGreen,
                    ),
                  ],
                  CupertinoColors.systemBlue,
                ),
                const SizedBox(height: 16),
                _buildIOSStyleCard(
                  context,
                  S.of(context).realTPerformance,
                  CupertinoIcons.chart_bar_fill,
                  '${dataManager.averageRealtAnnualYield.toStringAsFixed(2)}%',
                  S.of(context).annualYield,
                  [
                    _buildIOSValueRow(
                      context,
                      '',
                      S.of(context).annualYield,
                    ),
                  ],
                  CupertinoColors.systemIndigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSStyleCard(
    BuildContext context,
    String title,
    IconData icon,
    String mainValue,
    String mainLabel,
    List<Widget> additionalRows,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIOSValueRow(
              context,
              mainValue,
              mainLabel,
              valueSize: 18,
              valueColor: iconColor,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...additionalRows,
          ],
        ),
      ),
    );
  }

  Widget _buildIOSValueRow(
    BuildContext context,
    String value,
    String label, {
    double valueSize = 16,
    Color? valueColor,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: fontWeight,
              color: valueColor ?? CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14 +
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset(),
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
