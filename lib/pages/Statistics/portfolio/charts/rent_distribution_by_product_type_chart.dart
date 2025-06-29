import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class RentDistributionByProductTypeChart extends StatefulWidget {
  final DataManager dataManager;

  const RentDistributionByProductTypeChart({
    super.key,
    required this.dataManager,
  });

  @override
  State<RentDistributionByProductTypeChart> createState() => _RentDistributionByProductTypeChartState();
}

class _RentDistributionByProductTypeChartState extends State<RentDistributionByProductTypeChart> {
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
              S.of(context).rentDistributionByProductType,
              style: TextStyle(
                fontSize: 20 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ValueListenableBuilder<int?>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, child) {
                  return _buildRentDistributionChart(selectedIndex);
                },
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: _buildInteractiveLegend(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateRentByProductType() {
    Map<String, double> rentByProductType = {};
    
    for (var token in widget.dataManager.portfolio) {
      final String productType = token['productType'] ?? 'other';
      final double totalRentReceived = (token['totalRentReceived'] ?? 0.0).toDouble();
      
      if (totalRentReceived > 0) {
        rentByProductType[productType] = (rentByProductType[productType] ?? 0.0) + totalRentReceived;
      }
    }
    
    return rentByProductType;
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

  List<Color> _getColors() {
    return [
      const Color(0xFF4285F4), // Bleu
      const Color(0xFF34A853), // Vert
      const Color(0xFFEA4335), // Rouge
      const Color(0xFFFBBC04), // Jaune
      const Color(0xFF9C27B0), // Violet
      const Color(0xFFFF9800), // Orange
      const Color(0xFF607D8B), // Bleu-gris
      const Color(0xFF795548), // Marron
      const Color(0xFFE91E63), // Rose
      const Color(0xFF00BCD4), // Cyan
    ];
  }

  Widget _buildRentDistributionChart(int? selectedIndex) {
    final Map<String, double> rentByProductType = _calculateRentByProductType();
    
    if (rentByProductType.isEmpty) {
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

    final List<Color> colors = _getColors();
    final double total = rentByProductType.values.fold(0.0, (sum, value) => sum + value);
    
    List<MapEntry<String, double>> sortedData = rentByProductType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        sections: sortedData.asMap().entries.map((entry) {
          final int index = entry.key;
          final double value = entry.value.value;
          final double percentage = (value / total) * 100;
          final bool isSelected = selectedIndex == index;
          
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: percentage,
            title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: isSelected ? 70 : 60,
            titleStyle: TextStyle(
              fontSize: isSelected ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
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
    );
  }

  Widget _buildInteractiveLegend() {
    final Map<String, double> rentByProductType = _calculateRentByProductType();
    final appState = Provider.of<AppState>(context);
    
    if (rentByProductType.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Color> colors = _getColors();
    final double total = rentByProductType.values.fold(0.0, (sum, value) => sum + value);
    
    List<MapEntry<String, double>> sortedData = rentByProductType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                     ...sortedData.asMap().entries.map((entry) {
             final int index = entry.key;
             final String productType = entry.value.key;
             final double percentage = (entry.value.value / total) * 100;
            
            return ValueListenableBuilder<int?>(
              valueListenable: _selectedIndexNotifier,
              builder: (context, selectedIndex, child) {
                final bool isSelected = selectedIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    _selectedIndexNotifier.value = isSelected ? null : index;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected 
                                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getLocalizedProductTypeName(context, productType),
                            style: TextStyle(
                              fontSize: 13 + appState.getTextSizeOffset(),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      );
  }
} 