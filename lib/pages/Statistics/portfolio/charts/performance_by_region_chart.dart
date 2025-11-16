import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';

class PerformanceByRegionChart extends StatefulWidget {
  final DataManager dataManager;

  const PerformanceByRegionChart({super.key, required this.dataManager});

  @override
  _PerformanceByRegionChartState createState() => _PerformanceByRegionChartState();
}

class _PerformanceByRegionChartState extends State<PerformanceByRegionChart> {
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);
  String _sortBy = 'roi'; // 'roi' ou 'count'

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
            Text(
              S.of(context).performanceByRegion,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<String>(
                  value: _sortBy,
                  items: [
                    DropdownMenuItem(value: 'roi', child: Text(S.of(context).sortByROI)),
                    DropdownMenuItem(value: 'count', child: Text(S.of(context).sortByCount)),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = value!;
                      _selectedIndexNotifier.value = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return _buildRegionPerformanceChart(selectedIndex);
                },
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildRegionLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateRegionPerformance() {
    Map<String, Map<String, dynamic>> regionData = {};

    for (var token in widget.dataManager.portfolio) {
      final String regionCode = token['regionCode'] ?? 'Unknown';
      final String regionName = Parameters.getRegionDisplayName(regionCode);
      final double totalRentReceived = (token['totalRentReceived'] ?? 0.0).toDouble();
      final double initialValue = (token['initialValue'] ?? 0.0).toDouble();
      final double roi = initialValue > 0 ? (totalRentReceived / initialValue) * 100 : 0.0;

      if (!regionData.containsKey(regionName)) {
        regionData[regionName] = {
          'totalRoi': 0.0,
          'totalInitialValue': 0.0,
          'totalRentReceived': 0.0,
          'tokenCount': 0,
        };
      }

      regionData[regionName]!['totalRoi'] = regionData[regionName]!['totalRoi'] + roi;
      regionData[regionName]!['totalInitialValue'] = regionData[regionName]!['totalInitialValue'] + initialValue;
      regionData[regionName]!['totalRentReceived'] = regionData[regionName]!['totalRentReceived'] + totalRentReceived;
      regionData[regionName]!['tokenCount'] = regionData[regionName]!['tokenCount'] + 1;
    }

    // Calculer le ROI moyen par région
    regionData.forEach((region, data) {
      final int tokenCount = data['tokenCount'];
      final double totalInitialValue = data['totalInitialValue'];
      final double totalRentReceived = data['totalRentReceived'];
      
      data['averageRoi'] = totalInitialValue > 0 ? (totalRentReceived / totalInitialValue) * 100 : 0.0;
    });

    return regionData;
  }

  Widget _buildRegionPerformanceChart(int? selectedIndex) {
    final Map<String, Map<String, dynamic>> regionData = _calculateRegionPerformance();
    
    if (regionData.isEmpty) {
      return Center(
        child: Text(
          S.of(context).noDataAvailable,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    // Trier les données selon le critère sélectionné
    final List<MapEntry<String, Map<String, dynamic>>> sortedEntries = regionData.entries.toList();
    if (_sortBy == 'roi') {
      sortedEntries.sort((a, b) => b.value['averageRoi'].compareTo(a.value['averageRoi']));
    } else {
      sortedEntries.sort((a, b) => b.value['tokenCount'].compareTo(a.value['tokenCount']));
    }

    // Limiter à 8 régions pour la lisibilité
    final List<MapEntry<String, Map<String, dynamic>>> displayEntries = 
        sortedEntries.take(8).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: displayEntries.isEmpty ? 10 : displayEntries.map((e) => e.value['averageRoi'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = displayEntries[group.x.toInt()];
              final regionName = entry.key;
              final data = entry.value;
              return BarTooltipItem(
                                 '$regionName\n${S.of(context).averageROI}: ${data['averageRoi'].toStringAsFixed(1)}%\nTokens: ${data['tokenCount']}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12 + Provider.of<AppState>(context).getTextSizeOffset(),
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (response != null && response.spot != null) {
              final touchedIndex = response.spot!.touchedBarGroupIndex;
              _selectedIndexNotifier.value = touchedIndex >= 0 ? touchedIndex : null;
            } else {
              _selectedIndexNotifier.value = null;
            }
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayEntries.length) {
                  final regionName = displayEntries[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      regionName.length > 6 ? '${regionName.substring(0, 6)}...' : regionName,
                      style: TextStyle(
                        fontSize: 10 + Provider.of<AppState>(context).getTextSizeOffset(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10 + Provider.of<AppState>(context).getTextSizeOffset(),
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: displayEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final regionEntry = entry.value;
          final data = regionEntry.value;
          final roi = data['averageRoi'] as double;
          final isSelected = selectedIndex == index;

          Color barColor;
          if (roi >= 10) {
            barColor = const Color(0xFF34C759); // Vert
          } else if (roi >= 5) {
            barColor = const Color(0xFFFFD60A); // Jaune
          } else if (roi >= 0) {
            barColor = const Color(0xFFFF9500); // Orange
          } else {
            barColor = const Color(0xFFFF3B30); // Rouge
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: math.max(roi.abs(), 1.0) * (roi >= 0 ? 1 : -1),
                color: barColor.withOpacity(isSelected ? 1.0 : 0.8),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: displayEntries.map((e) => e.value['averageRoi'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
            showingTooltipIndicators: isSelected ? [0] : [],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRegionLegend() {
    final Map<String, Map<String, dynamic>> regionData = _calculateRegionPerformance();
    final appState = Provider.of<AppState>(context);

    final List<MapEntry<String, Map<String, dynamic>>> sortedEntries = regionData.entries.toList();
    if (_sortBy == 'roi') {
      sortedEntries.sort((a, b) => b.value['averageRoi'].compareTo(a.value['averageRoi']));
    } else {
      sortedEntries.sort((a, b) => b.value['tokenCount'].compareTo(a.value['tokenCount']));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.take(8).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final regionEntry = entry.value;
        final regionName = regionEntry.key;
        final data = regionEntry.value;
        final roi = data['averageRoi'] as double;
        final tokenCount = data['tokenCount'] as int;

        Color color;
        if (roi >= 10) {
          color = const Color(0xFF34C759);
        } else if (roi >= 5) {
          color = const Color(0xFFFFD60A);
        } else if (roi >= 0) {
          color = const Color(0xFFFF9500);
        } else {
          color = const Color(0xFFFF3B30);
        }

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
                  '$regionName: ${roi.toStringAsFixed(1)}% ($tokenCount)',
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