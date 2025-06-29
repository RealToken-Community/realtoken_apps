import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

class TransactionAnalysisChart extends StatefulWidget {
  final DataManager dataManager;

  const TransactionAnalysisChart({super.key, required this.dataManager});

  @override
  _TransactionAnalysisChartState createState() => _TransactionAnalysisChartState();
}

class _TransactionAnalysisChartState extends State<TransactionAnalysisChart> {
  final ValueNotifier<int?> _selectedIndexNotifier = ValueNotifier<int?>(null);
  String _analysisType = 'count'; // 'count' ou 'volume'

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
              S.of(context).transactionAnalysis,
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
                  value: _analysisType,
                  items: [
                    DropdownMenuItem(value: 'count', child: Text(S.of(context).transactionCount)),
                    DropdownMenuItem(value: 'volume', child: Text(S.of(context).transactionVolume)),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _analysisType = value!;
                      _selectedIndexNotifier.value = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          sections: _buildTransactionDonutChartData(selectedIndex),
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
                child: _buildTransactionLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateTransactionData() {
    Map<String, int> transactionCounts = {
      'purchase': 0,
      'transfer': 0,
      'yam': 0,
    };
    
    Map<String, double> transactionVolumes = {
      'purchase': 0.0,
      'transfer': 0.0,
      'yam': 0.0,
    };

    // Parcourir toutes les transactions par token
    for (var tokenTransactions in widget.dataManager.transactionsByToken.values) {
      for (var transaction in tokenTransactions) {
        final String transactionType = transaction['transactionType'] ?? 'unknown';
        final double amount = (transaction['amount'] ?? 0.0).toDouble();
        final double price = (transaction['price'] ?? 0.0).toDouble();
        final double volume = amount * price;

        if (transactionCounts.containsKey(transactionType)) {
          transactionCounts[transactionType] = transactionCounts[transactionType]! + 1;
          transactionVolumes[transactionType] = transactionVolumes[transactionType]! + volume;
        }
      }
    }

    return {
      'counts': transactionCounts,
      'volumes': transactionVolumes,
    };
  }

  List<PieChartSectionData> _buildTransactionDonutChartData(int? selectedIndex) {
    final Map<String, dynamic> transactionData = _calculateTransactionData();
    final Map<String, dynamic> dataToUse = _analysisType == 'count' 
        ? transactionData['counts'] 
        : transactionData['volumes'];
    
    final double total = dataToUse.values.fold(0.0, (sum, value) => sum + value);

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

    final List<MapEntry<String, dynamic>> sortedEntries = dataToUse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final transactionType = entry.value.key;
      final value = entry.value.value;
      final percentage = (value / total) * 100;

      final bool isSelected = selectedIndex == index;
      final opacity = selectedIndex != null && !isSelected ? 0.5 : 1.0;

      Color color;
      switch (transactionType) {
        case 'purchase':
          color = const Color(0xFF34C759); // Vert pour les achats
          break;
        case 'transfer':
          color = const Color(0xFF007AFF); // Bleu pour les transferts
          break;
        case 'yam':
          color = const Color(0xFFFF9500); // Orange pour YAM
          break;
        default:
          color = Colors.grey;
      }

      return PieChartSectionData(
        value: value.toDouble(),
        title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
        color: color.withValues(alpha: opacity),
        radius: isSelected ? 52 : 45,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 + Provider.of<AppState>(context).getTextSizeOffset() : 10 + Provider.of<AppState>(context).getTextSizeOffset(),
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
    final Map<String, dynamic> transactionData = _calculateTransactionData();
    final Map<String, dynamic> dataToUse = _analysisType == 'count' 
        ? transactionData['counts'] 
        : transactionData['volumes'];
    
    final double total = dataToUse.values.fold(0.0, (sum, value) => sum + value);
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
            _analysisType == 'count' 
                ? total.toStringAsFixed(0)
                : currencyUtils.getFormattedAmount(currencyUtils.convert(total), currencyUtils.currencySymbol, true),
            style: TextStyle(
              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final List<MapEntry<String, dynamic>> sortedEntries = dataToUse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (selectedIndex >= sortedEntries.length) return Container();

    final selectedEntry = sortedEntries[selectedIndex];
    final String transactionTypeName = _getTransactionTypeName(selectedEntry.key);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          transactionTypeName,
          style: TextStyle(
            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
            fontWeight: FontWeight.bold,
            color: _getTransactionTypeColor(selectedEntry.key),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _analysisType == 'count' 
              ? selectedEntry.value.toStringAsFixed(0)
              : currencyUtils.getFormattedAmount(currencyUtils.convert(selectedEntry.value), currencyUtils.currencySymbol, true),
          style: TextStyle(
            fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getTransactionTypeName(String transactionType) {
    switch (transactionType) {
      case 'purchase':
        return S.of(context).purchase;
      case 'transfer':
        return S.of(context).internal_transfer;
      case 'yam':
        return S.of(context).yam;
      default:
        return S.of(context).unknownTransaction;
    }
  }

  Color _getTransactionTypeColor(String transactionType) {
    switch (transactionType) {
      case 'purchase':
        return const Color(0xFF34C759);
      case 'transfer':
        return const Color(0xFF007AFF);
      case 'yam':
        return const Color(0xFFFF9500);
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionLegend() {
    final Map<String, dynamic> transactionData = _calculateTransactionData();
    final Map<String, dynamic> dataToUse = _analysisType == 'count' 
        ? transactionData['counts'] 
        : transactionData['volumes'];
    
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final List<MapEntry<String, dynamic>> sortedEntries = dataToUse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8.0,
      runSpacing: 3.0,
      alignment: WrapAlignment.start,
      children: sortedEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final transactionType = entry.value.key;
        final value = entry.value.value;
        final color = _getTransactionTypeColor(transactionType);
        final typeName = _getTransactionTypeName(transactionType);

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
                Text(
                  '$typeName: ${_analysisType == 'count' ? value.toStringAsFixed(0) : currencyUtils.getFormattedAmount(currencyUtils.convert(value), currencyUtils.currencySymbol, true)}',
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