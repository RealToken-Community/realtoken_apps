import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'portfolio_display_1.dart';
import 'portfolio_display_2.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart'; // Import pour les traductions
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/components/filter_widgets.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  PortfolioPageState createState() => PortfolioPageState();
}

class PortfolioPageState extends State<PortfolioPage> {
  // Identifiants internes pour les statuts de location
  static const String rentalStatusAll = "all";
  static const String rentalStatusRented = "rented";
  static const String rentalStatusPartially = "partially";
  static const String rentalStatusNotRented = "not_rented";

  bool _isDisplay1 = true;
  String _searchQuery = '';
  String _sortOption = 'sort by recently added';
  bool _isAscending = true;
  String? _selectedCity;
  String? _selectedRegion;
  String? _selectedCountry;
  String _rentalStatusFilter = rentalStatusAll; // Utilise l'identifiant interne
  Set<String> _selectedWallets = {};
  Set<String> _selectedTokenTypes = {"wallet", "RMM"};
  Set<String> _selectedProductTypes = {}; // Nouveau filtre pour productType

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Vérifier si les données sont déjà chargées
      final dataManager = Provider.of<DataManager>(context, listen: false);
      
      // Si les données du portfolio sont déjà chargées (depuis main.dart)
      if (!dataManager.isLoadingMain && dataManager.evmAddresses.isNotEmpty && dataManager.portfolio.isNotEmpty) {
        debugPrint("💼 Portfolio: données déjà chargées, skip chargement");
      } 
      // Sinon, charger les données avec cache
      else {
        debugPrint("💼 Portfolio: chargement des données nécessaire");
        await DataFetchUtils.loadDataWithCache(context);
      }
      
      // Charger les préférences d'affichage dans tous les cas
      _loadDisplayPreference();
      _loadFilterPreferences();
    });
  }

  // Charger les préférences d'affichage
  Future<void> _loadDisplayPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Assurez-vous d'utiliser addPostFrameCallback même ici
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Vérifie que le widget est toujours monté
        setState(() {
          _isDisplay1 = prefs.getBool('isDisplay1') ?? true;
        });
      }
    });
  }

  // Sauvegarder l'affichage
  Future<void> _saveDisplayPreference(bool isDisplay1) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDisplay1', isDisplay1);
  }

  void _toggleDisplay() {
    setState(() {
      _isDisplay1 = !_isDisplay1;
    });
    _saveDisplayPreference(_isDisplay1);
  }

  // Charger les filtres et tri depuis SharedPreferences
  Future<void> _loadFilterPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Assurez-vous d'utiliser addPostFrameCallback même ici
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Vérifie que le widget est toujours monté
        setState(() {
          _sortOption = prefs.getString('sortOption') ?? S.of(context).sortByInitialLaunchDate;
          _isAscending = prefs.getBool('isAscending') ?? false;
          _selectedCity = prefs.getString('selectedCity')?.isEmpty ?? true ? null : prefs.getString('selectedCity');
          _selectedRegion = prefs.getString('selectedRegion')?.isEmpty ?? true ? null : prefs.getString('selectedRegion');
          _selectedCountry = prefs.getString('selectedCountry')?.isEmpty ?? true ? null : prefs.getString('selectedCountry');
          // On récupère l'identifiant interne, par défaut "all"
          _rentalStatusFilter = prefs.getString('rentalStatusFilter') ?? rentalStatusAll;
          // Charger les productTypes sélectionnés
          List<String>? savedProductTypes = prefs.getStringList('selectedProductTypes');
          _selectedProductTypes = savedProductTypes?.toSet() ?? {};
        });
      }
    });
  }

  // Sauvegarder les filtres et tri dans SharedPreferences
  Future<void> _saveFilterPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortOption', _sortOption);
    await prefs.setBool('isAscending', _isAscending);
    await prefs.setString('selectedCity', _selectedCity ?? '');
    await prefs.setString('selectedRegion', _selectedRegion ?? '');
    await prefs.setString('selectedCountry', _selectedCountry ?? '');
    // On sauvegarde l'identifiant interne
    await prefs.setString('rentalStatusFilter', _rentalStatusFilter);
    // Sauvegarder les productTypes sélectionnés
    await prefs.setStringList('selectedProductTypes', _selectedProductTypes.toList());
  }

  // Méthodes de gestion des filtres et tri
  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _updateSortOption(String value) {
    setState(() {
      _sortOption = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateCityFilter(String? value) {
    setState(() {
      _selectedCity = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateRegionFilter(String? value) {
    setState(() {
      _selectedRegion = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateCountryFilter(String? value) {
    setState(() {
      _selectedCountry = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  void _updateRentalStatusFilter(String value) {
    setState(() {
      _rentalStatusFilter = value;
    });
    _saveFilterPreferences(); // Sauvegarde
  }

  List<Map<String, dynamic>> _groupAndSumPortfolio(List<Map<String, dynamic>> portfolio) {
    Map<String, Map<String, dynamic>> groupedPortfolio = {};

    for (var token in portfolio) {
      String shortName = token['shortName']; // Utilisez l'identifiant unique
      double tokenAmount = double.tryParse(token['amount'].toString()) ?? 0.0;
      double tokenValue = double.tryParse(token['totalValue'].toString()) ?? 0.0;
      double dailyIncome = double.tryParse(token['dailyIncome'].toString()) ?? 0.0;
      double monthlyIncome = double.tryParse(token['monthlyIncome'].toString()) ?? 0.0;
      double yearlyIncome = double.tryParse(token['yearlyIncome'].toString()) ?? 0.0;

      bool isInWallet = token['source'] == 'wallet'; // Ajout de la vérification pour le wallet
      bool isInRMM = token['source'] == 'RMM'; // Ajout de la vérification pour le RMM

      if (groupedPortfolio.containsKey(shortName)) {
        groupedPortfolio[shortName]!['amount'] = (groupedPortfolio[shortName]!['amount'] as double) + tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] = (groupedPortfolio[shortName]!['totalValue'] as double) + tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] = (groupedPortfolio[shortName]!['dailyIncome'] as double) + dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] = (groupedPortfolio[shortName]!['monthlyIncome'] as double) + monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] = (groupedPortfolio[shortName]!['yearlyIncome'] as double) + yearlyIncome;

        groupedPortfolio[shortName]!['inWallet'] |= isInWallet;
        groupedPortfolio[shortName]!['inRMM'] |= isInRMM;
        // Agrégation des adresses wallet
        if (token['evmAddress'] != null && token['evmAddress'].toString().isNotEmpty) {
          if (groupedPortfolio[shortName]!['evmAddresses'] == null) {
            groupedPortfolio[shortName]!['evmAddresses'] = {token['evmAddress']};
          } else {
            (groupedPortfolio[shortName]!['evmAddresses'] as Set<String>).add(token['evmAddress']);
          }
        }
      } else {
        groupedPortfolio[shortName] = Map<String, dynamic>.from(token);
        groupedPortfolio[shortName]!['amount'] = tokenAmount;
        groupedPortfolio[shortName]!['totalValue'] = tokenValue;
        groupedPortfolio[shortName]!['dailyIncome'] = dailyIncome;
        groupedPortfolio[shortName]!['monthlyIncome'] = monthlyIncome;
        groupedPortfolio[shortName]!['yearlyIncome'] = yearlyIncome;
        groupedPortfolio[shortName]!['inWallet'] = isInWallet;
        groupedPortfolio[shortName]!['inRMM'] = isInRMM;
        // Initialisation du set d'adresses wallet
        groupedPortfolio[shortName]!['evmAddresses'] = (token['evmAddress'] != null && token['evmAddress'].toString().isNotEmpty) ? {token['evmAddress']} : <String>{};
      }
    }

    return groupedPortfolio.values.toList();
  }

  // Modifier la méthode pour appliquer le filtre sur le statut de location
  List<Map<String, dynamic>> _filterAndSortPortfolio(List<Map<String, dynamic>> portfolio) {
    // Regroupez et cumulez les tokens similaires
    List<Map<String, dynamic>> groupedPortfolio = _groupAndSumPortfolio(portfolio);

    // Filtrez sur différents critères
    List<Map<String, dynamic>> filteredPortfolio = groupedPortfolio
        .where((token) =>
            // Filtre par recherche
            token['fullName'].toLowerCase().contains(_searchQuery.toLowerCase()) &&
            // Filtre par ville (conservé pour compatibilité)
            (_selectedCity == null || token['fullName'].contains(_selectedCity!)) &&
            // Filtre par région
            (_selectedRegion == null || (token['regionCode'] != null && token['regionCode'] == _selectedRegion)) &&
            // Filtre par pays
            (_selectedCountry == null || _matchesCountryFilter(token, _selectedCountry)) &&
            // Filtre par statut de location
            (_rentalStatusFilter == rentalStatusAll || _filterByRentalStatus(token)))
        .toList();

    // Filtre par wallet (si au moins un wallet est sélectionné)
    if (_selectedWallets.isNotEmpty) {
      filteredPortfolio = filteredPortfolio.where((token) {
        // Utiliser la clé 'wallets' qui contient la liste des wallets
        if (token['wallets'] != null) {
          try {
            // Si c'est une liste, la convertir en Set
            if (token['wallets'] is List) {
              var walletsList = token['wallets'] as List;
              Set<String> tokenWallets = walletsList.map((w) => w.toString()).toSet();
              // Vérifier s'il y a une intersection avec les wallets sélectionnés
              return tokenWallets.intersection(_selectedWallets).isNotEmpty;
            }
            // Si c'est une chaîne unique
            else if (token['wallets'] is String) {
              String wallet = token['wallets'].toString();
              return _selectedWallets.contains(wallet);
            }
          } catch (e) {
            // En cas d'erreur
            debugPrint("Erreur lors du filtrage des wallets: $e");
          }
        }
        return false; // Aucun wallet trouvé ou ne correspond
      }).toList();
    }

    // Filtre par type si l'utilisateur n'a pas sélectionné tous les types
    if (_selectedTokenTypes.isEmpty) {
      // Aucun type sélectionné : ne retourner aucun token
      filteredPortfolio = [];
    } else if (!(_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM"))) {
      // Si la sélection n'inclut pas tous les types, appliquer le filtre par token["source"]
      filteredPortfolio = filteredPortfolio.where((token) {
        String tokenType = token['source'] ?? '';
        return _selectedTokenTypes.contains(tokenType);
      }).toList();
    }

    // Filtre par productType si des types de produits sont sélectionnés
    if (_selectedProductTypes.isNotEmpty) {
      filteredPortfolio = filteredPortfolio.where((token) {
        String productType = token['productType'] ?? 'other';
        return _selectedProductTypes.contains(productType);
      }).toList();
    }

    // Tri en fonction des options sélectionnées
    if (_sortOption == S.of(context).sortByName) {
      filteredPortfolio.sort((a, b) => _isAscending ? a['shortName'].compareTo(b['shortName']) : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == S.of(context).sortByValue) {
      filteredPortfolio.sort((a, b) => _isAscending ? a['totalValue'].compareTo(b['totalValue']) : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == S.of(context).sortByAPY) {
      filteredPortfolio.sort((a, b) => _isAscending ? a['annualPercentageYield'].compareTo(b['annualPercentageYield']) : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    } else if (_sortOption == S.of(context).sortByInitialLaunchDate) {
      filteredPortfolio.sort((a, b) {
        final dateA = a['initialLaunchDate'] != null ? DateTime.tryParse(a['initialLaunchDate']) : DateTime(1970);
        final dateB = b['initialLaunchDate'] != null ? DateTime.tryParse(b['initialLaunchDate']) : DateTime(1970);
        return _isAscending ? dateA!.compareTo(dateB!) : dateB!.compareTo(dateA!);
      });
    }

    return filteredPortfolio;
  }

  // Nouvelle méthode pour filtrer par statut de location
  bool _filterByRentalStatus(Map<String, dynamic> token) {
    int rentedUnits = token['rentedUnits'] ?? 0;
    int totalUnits = token['totalUnits'] ?? 1;

    if (_rentalStatusFilter == rentalStatusRented) {
      return rentedUnits == totalUnits;
    } else if (_rentalStatusFilter == rentalStatusPartially) {
      return rentedUnits > 0 && rentedUnits < totalUnits;
    } else if (_rentalStatusFilter == rentalStatusNotRented) {
      return rentedUnits == 0;
    }
    return true;
  }

  // Méthodes factorisées utilisant FilterWidgets
  List<String> _getUniqueCities(List<Map<String, dynamic>> portfolio) => FilterWidgets.getUniqueCities(portfolio);
  List<String> _getUniqueRegions(List<Map<String, dynamic>> portfolio) => FilterWidgets.getUniqueRegions(portfolio);
  List<String> _getUniqueCountries(List<Map<String, dynamic>> portfolio) => FilterWidgets.getUniqueCountries(portfolio);
  
  // Méthode pour vérifier si un token correspond au filtre pays
  bool _matchesCountryFilter(Map<String, dynamic> token, String? selectedCountry) {
    if (selectedCountry == null) return true;
    
    String tokenCountry = token['country'] ?? "Unknown Country";
    
    // Si "Series XX" est sélectionné, filtrer tous les tokens factoring_profitshare avec des séries
    if (selectedCountry == "Series XX") {
      return (token['productType']?.toString().toLowerCase() == 'factoring_profitshare') && 
             tokenCountry.toLowerCase().startsWith('series ');
    }
    
    // Filtre normal
    return tokenCountry == selectedCountry;
  }
  
  // Méthode pour obtenir les types de produits uniques
  List<String> _getUniqueProductTypes(List<Map<String, dynamic>> portfolio) {
    Set<String> productTypes = {};
    for (var token in portfolio) {
      String productType = token['productType'] ?? 'other';
      if (productType.isNotEmpty) {
        productTypes.add(productType);
      }
    }
    return productTypes.toList()..sort();
  }

  // Méthode pour obtenir l'icône appropriée pour chaque type de produit
  IconData _getProductTypeIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'real_estate_rental':
        return Icons.home;
      case 'factoring_profitshare':
        return Icons.business_center;
      case 'loan_income':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewPadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: false,
        body: Consumer<DataManager>(
          builder: (context, dataManager, child) {
            final sortedFilteredPortfolio = _filterAndSortPortfolio(dataManager.portfolio);
            final uniqueCities = _getUniqueCities(dataManager.portfolio);
            final uniqueRegions = _getUniqueRegions(dataManager.portfolio);
            final uniqueCountries = _getUniqueCountries(dataManager.portfolio);

            return Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      automaticallyImplyLeading: false,
                      expandedHeight: UIUtils.getSliverAppBarHeight(context) + 65,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                child: Column(
                                  children: [
                                    // Barre avec recherche et bouton d'affichage
                                    Row(
                                      children: [
                                        // Conteneur de recherche avec bords arrondis
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8, right: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.03),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                // Icône de recherche
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 12.0),
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Theme.of(context).primaryColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Champ de recherche
                                                Expanded(
                                                  child: TextField(
                                                    onChanged: (value) {
                                                      _updateSearchQuery(value);
                                                    },
                                                    style: TextStyle(fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      hintText: S.of(context).searchHint,
                                                      hintStyle: TextStyle(
                                                        fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Bouton d'affichage séparé
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: EdgeInsets.zero,
                                          child: _buildFilterButton(
                                            icon: _isDisplay1 ? Icons.view_module : Icons.view_list,
                                            label: _isDisplay1 ? S.of(context).gridView : S.of(context).listView,
                                            onTap: _toggleDisplay,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Ligne des contrôles principaux
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          // Filtre par Pays
                                          _buildCountryFilterMenu(
                                            context: context,
                                            icon: Icons.flag,
                                            selectedCountry: _selectedCountry,
                                            onCountryChanged: (newSelectedCountry) {
                                              _updateCountryFilter(newSelectedCountry);
                                            },
                                          ),

                                          const SizedBox(width: 8),

                                          // Filtre par Région
                                          _buildRegionFilterMenu(
                                            context: context,
                                            icon: Icons.map,
                                            selectedRegion: _selectedRegion,
                                            onRegionChanged: (newSelectedRegion) {
                                              _updateRegionFilter(newSelectedRegion);
                                            },
                                          ),

                                          const SizedBox(width: 8),

                                          // Filtre par ProductType
                                          _buildProductTypeFilterMenu(
                                            context: context,
                                            icon: Icons.category,
                                            selectedProductTypes: _selectedProductTypes,
                                            onProductTypesChanged: (newSelectedProductTypes) {
                                              setState(() {
                                                _selectedProductTypes = newSelectedProductTypes;
                                              });
                                              _saveFilterPreferences();
                                            },
                                          ),

                                          const SizedBox(width: 8),

                                          // Filtre Statut de location
                                          _buildRentalStatusFilterMenu(
                                            context: context,
                                            icon: Icons.home_work,
                                            selectedRentalStatus: _rentalStatusFilter,
                                            onRentalStatusChanged: (newRentalStatus) {
                                              _updateRentalStatusFilter(newRentalStatus);
                                              _saveFilterPreferences();
                                            },
                                          ),

                                          const SizedBox(width: 8),

                                          // Filtre Type de token (Wallet/RMM)
                                          _buildTokenTypeFilterMenu(
                                            context: context,
                                            icon: Icons.account_tree,
                                            selectedTokenTypes: _selectedTokenTypes,
                                            onTokenTypesChanged: (newSelectedTokenTypes) {
                                              setState(() {
                                                _selectedTokenTypes = newSelectedTokenTypes;
                                              });
                                              _saveFilterPreferences();
                                            },
                                          ),

                                          const SizedBox(width: 8),

                                          // Filtres Wallet
                                          _buildWalletFilterMenu(
                                            context: context,
                                            icon: Icons.account_balance_wallet,
                                            selectedWallets: _selectedWallets,
                                            onWalletsChanged: (newSelectedWallets) {
                                              setState(() {
                                                _selectedWallets = newSelectedWallets;
                                              });
                                            },
                                          ),

                                          // Espace flexible pour pousser le tri à droite
                                          const Spacer(),

                                          //Tri
                                          Container(
                                            margin: EdgeInsets.zero, // Sans marge
                                            child: PopupMenuButton<String>(
                                              tooltip: "",
                                              onSelected: (String value) {
                                                if (value == 'asc' || value == 'desc') {
                                                  setState(() {
                                                    _isAscending = (value == 'asc');
                                                  });
                                                  _saveFilterPreferences(); // Sauvegarder après la modification
                                                } else {
                                                  _updateSortOption(value);
                                                }
                                              },
                                              offset: const Offset(0, 40),
                                              elevation: 8,
                                              color: Theme.of(context).cardColor.withValues(alpha: 0.97),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.sort,
                                                  size: 20,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              itemBuilder: (context) => [
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByName,
                                                  checked: _sortOption == S.of(context).sortByName,
                                                  child: Text(S.of(context).sortByName),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByValue,
                                                  checked: _sortOption == S.of(context).sortByValue,
                                                  child: Text(S.of(context).sortByValue),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByAPY,
                                                  checked: _sortOption == S.of(context).sortByAPY,
                                                  child: Text(S.of(context).sortByAPY),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: S.of(context).sortByInitialLaunchDate,
                                                  checked: _sortOption == S.of(context).sortByInitialLaunchDate,
                                                  child: Text(S.of(context).sortByInitialLaunchDate),
                                                ),
                                                const PopupMenuDivider(),
                                                CheckedPopupMenuItem(
                                                  value: 'asc',
                                                  checked: _isAscending,
                                                  child: Text(S.of(context).ascending),
                                                ),
                                                CheckedPopupMenuItem(
                                                  value: 'desc',
                                                  checked: !_isAscending,
                                                  child: Text(S.of(context).descending),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                  ];
                },
 body: _isDisplay1 
                  ? PortfolioDisplay1(
                      portfolio: sortedFilteredPortfolio,
                      isLoading: Provider.of<DataManager>(context).isLoadingMain || Provider.of<DataManager>(context).isUpdatingData,
                    ) 
                  : PortfolioDisplay2(
                      portfolio: sortedFilteredPortfolio,
                      isLoading: Provider.of<DataManager>(context).isLoadingMain || Provider.of<DataManager>(context).isUpdatingData,
                    ),              ),
            );
          },
        ),
      ),
    );
  }

  // Helper pour construire un bouton de filtre simple
  // Méthodes factorisées utilisant FilterWidgets
  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => FilterWidgets.buildFilterButton(
    context: context,
    icon: icon,
    label: label,
    onTap: onTap,
  );

  Widget _buildFilterPopupMenu({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<String>> items,
    required Function(String) onSelected,
  }) => FilterWidgets.buildFilterPopupMenu(
    context: context,
    icon: icon,
    label: label,
    items: items,
    onSelected: onSelected,
  );

  // Helper pour obtenir le label du tri actuel
  String _getSortLabel(BuildContext context) {
    if (_sortOption == S.of(context).sortByName) {
      return "Name";
    } else if (_sortOption == S.of(context).sortByValue) {
      return "Value";
    } else if (_sortOption == S.of(context).sortByAPY) {
      return "APY";
    } else {
      return "Date";
    }
  }

  // Helper pour obtenir le label du statut de location
  String _getRentalStatusLabel(BuildContext context) {
    switch (_rentalStatusFilter) {
      case rentalStatusRented:
        return S.of(context).rentalStatusRented;
      case rentalStatusPartially:
        return S.of(context).rentalStatusPartiallyRented;
      case rentalStatusNotRented:
        return S.of(context).rentalStatusNotRented;
      default:
        return S.of(context).rentalStatusAll;
    }
  }

  // Helper pour obtenir le label des filtres combinés
  String _getCombinedFilterLabel() {
    String baseLabel = "Filtres";
    List<String> activeFilters = [];
    if (_rentalStatusFilter != rentalStatusAll) {
      if (_rentalStatusFilter == rentalStatusRented) {
        activeFilters.add("R");
      } else if (_rentalStatusFilter == rentalStatusPartially) {
        activeFilters.add("P");
      } else {
        activeFilters.add("NR");
      }
    }
    if (!(_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM"))) {
      if (_selectedTokenTypes.contains("wallet") && !_selectedTokenTypes.contains("RMM")) {
        activeFilters.add("W");
      } else if (!_selectedTokenTypes.contains("wallet") && _selectedTokenTypes.contains("RMM")) {
        activeFilters.add("RMM");
      }
    }
    if (activeFilters.isNotEmpty) {
      return activeFilters.join('+');
    }
    return baseLabel;
  }

  // Filtres Wallet
  Widget _buildWalletFilterMenu({
    required BuildContext context,
    required IconData icon,
    required Set<String> selectedWallets,
    required Function(Set<String>) onWalletsChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          if (value == "apply_wallets") {
            // Gérer la sélection directe (au cas où StatefulBuilder ne fonctionne pas comme prévu)
            onWalletsChanged(selectedWallets);
          }
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedWallets.isNotEmpty 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedWallets.isNotEmpty 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "wallet_header",
            enabled: false,
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet, size: 20),
                SizedBox(width: 8.0),
                Text(
                  "Wallets",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...Provider.of<DataManager>(context, listen: false).evmAddresses.toSet().toList().map((wallet) => PopupMenuItem(
                value: wallet,
                child: StatefulBuilder(
                  builder: (context, setStateLocal) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (selectedWallets.contains(wallet)) {
                            selectedWallets.remove(wallet);
                          } else {
                            selectedWallets.add(wallet);
                          }
                        });
                        setStateLocal(() {});
                      },
                      child: Row(
                        children: [
                          selectedWallets.contains(wallet) ? const Icon(Icons.check, size: 20) : const SizedBox(width: 20),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.account_balance_wallet, size: 20),
                          const SizedBox(width: 8.0),
                          Flexible(child: Text(wallet.length > 15 ? '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}' : wallet)),
                        ],
                      ),
                    );
                  },
                ),
              )),
          // Bouton pour fermer/appliquer
          const PopupMenuDivider(),
          PopupMenuItem(
            value: "apply_wallets",
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Appliquer"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filtre ProductType
  Widget _buildProductTypeFilterMenu({
    required BuildContext context,
    required IconData icon,
    required Set<String> selectedProductTypes,
    required Function(Set<String>) onProductTypesChanged,
  }) {
    return PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          // La logique de sélection est gérée dans StatefulBuilder
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedProductTypes.isNotEmpty 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedProductTypes.isNotEmpty 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) {
          final uniqueProductTypes = _getUniqueProductTypes(Provider.of<DataManager>(context, listen: false).portfolio);
          
          return [
            PopupMenuItem(
              value: "product_type_header",
              enabled: false,
              child: Row(
                children: const [
                  Icon(Icons.category, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    "Types de produit",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...uniqueProductTypes.map((productType) => PopupMenuItem(
                  value: productType,
                  child: StatefulBuilder(
                    builder: (context, setStateLocal) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (selectedProductTypes.contains(productType)) {
                              selectedProductTypes.remove(productType);
                            } else {
                              selectedProductTypes.add(productType);
                            }
                          });
                          setStateLocal(() {});
                          onProductTypesChanged(selectedProductTypes);
                        },
                        child: Row(
                          children: [
                            selectedProductTypes.contains(productType) 
                              ? const Icon(Icons.check, size: 20) 
                              : const SizedBox(width: 20),
                            const SizedBox(width: 8.0),
                            Icon(_getProductTypeIcon(productType), size: 20),
                            const SizedBox(width: 8.0),
                            Flexible(
                              child: Text(_getLocalizedProductTypeName(context, productType)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )),
            // Bouton pour fermer/appliquer
            const PopupMenuDivider(),
            PopupMenuItem(
              value: "apply_product_types",
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Appliquer"),
                ),
              ),
            ),
          ];
        },
      );
  }

  // Filtre Region
  Widget _buildRegionFilterMenu({
    required BuildContext context,
    required IconData icon,
    required String? selectedRegion,
    required Function(String?) onRegionChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          if (value == "all_regions") {
            onRegionChanged(null);
          } else {
            onRegionChanged(value);
          }
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedRegion != null 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedRegion != null 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) {
          final uniqueRegions = _getUniqueRegions(Provider.of<DataManager>(context, listen: false).portfolio);
          
          return [
            PopupMenuItem(
              value: "region_header",
              enabled: false,
              child: Row(
                children: [
                  Icon(Icons.map, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    S.of(context).region,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: "all_regions",
              child: Row(
                children: [
                  selectedRegion == null ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                  SizedBox(width: 8.0),
                  Icon(Icons.public, size: 20),
                  SizedBox(width: 8.0),
                  Text(S.of(context).allRegions),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...uniqueRegions.map((region) => PopupMenuItem(
                  value: region,
                  child: Row(
                    children: [
                      selectedRegion == region ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                      SizedBox(width: 8.0),
                      if (region != "Unknown Region")
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.asset(
                            'assets/states/${region.toLowerCase()}.png',
                            width: 24,
                            height: 16,
                            errorBuilder: (context, _, __) => const Icon(Icons.flag, size: 20),
                          ),
                        ),
                      Flexible(child: Text(Parameters.getRegionDisplayName(region))),
                    ],
                  ),
                )),
          ];
        },
      ),
    );
  }

  // Filtre Country
  Widget _buildCountryFilterMenu({
    required BuildContext context,
    required IconData icon,
    required String? selectedCountry,
    required Function(String?) onCountryChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          if (value == "all_countries") {
            onCountryChanged(null);
          } else {
            onCountryChanged(value);
          }
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedCountry != null 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedCountry != null 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) {
          final uniqueCountries = _getUniqueCountries(Provider.of<DataManager>(context, listen: false).portfolio);
          
          return [
            PopupMenuItem(
              value: "country_header",
              enabled: false,
              child: Row(
                children: [
                  Icon(Icons.flag, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    S.of(context).country,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: "all_countries",
              child: Row(
                children: [
                  selectedCountry == null ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                  SizedBox(width: 8.0),
                  Icon(Icons.public, size: 20),
                  SizedBox(width: 8.0),
                  Text(S.of(context).allCountries),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...uniqueCountries.map((country) => PopupMenuItem(
                  value: country,
                  child: Row(
                    children: [
                      selectedCountry == country ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                      SizedBox(width: 8.0),
                      if (country != "Unknown Country")
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.asset(
                            'assets/country/${Parameters.getCountryFileName(country)}.png',
                            width: 24,
                            height: 16,
                            errorBuilder: (context, _, __) => const Icon(Icons.flag, size: 20),
                          ),
                        ),
                      Flexible(child: Text(country)),
                    ],
                  ),
                )),
          ];
        },
      ),
    );
  }

  // Filtre Statut de location
  Widget _buildRentalStatusFilterMenu({
    required BuildContext context,
    required IconData icon,
    required String selectedRentalStatus,
    required Function(String) onRentalStatusChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          onRentalStatusChanged(value);
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedRentalStatus != rentalStatusAll 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedRentalStatus != rentalStatusAll 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "rental_status_header",
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.home_work, size: 20),
                SizedBox(width: 8.0),
                Text(
                  "Statut de location",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: rentalStatusAll,
            child: Row(
              children: [
                selectedRentalStatus == rentalStatusAll ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                SizedBox(width: 8.0),
                Icon(Icons.home_work_outlined, size: 20),
                SizedBox(width: 8.0),
                Text(S.of(context).rentalStatusAll),
              ],
            ),
          ),
          PopupMenuItem(
            value: rentalStatusRented,
            child: Row(
              children: [
                selectedRentalStatus == rentalStatusRented ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                SizedBox(width: 8.0),
                Icon(Icons.check_circle, size: 20, color: Colors.green),
                SizedBox(width: 8.0),
                Text(S.of(context).rentalStatusRented),
              ],
            ),
          ),
          PopupMenuItem(
            value: rentalStatusPartially,
            child: Row(
              children: [
                selectedRentalStatus == rentalStatusPartially ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                SizedBox(width: 8.0),
                Icon(Icons.adjust, size: 20, color: Colors.orange),
                SizedBox(width: 8.0),
                Text(S.of(context).rentalStatusPartiallyRented),
              ],
            ),
          ),
          PopupMenuItem(
            value: rentalStatusNotRented,
            child: Row(
              children: [
                selectedRentalStatus == rentalStatusNotRented ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                SizedBox(width: 8.0),
                Icon(Icons.cancel, size: 20, color: Colors.red),
                SizedBox(width: 8.0),
                Text(S.of(context).rentalStatusNotRented),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filtre Type de token (Wallet/RMM)
  Widget _buildTokenTypeFilterMenu({
    required BuildContext context,
    required IconData icon,
    required Set<String> selectedTokenTypes,
    required Function(Set<String>) onTokenTypesChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: "",
        onSelected: (String value) {
          // La logique de sélection est gérée dans StatefulBuilder
        },
        offset: const Offset(0, 40),
        elevation: 8,
        color: Theme.of(context).cardColor.withValues(alpha: 0.97),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedTokenTypes.isNotEmpty 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: selectedTokenTypes.isNotEmpty 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "token_type_header",
            enabled: false,
            child: Row(
              children: [
                Icon(Icons.account_tree, size: 20),
                SizedBox(width: 8.0),
                Text(
                  S.of(context).tokenTypeTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: "wallet_toggle",
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedTokenTypes.contains("wallet")) {
                        selectedTokenTypes.remove("wallet");
                      } else {
                        selectedTokenTypes.add("wallet");
                      }
                    });
                    setStateLocal(() {});
                    onTokenTypesChanged(selectedTokenTypes);
                  },
                  child: Row(
                    children: [
                      selectedTokenTypes.contains("wallet") ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                      SizedBox(width: 8.0),
                      Icon(Icons.account_balance_wallet, size: 20),
                      SizedBox(width: 8.0),
                      Text("Wallet"),
                    ],
                  ),
                );
              },
            ),
          ),
          PopupMenuItem(
            value: "rmm_toggle",
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedTokenTypes.contains("RMM")) {
                        selectedTokenTypes.remove("RMM");
                      } else {
                        selectedTokenTypes.add("RMM");
                      }
                    });
                    setStateLocal(() {});
                    onTokenTypesChanged(selectedTokenTypes);
                  },
                  child: Row(
                    children: [
                      selectedTokenTypes.contains("RMM") ? Icon(Icons.check, size: 20) : SizedBox(width: 20),
                      SizedBox(width: 8.0),
                      Icon(Icons.business, size: 20),
                      SizedBox(width: 8.0),
                      Text("RMM"),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour obtenir le nom localisé du type de produit
  String _getLocalizedProductTypeName(BuildContext context, String productType) {
    switch (productType.toLowerCase()) {
      case 'real_estate_rental':
        return S.of(context).productTypeRealEstateRental;
      case 'factoring_profitshare':
        return S.of(context).productTypeFactoringProfitshare;
      case 'loan_income':
        return S.of(context).productTypeLoanIncome;
      default:
        return S.of(context).productTypeOther;
    }
  }
}
