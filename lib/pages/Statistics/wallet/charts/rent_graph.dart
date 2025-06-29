import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/components/charts/generic_chart_widget.dart';
import 'package:realtoken_asset_tracker/models/rent_record.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';

class RentGraph extends StatefulWidget {
  final List<Map<String, dynamic>> groupedData;
  final DataManager dataManager;
  final bool showCumulativeRent;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<bool> onCumulativeRentChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;
  final bool rentIsBarChart;
  final Function(bool) onChartTypeChanged;

  const RentGraph({
    super.key,
    required this.groupedData,
    required this.dataManager,
    required this.showCumulativeRent,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onCumulativeRentChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
    required this.rentIsBarChart,
    required this.onChartTypeChanged,
  });

  @override
  _RentGraphState createState() => _RentGraphState();
}

class _RentGraphState extends State<RentGraph> {
  bool _showCumulativeRent = false;

  @override
  void initState() {
    super.initState();
    _showCumulativeRent = widget.showCumulativeRent;
  }

  @override
  void didUpdateWidget(RentGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCumulativeRent != widget.showCumulativeRent) {
      _showCumulativeRent = widget.showCumulativeRent;
    }
  }

  List<RentRecord> _convertRentData() {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    List<RentRecord> rentRecords = [];

    // Grouper les données par période
    List<Map<String, dynamic>> groupedData = widget.groupedData;
    if (groupedData.isEmpty) {
      // Si pas de données groupées, utiliser les données brutes du DataManager
      final dataManager = widget.dataManager;
      if (dataManager.rentData.isNotEmpty) {
        double cumulativeRent = 0;
        
        // Trier les données par date
        List<Map<String, dynamic>> sortedData = List.from(dataManager.rentData)
          ..sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
        
        for (var entry in sortedData) {
          double rent = entry['rent']?.toDouble() ?? 0.0;
          DateTime date = DateTime.parse(entry['date']);
          cumulativeRent += rent;
          
          rentRecords.add(RentRecord(
            timestamp: date,
            rent: currencyUtils.convert(rent),
            cumulativeRent: currencyUtils.convert(cumulativeRent),
          ));
        }
      }
    } else {
      double cumulativeRent = 0;
      
      // Trier les données par date
      List<Map<String, dynamic>> sortedData = List.from(groupedData)
        ..sort((a, b) {
          // Analyser la date selon son format
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateA.compareTo(dateB);
        });
      
      for (var entry in sortedData) {
        double rent = entry['rent']?.toDouble() ?? 0.0;
        DateTime date = _parseDate(entry['date']);
        cumulativeRent += rent;
        
        rentRecords.add(RentRecord(
          timestamp: date,
          rent: currencyUtils.convert(rent),
          cumulativeRent: currencyUtils.convert(cumulativeRent),
        ));
      }
    }
    
    debugPrint("🔄 Conversion des données de loyer: ${rentRecords.length} enregistrements");
    return rentRecords;
  }
  
  // Helper pour analyser différents formats de date
  DateTime _parseDate(String dateStr) {
    try {
      // Essayer plusieurs formats possibles
      if (dateStr.contains('/')) {
        // Format yyyy/MM/dd
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
        // Format MM/yyyy
        if (parts.length == 2) {
          return DateTime(int.parse(parts[1]), int.parse(parts[0]), 1);
        }
      }
      
      // Format année seule
      if (dateStr.length == 4 && RegExp(r'^\d{4}$').hasMatch(dateStr)) {
        return DateTime(int.parse(dateStr), 1, 1);
      }
      
      // Format ISO
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint("❌ Erreur lors de l'analyse de la date: $dateStr");
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    
    // Convertir les données au format requis par GenericChartWidget
    List<RentRecord> rentRecords = _convertRentData();
    
    // Utiliser GenericChartWidget avec le switch intégré
    return GenericChartWidget<RentRecord>(
      title: "Loyer", // Titre de base (peut être remplacé par les labels cumulatifs)
      chartColor: const Color(0xFF007AFF),
      dataList: rentRecords,
      selectedPeriod: widget.selectedPeriod,
      onPeriodChanged: widget.onPeriodChanged,
      isBarChart: widget.rentIsBarChart,
      onChartTypeChanged: widget.onChartTypeChanged,
      selectedTimeRange: widget.selectedTimeRange,
      onTimeRangeChanged: widget.onTimeRangeChanged,
      timeOffset: widget.timeOffset,
      onTimeOffsetChanged: widget.onTimeOffsetChanged,
      getYValue: (record) => _showCumulativeRent ? record.cumulativeRent : record.rent,
      getTimestamp: (record) => record.timestamp,
      valuePrefix: currencyUtils.currencySymbol,
      // Nouveaux paramètres pour le switch
      isCumulative: _showCumulativeRent,
      onCumulativeChanged: (value) {
        setState(() {
          _showCumulativeRent = value;
          widget.onCumulativeRentChanged(value);
        });
      },
      cumulativeLabel: S.of(context).cumulativeRentGraph,
      nonCumulativeLabel: S.of(context).groupedRentGraph,
    );
  }
}
