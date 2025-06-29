// ignore_for_file: all

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart'; // Assurez-vous d'importer votre DataManager
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:show_network_image/show_network_image.dart'; // Import pour les traductions
import 'dart:ui';
import 'package:intl/intl.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  _UpdatesPageState createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool showUserTokensOnly = false;
  bool showAllChanges = false;
  bool includeAllFieldChanges = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: TextStyle(
          color: MediaQuery.of(context).platformBrightness == Brightness.dark 
            ? Colors.white 
            : Colors.black,
          fontSize: 14,
        ),
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: MediaQuery.of(context).platformBrightness,
          ),
          child: Builder(
            builder: (context) {
          final dataManager = Provider.of<DataManager>(context);
          final appState = Provider.of<AppState>(context);
          final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

          // Obtenir les changements récents
      List<Map<String, dynamic>> recentChanges = dataManager.getRecentTokenChanges(
        days: showAllChanges ? null : 365,  // null = pas de limite, sinon 1 an par défaut
        includeAllChanges: includeAllFieldChanges
      );

    // Filtrer pour les tokens de l'utilisateur uniquement si nécessaire
    if (showUserTokensOnly) {
      Set<String> userTokenUuids = dataManager.portfolio.map((token) => 
        (token['uuid']?.toLowerCase() ?? '') as String
      ).toSet();
      
      recentChanges = recentChanges.where((change) =>
        userTokenUuids.contains(change['token_uuid']?.toLowerCase() ?? '')
      ).toList();
    }

    if (recentChanges.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.8),
          border: null,
          middle: Text(
            S.of(context).recentUpdatesTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17 + appState.getTextSizeOffset(),
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 56,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 20),
              Text(
                "Aucune modification récente",
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8),
              Text(
                showAllChanges 
                  ? "Aucun changement trouvé dans l'historique complet"
                  : "Aucun changement trouvé dans l'année écoulée",
                style: TextStyle(
                  color: CupertinoColors.systemGrey2,
                  fontSize: 14 + appState.getTextSizeOffset(),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Grouper les changements par date
    Map<String, List<Map<String, dynamic>>> changesByDate = {};
    for (var change in recentChanges) {
      String date = change['date'] ?? '';
      if (date.isNotEmpty) {
        if (!changesByDate.containsKey(date)) {
          changesByDate[date] = [];
        }
        changesByDate[date]!.add(change);
      }
    }

    // Trier les dates (plus récente en premier)
    List<String> sortedDates = changesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.8),
        border: null,
        middle: Text(
          S.of(context).recentUpdatesTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + appState.getTextSizeOffset(),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // En-tête avec filtres
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5.resolveFrom(context).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Premier switch: Portfolio uniquement
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Portfolio",
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label.resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: showUserTokensOnly,
                                onChanged: (value) {
                                  setState(() {
                                    showUserTokensOnly = value;
                                  });
                                },
                                activeTrackColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: isDarkMode 
                                    ? CupertinoColors.systemGrey4.darkColor 
                                    : CupertinoColors.systemGrey5.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Deuxième switch: Inclure tous les champs
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Tous les\nchangements",
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label.resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: includeAllFieldChanges,
                                onChanged: (value) {
                                  setState(() {
                                    includeAllFieldChanges = value;
                                  });
                                },
                                activeTrackColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: isDarkMode 
                                    ? CupertinoColors.systemGrey4.darkColor 
                                    : CupertinoColors.systemGrey5.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Troisième switch: Tous les changements
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Historique\nComplet",
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label.resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: showAllChanges,
                                onChanged: (value) {
                                  setState(() {
                                    showAllChanges = value;
                                  });
                                },
                                activeTrackColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: isDarkMode 
                                    ? CupertinoColors.systemGrey4.darkColor 
                                    : CupertinoColors.systemGrey5.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Liste des changements
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  String date = sortedDates[index];
                  List<Map<String, dynamic>> changesForDate = changesByDate[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de date aligné avec la timeline
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            // Espace pour aligner avec la timeline (32px de largeur)
                            SizedBox(
                              width: 32,
                              child: Center(
                                                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  child: Icon(
                                    CupertinoIcons.calendar,
                                    size: 24,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            
                                                          // Contenu de la date
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      _formatDate(date),
                                      style: TextStyle(
                                        fontSize: 16 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.label.resolveFrom(context),
                                      ),
                                    ),
                                    Spacer(),
                                                                    Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${changesForDate.length} modification${changesForDate.length > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: 12 + appState.getTextSizeOffset(),
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                  ],
                                ),
                              ),
                            
                          ],
                        ),
                      ),

                      // Grouper les changements par token pour cette date avec timeline
                      ..._buildChangesForDateWithTimeline(context, changesForDate, appState, index, sortedDates.length),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
            },
          ),
        ),
      ),
    );
  }

    List<Widget> _buildChangesForDateWithTimeline(BuildContext context, List<Map<String, dynamic>> changes, AppState appState, int dateIndex, int totalDates) {
    // Grouper par token
    Map<String, List<Map<String, dynamic>>> changesByToken = {};
    for (var change in changes) {
      String tokenUuid = change['token_uuid'] ?? '';
      if (!changesByToken.containsKey(tokenUuid)) {
        changesByToken[tokenUuid] = [];
      }
      changesByToken[tokenUuid]!.add(change);
    }

    List<Widget> widgets = [];
    List<String> tokenKeys = changesByToken.keys.toList();
    
    for (int tokenIndex = 0; tokenIndex < tokenKeys.length; tokenIndex++) {
      String tokenUuid = tokenKeys[tokenIndex];
      List<Map<String, dynamic>> tokenChanges = changesByToken[tokenUuid]!;
      
      if (tokenChanges.isNotEmpty) {
        var firstChange = tokenChanges.first;
        String shortName = firstChange['shortName'] ?? 'Token inconnu';
        // Gérer le cas où imageLink peut être une liste ou une chaîne
        String imageUrl = '';
        var imageData = firstChange['imageLink'];
        if (imageData is List && imageData.isNotEmpty) {
          imageUrl = imageData.first?.toString() ?? '';
        } else if (imageData is String) {
          imageUrl = imageData;
        }

        // Récupérer les informations du token complet pour obtenir le pays
        final dataManager = Provider.of<DataManager>(context, listen: false);
        Map<String, dynamic>? fullTokenInfo = dataManager.allTokens.cast<Map<String, dynamic>?>().firstWhere(
          (token) => token?['uuid']?.toLowerCase() == tokenUuid.toLowerCase(),
          orElse: () => null,
        );
        String? country = fullTokenInfo?['country'];

        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline sur la gauche avec hauteur adaptative
                  _buildTimelineIndicator(
                    context, 
                    dateIndex, 
                    tokenIndex, 
                    totalDates, 
                    tokenKeys.length, 
                    _getChangeColor(tokenChanges)
                  ),
                  SizedBox(width: 12),
                  
                  // Carte du token
                  Expanded(
                    child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête du token avec image
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: kIsWeb
                                  ? ShowNetworkImage(
                                      imageSrc: imageUrl,
                                      mobileBoxFit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CupertinoActivityIndicator(
                                          radius: 14,
                                          color: CupertinoColors.activeBlue,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: CupertinoColors.systemGrey6,
                                        child: Icon(
                                          CupertinoIcons.exclamationmark_triangle,
                                          color: CupertinoColors.systemGrey,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                        // Contenu de la carte
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom du token avec indicateur
                              Row(
                                children: [
                                  if (country != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        'assets/country/${country.toLowerCase()}.png',
                                        width: 20 + appState.getTextSizeOffset(),
                                        height: 20 + appState.getTextSizeOffset(),
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            CupertinoIcons.flag,
                                            size: 20 + appState.getTextSizeOffset(),
                                            color: CupertinoColors.systemGrey,
                                          );
                                        },
                                      ),
                                    ),
                                  if (country == null)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getChangeColor(tokenChanges),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      shortName,
                                      style: TextStyle(
                                        fontSize: 18 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label.resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Liste des changements pour ce token
                              ...tokenChanges.map((change) => _buildChangeItem(context, change, appState)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildTimelineIndicator(BuildContext context, int dateIndex, int tokenIndex, int totalDates, int tokensInDate, Color changeColor) {
    bool isFirstDate = dateIndex == 0;
    bool isLastDate = dateIndex == totalDates - 1;
    bool isFirstToken = tokenIndex == 0;
    bool isLastToken = tokenIndex == tokensInDate - 1;
    bool isVeryFirstItem = isFirstDate && isFirstToken;
    bool isVeryLastItem = isLastDate && isLastToken;

    return SizedBox(
      width: 32,
      // Pas de hauteur fixe - s'adapte à la hauteur de la carte
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lignes de connexion continues
          Column(
            children: [
              // Ligne du haut - remplit la moitié supérieure
              if (!isVeryFirstItem)
                Expanded(
                  child: Transform.translate(
                    offset: Offset(0, -8), // Remonte dans l'espace entre les cartes
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.6),
                            CupertinoColors.systemGrey3.resolveFrom(context).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Ligne du bas - remplit la moitié inférieure
              if (!isVeryLastItem)
                Expanded(
                  child: Transform.translate(
                    offset: Offset(0, 8), // Descend dans l'espace entre les cartes
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CupertinoColors.systemGrey3.resolveFrom(context).withOpacity(0.8),
                            CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Point principal de la timeline par-dessus les lignes
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: changeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: changeColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(BuildContext context, Map<String, dynamic> change, AppState appState) {
    String fieldLabel = change['fieldLabel'] ?? 'Champ inconnu';
    String changeType = change['changeType'] ?? 'change';
    var previousValue = change['previousValue'];
    var currentValue = change['currentValue'];

    Color changeColor = _getChangeTypeColor(changeType);
    IconData changeIcon = _getChangeTypeIcon(changeType);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: changeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                changeIcon,
                size: 16,
                color: changeColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  fieldLabel,
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Ancienne valeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                      Text(
                    "Ancien:",
                    style: TextStyle(
                      fontSize: 12 + appState.getTextSizeOffset(),
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                                      Text(
                    _formatValue(previousValue, change['field']),
                    style: TextStyle(
                      fontSize: 13 + appState.getTextSizeOffset(),
                      decoration: TextDecoration.lineThrough,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                  ],
                ),
              ),
              // Flèche
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  CupertinoIcons.arrow_right,
                  size: 14,
                  color: changeColor,
                ),
              ),
              // Nouvelle valeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nouveau:",
                      style: TextStyle(
                        fontSize: 12 + appState.getTextSizeOffset(),
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                    Text(
                      _formatValue(currentValue, change['field']),
                      style: TextStyle(
                        fontSize: 14 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime targetDate = DateTime(date.year, date.month, date.day);
      
      int difference = today.difference(targetDate).inDays;
      
      if (difference == 0) {
        return "Aujourd'hui";
      } else if (difference == 1) {
        return "Hier";
      } else if (difference < 7) {
        return "Il y a $difference jours";
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatValue(dynamic value, String? field) {
    if (value == null) return 'N/A';
    
    if (value is num) {
      if (field?.contains('price') == true || field?.contains('investment') == true || field?.contains('rent') == true || field?.contains('reserve') == true) {
        return '\$${NumberFormat('#,##0.00').format(value)}';
      } else if (field?.contains('units') == true) {
        int units = value.round();
        return '$units unité${units > 1 ? 's' : ''}';
      } else {
        return NumberFormat('#,##0.00').format(value);
      }
    }
    
    return value.toString();
  }

  Color _getChangeColor(List<Map<String, dynamic>> changes) {
    if (changes.any((change) => change['changeType'] == 'increase')) {
      return CupertinoColors.systemGreen;
    } else if (changes.any((change) => change['changeType'] == 'decrease')) {
      return CupertinoColors.systemRed;
    }
    return CupertinoColors.systemBlue;
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'increase':
        return CupertinoColors.systemGreen;
      case 'decrease':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemBlue;
    }
  }

  IconData _getChangeTypeIcon(String changeType) {
    switch (changeType) {
      case 'increase':
        return CupertinoIcons.arrow_up;
      case 'decrease':
        return CupertinoIcons.arrow_down;
      default:
        return CupertinoIcons.arrow_right_arrow_left;
    }
  }
}
