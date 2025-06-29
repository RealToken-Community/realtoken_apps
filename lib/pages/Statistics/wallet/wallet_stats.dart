import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import des fichiers de graphiques
import 'charts/wallet_balance_graph.dart';
import 'charts/rent_distribution_by_wallet_chart.dart';
import 'charts/token_distribution_by_product_type_chart.dart';
import 'charts/roi_graph.dart';
import 'charts/apy_graph.dart';
import 'charts/transaction_analysis_chart.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/portfolio/charts/token_distribution_by_wallet_card.dart';

class WalletStats extends StatefulWidget {
  const WalletStats({super.key});

  @override
  _WalletStats createState() => _WalletStats();
}

class _WalletStats extends State<WalletStats> {
  late String _selectedWalletPeriod;
  late String _selectedRoiPeriod;
  late String _selectedApyPeriod;
  String _selectedWalletTimeRange = 'all';
  String _selectedRoiTimeRange = 'all';
  String _selectedApyTimeRange = 'all';

  bool walletIsBarChart = false;
  bool roiIsBarChart = false;
  bool apyIsBarChart = true;
  late SharedPreferences prefs;

  int _walletTimeOffset = 0;
  int _roiTimeOffset = 0;
  int _apyTimeOffset = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();

      setState(() {
        // Charger les types de graphiques
        walletIsBarChart = prefs.getBool('walletIsBarChart') ?? false;
        roiIsBarChart = prefs.getBool('roiIsBarChart') ?? false;
        apyIsBarChart = prefs.getBool('apyIsBarChart') ?? true;

        // Charger les périodes sélectionnées
        _selectedWalletPeriod =
            prefs.getString('walletPeriod') ?? S.of(context).week;
        _selectedRoiPeriod = prefs.getString('roiPeriod') ?? S.of(context).week;
        _selectedApyPeriod = prefs.getString('apyPeriod') ?? S.of(context).week;

        // Charger les plages de temps
        _selectedWalletTimeRange = prefs.getString('walletTimeRange') ?? 'all';
        _selectedRoiTimeRange = prefs.getString('roiTimeRange') ?? 'all';
        _selectedApyTimeRange = prefs.getString('apyTimeRange') ?? 'all';

        // Charger les offsets
        _walletTimeOffset = prefs.getInt('walletTimeOffset') ?? 0;
        _roiTimeOffset = prefs.getInt('roiTimeOffset') ?? 0;
        _apyTimeOffset = prefs.getInt('apyTimeOffset') ?? 0;
      });

      try {
        final dataManager = Provider.of<DataManager>(context, listen: false);

        // Vérifier si les données sont déjà disponibles
        if (!dataManager.isLoadingMain &&
            dataManager.evmAddresses.isNotEmpty &&
            dataManager.walletBalanceHistory.isNotEmpty) {
          debugPrint("📈 WalletStats: données déjà chargées, skip chargement");
        } else {
          debugPrint("📈 WalletStats: chargement des données nécessaire");
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
    // Ne pas initialiser les périodes ici car elles sont chargées depuis les préférences
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 700;
    final double fixedCardHeight = 380;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
              top: 8.0, bottom: 80.0, left: 8.0, right: 8.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWideScreen ? 2 : 1,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              mainAxisExtent: fixedCardHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                switch (index) {
                  case 0:
                    return TokenDistributionByWalletCard(
                      key: const ValueKey('token_distribution_by_wallet_card'),
                      dataManager: dataManager,
                    );
                  case 1:
                    return RentDistributionByWalletChart(
                      key: const ValueKey('rent_distribution_by_wallet_chart'),
                      dataManager: dataManager,
                    );
                  case 2:
                    return TokenDistributionByProductTypeChart(
                      key: const ValueKey(
                          'token_distribution_by_product_type_chart'),
                      dataManager: dataManager,
                    );
                  case 3:
                    return WalletBalanceGraph(
                      key: const ValueKey('wallet_balance_graph'),
                      selectedPeriod: _selectedWalletPeriod,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedWalletPeriod = period;
                          _savePeriodPreference('walletPeriod', period);
                        });
                      },
                      balanceIsBarChart: walletIsBarChart,
                      onChartTypeChanged: (isBarChart) {
                        setState(() {
                          walletIsBarChart = isBarChart;
                          _saveChartPreference(
                              'walletIsBarChart', walletIsBarChart);
                        });
                      },
                      selectedTimeRange: _selectedWalletTimeRange,
                      onTimeRangeChanged: (newRange) {
                        setState(() {
                          _selectedWalletTimeRange = newRange;
                          _saveTimeRangePreference('walletTimeRange', newRange);
                          _walletTimeOffset = 0;
                          _saveTimeOffsetPreference('walletTimeOffset', 0);
                        });
                      },
                      timeOffset: _walletTimeOffset,
                      onTimeOffsetChanged: (newOffset) {
                        setState(() {
                          _walletTimeOffset = newOffset;
                          _saveTimeOffsetPreference(
                              'walletTimeOffset', newOffset);
                        });
                      },
                    );
                  case 4:
                    return RoiHistoryGraph(
                      key: const ValueKey('roi_graph'),
                      selectedPeriod: _selectedRoiPeriod,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedRoiPeriod = period;
                          _savePeriodPreference('roiPeriod', period);
                        });
                      },
                      roiIsBarChart: roiIsBarChart,
                      onChartTypeChanged: (isBarChart) {
                        setState(() {
                          roiIsBarChart = isBarChart;
                          _saveChartPreference('roiIsBarChart', roiIsBarChart);
                        });
                      },
                      selectedTimeRange: _selectedRoiTimeRange,
                      onTimeRangeChanged: (newRange) {
                        setState(() {
                          _selectedRoiTimeRange = newRange;
                          _saveTimeRangePreference('roiTimeRange', newRange);
                          _roiTimeOffset = 0;
                          _saveTimeOffsetPreference('roiTimeOffset', 0);
                        });
                      },
                      timeOffset: _roiTimeOffset,
                      onTimeOffsetChanged: (newOffset) {
                        setState(() {
                          _roiTimeOffset = newOffset;
                          _saveTimeOffsetPreference('roiTimeOffset', newOffset);
                        });
                      },
                    );
                  case 5:
                    return ApyHistoryGraph(
                      key: const ValueKey('apy_graph'),
                      dataManager: dataManager,
                      selectedPeriod: _selectedApyPeriod,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedApyPeriod = period;
                          _savePeriodPreference('apyPeriod', period);
                        });
                      },
                      apyIsBarChart: apyIsBarChart,
                      onChartTypeChanged: (isBarChart) {
                        setState(() {
                          apyIsBarChart = isBarChart;
                          _saveChartPreference('apyIsBarChart', apyIsBarChart);
                        });
                      },
                      selectedTimeRange: _selectedApyTimeRange,
                      onTimeRangeChanged: (newRange) {
                        setState(() {
                          _selectedApyTimeRange = newRange;
                          _saveTimeRangePreference('apyTimeRange', newRange);
                          _apyTimeOffset = 0;
                          _saveTimeOffsetPreference('apyTimeOffset', 0);
                        });
                      },
                      timeOffset: _apyTimeOffset,
                      onTimeOffsetChanged: (newOffset) {
                        setState(() {
                          _apyTimeOffset = newOffset;
                          _saveTimeOffsetPreference('apyTimeOffset', newOffset);
                        });
                      },
                    );
                  case 6:
                    return TransactionAnalysisChart(
                      key: const ValueKey('transaction_analysis_chart'),
                      dataManager: dataManager,
                    );
                  default:
                    return Container();
                }
              },
              childCount: 7,
            ),
          ),
        ),
      ],
    );
  }

  // Méthodes pour sauvegarder les différentes préférences
  void _saveChartPreference(String key, bool value) {
    prefs.setBool(key, value);
  }

  void _savePeriodPreference(String key, String value) {
    prefs.setString(key, value);
  }

  void _saveTimeRangePreference(String key, String value) {
    prefs.setString(key, value);
  }

  void _saveTimeOffsetPreference(String key, int value) {
    prefs.setInt(key, value);
  }
}
