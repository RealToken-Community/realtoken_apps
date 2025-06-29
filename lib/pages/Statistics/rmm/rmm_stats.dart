import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/managers/archive_manager.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/models/balance_record.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/rmm/borrow_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/rmm/deposit_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/rmm/healthFactorLtv_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RmmStats extends StatefulWidget {
  const RmmStats({super.key});

  @override
  RmmStatsState createState() => RmmStatsState();
}

class RmmStatsState extends State<RmmStats> {
  String selectedDepositPeriod = '';
  String selectedBorrowPeriod = '';
  String selectedHealthAndLtvPeriod = '';
  late String _selectedHealthAndLtvPeriod;
  final ArchiveManager _archiveManager = ArchiveManager();
  final DataManager _dataManager = DataManager();

  late SharedPreferences prefs;

  bool healthAndLtvIsBarChart = true;

  // Nouvelles variables pour les options de graphique
  String selectedDepositTimeRange = 'all';
  int depositTimeOffset = 0;
  bool isDepositBarChart = false;
  
  String selectedBorrowTimeRange = 'all';
  int borrowTimeOffset = 0;
  bool isBorrowBarChart = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      // Charger la préférence stockée, si elle existe, sinon utiliser true par défaut
      healthAndLtvIsBarChart = prefs.getBool('healthAndLtvIsBarChart') ?? true;
      
      // Initialiser les nouvelles options
      selectedDepositPeriod = prefs.getString('selectedDepositPeriod') ?? S.of(context).month;
      selectedBorrowPeriod = prefs.getString('selectedBorrowPeriod') ?? S.of(context).month;
      
      isDepositBarChart = prefs.getBool('isDepositBarChart') ?? false;
      selectedDepositTimeRange = prefs.getString('selectedDepositTimeRange') ?? 'all';
      depositTimeOffset = prefs.getInt('depositTimeOffset') ?? 0;
      
      isBorrowBarChart = prefs.getBool('isBorrowBarChart') ?? false;
      selectedBorrowTimeRange = prefs.getString('selectedBorrowTimeRange') ?? 'all';
      borrowTimeOffset = prefs.getInt('borrowTimeOffset') ?? 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedDepositPeriod.isEmpty) {
      selectedDepositPeriod = S.of(context).week;
    }
    if (selectedBorrowPeriod.isEmpty) {
      selectedBorrowPeriod = S.of(context).week;
    }
    if (selectedHealthAndLtvPeriod.isEmpty) {
      selectedHealthAndLtvPeriod = S.of(context).week;
    }

    _selectedHealthAndLtvPeriod = S.of(context).week;
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const double fixedCardHeight = 380;

    return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildApyCard(dataManager, screenWidth),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 80),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 700 ? 2 : 1,
                mainAxisExtent: fixedCardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  switch (index) {
                    case 0:
                      return _buildDepositBalanceCard(dataManager, 380);
                    case 1:
                      return _buildBorrowBalanceCard(dataManager, 380);
                    case 2:
                      return _buildHealthAndLtvHistoryCard(dataManager);

                    default:
                      return Container();
                  }
                },
                childCount: 3,
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildHealthAndLtvHistoryCard(DataManager dataManager) {
    return SizedBox(
      height: 380,
      child: HealthAndLtvHistoryGraph(
        dataManager: dataManager,
        selectedPeriod: selectedHealthAndLtvPeriod,
        healthAndLtvIsBarChart: healthAndLtvIsBarChart,
        onPeriodChanged: (newPeriod) {
          setState(() {
            selectedHealthAndLtvPeriod = newPeriod;
          });
        },
        onChartTypeChanged: (isBarChart) {
          setState(() {
            healthAndLtvIsBarChart = isBarChart;
            prefs.setBool('healthAndLtvIsBarChart', isBarChart);
          });
        },
      ),
    );
  }

  Widget _buildApyCard(DataManager dataManager, double screenWidth) {
    return Card(
      elevation: 0.2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(S.of(context).averageApy),
                      content: const Text(
                        'L\'APY moyen est calculé en moyenne sur les variations de balance entre plusieurs paires de données. '
                        'Les valeurs avec des variations anormales (dépôts ou retraits) sont écartées.',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).averageApy,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dataManager.apyAverage.isNaN ? "0" : dataManager.apyAverage.toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildApyTable(dataManager),
          ],
        ),
      ),
    );
  }

  Widget _buildApyTable(DataManager dataManager) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final valueStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              SizedBox(width: 80, child: Container()),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Image.asset('assets/icons/usdc.png', width: 22, height: 22),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Image.asset('assets/icons/xdai.png', width: 22, height: 22),
                ),
              ),
            ],
          ),

          // Ligne de séparation
          Divider(height: 0, thickness: 0.5, color: Theme.of(context).dividerColor.withOpacity(0.1)),

          // Ligne Deposit
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: Text('Deposit', style: textStyle),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${dataManager.usdcDepositApy.toInt()}%',
                    style: valueStyle.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${dataManager.xdaiDepositApy.toInt()}%',
                    style: valueStyle.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Ligne de séparation
          Divider(height: 0, thickness: 0.5, color: Theme.of(context).dividerColor.withOpacity(0.1)),

          // Ligne Borrow
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: Text('Borrow', style: textStyle),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${dataManager.usdcBorrowApy.toInt()}%',
                    style: valueStyle.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${dataManager.xdaiBorrowApy.toInt()}%',
                    style: valueStyle.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositBalanceCard(DataManager dataManager, double cardHeight) {
    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(dataManager, selectedDepositPeriod),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return DepositChart(
                        allHistories: allHistories,
                        selectedPeriod: selectedDepositPeriod,
                        onPeriodChanged: (newPeriod) {
                          setState(() {
                            selectedDepositPeriod = newPeriod;
                            prefs.setString('selectedDepositPeriod', newPeriod);
                          });
                        },
                        isBarChart: isDepositBarChart,
                        onChartTypeChanged: (isBar) {
                          setState(() {
                            isDepositBarChart = isBar;
                            prefs.setBool('isDepositBarChart', isBar);
                          });
                        },
                        selectedTimeRange: selectedDepositTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            selectedDepositTimeRange = newRange;
                            depositTimeOffset = 0; // Réinitialiser l'offset lors du changement de plage
                            prefs.setString('selectedDepositTimeRange', newRange);
                            prefs.setInt('depositTimeOffset', 0);
                          });
                        },
                        timeOffset: depositTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            depositTimeOffset = newOffset;
                            prefs.setInt('depositTimeOffset', newOffset);
                          });
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, List<BalanceRecord>>> _fetchAndAggregateBalanceHistories(DataManager dataManager, String selectedPeriod) async {
    Map<String, List<BalanceRecord>> allHistories = {};

    allHistories['usdcDeposit'] = await _archiveManager.getBalanceHistory('usdcDeposit');
    allHistories['usdcBorrow'] = await _archiveManager.getBalanceHistory('usdcBorrow');
    allHistories['xdaiDeposit'] = await _archiveManager.getBalanceHistory('xdaiDeposit');
    allHistories['xdaiBorrow'] = await _archiveManager.getBalanceHistory('xdaiBorrow');

    for (String tokenType in allHistories.keys) {
      allHistories[tokenType] = await _aggregateByPeriod(allHistories[tokenType]!, selectedPeriod);
    }

    return allHistories;
  }

  Future<List<BalanceRecord>> _aggregateByPeriod(List<BalanceRecord> records, String period) async {
    Map<DateTime, List<double>> groupedByPeriod = {};

    for (var record in records) {
      DateTime truncatedToPeriod;

      if (period == S.of(context).day) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
      } else if (period == S.of(context).week) {
        final date = record.timestamp;
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        truncatedToPeriod = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
      } else if (period == S.of(context).month) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
        );
      } else if (period == S.of(context).year) {
        truncatedToPeriod = DateTime(
          record.timestamp.year,
        );
      } else {
        // Valeur par défaut (ici on considère le jour)
        truncatedToPeriod = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
      }

      groupedByPeriod.putIfAbsent(truncatedToPeriod, () => []).add(record.balance);
    }

    List<BalanceRecord> averagedRecords = [];
    groupedByPeriod.forEach((timestamp, balances) {
      double averageBalance = balances.reduce((a, b) => a + b) / balances.length;
      averagedRecords.add(BalanceRecord(
        tokenType: records.first.tokenType,
        balance: averageBalance,
        timestamp: timestamp,
      ));
    });

    return averagedRecords;
  }

  Widget _buildBorrowBalanceCard(DataManager dataManager, double cardHeight) {
    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FutureBuilder<Map<String, List<BalanceRecord>>>(
                  future: _fetchAndAggregateBalanceHistories(dataManager, selectedBorrowPeriod),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Pas de données disponibles.');
                    } else {
                      final allHistories = snapshot.data!;
                      return BorrowChart(
                        allHistories: allHistories,
                        selectedPeriod: selectedBorrowPeriod,
                        onPeriodChanged: (newPeriod) {
                          setState(() {
                            selectedBorrowPeriod = newPeriod;
                            prefs.setString('selectedBorrowPeriod', newPeriod);
                          });
                        },
                        isBarChart: isBorrowBarChart,
                        onChartTypeChanged: (isBar) {
                          setState(() {
                            isBorrowBarChart = isBar;
                            prefs.setBool('isBorrowBarChart', isBar);
                          });
                        },
                        selectedTimeRange: selectedBorrowTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            selectedBorrowTimeRange = newRange;
                            borrowTimeOffset = 0; // Réinitialiser l'offset lors du changement de plage
                            prefs.setString('selectedBorrowTimeRange', newRange);
                            prefs.setInt('borrowTimeOffset', 0);
                          });
                        },
                        timeOffset: borrowTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            borrowTimeOffset = newOffset;
                            prefs.setInt('borrowTimeOffset', newOffset);
                          });
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }
}
