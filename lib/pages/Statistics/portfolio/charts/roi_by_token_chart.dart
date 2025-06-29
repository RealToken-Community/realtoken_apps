import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

class RoiByTokenChart extends StatefulWidget {
  final DataManager dataManager;

  const RoiByTokenChart({super.key, required this.dataManager});

  @override
  _RoiByTokenChartState createState() => _RoiByTokenChartState();
}

class _RoiByTokenChartState extends State<RoiByTokenChart> {
  bool _showTopOnly = true; // Afficher seulement le top 10 par défaut
  String _sortBy = 'roi'; // 'roi' ou 'rent'

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
            Row(
              children: [
                Text(
                  S.of(context).roiByToken,
                  style: TextStyle(
                    fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20.0,
                    color: Theme.of(context).primaryColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _showFilterModal(context, appState);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildRoiChart(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
                    child: Text(
                      S.of(context).filterOptions,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.filter_list_rounded,
                      color: const Color(0xFF007AFF),
                      size: 28,
                    ),
                    title: Text(
                      _showTopOnly ? S.of(context).showTop10 : S.of(context).showAll,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Switch(
                      value: _showTopOnly,
                      onChanged: (value) {
                        setModalState(() {
                          _showTopOnly = value;
                        });
                        setState(() {
                          _showTopOnly = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.sort_rounded,
                      color: const Color(0xFF34C759),
                      size: 28,
                    ),
                    title: Text(
                      S.of(context).sortBy,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: _sortBy,
                      items: [
                        DropdownMenuItem(value: 'roi', child: Text('ROI')),
                        DropdownMenuItem(value: 'rent', child: Text(S.of(context).totalRent)),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setModalState(() {
                            _sortBy = value;
                          });
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoiChart(BuildContext context) {
    final List<Map<String, dynamic>> roiData = _calculateRoiData();
    
    if (roiData.isEmpty) {
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

    return SingleChildScrollView(
      child: SizedBox(
        height: roiData.length * 50.0 + 50, // Hauteur dynamique
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: roiData.isNotEmpty ? roiData.first['roi'] * 1.1 : 100,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final token = roiData[groupIndex];
                  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
                  return BarTooltipItem(
                    '${token['shortName']}\nROI: ${token['roi'].toStringAsFixed(2)}%\n${S.of(context).totalRent}: ${currencyUtils.getFormattedAmount(currencyUtils.convert(token['totalRent']), currencyUtils.currencySymbol, true)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(12),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value.toInt() >= 0 && value.toInt() < roiData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            roiData[value.toInt()]['shortName'],
                            style: TextStyle(
                              fontSize: 10 + Provider.of<AppState>(context).getTextSizeOffset(),
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '${value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10 + Provider.of<AppState>(context).getTextSizeOffset(),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: roiData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final roi = data['roi'];
              
              Color barColor;
              if (roi >= 10) {
                barColor = const Color(0xFF34C759); // Vert pour ROI élevé
              } else if (roi >= 5) {
                barColor = const Color(0xFFFBBC04); // Jaune pour ROI moyen
              } else if (roi >= 0) {
                barColor = const Color(0xFFFF9500); // Orange pour ROI faible
              } else {
                barColor = const Color(0xFFEA4335); // Rouge pour ROI négatif
              }

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: roi > 0 ? roi : 0.1, // Minimum pour la visibilité
                    color: barColor,
                    width: 16,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateRoiData() {
    List<Map<String, dynamic>> roiData = [];

    for (var token in widget.dataManager.portfolio) {
      final double totalRentReceived = (token['totalRentReceived'] ?? 0.0).toDouble();
      final double initialTotalValue = (token['initialTotalValue'] ?? 0.0).toDouble();
      
      // Calculer le ROI seulement si on a un investissement initial
      if (initialTotalValue > 0.001) {
        final double roi = (totalRentReceived / initialTotalValue) * 100;
        
        roiData.add({
          'shortName': token['shortName'] ?? 'Unknown',
          'fullName': token['fullName'] ?? 'Unknown',
          'roi': roi,
          'totalRent': totalRentReceived,
          'initialValue': initialTotalValue,
        });
      }
    }

    // Trier selon le critère sélectionné
    if (_sortBy == 'roi') {
      roiData.sort((a, b) => b['roi'].compareTo(a['roi']));
    } else {
      roiData.sort((a, b) => b['totalRent'].compareTo(a['totalRent']));
    }

    // Limiter au top 10 si demandé
    if (_showTopOnly && roiData.length > 10) {
      roiData = roiData.take(10).toList();
    }

    return roiData;
  }
} 