import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).toolsTitle,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              S.of(context).exportRentsTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).exportRentsDescription,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Image.asset('assets/icons/excel.png', width: 24, height: 24),
              label: Text(S.of(context).exportRentsCsv),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(), fontWeight: FontWeight.w600),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      content: Text(S.of(context).noRentDataToShare, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
            const SizedBox(height: 24),
            Divider(height: 32),
            Text(
              S.of(context).exportAllTransactionsTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).exportAllTransactionsDescription,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Image.asset('assets/icons/excel.png', width: 24, height: 24),
              label: Text(S.of(context).exportAllTransactionsCsv),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(), fontWeight: FontWeight.w600),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final allEvents = _getAllEvents(dataManager, currencyUtils);
                if (allEvents.isNotEmpty) {
                  final csvData = _generateAllEventsCSV(allEvents);
                  final fileName = 'transactions_${_getFormattedToday()}.csv';
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
                      content: Text(S.of(context).noTransactionOrRentToExport, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
            const SizedBox(height: 24),
            if (dataManager.rentData.isEmpty)
              Text(
                S.of(context).noRentDataAvailable,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedToday() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(now);
  }

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

  List<Map<String, dynamic>> _getAllEvents(DataManager dataManager, CurrencyProvider currencyUtils) {
    final List<Map<String, dynamic>> events = [];
    // Transactions du portfolio
    for (var token in dataManager.portfolio) {
      if (token.containsKey('transactions') && token['transactions'] is List) {
        for (var transaction in token['transactions']) {
          if (transaction['dateTime'] != null) {
            DateTime date = transaction['dateTime'] is String
                ? DateTime.parse(transaction['dateTime'])
                : transaction['dateTime'];
            events.add({
              'date': date,
              'type': 'transaction',
              'amount': transaction['amount'],
              'price': currencyUtils.convert(transaction['price'] ?? token['tokenPrice']),
              'currency': currencyUtils.currencySymbol,
              'fullName': token['fullName'],
              'uuid': token['uuid'] ?? '',
              'transactionType': transaction['transactionType'] ?? 'Inconnu',
            });
          }
        }
      }
    }
    // Loyers
    for (var rent in dataManager.rentData) {
      if (rent['date'] != null) {
        DateTime date = rent['date'] is String ? DateTime.parse(rent['date']) : rent['date'];
        events.add({
          'date': date,
          'type': 'rent',
          'amount': rent['rent'],
          'price': '',
          'currency': currencyUtils.currencySymbol,
          'fullName': '',
          'uuid': '',
          'transactionType': 'Loyer',
        });
      }
    }
    // Tri par date décroissante
    events.sort((a, b) => b['date'].compareTo(a['date']));
    return events;
  }

  String _generateAllEventsCSV(List<Map<String, dynamic>> events) {
    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Date,Type,Montant,Prix,Devise,Nom du token,UUID,Type de transaction');
    for (var event in events) {
      final String date = DateFormat('yyyy-MM-dd').format(event['date']);
      final String type = event['type'] == 'rent' ? 'Loyer' : 'Transaction';
      final String amount = event['amount'] != null ? event['amount'].toString() : '';
      final String price = event['price'] != null && event['price'].toString().isNotEmpty ? event['price'].toString() : '';
      final String currency = event['currency'] ?? '';
      final String fullName = event['fullName'] ?? '';
      final String uuid = event['uuid'] ?? '';
      final String transactionType = event['transactionType'] ?? '';
      csvBuffer.writeln('$date,$type,$amount,$price,$currency,$fullName,$uuid,$transactionType');
    }
    return csvBuffer.toString();
  }
} 