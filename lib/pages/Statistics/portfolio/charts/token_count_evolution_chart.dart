import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class TokenCountEvolutionChart extends StatefulWidget {
  final DataManager dataManager;

  const TokenCountEvolutionChart({super.key, required this.dataManager});

  @override
  _TokenCountEvolutionChartState createState() => _TokenCountEvolutionChartState();
}

class _TokenCountEvolutionChartState extends State<TokenCountEvolutionChart> {
  String _selectedPeriod = 'month';
  bool _isBarChart = false;

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
                  S.of(context).tokenCountEvolution,
                  style: TextStyle(
                    fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: [
                        DropdownMenuItem(value: 'week', child: Text(S.of(context).week)),
                        DropdownMenuItem(value: 'month', child: Text(S.of(context).month)),
                        DropdownMenuItem(value: 'year', child: Text(S.of(context).year)),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isBarChart ? Icons.show_chart_rounded : Icons.bar_chart_rounded,
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
                        setState(() {
                          _isBarChart = !_isBarChart;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildTokenCountChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCountChart(BuildContext context) {
    final List<FlSpot> tokenCountData = _calculateTokenCountEvolution();
    final appState = Provider.of<AppState>(context);

    if (tokenCountData.isEmpty) {
      return Center(
        child: Text(
          S.of(context).noDataAvailable,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    if (_isBarChart) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: tokenCountData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final labels = _buildDateLabels();
                if (groupIndex < labels.length) {
                  return BarTooltipItem(
                    '${labels[groupIndex]}\n${rod.toY.toStringAsFixed(0)} tokens',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
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
                  final labels = _buildDateLabels();
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            fontSize: 10,
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
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: tokenCountData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.y,
                  color: const Color(0xFF007AFF),
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
      );
    }

    return LineChart(
      LineChartData(
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
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final labels = _buildDateLabels();
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: tokenCountData,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 3,
            color: const Color(0xFF34C759),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF34C759),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF34C759).withValues(alpha: 0.3),
                  const Color(0xFF34C759).withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                final value = touchedSpot.y;
                final labels = _buildDateLabels();
                final String periodLabel = index < labels.length ? labels[index] : '';

                return LineTooltipItem(
                  '$periodLabel\n${value.toStringAsFixed(0)} tokens',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 8,
            tooltipHorizontalOffset: 0,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.all(12),
          ),
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
        ),
      ),
    );
  }

  List<FlSpot> _calculateTokenCountEvolution() {
    // Collecter toutes les transactions avec leurs dates
    List<Map<String, dynamic>> allTransactions = [];
    
    for (var tokenTransactions in widget.dataManager.transactionsByToken.values) {
      for (var transaction in tokenTransactions) {
        final timestamp = transaction['timestamp'];
        if (timestamp != null) {
          DateTime date;
          if (timestamp is DateTime) {
            date = timestamp;
          } else if (timestamp is String) {
            try {
              date = DateTime.parse(timestamp);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }
          
          allTransactions.add({
            'date': date,
            'type': transaction['transactionType'] ?? 'unknown',
            'tokenId': transaction['tokenId'] ?? '',
          });
        }
      }
    }

    // Trier par date
    allTransactions.sort((a, b) => a['date'].compareTo(b['date']));

    if (allTransactions.isEmpty) {
      return [];
    }

    // Grouper par période
    Map<String, Set<String>> tokensByPeriod = {};
    Set<String> cumulativeTokens = {};

    for (var transaction in allTransactions) {
      final DateTime date = transaction['date'];
      final String tokenId = transaction['tokenId'];
      final String type = transaction['type'];
      
      String periodKey;
      if (_selectedPeriod == 'week') {
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        periodKey = DateFormat('yyyy-MM-dd').format(weekStart);
      } else if (_selectedPeriod == 'month') {
        periodKey = DateFormat('yyyy-MM').format(date);
      } else {
        periodKey = date.year.toString();
      }

      // Ajouter le token aux tokens cumulatifs si c'est un achat
      if (type == 'purchase' || type == 'transfer') {
        cumulativeTokens.add(tokenId);
      }

      tokensByPeriod[periodKey] = Set.from(cumulativeTokens);
    }

    // Convertir en FlSpot
    final sortedPeriods = tokensByPeriod.keys.toList()..sort();
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i];
      final tokenCount = tokensByPeriod[period]?.length ?? 0;
      spots.add(FlSpot(i.toDouble(), tokenCount.toDouble()));
    }

    return spots;
  }

  List<String> _buildDateLabels() {
    List<Map<String, dynamic>> allTransactions = [];
    
    for (var tokenTransactions in widget.dataManager.transactionsByToken.values) {
      for (var transaction in tokenTransactions) {
        final timestamp = transaction['timestamp'];
        if (timestamp != null) {
          DateTime date;
          if (timestamp is DateTime) {
            date = timestamp;
          } else if (timestamp is String) {
            try {
              date = DateTime.parse(timestamp);
            } catch (e) {
              continue;
            }
          } else {
            continue;
          }
          
          allTransactions.add({
            'date': date,
            'type': transaction['transactionType'] ?? 'unknown',
            'tokenId': transaction['tokenId'] ?? '',
          });
        }
      }
    }

    allTransactions.sort((a, b) => a['date'].compareTo(b['date']));

    if (allTransactions.isEmpty) {
      return [];
    }

    Map<String, Set<String>> tokensByPeriod = {};
    Set<String> cumulativeTokens = {};

    for (var transaction in allTransactions) {
      final DateTime date = transaction['date'];
      final String tokenId = transaction['tokenId'];
      final String type = transaction['type'];
      
      String periodKey;
      if (_selectedPeriod == 'week') {
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        periodKey = DateFormat('MM/dd').format(weekStart);
      } else if (_selectedPeriod == 'month') {
        periodKey = DateFormat('MM/yy').format(date);
      } else {
        periodKey = date.year.toString();
      }

      if (type == 'purchase' || type == 'transfer') {
        cumulativeTokens.add(tokenId);
      }

      tokensByPeriod[periodKey] = Set.from(cumulativeTokens);
    }

    return tokensByPeriod.keys.toList()..sort();
  }
} 