import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rent_distribution_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rent_distribution_by_product_type_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rented_graph.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_city_card.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_country_card.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_region_card.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_wallet_card.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/roi_by_token_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_count_evolution_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/performance_by_region_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/rental_status_distribution_chart.dart';
import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class PortfolioStats extends StatefulWidget {
  const PortfolioStats({super.key});

  @override
  _PortfolioStats createState() => _PortfolioStats();
}

class _PortfolioStats extends State<PortfolioStats> {
  late String _selectedPeriod;
  late String _selectedFilter;
  bool _rentedIsBarChart = true; // Ajoutez cette variable pour gérer le type de graphique

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Region';
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        // Vérifier si les données sont déjà disponibles
        final dataManager = Provider.of<DataManager>(context, listen: false);
        
        if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && 
            dataManager.portfolio.isNotEmpty && dataManager.rentHistory.isNotEmpty) {
          debugPrint("📊 Stats: données déjà chargées, skip chargement");
        } else {
          debugPrint("📊 Stats: chargement des données nécessaire");
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
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
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
                      // Vérification de sécurité pour éviter les erreurs de renderObject
                      if (!mounted) return const SizedBox.shrink();
                      
                      return _buildChartWidget(context, index, dataManager);
                    },
                    childCount: 12,
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
                });
              }
            },
          );
        case 1:
          return RentDistributionChart(
            key: const ValueKey('rent_distribution_chart'),
            dataManager: dataManager,
          );
        case 2:
          return RentDistributionByProductTypeChart(
            key: const ValueKey('rent_distribution_by_product_type_chart'),
            dataManager: dataManager,
          );
        case 3:
          return TokenDistributionCard(
            key: const ValueKey('token_distribution_card'),
            dataManager: dataManager,
          );
        case 4:
          return TokenDistributionByCountryCard(
            key: const ValueKey('token_distribution_by_country_card'),
            dataManager: dataManager,
          );
        case 5:
          return TokenDistributionByRegionCard(
            key: const ValueKey('token_distribution_by_region_card'),
            dataManager: dataManager,
          );
        case 6:
          return TokenDistributionByCityCard(
            key: const ValueKey('token_distribution_by_city_card'),
            dataManager: dataManager,
          );
        case 7:
          return TokenDistributionByWalletCard(
            key: const ValueKey('token_distribution_by_wallet_card'),
            dataManager: dataManager,
          );
        case 8:
          return RoiByTokenChart(
            key: const ValueKey('roi_by_token_chart'),
            dataManager: dataManager,
          );
        case 9:
          return TokenCountEvolutionChart(
            key: const ValueKey('token_count_evolution_chart'),
            dataManager: dataManager,
          );
        case 10:
          return PerformanceByRegionChart(
            key: const ValueKey('performance_by_region_chart'),
            dataManager: dataManager,
          );
        case 11:
          return RentalStatusDistributionChart(
            key: const ValueKey('rental_status_distribution_chart'),
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
}
