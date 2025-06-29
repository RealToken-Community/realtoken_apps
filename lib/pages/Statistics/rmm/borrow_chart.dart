// borrow_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/models/balance_record.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/components/charts/generic_chart_widget.dart';

/// Classe représentant un groupe d'emprunts agrégé selon la période.
class BorrowRecord {
  final DateTime timestamp;
  final double usdc;
  final double xdai;
  final double total;

  BorrowRecord({
    required this.timestamp,
    required this.usdc,
    required this.xdai,
  }) : total = usdc + xdai;
}

class BorrowChart extends StatefulWidget {
  final Map<String, List<BalanceRecord>> allHistories;
  final String selectedPeriod;
  final String selectedTimeRange;
  final Function(String) onPeriodChanged;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;
  final bool isBarChart;
  final Function(bool) onChartTypeChanged;

  const BorrowChart({
    required this.allHistories,
    required this.selectedPeriod,
    this.selectedTimeRange = 'all',
    required this.onPeriodChanged,
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
    this.isBarChart = false,
    required this.onChartTypeChanged,
    super.key,
  });

  @override
  State<BorrowChart> createState() => _BorrowChartState();
}

class _BorrowChartState extends State<BorrowChart> {
  List<BorrowRecord> _borrowRecords = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Ne pas initialiser ici pour éviter les problèmes avec le context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _updateBorrowRecords();
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(BorrowChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allHistories != widget.allHistories ||
        oldWidget.selectedPeriod != widget.selectedPeriod) {
      _updateBorrowRecords();
    }
  }

  /// Convertit les historiques de balance en liste de BorrowRecord
  void _updateBorrowRecords() {
    final Map<DateTime, BorrowRecord> recordsMap = {};

    // Traiter les emprunts USDC
    if (widget.allHistories['usdcBorrow'] != null) {
      for (final record in widget.allHistories['usdcBorrow']!) {
        final date = _truncateDate(record.timestamp);
        if (recordsMap.containsKey(date)) {
          recordsMap[date] = BorrowRecord(
            timestamp: date,
            usdc: recordsMap[date]!.usdc + record.balance,
            xdai: recordsMap[date]!.xdai,
          );
        } else {
          recordsMap[date] = BorrowRecord(
            timestamp: date,
            usdc: record.balance,
            xdai: 0,
          );
        }
      }
    }

    // Traiter les emprunts xDai
    if (widget.allHistories['xdaiBorrow'] != null) {
      for (final record in widget.allHistories['xdaiBorrow']!) {
        final date = _truncateDate(record.timestamp);
        if (recordsMap.containsKey(date)) {
          recordsMap[date] = BorrowRecord(
            timestamp: date,
            usdc: recordsMap[date]!.usdc,
            xdai: recordsMap[date]!.xdai + record.balance,
          );
        } else {
          recordsMap[date] = BorrowRecord(
            timestamp: date,
            usdc: 0,
            xdai: record.balance,
          );
        }
      }
    }

    // Convertir la Map en List et trier par date
    _borrowRecords = recordsMap.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Tronque une date selon la période sélectionnée
  DateTime _truncateDate(DateTime date) {
    if (widget.selectedPeriod == S.of(context).day) {
      return DateTime(date.year, date.month, date.day);
    } else if (widget.selectedPeriod == S.of(context).week) {
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    } else if (widget.selectedPeriod == S.of(context).month) {
      return DateTime(date.year, date.month);
    } else if (widget.selectedPeriod == S.of(context).year) {
      return DateTime(date.year);
    } else {
      return DateTime(date.year, date.month, date.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Deux couleurs pour les données empilées
    final Color primaryColor = const Color(0xFFFF9500); // Orange iOS pour USDC
    final Color secondaryColor = const Color(0xFFFF3B30); // Rouge iOS pour xDai

    return GenericChartWidget<BorrowRecord>(
      title: S.of(context).borrowBalance,
      chartColor: primaryColor,
      stackColors: [primaryColor, secondaryColor], // Couleurs pour l'empilement
      dataList: _borrowRecords,
      selectedPeriod: widget.selectedPeriod,
      onPeriodChanged: widget.onPeriodChanged,
      isBarChart: widget.isBarChart,
      onChartTypeChanged: widget.onChartTypeChanged,
      selectedTimeRange: widget.selectedTimeRange,
      onTimeRangeChanged: widget.onTimeRangeChanged,
      timeOffset: widget.timeOffset,
      onTimeOffsetChanged: widget.onTimeOffsetChanged,
      getYValue: (record) => currencyUtils.convert(record.total),
      getStackValues: (record) => [
        currencyUtils.convert(record.usdc),
        currencyUtils.convert(record.xdai),
      ], // Valeurs pour l'empilement
      getTimestamp: (record) => record.timestamp,
      valuePrefix: currencyUtils.currencySymbol,
      isStacked: true, // Activer l'affichage empilé
      stackLabels: ['USDC', 'xDai'], // Étiquettes pour la légende
    );
  }
}
