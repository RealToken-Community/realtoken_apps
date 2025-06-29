import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/wallet/charts/rent_graph.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class DashboardRentsDetailsPage extends StatefulWidget {
  const DashboardRentsDetailsPage({super.key});

  @override
  _DashboardRentsDetailsPageState createState() => _DashboardRentsDetailsPageState();
}

class _DashboardRentsDetailsPageState extends State<DashboardRentsDetailsPage> with SingleTickerProviderStateMixin {
  bool _isGraphVisible = true;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Ajout des variables d'état pour les filtres du graphique
  late String _selectedRentPeriod;
  String _selectedRentTimeRange = 'all';
  int _rentTimeOffset = 0;
  bool rentIsBarChart = false;
  bool showCumulativeRent = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Initialiser la période par défaut
    _selectedRentPeriod = 'Mois'; // ou S.of(context).month si besoin de la traduction
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _isGraphVisible) {
      setState(() {
        _isGraphVisible = false;
        _animationController.forward();
      });
    } else if (_scrollController.offset <= 50 && !_isGraphVisible) {
      setState(() {
        _isGraphVisible = true;
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Détails des loyers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/icons/excel.png',
                width: 20,
                height: 20,
              ),
            ),
            onPressed: () async {
              if (dataManager.rentData.isNotEmpty) {
                final csvData = _generateCSV(dataManager.rentData, currencyUtils);
                final fileName = 'rents_${_getFormattedToday()}.csv';
                final directory = await getTemporaryDirectory();
                final filePath = '${directory.path}/$fileName';
                final file = File(filePath);
                await file.writeAsString(csvData);
                await Share.shareXFiles(
                  [XFile(filePath)],
                  sharePositionOrigin: Rect.fromCenter(
                    center: MediaQuery.of(context).size.center(Offset.zero),
                    width: 100,
                    height: 100,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aucune donnée de loyer à partager.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(10),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dataManager.rentData.isEmpty
          ? Center(
              child: Text(
                'Aucune donnée de loyer disponible.',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
              slivers: [
                // Section graphique avec animation
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return SizedBox(
                        height: 380 * _animation.value,
                        child: Opacity(
                          opacity: _animation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: RentGraph(
                        groupedData: [],
                        dataManager: dataManager,
                        showCumulativeRent: showCumulativeRent,
                        selectedPeriod: _selectedRentPeriod,
                        onPeriodChanged: (period) {
                          setState(() {
                            _selectedRentPeriod = period;
                          });
                        },
                        onCumulativeRentChanged: (value) {
                          setState(() {
                            showCumulativeRent = value;
                          });
                        },
                        selectedTimeRange: _selectedRentTimeRange,
                        onTimeRangeChanged: (newRange) {
                          setState(() {
                            _selectedRentTimeRange = newRange;
                            _rentTimeOffset = 0;
                          });
                        },
                        timeOffset: _rentTimeOffset,
                        onTimeOffsetChanged: (newOffset) {
                          setState(() {
                            _rentTimeOffset = newOffset;
                          });
                        },
                        rentIsBarChart: rentIsBarChart,
                        onChartTypeChanged: (isBarChart) {
                          setState(() {
                            rentIsBarChart = isBarChart;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                // En-tête de la liste
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Montant',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Liste des paiements
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Trier les données par date décroissante
                        final sortedData = List<dynamic>.from(dataManager.rentData)
                          ..sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
                        
                        final rentEntry = sortedData[index];
                        final rentDate = CustomDateUtils.formatDate(rentEntry['date']);
                        final rentAmount = currencyUtils.formatCurrency(
                          currencyUtils.convert(rentEntry['rent']),
                          currencyUtils.currencySymbol,
                        );

                        // Vérifier s'il s'agit d'un nouveau mois pour ajouter un en-tête
                        bool isNewMonth = false;
                        if (index == 0) {
                          isNewMonth = true;
                        } else {
                          final currentDate = DateTime.parse(rentEntry['date']);
                          final previousDate = DateTime.parse(sortedData[index - 1]['date']);
                          isNewMonth = currentDate.year != previousDate.year || currentDate.month != previousDate.month;
                        }

                        // Si c'est un nouveau mois, ajouter un en-tête
                        if (isNewMonth) {
                          final date = DateTime.parse(rentEntry['date']);
                          final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(date);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index != 0) const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                                child: Text(
                                  monthName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              _buildRentCard(rentDate, rentAmount, context),
                            ],
                          );
                        }

                        return _buildRentCard(rentDate, rentAmount, context);
                      },
                      childCount: dataManager.rentData.length,
                    ),
                  ),
                ),

                // Espace en bas pour éviter que le dernier élément ne soit caché
                const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
              ],
            ),
    );
  }

  Widget _buildRentCard(String date, String amount, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light ? Colors.black.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formate la date du jour pour le nom du fichier (ex: 20250222)
  String _getFormattedToday() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(now);
  }

  // Génère une chaîne CSV à partir des données de loyer
  String _generateCSV(List<dynamic> rentData, CurrencyProvider currencyUtils) {
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Date,Montant');
    for (var rentEntry in rentData) {
      final String rentDate = CustomDateUtils.formatDate(rentEntry['date']);
      final String rentAmount = currencyUtils.formatCurrency(
        currencyUtils.convert(rentEntry['rent']),
        currencyUtils.currencySymbol,
      );
      csvBuffer.writeln('$rentDate,$rentAmount');
    }
    return csvBuffer.toString();
  }

  List<Map<String, dynamic>> _groupByMonth(List<dynamic> data) {
    Map<String, double> groupedData = {};
    for (var entry in data) {
      DateTime date = DateTime.parse(entry['date']);
      String monthKey = DateFormat('yyyy/MM').format(date);
      groupedData[monthKey] = (groupedData[monthKey] ?? 0) + entry['rent'];
    }
    List<Map<String, dynamic>> list = groupedData.entries.map((e) => {'date': e.key, 'rent': e.value}).toList();
    list.sort((a, b) => DateFormat('yyyy/MM').parse(a['date']).compareTo(DateFormat('yyyy/MM').parse(b['date'])));
    return list;
  }
}
