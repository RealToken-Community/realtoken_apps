import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';

Widget buildHistoryTab(BuildContext context, Map<String, dynamic> token,
    bool isLoadingTransactions) {
  final appState = Provider.of<AppState>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);

  // Tri des transactions par date (du plus récent au plus ancien) si disponibles
  if (token['transactions'] != null && token['transactions'].isNotEmpty) {
    List<dynamic> sortedTransactions = List.from(token['transactions']);
    sortedTransactions.sort((a, b) {
      final dateA = a['dateTime'] != null ? DateTime.parse(a['dateTime'].toString()) : DateTime.now();
      final dateB = b['dateTime'] != null ? DateTime.parse(b['dateTime'].toString()) : DateTime.now();
      return dateB.compareTo(dateA);
    });
    token['transactions'] = sortedTransactions;
  }

  // Récupérer l'historique des modifications pour ce token spécifique
  final String tokenUuid = token['uuid'] ?? token['gnosisContract'] ?? '';
  List<Map<String, dynamic>> rawTokenHistory = [];
  List<Map<String, dynamic>> tokenChanges = [];
  
  if (tokenUuid.isNotEmpty && dataManager.tokenHistoryData.isNotEmpty) {
    print("🔍 Recherche historique pour token: $tokenUuid");
    
    // Utiliser la méthode existante du DataManager
    rawTokenHistory = dataManager.getTokenHistory(tokenUuid);
    print("📋 Historique brut trouvé: ${rawTokenHistory.length} entrées");
    
    // Détecter les changements entre les entrées consécutives
    for (int i = 1; i < rawTokenHistory.length; i++) {
      var previous = rawTokenHistory[i]; // Plus ancien
      var current = rawTokenHistory[i - 1]; // Plus récent
      
      // Détecter les changements dans les champs importants
      List<Map<String, dynamic>> changes = _detectTokenChanges(previous, current, token);
      
      if (changes.isNotEmpty) {
        tokenChanges.add({
          'date': current['date'],
          'changes': changes,
        });
      }
    }
    
    print("📊 Changements détectés: ${tokenChanges.length} dates avec modifications");
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section historique des transactions
        _buildSectionCard(
          context,
          title: S.of(context).transactionHistory,
          children: [
            // Gestion de l'état de chargement avec Shimmer
            if (isLoadingTransactions)
              ...List.generate(5, (index) => // Placeholder pour 5 items simulés
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Card(
                    elevation: 0, // Style iOS plat
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Coins arrondis style iOS
                    ),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          ShimmerUtils.standardShimmer(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerUtils.standardShimmer(
                                  child: Container(
                                    width: double.infinity,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                ShimmerUtils.standardShimmer(
                                  child: Container(
                                    width: 100,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              )
            else if (token['transactions'] != null && token['transactions'].isNotEmpty)
              ...token['transactions'].map((transaction) {
                final price =
                    '${currencyUtils.convert(transaction['price'] ?? token['tokenPrice']).toStringAsFixed(2)} ${currencyUtils.currencySymbol}';
                final amount = transaction['amount'] ?? 0.0;
                final transactionType = transaction.containsKey('transactionType')
                    ? transaction['transactionType']
                    : S.of(context).unknownTransaction;

                final dateTime = transaction['dateTime'] != null
                    ? DateFormat('yyyy-MM-dd HH:mm')
                        .format(transaction['dateTime'])
                    : S.of(context).unknownDate;

                IconData icon;
                Color iconColor;
                Color bgColor;

                if (transactionType == DataManager.transactionTypePurchase) {
                  icon = Icons.shopping_cart;
                  iconColor = Colors.white;
                  bgColor = Colors.blue;
                } else if (transactionType == DataManager.transactionTypeTransfer) {
                  icon = Icons.swap_horiz;
                  iconColor = Colors.white;
                  bgColor = Colors.grey;
                } else if (transactionType == DataManager.transactionTypeYam) {
                  icon = Icons.price_change;
                  iconColor = Colors.white;
                  bgColor = Colors.orange;
                } else {
                  icon = Icons.attach_money;
                  iconColor = Colors.white;
                  bgColor = Colors.green;
                }

                // Afficher chaque transaction dans une belle carte style iOS
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Theme.of(context).cardColor,
                        child: InkWell(
                          onTap: () {
                            // Optionnellement: afficher plus de détails sur la transaction
                          },
                          splashColor: bgColor.withOpacity(0.1),
                          highlightColor: bgColor.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icône avec cercle coloré
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icon, 
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Contenu
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Type de transaction
                                      Text(
                                        _getLocalizedTransactionType(transactionType, context),
                                        style: TextStyle(
                                          fontSize: 16 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Détails principaux
                                      Row(
                                        children: [
                                          Text(
                                            price, 
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Text(" • "),
                                          Text(
                                            "${S.of(context).quantity}: $amount",
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Date
                                      Text(
                                        DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(dateTime)),
                                        style: TextStyle(
                                          fontSize: 12 + appState.getTextSizeOffset(),
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Indicateur de navigation (flèche droite)
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList()
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        S.of(context).noTransactionsAvailable,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Section historique des modifications
        _buildSectionCard(
          context,
          title: "Historique des modifications",
          children: [
            if (tokenChanges.isNotEmpty)
              ...tokenChanges.map((historyEntry) {
                final date = DateTime.parse(historyEntry['date']);
                final changes = historyEntry['changes'] as List<dynamic>? ?? [];
                
                if (changes.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date de la modification
                          Text(
                            _formatHistoryDate(date),
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Liste des changements
                          ...changes.map((change) {
                            final changeType = _getChangeTypeFromChange(change);
                            final changeColor = _getChangeColor(changeType);
                            final changeIcon = _getChangeIcon(changeType);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  // Icône du changement
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: changeColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      changeIcon,
                                      size: 14,
                                      color: changeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Description du changement
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getFieldDisplayName(change['field']),
                                          style: TextStyle(
                                            fontSize: 13 + appState.getTextSizeOffset(),
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatChangeDescription(change, currencyUtils),
                                          style: TextStyle(
                                            fontSize: 12 + appState.getTextSizeOffset(),
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              })
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Aucune modification disponible",
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

// Widget pour construire une section, comme dans property_tab.dart
Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Column(children: children),
      ],
    ),
  );
}

// Méthode pour traduire les constantes en textes localisés
String _getLocalizedTransactionType(String transactionType, BuildContext context) {
  if (transactionType == DataManager.transactionTypePurchase) {
    return S.of(context).purchase;
  } else if (transactionType == DataManager.transactionTypeTransfer) {
    return S.of(context).internal_transfer;
  } else if (transactionType == DataManager.transactionTypeYam) {
    return S.of(context).yam;
  } else {
    return S.of(context).unknownTransaction;
  }
}

String _formatHistoryDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return "Aujourd'hui";
  } else if (difference.inDays == 1) {
    return "Hier";
  } else if (difference.inDays < 7) {
    return "Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}";
  } else {
    return DateFormat('dd MMMM yyyy').format(date);
  }
}

String _getChangeTypeFromChange(dynamic change) {
  final oldValue = change['oldValue'];
  final newValue = change['newValue'];
  
  if (oldValue == null || newValue == null) {
    return 'neutral';
  }
  
  // Convertir en double pour la comparaison
  double? oldVal = double.tryParse(oldValue.toString());
  double? newVal = double.tryParse(newValue.toString());
  
  if (oldVal != null && newVal != null) {
    if (newVal > oldVal) {
      return 'increase';
    } else if (newVal < oldVal) {
      return 'decrease';
    }
  }
  
  return 'neutral';
}

String _formatChangeDescription(dynamic change, CurrencyProvider currencyUtils) {
  final field = change['field'];
  final oldValue = change['oldValue'];
  final newValue = change['newValue'];
  
  if (oldValue == null || newValue == null) {
    return 'Valeur modifiée';
  }
  
  String formattedOldValue = oldValue.toString();
  String formattedNewValue = newValue.toString();
  
  // Formatage spécifique selon le champ
  if (field == 'token_price' || field == 'underlying_asset_price') {
    double? oldVal = double.tryParse(oldValue.toString());
    double? newVal = double.tryParse(newValue.toString());
    if (oldVal != null && newVal != null) {
      formattedOldValue = '${currencyUtils.convert(oldVal).toStringAsFixed(2)} ${currencyUtils.currencySymbol}';
      formattedNewValue = '${currencyUtils.convert(newVal).toStringAsFixed(2)} ${currencyUtils.currencySymbol}';
    }
  } else if (field == 'total_investment' || field == 'gross_rent_year' || field == 'net_rent_year') {
    double? oldVal = double.tryParse(oldValue.toString());
    double? newVal = double.tryParse(newValue.toString());
    if (oldVal != null && newVal != null) {
      formattedOldValue = '${currencyUtils.convert(oldVal).toStringAsFixed(0)} ${currencyUtils.currencySymbol}';
      formattedNewValue = '${currencyUtils.convert(newVal).toStringAsFixed(0)} ${currencyUtils.currencySymbol}';
    }
  } else if (field == 'rented_units') {
    formattedOldValue = '$oldValue unité${oldValue != '1' ? 's' : ''}';
    formattedNewValue = '$newValue unité${newValue != '1' ? 's' : ''}';
  }
  
  return '$formattedOldValue → $formattedNewValue';
}

String _getFieldDisplayName(String field) {
  switch (field) {
    case 'token_price':
      return 'Prix du token';
    case 'underlying_asset_price':
      return 'Prix de l\'actif sous-jacent';
    case 'total_investment':
      return 'Investissement total';
    case 'gross_rent_year':
      return 'Loyer brut annuel';
    case 'net_rent_year':
      return 'Loyer net annuel';
    case 'rented_units':
      return 'Unités louées';
    default:
      return field;
  }
}

Color _getChangeColor(String changeType) {
  switch (changeType) {
    case 'increase':
      return Colors.green;
    case 'decrease':
      return Colors.red;
    case 'neutral':
    default:
      return Colors.blue;
  }
}

IconData _getChangeIcon(String changeType) {
  switch (changeType) {
    case 'increase':
      return Icons.trending_up;
    case 'decrease':
      return Icons.trending_down;
    case 'neutral':
    default:
      return Icons.trending_flat;
  }
}

List<Map<String, dynamic>> _detectTokenChanges(
  Map<String, dynamic> previous, 
  Map<String, dynamic> current, 
  Map<String, dynamic> tokenInfo
) {
  List<Map<String, dynamic>> changes = [];
  
  // Champs à surveiller
  final fieldsToWatch = {
    'token_price': 'Prix du token',
    'underlying_asset_price': 'Prix de l\'actif sous-jacent',
    'total_investment': 'Investissement total',
    'gross_rent_year': 'Loyer brut annuel',
    'net_rent_year': 'Loyer net annuel',
    'rented_units': 'Unités louées',
  };
  
  fieldsToWatch.forEach((field, label) {
    var prevValue = previous[field];
    var currValue = current[field];
    
    if (prevValue != null && currValue != null && prevValue != currValue) {
      changes.add({
        'field': field,
        'fieldLabel': label,
        'oldValue': prevValue,
        'newValue': currValue,
      });
    }
  });
  
  return changes;
}
