import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/models/balance_record.dart';
import 'package:realtoken_asset_tracker/components/charts/generic_chart_widget.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:intl/intl.dart';

class EditableBalanceRecord {
  BalanceRecord original;
  final TextEditingController valueController;
  final TextEditingController dateController;

  EditableBalanceRecord(this.original, this.valueController, this.dateController);
}

class WalletBalanceGraph extends StatefulWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final bool balanceIsBarChart;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const WalletBalanceGraph({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.balanceIsBarChart,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

  @override
  State<WalletBalanceGraph> createState() => _WalletBalanceGraphState();
}

class _WalletBalanceGraphState extends State<WalletBalanceGraph> {
  late List<EditableBalanceRecord> _editableRecords;

  @override
  void dispose() {
    for (var record in _editableRecords) {
      record.valueController.dispose();
      record.dateController.dispose();
    }
    super.dispose();
  }

  List<EditableBalanceRecord> _createEditableRecords(List<BalanceRecord> records) {
    return records.map((record) {
      return EditableBalanceRecord(
        record,
        TextEditingController(text: record.balance.toStringAsFixed(2)),
        TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)),
      );
    }).toList();
  }

  void _updateBalanceValue(DataManager dataManager, EditableBalanceRecord editableRecord, double newValue) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.walletBalanceHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.balance == editableRecord.original.balance
    );
    
    if (index != -1) {
      // Créer un nouvel enregistrement avec la valeur mise à jour
      final updatedRecord = BalanceRecord(
        timestamp: editableRecord.original.timestamp,
        balance: newValue,
        tokenType: editableRecord.original.tokenType,
      );
      
      // Mettre à jour la liste
      dataManager.walletBalanceHistory[index] = updatedRecord;
      // Mettre à jour l'original dans l'enregistrement éditable
      editableRecord.original = updatedRecord;
      
      // Sauvegarder dans Hive
      dataManager.saveWalletBalanceHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Mettre à jour l'enregistrement éditable
      editableRecord.valueController.text = newValue.toStringAsFixed(2);
      
      // Pour le débogage
      print('Balance mise à jour à l\'index $index: $newValue');
    } else {
      print('Enregistrement non trouvé pour la mise à jour');
    }
  }

  void _updateBalanceDate(DataManager dataManager, EditableBalanceRecord editableRecord, DateTime newDate) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.walletBalanceHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.balance == editableRecord.original.balance
    );
    
    if (index != -1) {
      // Créer un nouvel enregistrement avec la date mise à jour
      final updatedRecord = BalanceRecord(
        timestamp: newDate,
        balance: editableRecord.original.balance,
        tokenType: editableRecord.original.tokenType,
      );
      
      // Mettre à jour la liste
      dataManager.walletBalanceHistory[index] = updatedRecord;
      // Mettre à jour l'original dans l'enregistrement éditable
      editableRecord.original = updatedRecord;
      
      // Sauvegarder dans Hive
      dataManager.saveWalletBalanceHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Mettre à jour l'enregistrement éditable
      editableRecord.dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDate);
      
      // Pour le débogage
      print('Date balance mise à jour à l\'index $index: ${newDate.toIso8601String()}');
    } else {
      print('Enregistrement non trouvé pour la mise à jour de la date');
    }
  }

  void _deleteBalanceRecord(DataManager dataManager, EditableBalanceRecord editableRecord, StateSetter setState) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.walletBalanceHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.balance == editableRecord.original.balance
    );
    
    if (index != -1) {
      // Supprimer de la liste
      dataManager.walletBalanceHistory.removeAt(index);
      
      // Sauvegarder dans Hive
      dataManager.saveWalletBalanceHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Pour le débogage
      print('Balance supprimée à l\'index $index');
      
      // Recréer les enregistrements éditables
      setState(() {
        _editableRecords = _createEditableRecords(
          List<BalanceRecord>.from(dataManager.walletBalanceHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp))
        );
      });
    } else {
      print('Enregistrement non trouvé pour la suppression');
    }
  }

  void _showEditModal(BuildContext context, DataManager dataManager) {
    // Créer des enregistrements éditables à partir des enregistrements triés
    _editableRecords = _createEditableRecords(
      List<BalanceRecord>.from(dataManager.walletBalanceHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp))
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: screenHeight * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).editWalletBalance,
                        style: TextStyle(
                          fontSize: 20 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: dataManager.walletBalanceHistory.isEmpty
                        ? Center(
                            child: Text(
                              "Aucun historique disponible",
                              style: TextStyle(
                                fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 8,
                                horizontalMargin: 8,
                                columns: [
                                  DataColumn(
                                    label: SizedBox(
                                      width: 150,
                                      child: Text(
                                        S.of(context).date,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text(
                                        S.of(context).balance,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 60,
                                      child: Text(
                                        "Actions",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _editableRecords.map((editableRecord) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 150,
                                          child: TextField(
                                            controller: editableRecord.dateController,
                                            keyboardType: TextInputType.datetime,
                                            textInputAction: TextInputAction.done,
                                            style: TextStyle(
                                              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            onSubmitted: (value) {
                                              try {
                                                DateTime newDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
                                                _updateBalanceDate(dataManager, editableRecord, newDate);
                                                FocusScope.of(context).unfocus();
                                              } catch (e) {
                                                print('Erreur de format de date: $e');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Format de date invalide')),
                                                );
                                              }
                                            },
                                            onEditingComplete: () {
                                              try {
                                                DateTime newDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(editableRecord.dateController.text);
                                                _updateBalanceDate(dataManager, editableRecord, newDate);
                                                FocusScope.of(context).unfocus();
                                              } catch (e) {
                                                print('Erreur de format de date: $e');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Format de date invalide')),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: editableRecord.valueController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            textInputAction: TextInputAction.done,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                            ],
                                            style: TextStyle(
                                              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            onSubmitted: (value) {
                                              double? newValue = double.tryParse(value);
                                              if (newValue != null) {
                                                _updateBalanceValue(dataManager, editableRecord, newValue);
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: $value');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Valeur non valide')),
                                                );
                                              }
                                            },
                                            onEditingComplete: () {
                                              double? newValue = double.tryParse(editableRecord.valueController.text);
                                              if (newValue != null) {
                                                _updateBalanceValue(dataManager, editableRecord, newValue);
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: ${editableRecord.valueController.text}');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Valeur non valide')),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red.shade700,
                                                  size: 20 + Provider.of<AppState>(context).getTextSizeOffset(),
                                                ),
                                                onPressed: () {
                                                  _deleteBalanceRecord(dataManager, editableRecord, setState);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Mettre à jour tous les enregistrements
                          for (var editableRecord in _editableRecords) {
                            try {
                              // Mettre à jour la date
                              final dateText = editableRecord.dateController.text;
                              final DateTime newDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateText);
                              
                              // Mettre à jour la valeur
                              final valueText = editableRecord.valueController.text;
                              final double? newValue = double.tryParse(valueText);
                              
                              if (newValue != null) {
                                // Trouver l'index dans la liste originale
                                final index = dataManager.walletBalanceHistory.indexWhere((r) => 
                                  r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
                                  r.balance == editableRecord.original.balance
                                );
                                
                                if (index != -1) {
                                  // Créer un nouvel enregistrement avec les nouvelles valeurs
                                  final updatedRecord = BalanceRecord(
                                    timestamp: newDate,
                                    balance: newValue,
                                    tokenType: editableRecord.original.tokenType,
                                  );
                                  
                                  // Mettre à jour la liste
                                  dataManager.walletBalanceHistory[index] = updatedRecord;
                                  print('Mise à jour index $index: ${newDate.toIso8601String()} -> $newValue');
                                }
                              }
                            } catch (e) {
                              print('Erreur lors de la mise à jour: $e');
                            }
                          }
                          
                          // Sauvegarder dans Hive
                          dataManager.saveWalletBalanceHistory();
                          
                          // Notifier les écouteurs
                          dataManager.notifyListeners();
                          
                          // Fermer le modal
                          Navigator.pop(context);
                          
                          // Forcer la mise à jour du widget parent
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          S.of(context).save,
                          style: TextStyle(
                            fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    return GenericChartWidget<BalanceRecord>(
      title: S.of(context).walletBalanceHistory,
      chartColor: const Color(0xFF007AFF), // Bleu iOS
      dataList: dataManager.walletBalanceHistory,
      selectedPeriod: widget.selectedPeriod,
      onPeriodChanged: widget.onPeriodChanged,
      isBarChart: widget.balanceIsBarChart,
      onChartTypeChanged: widget.onChartTypeChanged,
      selectedTimeRange: widget.selectedTimeRange,
      onTimeRangeChanged: widget.onTimeRangeChanged,
      timeOffset: widget.timeOffset,
      onTimeOffsetChanged: widget.onTimeOffsetChanged,
      getYValue: (record) => record.balance,
      getTimestamp: (record) => record.timestamp,
      valuePrefix: '',
      valueSuffix: ' €',
      onEditPressed: (context) => _showEditModal(context, dataManager),
    );
  }
}
