import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class RentalStatusDistributionChart extends StatefulWidget {
  final DataManager dataManager;

  const RentalStatusDistributionChart({super.key, required this.dataManager});

  @override
  _RentalStatusDistributionChartState createState() =>
      _RentalStatusDistributionChartState();
}

class _RentalStatusDistributionChartState
    extends State<RentalStatusDistributionChart> {
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
              S.of(context).rentalStatusDistribution,
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
                          sections: _buildRentalStatusChartData(selectedIndex),
                          centerSpaceRadius: 65,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                PieTouchResponse? response) {
                              if (response != null &&
                                  response.touchedSection != null) {
                                final touchedIndex = response
                                    .touchedSection!.touchedSectionIndex;
                                _selectedIndexNotifier.value =
                                    touchedIndex >= 0 ? touchedIndex : null;
                              } else {
                                _selectedIndexNotifier.value = null;
                              }
                            },
                          ),
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 300),
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
                child: _buildRentalStatusLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateRentalStatusData() {
    Map<String, int> statusCount = {
      'fullyRented': 0,
      'partiallyRented': 0,
      'notRented': 0,
    };

    for (var token in widget.dataManager.portfolio) {
      final int rentedUnits = (token['rentedUnits'] ?? 0).toInt();
      final int totalUnits = (token['totalUnits'] ?? 1).toInt();

      if (rentedUnits == 0) {
        statusCount['notRented'] = statusCount['notRented']! + 1;
      } else if (rentedUnits == totalUnits) {
        statusCount['fullyRented'] = statusCount['fullyRented']! + 1;
      } else {
        statusCount['partiallyRented'] = statusCount['partiallyRented']! + 1;
      }
    }

    return statusCount;
  }

  List<PieChartSectionData> _buildRentalStatusChartData(int? selectedIndex) {
    final Map<String, int> statusData = _calculateRentalStatusData();
    final int total = statusData.values.fold(0, (sum, value) => sum + value);

    if (total <= 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.withValues(alpha: 0.2),
          radius: 40,
        )
      ];
    }

    final List<MapEntry<String, int>> sortedEntries =
        statusData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final statusType = entry.value.key;
      final count = entry.value.value;
      final percentage = (count / total) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      Color color;
      switch (statusType) {
        case 'fullyRented':
          color = const Color(0xFF34C759); // Vert pour entièrement loué
          break;
        case 'partiallyRented':
          color = const Color(0xFFFF9500); // Orange pour partiellement loué
          break;
        case 'notRented':
          color = const Color(0xFFFF3B30); // Rouge pour non loué
          break;
        default:
          color = Colors.grey;
      }

      return PieChartSectionData(
        value: count.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: color.withValues(alpha: opacity),
        radius: isSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isSelected
              ? 14 + Provider.of<AppState>(context).getTextSizeOffset()
              : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
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
    final Map<String, int> statusData = _calculateRentalStatusData();
    final int total = statusData.values.fold(0, (sum, value) => sum + value);

    if (selectedIndex == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).totalProperties,
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

    final List<MapEntry<String, int>> sortedEntries =
        statusData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex >= sortedEntries.length) return Container();

    final selectedEntry = sortedEntries[selectedIndex];
    final String statusName = _getRentalStatusName(selectedEntry.key);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusName,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: _getRentalStatusColor(selectedEntry.key),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          selectedEntry.value.toString(),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getRentalStatusName(String statusType) {
    switch (statusType) {
      case 'fullyRented':
        return S.of(context).fullyRented;
      case 'partiallyRented':
        return S.of(context).partiallyRented;
      case 'notRented':
        return S.of(context).notRented;
      default:
        return S.of(context).unknown;
    }
  }

  Color _getRentalStatusColor(String statusType) {
    switch (statusType) {
      case 'fullyRented':
        return const Color(0xFF34C759);
      case 'partiallyRented':
        return const Color(0xFFFF9500);
      case 'notRented':
        return const Color(0xFFFF3B30);
      default:
        return Colors.grey;
    }
  }

  Widget _buildRentalStatusLegend() {
    final Map<String, int> statusData = _calculateRentalStatusData();
    final appState = Provider.of<AppState>(context);

    final List<MapEntry<String, int>> sortedEntries =
        statusData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final statusEntry = entry.value;
        final statusType = statusEntry.key;
        final count = statusEntry.value;
        final color = _getRentalStatusColor(statusType);
        final statusName = _getRentalStatusName(statusType);

        return InkWell(
          onTap: () {
            _selectedIndexNotifier.value =
                (_selectedIndexNotifier.value == index) ? null : index;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: _selectedIndexNotifier.value == index
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedIndexNotifier.value == index
                    ? color
                    : Colors.transparent,
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
                Text(
                  '$statusName: $count',
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    color: _selectedIndexNotifier.value == index
                        ? color
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _selectedIndexNotifier.value == index
                        ? FontWeight.w600
                        : FontWeight.normal,
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
