import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/components/charts/generic_chart_widget.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/models/apy_record.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class EditableAPYRecord {
  APYRecord original;
  final TextEditingController netController;
  final TextEditingController grossController;
  final TextEditingController dateController;

  EditableAPYRecord(
    this.original, 
    this.netController,
    this.grossController,
    this.dateController
  );
}

class ApyHistoryGraph extends StatefulWidget {
  final DataManager dataManager;
  final String selectedPeriod;
  final bool apyIsBarChart;
  final Function(String) onPeriodChanged;
  final Function(bool) onChartTypeChanged;
  final String selectedTimeRange;
  final Function(String) onTimeRangeChanged;
  final int timeOffset;
  final Function(int) onTimeOffsetChanged;

  const ApyHistoryGraph({
    super.key,
    required this.dataManager,
    required this.selectedPeriod,
    required this.apyIsBarChart,
    required this.onPeriodChanged,
    required this.onChartTypeChanged,
    this.selectedTimeRange = 'all',
    required this.onTimeRangeChanged,
    this.timeOffset = 0,
    required this.onTimeOffsetChanged,
  });

  @override
  State<ApyHistoryGraph> createState() => _ApyHistoryGraphState();
}

class _ApyHistoryGraphState extends State<ApyHistoryGraph> {
  late List<EditableAPYRecord> _editableRecords;

  @override
  void dispose() {
    for (var record in _editableRecords) {
      record.netController.dispose();
      record.grossController.dispose();
      record.dateController.dispose();
    }
    super.dispose();
  }

  List<EditableAPYRecord> _createEditableRecords(List<APYRecord> records) {
    return records.map((record) {
      return EditableAPYRecord(
        record,
        TextEditingController(text: (record.netApy ?? record.apy).toStringAsFixed(2)),
        TextEditingController(text: (record.grossApy ?? record.apy).toStringAsFixed(2)),
        TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)),
      );
    }).toList();
  }

  void _updateAPYValue(DataManager dataManager, EditableAPYRecord editableRecord, 
      {double? netValue, double? grossValue}) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.apyHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.apy == editableRecord.original.apy
    );
    
    if (index != -1) {
      // Déterminer les valeurs à utiliser
      final newNetValue = netValue ?? editableRecord.original.netApy ?? editableRecord.original.apy;
      final newGrossValue = grossValue ?? editableRecord.original.grossApy ?? editableRecord.original.apy;
      
      // Créer un nouvel enregistrement avec les valeurs mises à jour
      final updatedRecord = APYRecord(
        timestamp: editableRecord.original.timestamp,
        apy: newNetValue, // Utiliser la valeur nette comme valeur principale
        netApy: newNetValue,
        grossApy: newGrossValue,
      );
      
      // Mettre à jour la liste
      dataManager.apyHistory[index] = updatedRecord;
      // Mettre à jour l'original dans l'enregistrement éditable
      editableRecord.original = updatedRecord;
      
      // Sauvegarder dans Hive
      dataManager.saveApyHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Mettre à jour les contrôleurs si nécessaire
      if (netValue != null) {
        editableRecord.netController.text = newNetValue.toStringAsFixed(2);
      }
      if (grossValue != null) {
        editableRecord.grossController.text = newGrossValue.toStringAsFixed(2);
      }
      
      // Pour le débogage
      print('APY mis à jour à l\'index $index: Net=$newNetValue, Gross=$newGrossValue');
    } else {
      print('Enregistrement non trouvé pour la mise à jour');
    }
  }

  void _updateAPYDate(DataManager dataManager, EditableAPYRecord editableRecord, DateTime newDate) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.apyHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.apy == editableRecord.original.apy
    );
    
    if (index != -1) {
      // Créer un nouvel enregistrement avec la date mise à jour
      final updatedRecord = APYRecord(
        timestamp: newDate,
        apy: editableRecord.original.apy,
        netApy: editableRecord.original.netApy,
        grossApy: editableRecord.original.grossApy,
      );
      
      // Mettre à jour la liste
      dataManager.apyHistory[index] = updatedRecord;
      // Mettre à jour l'original dans l'enregistrement éditable
      editableRecord.original = updatedRecord;
      
      // Sauvegarder dans Hive
      dataManager.saveApyHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Mettre à jour l'enregistrement éditable
      editableRecord.dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDate);
      
      // Pour le débogage
      print('Date APY mise à jour à l\'index $index: ${newDate.toIso8601String()}');
    } else {
      print('Enregistrement non trouvé pour la mise à jour de la date');
    }
  }

  void _deleteAPYRecord(DataManager dataManager, EditableAPYRecord editableRecord, StateSetter setState) {
    // Récupérer l'index de l'enregistrement original
    final index = dataManager.apyHistory.indexWhere((r) => 
      r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
      r.apy == editableRecord.original.apy
    );
    
    if (index != -1) {
      // Supprimer de la liste
      dataManager.apyHistory.removeAt(index);
      
      // Sauvegarder dans Hive
      dataManager.saveApyHistory();
      
      // Notifier les écouteurs
      dataManager.notifyListeners();
      
      // Pour le débogage
      print('APY supprimé à l\'index $index');
      
      // Recréer les enregistrements éditables
      setState(() {
        _editableRecords = _createEditableRecords(
          List<APYRecord>.from(dataManager.apyHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp))
        );
      });
    } else {
      print('Enregistrement non trouvé pour la suppression');
    }
  }

  void _showEditModal(BuildContext context) {
    // Créer des enregistrements éditables à partir des enregistrements triés
    _editableRecords = _createEditableRecords(
      List<APYRecord>.from(widget.dataManager.apyHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp))
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                        'Éditer l\'historique APY',
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
                    child: widget.dataManager.apyHistory.isEmpty
                        ? Center(
                            child: Text(
                              "Aucun historique disponible",
                              style: TextStyle(
                                fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                        "Date",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text(
                                        S.of(context).net,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: SizedBox(
                                      width: 100,
                                      child: Text(
                                        S.of(context).brute,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                          fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                                _updateAPYDate(widget.dataManager, editableRecord, newDate);
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
                                                _updateAPYDate(widget.dataManager, editableRecord, newDate);
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
                                            controller: editableRecord.netController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            textInputAction: TextInputAction.done,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                            ],
                                            style: TextStyle(
                                              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                                _updateAPYValue(
                                                  widget.dataManager, 
                                                  editableRecord, 
                                                  netValue: newValue
                                                );
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: $value');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Valeur non valide')),
                                                );
                                              }
                                            },
                                            onEditingComplete: () {
                                              double? newValue = double.tryParse(editableRecord.netController.text);
                                              if (newValue != null) {
                                                _updateAPYValue(
                                                  widget.dataManager, 
                                                  editableRecord, 
                                                  netValue: newValue
                                                );
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: ${editableRecord.netController.text}');
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
                                          width: 100,
                                          child: TextField(
                                            controller: editableRecord.grossController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            textInputAction: TextInputAction.done,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                            ],
                                            style: TextStyle(
                                              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
                                                _updateAPYValue(
                                                  widget.dataManager, 
                                                  editableRecord, 
                                                  grossValue: newValue
                                                );
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: $value');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Valeur non valide')),
                                                );
                                              }
                                            },
                                            onEditingComplete: () {
                                              double? newValue = double.tryParse(editableRecord.grossController.text);
                                              if (newValue != null) {
                                                _updateAPYValue(
                                                  widget.dataManager, 
                                                  editableRecord, 
                                                  grossValue: newValue
                                                );
                                                FocusScope.of(context).unfocus();
                                              } else {
                                                print('Valeur non valide: ${editableRecord.grossController.text}');
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
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  _deleteAPYRecord(widget.dataManager, editableRecord, setState);
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
                              
                              // Mettre à jour la valeur nette
                              final netText = editableRecord.netController.text;
                              final double? newNetValue = double.tryParse(netText);
                              
                              // Mettre à jour la valeur brute
                              final grossText = editableRecord.grossController.text;
                              final double? newGrossValue = double.tryParse(grossText);
                              
                              if (newNetValue != null && newGrossValue != null) {
                                // Trouver l'index dans la liste originale
                                final index = widget.dataManager.apyHistory.indexWhere((r) => 
                                  r.timestamp.isAtSameMomentAs(editableRecord.original.timestamp) && 
                                  r.apy == editableRecord.original.apy
                                );
                                
                                if (index != -1) {
                                  // Créer un nouvel enregistrement avec les nouvelles valeurs
                                  final updatedRecord = APYRecord(
                                    timestamp: newDate,
                                    apy: newNetValue, // Utiliser la valeur nette comme valeur principale
                                    netApy: newNetValue,
                                    grossApy: newGrossValue,
                                  );
                                  
                                  // Mettre à jour la liste
                                  widget.dataManager.apyHistory[index] = updatedRecord;
                                  print('Mise à jour index $index: ${newDate.toIso8601String()} -> $newNetValue');
                                }
                              }
                            } catch (e) {
                              print('Erreur lors de la mise à jour: $e');
                            }
                          }
                          
                          // Sauvegarder dans Hive
                          widget.dataManager.saveApyHistory();
                          
                          // Notifier les écouteurs
                          widget.dataManager.notifyListeners();
                          
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
                          'Sauvegarder',
                          style: TextStyle(
                            fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
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
    // Définir les couleurs pour les séries empilées
    final Color netColor = const Color(0xFF5AC8FA); // Bleu pour net
    final Color grossColor = const Color(0xFFFF9500); // Orange pour brut
    
    return GenericChartWidget<APYRecord>(
      title: S.of(context).apyHistory,
      chartColor: netColor, // Utiliser la couleur de la série principale
      stackColors: [netColor, grossColor], // Couleurs pour l'empilement
      dataList: widget.dataManager.apyHistory,
      selectedPeriod: widget.selectedPeriod,
      onPeriodChanged: widget.onPeriodChanged,
      isBarChart: widget.apyIsBarChart,
      onChartTypeChanged: widget.onChartTypeChanged,
      selectedTimeRange: widget.selectedTimeRange,
      onTimeRangeChanged: widget.onTimeRangeChanged,
      timeOffset: widget.timeOffset,
      onTimeOffsetChanged: widget.onTimeOffsetChanged,
      getYValue: (record) => record.apy ?? 0.0,
      // Fournir les valeurs pour l'empilement
      getStackValues: (record) {
        final netValue = record.netApy ?? record.apy ?? 0.0;
        final grossValue = record.grossApy ?? record.apy ?? 0.0;
        
        // Si gross est inférieur à net (rare), on affiche juste la valeur nette
        final grossDiff = grossValue > netValue ? grossValue - netValue : 0.0;
        
        return [netValue, grossDiff];
      },
      getTimestamp: (record) => record.timestamp ?? DateTime.now(),
      valuePrefix: '',
      valueSuffix: '%',
      maxY: 20, // Limiter la hauteur à 20%
      isStacked: true, // Activer l'affichage empilé pour APY
      stackLabels: [S.of(context).net, S.of(context).brute], // Ajouter les étiquettes pour la légende
      onEditPressed: (context) => _showEditModal(context),
    );
  }
}
