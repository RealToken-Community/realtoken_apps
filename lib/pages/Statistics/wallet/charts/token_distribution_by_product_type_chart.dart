import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/common_functions.dart';

class TokenDistributionByProductTypeChart extends StatefulWidget {
  final DataManager dataManager;

  const TokenDistributionByProductTypeChart({
    super.key,
    required this.dataManager,
  });

  @override
  State<TokenDistributionByProductTypeChart> createState() => _TokenDistributionByProductTypeChartState();
}

class _TokenDistributionByProductTypeChartState extends State<TokenDistributionByProductTypeChart> {
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);

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
              S.of(context).tokenDistributionByProductType,
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
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: _buildDonutChartData(selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                              if (response != null && response.touchedSection != null) {
                                final touchedIndex = response.touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifier.value = touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 300),
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
                child: _buildLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutChartData(int? selectedIndex) {
    final appState = Provider.of<AppState>(context);
    final tokensByType = _calculateTokensByProductType();
    
    if (tokensByType.isEmpty) return [];

    final int total = tokensByType.values.fold(0, (sum, value) => sum + value);
    final sortedTypes = tokensByType.keys.toList()
      ..sort((a, b) => tokensByType[b]!.compareTo(tokensByType[a]!));

    return sortedTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final productType = entry.value;
      final int value = tokensByType[productType]!;
      final double percentage = (value / total) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      final Color baseColor = generateColor(index);

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: baseColor.withValues(alpha: opacity),
        radius: isSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + appState.getTextSizeOffset() : 10 + appState.getTextSizeOffset(),
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

  Widget _buildCenterText(int? selectedIndex) {
    final tokensByType = _calculateTokensByProductType();
    final int total = tokensByType.values.fold(0, (sum, value) => sum + value);

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
            total.toString(),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final sortedTypes = tokensByType.keys.toList()
      ..sort((a, b) => tokensByType[b]!.compareTo(tokensByType[a]!));

    if (selectedIndex >= sortedTypes.length) return Container();

    final selectedType = sortedTypes[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getLocalizedProductTypeName(context, selectedType),
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: generateColor(selectedIndex),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          tokensByType[selectedType].toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final appState = Provider.of<AppState>(context);
    final tokensByType = _calculateTokensByProductType();
    
    if (tokensByType.isEmpty) return Container();

    final int total = tokensByType.values.fold(0, (sum, value) => sum + value);
    final sortedTypes = tokensByType.keys.toList()
      ..sort((a, b) => tokensByType[b]!.compareTo(tokensByType[a]!));

    return Wrap(
      spacing: 12.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.start,
      children: sortedTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final productType = entry.value;
        final color = generateColor(index);
        final count = tokensByType[productType]!;
        final percentage = (count / total) * 100;

        return InkWell(
          onTap: () {
            _selectedIndexNotifier.value = (_selectedIndexNotifier.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifier.value == index ? color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifier.value == index ? color : Colors.transparent,
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
                    '${_getLocalizedProductTypeName(context, productType)} (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: _selectedIndexNotifier.value == index ? color : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _selectedIndexNotifier.value == index ? FontWeight.w600 : FontWeight.normal,
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

  Map<String, int> _calculateTokensByProductType() {
    Map<String, int> tokensByProductType = {};
    
    for (var token in widget.dataManager.portfolio) {
      final String productType = token['productType'] ?? 'other';
      tokensByProductType[productType] = (tokensByProductType[productType] ?? 0) + 1;
    }
    
    return tokensByProductType;
  }

  String _getLocalizedProductTypeName(BuildContext context, String productType) {
    switch (productType.toLowerCase()) {
      case 'real_estate_rental':
        return S.of(context).productTypeRealEstateRental;
      case 'factoring_profitshare':
        return S.of(context).productTypeFactoringProfitshare;
      case 'loan_income':
        return S.of(context).productTypeLoanIncome;
      default:
        return S.of(context).productTypeOther;
    }
  }
} 