import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/common_functions.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';

class RentDistributionChart extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionChart({super.key, required this.dataManager});

  @override
  _RentDistributionChartState createState() => _RentDistributionChartState();
}

class _RentDistributionChartState extends State<RentDistributionChart> {
  late String _selectedFilter;
  int? _selectedIndex;
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region';
  }

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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).rentDistribution,
                  style: TextStyle(
                    fontSize: 20 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: [
                    DropdownMenuItem(value: 'Country', child: Text(S.of(context).country)),
                    DropdownMenuItem(value: 'Region', child: Text(S.of(context).region)),
                    DropdownMenuItem(value: 'City', child: Text(S.of(context).city)),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value!;
                      _selectedIndexNotifier.value = null;
                    });
                  },
                ),
              ],
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
                          sections: _buildRentDonutChartData(selectedIndex),
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
                child: _buildRentLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _groupRentDataBySelectedFilter() {
    Map<String, double> groupedData = {};

    for (var token in widget.dataManager.portfolio) {
      String key;

      if (_selectedFilter == 'Country') {
        key = token['country'] ?? S.of(context).unknownCountry;
      } else if (_selectedFilter == 'Region') {
        String regionCode = token['regionCode'] ?? S.of(context).unknownRegion;
        key = Parameters.getRegionDisplayName(regionCode);
      } else if (_selectedFilter == 'City') {
        key = token['city'] ?? S.of(context).unknownCity;
      } else {
        key = S.of(context).unknown;
      }

      groupedData[key] = (groupedData[key] ?? 0) + (token['monthlyIncome'] ?? 0.0);
    }

    return groupedData;
  }

  List<PieChartSectionData> _buildRentDonutChartData(int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter();
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);

    if (totalRent <= 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.withOpacity(0.2),
          radius: 40,
        )
      ];
    }

    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final percentage = (data.value / totalRent) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      return PieChartSectionData(
        value: data.value,
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: generateColor(index).withOpacity(opacity),
        radius: isSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + Provider.of<AppState>(context).getTextSizeOffset() : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterText(int? selectedIndex) {
    final Map<String, double> groupedData = _groupRentDataBySelectedFilter();
    final totalRent = groupedData.values.fold(0.0, (sum, value) => sum + value);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

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
            currencyUtils.getFormattedAmount(currencyUtils.convert(totalRent), currencyUtils.currencySymbol, true),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Obtenir l'entrée sélectionnée
    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex >= sortedEntries.length) return Container();

    final selectedEntry = sortedEntries[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedEntry.key,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: generateColor(selectedIndex),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          currencyUtils.getFormattedAmount(currencyUtils.convert(selectedEntry.value), currencyUtils.currencySymbol, true),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRentLegend() {
    Map<String, double> groupedData = _groupRentDataBySelectedFilter();
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final sortedEntries = groupedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = generateColor(index);

        return InkWell(
          onTap: () {
            _selectedIndexNotifier.value = (_selectedIndexNotifier.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifier.value == index ? color.withOpacity(0.1) : Colors.transparent,
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.key,
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: _selectedIndexNotifier.value == index ? color : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifier.value == index ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
