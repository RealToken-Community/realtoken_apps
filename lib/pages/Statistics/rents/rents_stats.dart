import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rent_distribution_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rent_distribution_by_product_type_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rented_graph.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/wallet/charts/rent_graph.dart';

import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RentsStats extends StatefulWidget {
  const RentsStats({super.key});

  @override
  _RentsStatsState createState() => _RentsStatsState();
}

class _RentsStatsState extends State<RentsStats> {
  late String _selectedPeriod;
  late String _selectedRentPeriod;
  
  String _selectedRentTimeRange = 'all';
  
  bool _rentedIsBarChart = true;
  bool rentIsBarChart = false;
  bool showCumulativeRent = false;
  
  late SharedPreferences prefs;
  
  int _rentTimeOffset = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();

      setState(() {
        // Charger les types de graphiques
        rentIsBarChart = prefs.getBool('rentIsBarChart') ?? false;
        showCumulativeRent = prefs.getBool('showCumulativeRent') ?? false;
        _rentedIsBarChart = prefs.getBool('rentedIsBarChart') ?? true;
        
        // Charger les périodes sélectionnées
        _selectedRentPeriod = prefs.getString('rentPeriod') ?? S.of(context).week;
        
        // Charger les plages de temps
        _selectedRentTimeRange = prefs.getString('rentTimeRange') ?? 'all';
        
        // Charger les offsets
        _rentTimeOffset = prefs.getInt('rentTimeOffset') ?? 0;
      });

      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);
        
        if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && 
            dataManager.portfolio.isNotEmpty && dataManager.rentHistory.isNotEmpty) {
          debugPrint("📊 RentsStats: données déjà chargées, skip chargement");
        } else {
          debugPrint("📊 RentsStats: chargement des données nécessaire");
          await DataFetchUtils.loadDataWithCache(context);
        }
      } catch (e, stacktrace) {
        debugPrint("Error during initState: $e");
        debugPrint("Stacktrace: $stacktrace");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedPeriod = S.of(context).month;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isWideScreen = screenWidth > 700;
        final double fixedCardHeight = 380;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 80.0, left: 8.0, right: 8.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWideScreen ? 2 : 1,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    mainAxisExtent: fixedCardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (!mounted) return const SizedBox.shrink();
                      
                      return _buildChartWidget(context, index, dataManager);
                    },
                    childCount: 4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartWidget(BuildContext context, int index, DataManager dataManager) {
    try {
      switch (index) {
        case 0:
          return RentGraph(
            key: const ValueKey('rent_graph'),
            groupedData: [],
            dataManager: dataManager,
            showCumulativeRent: showCumulativeRent,
            selectedPeriod: _selectedRentPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedRentPeriod = period;
                _savePeriodPreference('rentPeriod', period);
              });
            },
            onCumulativeRentChanged: (value) {
              setState(() {
                showCumulativeRent = value;
                _saveChartPreference('showCumulativeRent', showCumulativeRent);
              });
            },
            selectedTimeRange: _selectedRentTimeRange,
            onTimeRangeChanged: (newRange) {
              setState(() {
                _selectedRentTimeRange = newRange;
                _saveTimeRangePreference('rentTimeRange', newRange);
                _rentTimeOffset = 0;
                _saveTimeOffsetPreference('rentTimeOffset', 0);
              });
            },
            timeOffset: _rentTimeOffset,
            onTimeOffsetChanged: (newOffset) {
              setState(() {
                _rentTimeOffset = newOffset;
                _saveTimeOffsetPreference('rentTimeOffset', newOffset);
              });
            },
            rentIsBarChart: rentIsBarChart,
            onChartTypeChanged: (isBarChart) {
              setState(() {
                rentIsBarChart = isBarChart;
                _saveChartPreference('rentIsBarChart', rentIsBarChart);
              });
            },
          );
        case 1:
          return RentedHistoryGraph(
            key: const ValueKey('rented_history_graph'),
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              if (mounted) {
                setState(() {
                  _selectedPeriod = period;
                });
              }
            },
            rentedIsBarChart: _rentedIsBarChart,
            onChartTypeChanged: (isBarChart) {
              if (mounted) {
                setState(() {
                  _rentedIsBarChart = isBarChart;
                  prefs.setBool('rentedIsBarChart', isBarChart);
                });
              }
            },
          );
        case 2:
          return RentDistributionChart(
            key: const ValueKey('rent_distribution_chart'),
            dataManager: dataManager,
          );
        case 3:
          return RentDistributionByProductTypeChart(
            key: const ValueKey('rent_distribution_by_product_type_chart'),
            dataManager: dataManager,
          );
        default:
          return const SizedBox.shrink();
      }
    } catch (e) {
      debugPrint("Error building chart widget at index $index: $e");
      return SizedBox(
        height: 380,
        child: const Center(
          child: Text("Erreur de chargement du graphique"),
        ),
      );
    }
  }

  void _savePeriodPreference(String key, String value) {
    prefs.setString(key, value);
  }

  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }

  void _saveTimeRangePreference(String key, String value) {
    prefs.setString(key, value);
  }

  void _saveTimeOffsetPreference(String key, int value) {
    prefs.setInt(key, value);
  }
} 