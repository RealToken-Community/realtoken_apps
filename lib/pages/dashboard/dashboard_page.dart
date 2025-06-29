import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/settings/manage_evm_addresses_page.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'dart:ui'; // Pour ImageFilter
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/portfolio_card.dart';
import 'widgets/rmm_card.dart';
import 'widgets/real_estate_card.dart';
import 'widgets/loan_income_card.dart';
import 'widgets/factoring_card.dart';
import 'widgets/tokens_card.dart';
import 'widgets/rents_card.dart';
import 'widgets/next_rondays_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Vérifier si les données sont déjà chargées
      final dataManager = Provider.of<DataManager>(context, listen: false);
      
      // Si les données principales sont déjà chargées (depuis main.dart)
      if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && dataManager.portfolio.isNotEmpty) {
        debugPrint("📊 Dashboard: données principales déjà chargées");
        // Vérifier si les données de loyer sont aussi chargées
        if (dataManager.rentData.isNotEmpty) {
          debugPrint("📊 Dashboard: données de loyer aussi chargées, skip chargement");
          setState(() {
            _isPageLoading = false;
          });
        } else {
          debugPrint("📊 Dashboard: données de loyer manquantes, chargement nécessaire");
          await DataFetchUtils.loadDataWithCache(context);
        setState(() {
          _isPageLoading = false;
        });
        }
      } 
      // Sinon, charger les données avec cache
      else {
        debugPrint("📊 Dashboard: chargement des données nécessaire");
        await DataFetchUtils.loadDataWithCache(context);
        setState(() {
          _isPageLoading = false;
        });
      }

      // Vérifier s'il n'y a pas de wallet après le chargement
      if (dataManager.evmAddresses.isEmpty) {
        _showNoWalletPopup();
      }
    });
  }

  Future<void> _importZippedHiveData() async {
    try {
      // Utiliser file_picker pour permettre à l'utilisateur de sélectionner un fichier ZIP
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'], // Limiter à l'importation de fichiers ZIP
      );

      if (result != null) {
        // Obtenir le fichier sélectionné
        List<int> bytes;
        if (kIsWeb) {
          bytes = result.files.single.bytes!;
        } else {
          File zipFile = File(result.files.single.path!);
          bytes = await zipFile.readAsBytes();
        }

        // Lire le fichier ZIP et le décompresser
        Archive archive = ZipDecoder().decodeBytes(bytes);

        // Parcourir les fichiers dans l'archive ZIP
        for (ArchiveFile file in archive) {
          List<int> jsonBytes = file.content as List<int>;
          String jsonContent = utf8.decode(jsonBytes);

          if (file.name == 'balanceHistoryBackup.json') {
            // Décoder et insérer les données dans la boîte 'balanceHistory'
            Map<String, dynamic> balanceHistoryData = jsonDecode(jsonContent);
            var balanceHistoryBox = await Hive.openBox('balanceHistory');
            await balanceHistoryBox.putAll(balanceHistoryData);
          } else if (file.name == 'preferencesBackup.json') {
            // Décoder et insérer les préférences dans SharedPreferences
            Map<String, dynamic> preferencesData = jsonDecode(jsonContent);
            final prefs = await SharedPreferences.getInstance();

            // Restaurer les préférences sauvegardées
            List<String> ethAddresses = List<String>.from(preferencesData['ethAddresses'] ?? []);
            String? userIdToAddresses = preferencesData['userIdToAddresses'];
            String? selectedCurrency = preferencesData['selectedCurrency'];
            bool convertToSquareMeters = preferencesData['convertToSquareMeters'] ?? false;

            // Sauvegarder les préférences restaurées
            await prefs.setStringList('evmAddresses', ethAddresses);
            if (userIdToAddresses != null) await prefs.setString('userIdToAddresses', userIdToAddresses);
            if (selectedCurrency != null) await prefs.setString('selectedCurrency', selectedCurrency);
            await prefs.setBool('convertToSquareMeters', convertToSquareMeters);
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).importSuccess)),
          );
          
          // Rafraîchir les données après l'import
          await DataFetchUtils.refreshData(context);
          
          // Recharger la page pour refléter les changements
          setState(() {
            _isPageLoading = false;
          });
        }
      } else {
        debugPrint('Importation annulée par l\'utilisateur.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).importFailed)),
        );
      }
      debugPrint('Erreur lors de l\'importation des données : $e');
    }
  }

  void _showNoWalletPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.of(context).noDataAvailable,
                      style: TextStyle(
                        fontSize: 18 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
                             content: Text(
                 S.of(context).noWalletMessage,
                 style: TextStyle(
                   fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                 ),
               ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Première ligne : boutons Ajouter et Import côte à côte
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _importZippedHiveData();
                            },
                            icon: Icon(
                              Icons.upload_file,
                              size: 18,
                            ),
                            label: Text(S.of(context).importButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ManageEvmAddressesPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(S.of(context).manageAddresses),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Deuxième ligne : bouton Plus tard centré
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Plus tard',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Calcule le temps écoulé depuis le premier loyer reçu
  String _getTimeElapsedSinceFirstRent(DataManager dataManager) {
    final rentData = dataManager.rentData;

    if (rentData.isEmpty) {
      return "";
    }

    // Trier les données par date (la plus ancienne en premier)
    rentData.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    // Date du premier loyer
    final firstRentDate = DateTime.parse(rentData.first['date']);
    final today = DateTime.now();

    // Calcul de la différence
    final difference = today.difference(firstRentDate);

    // Calcul en années et mois
    int years = difference.inDays ~/ 365;
    int months = (difference.inDays % 365) ~/ 30;

    // Format plus lisible
    if (years > 0) {
      return years == 1 ? "$years year ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}" : "$years years ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}";
    } else if (months > 0) {
      return "$months month${months > 1 ? 's' : ''}";
    } else {
      return "< 1 month";
    }
  }

  /// Vérifie si tous les wallets ont été traités avec succès cette semaine pour les données de loyer basiques
  Future<bool> _checkRentWalletsStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> wallets = prefs.getStringList('evmAddresses') ?? [];
      
      if (wallets.isEmpty) return true; // Pas de wallets = pas de problème
      
      final box = Hive.box('realTokens');
      final DateTime now = DateTime.now();
      
      // Calculer le début de la semaine actuelle (lundi)
      final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
      final DateTime startOfCurrentWeekMidnight = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
      
      debugPrint('🔍 DEBUG ALERTE - Début de semaine: $startOfCurrentWeekMidnight');
      debugPrint('🔍 DEBUG ALERTE - Maintenant: $now');
      debugPrint('🔍 DEBUG ALERTE - ${wallets.length} wallets à vérifier: ${wallets.join(", ")}');
      
      // Vérifier le statut de chaque wallet pour les données basiques uniquement
      for (String wallet in wallets) {
        final lastSuccessTime = box.get('lastRentSuccess_$wallet');
        if (lastSuccessTime != null) {
          final DateTime lastSuccess = DateTime.parse(lastSuccessTime);
          final bool isAfterWeekStart = lastSuccess.isAfter(startOfCurrentWeekMidnight);
          debugPrint('🔍 DEBUG ALERTE - Wallet $wallet basique: $lastSuccess (après début semaine: $isAfterWeekStart)');
          if (!isAfterWeekStart) {
            debugPrint('🚨 DEBUG ALERTE - ALERTE: Wallet $wallet pas traité cette semaine (basique)');
            return false; // Ce wallet n'a pas été traité cette semaine
          }
        } else {
          debugPrint('🚨 DEBUG ALERTE - ALERTE: Wallet $wallet sans timestamp de succès (basique)');
          return false; // Aucun timestamp de succès pour ce wallet
        }
      }
      
      debugPrint('✅ DEBUG ALERTE - Tous les wallets OK, pas d\'alerte');
      return true; // Tous les wallets ont été traités avec succès
    } catch (e) {
      debugPrint('❌ Erreur vérification statut wallets: $e');
      return false; // En cas d'erreur, considérer qu'il y a un problème
    }
  }

  /// Construit l'icône d'alerte pour les problèmes de wallets
  Widget _buildWalletAlertIcon() {
    return FutureBuilder<bool>(
      future: _checkRentWalletsStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Pas d'icône pendant le chargement
        }
        
        final bool allWalletsOk = snapshot.data ?? true;
        
        if (allWalletsOk) {
          return const SizedBox.shrink(); // Pas d'icône si tout va bien
        }
        
        // Afficher l'icône d'alerte
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Problème sync',
                style: TextStyle(
                  fontSize: 11 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final appState = Provider.of<AppState>(context);

    final lastRentReceived = _getLastRentReceived(dataManager);
    final totalRentReceived = _getTotalRentReceived(dataManager, currencyUtils, appState);
    final timeElapsed = _getTimeElapsedSinceFirstRent(dataManager);
    
    // Vérifier si des données sont en cours de mise à jour pour les shimmers
    final bool shouldShowShimmers = _isPageLoading || dataManager.isUpdatingData;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Color(0xFFF2F2F7) // Couleur de fond iOS light mode
          : Color(0xFF000000), // Couleur de fond iOS dark mode
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isPageLoading = true;
              });
              await DataFetchUtils.refreshData(context);
              setState(() {
                _isPageLoading = false;
              });
            },
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).cardColor,
            displacement: 110,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(top: UIUtils.getAppBarHeight(context), left: 12.0, right: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context).hello,
                            style: TextStyle(fontSize: 28 + appState.getTextSizeOffset(), fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                          if (kIsWeb)
                            IconButton(
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _isPageLoading = true;
                                });
                                await DataFetchUtils.refreshData(context);
                                setState(() {
                                  _isPageLoading = false;
                                });
                              },
                            ),
                                            ],
                  ),
                ),
                const SizedBox(height: 8),
                    Container(
                      margin: EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            Theme.of(context).primaryColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.2, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            S.of(context).lastRentReceived,
                                            style: TextStyle(
                                              fontSize: 13 + appState.getTextSizeOffset(),
                                              color: Colors.white70,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          dataManager.isLoadingMain || shouldShowShimmers
                                            ? ShimmerUtils.originalColorShimmer(
                                                child: Text(
                                                  lastRentReceived,
                                                  style: TextStyle(
                                                    fontSize: 20 + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                color: Colors.white,
                                              )
                                            : Text(
                                                lastRentReceived,
                                                style: TextStyle(
                                                  fontSize: 20 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Total des loyers',
                                            style: TextStyle(
                                              fontSize: 13 + appState.getTextSizeOffset(),
                                              color: Colors.white70,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          dataManager.isLoadingMain || shouldShowShimmers
                                            ? ShimmerUtils.originalColorShimmer(
                                                child: Text(
                                                  totalRentReceived,
                                                  style: TextStyle(
                                                    fontSize: 20 + appState.getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                color: Colors.white,
                                              )
                                            : Text(
                                                totalRentReceived,
                                                style: TextStyle(
                                                  fontSize: 20 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                   Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Icône d'alerte à gauche
                                    _buildWalletAlertIcon(),
                                    // Informations calendrier à droite
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Depuis $timeElapsed',
                                            style: TextStyle(
                                              fontSize: 12 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Affichage adaptatif : 2 colonnes sur grands écrans, 1 colonne sur petits écrans
                    MediaQuery.of(context).size.width > 700
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Première colonne
                              Expanded(
                                child: Column(
                                  children: [
                                    PortfolioCard(
                                      showAmounts: appState.showAmounts,
                                      isLoading: shouldShowShimmers,
                                      context: context,
                                    ),
                                    const SizedBox(height: 8),
                                    TokensCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                    const SizedBox(height: 8),
                                    // Cartes par type de produit en ligne
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RealEstateCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: LoanIncomeCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: FactoringCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    RentsCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                  ],
                                ),
                              ),
                              // Espacement entre les colonnes
                              const SizedBox(width: 8),
                              // Deuxième colonne
                              Expanded(
                                child: Column(
                                  children: [
                                    RmmCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                    const SizedBox(height: 8),
                                    NextRondaysCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              PortfolioCard(
                                showAmounts: appState.showAmounts,
                                isLoading: shouldShowShimmers,
                                context: context,
                              ),
                              const SizedBox(height: 8),
                              RmmCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                              const SizedBox(height: 8),
                              TokensCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                              const SizedBox(height: 8),
                              // Cartes par type de produit en ligne sur tous les écrans
                              Row(
                                children: [
                                  Expanded(
                                    child: RealEstateCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: LoanIncomeCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: FactoringCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RentsCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                              const SizedBox(height: 8),
                              NextRondaysCard(showAmounts: appState.showAmounts, isLoading: shouldShowShimmers),
                            ],
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? Color(0xFFE5F2FF) : Color(0xFF0A3060),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              S.of(context).noDataAvailable,
              style: TextStyle(
                fontSize: 17 + Provider.of<AppState>(context).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.light ? Color(0xFF007AFF) : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ManageEvmAddressesPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF007AFF),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(S.of(context).manageAddresses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Récupère la dernière valeur de loyer
  String _getLastRentReceived(DataManager dataManager) {
    final rentData = dataManager.rentData;
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context);

    // Si les données sont en cours de chargement, retourner un placeholder
    if (dataManager.isLoadingMain || _isPageLoading) {
      return "---";
    }

    if (rentData.isEmpty) {
      return S.of(context).noRentReceived;
    }

    rentData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final lastRent = rentData.first['rent'];

    // Utiliser _getFormattedAmount pour masquer ou afficher la valeur
    return currencyUtils.getFormattedAmount(currencyUtils.convert(lastRent), currencyUtils.currencySymbol, appState.showAmounts);
  }

  // Récupère le total des loyers reçus avec gestion du chargement
  String _getTotalRentReceived(DataManager dataManager, CurrencyProvider currencyUtils, AppState appState) {
    // Si les données sont en cours de chargement, retourner un placeholder
    if (dataManager.isLoadingMain || _isPageLoading) {
      return "---";
    }

    final totalRent = dataManager.getTotalRentReceived();
    return currencyUtils.getFormattedAmount(currencyUtils.convert(totalRent), currencyUtils.currencySymbol, appState.showAmounts);
  }
}
