import 'package:flutter/foundation.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/modals/token_details/showTokenDetails.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/components/filter_widgets.dart';

class RealTokensPage extends StatefulWidget {
  const RealTokensPage({super.key});

  @override
  RealTokensPageState createState() => RealTokensPageState();
}

class RealTokensPageState extends State<RealTokensPage> {
  String _searchQuery = '';
  String _sortOption = 'recentlyAdded';
  bool _isAscending = true;
  String? _selectedCity;
  String? _selectedRegion;
  String? _selectedCountry;
  // Afficher ou non les tokens non whitelistés
  bool _showNonWhitelisted = true;
  // Filtrer les tokens non présents dans le wallet
  bool _filterNotInWallet = false;

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOption = prefs.getString('sortOption') ?? 'recentlyAdded';
      _isAscending = prefs.getBool('isAscending') ?? true;
      _showNonWhitelisted = prefs.getBool('showNonWhitelisted') ?? true;
      _filterNotInWallet = prefs.getBool('filterNotInWallet') ?? false;
      _selectedRegion = prefs.getString('selectedRegion')?.isEmpty ?? true
          ? null
          : prefs.getString('selectedRegion');
      _selectedCountry = prefs.getString('selectedCountry')?.isEmpty ?? true
          ? null
          : prefs.getString('selectedCountry');
    });
  }

  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sortOption', _sortOption);
    prefs.setBool('isAscending', _isAscending);
    prefs.setBool('showNonWhitelisted', _showNonWhitelisted);
    prefs.setBool('filterNotInWallet', _filterNotInWallet);
    prefs.setString('selectedRegion', _selectedRegion ?? '');
    prefs.setString('selectedCountry', _selectedCountry ?? '');
  }

  List<Map<String, dynamic>> _filterAndSortTokens(DataManager dataManager) {
    List<Map<String, dynamic>> filteredTokens =
        dataManager.allTokens.where((token) {
      final matchesSearchQuery =
          token['fullName'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity =
          _selectedCity == null || token['fullName'].contains(_selectedCity!);
      final matchesRegion = _selectedRegion == null ||
          (token['regionCode'] != null &&
              token['regionCode'] == _selectedRegion);
      final matchesCountry = _selectedCountry == null ||
          _matchesCountryFilter(token, _selectedCountry);

      return matchesSearchQuery &&
          matchesCity &&
          matchesRegion &&
          matchesCountry;
    }).toList();

    if (_filterNotInWallet) {
      filteredTokens = filteredTokens
          .where((token) => !dataManager.portfolio.any(
              (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase()))
          .toList();
    }

    if (!_showNonWhitelisted) {
      filteredTokens = filteredTokens
          .where((token) => dataManager.whitelistTokens.any((whitelisted) =>
              whitelisted['token'].toLowerCase() ==
              token['uuid'].toLowerCase()))
          .toList();
    }

    if (_sortOption == S.of(context).sortByName) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['shortName'].compareTo(b['shortName'])
          : b['shortName'].compareTo(a['shortName']));
    } else if (_sortOption == S.of(context).sortByValue) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['totalValue'].compareTo(b['totalValue'])
          : b['totalValue'].compareTo(a['totalValue']));
    } else if (_sortOption == S.of(context).sortByAPY) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['annualPercentageYield'].compareTo(b['annualPercentageYield'])
          : b['annualPercentageYield'].compareTo(a['annualPercentageYield']));
    } else if (_sortOption == S.of(context).sortByInitialLaunchDate) {
      filteredTokens.sort((a, b) => _isAscending
          ? a['initialLaunchDate'].compareTo(b['initialLaunchDate'])
          : b['initialLaunchDate'].compareTo(a['initialLaunchDate']));
    }

    return filteredTokens;
  }

  // Méthodes factorisées utilisant FilterWidgets
  List<String> _getUniqueCities(List<Map<String, dynamic>> tokens) =>
      FilterWidgets.getUniqueCities(tokens);
  List<String> _getUniqueRegions(List<Map<String, dynamic>> tokens) =>
      FilterWidgets.getUniqueRegions(tokens);
  List<String> _getUniqueCountries(List<Map<String, dynamic>> tokens) =>
      FilterWidgets.getUniqueCountries(tokens);

  // Méthode pour vérifier si un token correspond au filtre pays
  bool _matchesCountryFilter(
      Map<String, dynamic> token, String? selectedCountry) {
    if (selectedCountry == null) return true;

    String tokenCountry = token['country'] ?? "Unknown Country";

    // Si "Series XX" est sélectionné, filtrer tous les tokens factoring_profitshare avec des séries
    if (selectedCountry == "Series XX") {
      return (token['productType']?.toString().toLowerCase() ==
              'factoring_profitshare') &&
          tokenCountry.toLowerCase().startsWith('series ');
    }

    // Filtre normal
    return tokenCountry == selectedCountry;
  }

  // Méthodes factorisées utilisant FilterWidgets
  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      FilterWidgets.buildFilterButton(
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
    bool isActive = false,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      elevation: 8,
      color: Theme.of(context).cardColor.withValues(alpha: 0.97),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
      ),
      itemBuilder: (context) => items,
    );
  }

  // Helper pour obtenir le label du tri actuel
  String _getSortLabel(BuildContext context) {
    if (_sortOption == S.of(context).sortByName) {
      return S.of(context).sortByName;
    } else if (_sortOption == S.of(context).sortByValue) {
      return S.of(context).sortByValue;
    } else if (_sortOption == S.of(context).sortByAPY) {
      return S.of(context).sortByAPY;
    } else {
      return S.of(context).sortByInitialLaunchDate;
    }
  }

  // Helper pour obtenir le label des filtres combinés
  String _getFilterLabel() {
    List<String> activeFilters = [];

    if (_filterNotInWallet) {
      activeFilters.add("NW");
    }

    if (!_showNonWhitelisted) {
      activeFilters.add("WL");
    }

    if (activeFilters.isNotEmpty) {
      return activeFilters.join('+');
    }

    return "Filtres";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(S.of(context).appTitle),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final filteredAndSortedTokens = _filterAndSortTokens(dataManager);
          final uniqueCities = _getUniqueCities(dataManager.allTokens);
          final uniqueRegions = _getUniqueRegions(dataManager.allTokens);
          final uniqueCountries = _getUniqueCountries(dataManager.allTokens);
          final currencyUtils =
              Provider.of<CurrencyProvider>(context, listen: false);

          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: UIUtils.getSliverAppBarHeight(context) + 20,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 2.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rangée avec barre de recherche
                            Row(
                              children: [
                                // Conteneur de recherche avec bords arrondis
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 8, right: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icône de recherche
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12.0),
                                          child: Icon(
                                            Icons.search,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Champ de recherche
                                        Expanded(
                                          child: TextField(
                                            onChanged: (value) {
                                              setState(() {
                                                _searchQuery = value;
                                              });
                                            },
                                            style: TextStyle(fontSize: 14),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText:
                                                  S.of(context).searchHint,
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Rangée avec les filtres
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  // Filtre par ville
                                  _buildFilterPopupMenu(
                                    context: context,
                                    icon: Icons.location_city,
                                    label: _selectedCity ?? S.of(context).city,
                                    isActive: _selectedCity != null,
                                    items: [
                                      PopupMenuItem(
                                        value: S.of(context).allCities,
                                        child: Text(S.of(context).allCities),
                                      ),
                                      ...uniqueCities
                                          .map((city) => PopupMenuItem(
                                                value: city,
                                                child: Text(city),
                                              )),
                                    ],
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedCity =
                                            value == S.of(context).allCities
                                                ? null
                                                : value;
                                      });
                                    },
                                  ),

                                  // Filtre par pays
                                  _buildFilterPopupMenu(
                                    context: context,
                                    icon: Icons.flag,
                                    label: _selectedCountry ?? "Pays",
                                    isActive: _selectedCountry != null,
                                    items: [
                                      const PopupMenuItem(
                                        value: "all_countries",
                                        child: Text("Tous les pays"),
                                      ),
                                      ...uniqueCountries.map((country) =>
                                          PopupMenuItem(
                                            value: country,
                                            child: Row(
                                              children: [
                                                _selectedCountry == country
                                                    ? Icon(Icons.check,
                                                        size: 20)
                                                    : SizedBox(width: 20),
                                                SizedBox(width: 8.0),
                                                if (country !=
                                                    "Unknown Country")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Image.asset(
                                                      'assets/country/${Parameters.getCountryFileName(country)}.png',
                                                      width: 24,
                                                      height: 16,
                                                      errorBuilder: (context, _,
                                                              __) =>
                                                          const Icon(Icons.flag,
                                                              size: 20),
                                                    ),
                                                  ),
                                                Text(country),
                                              ],
                                            ),
                                          )),
                                    ],
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedCountry =
                                            value == "all_countries"
                                                ? null
                                                : value;
                                        _saveSortPreferences();
                                      });
                                    },
                                  ),

                                  // Filtre par région
                                  _buildFilterPopupMenu(
                                    context: context,
                                    icon: Icons.map,
                                    label: _selectedRegion != null
                                        ? Parameters.getRegionDisplayName(
                                            _selectedRegion!)
                                        : "Région",
                                    isActive: _selectedRegion != null,
                                    items: [
                                      const PopupMenuItem(
                                        value: "all_regions",
                                        child: Text("Toutes les régions"),
                                      ),
                                      ...uniqueRegions.map((region) =>
                                          PopupMenuItem(
                                            value: region,
                                            child: Row(
                                              children: [
                                                _selectedRegion == region
                                                    ? Icon(Icons.check,
                                                        size: 20)
                                                    : SizedBox(width: 20),
                                                SizedBox(width: 8.0),
                                                if (region != "Unknown Region")
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: Image.asset(
                                                      'assets/states/${region.toLowerCase()}.png',
                                                      width: 24,
                                                      height: 16,
                                                      errorBuilder: (context, _,
                                                              __) =>
                                                          const Icon(Icons.flag,
                                                              size: 20),
                                                    ),
                                                  ),
                                                Text(Parameters
                                                    .getRegionDisplayName(
                                                        region)),
                                              ],
                                            ),
                                          )),
                                    ],
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedRegion = value == "all_regions"
                                            ? null
                                            : value;
                                        _saveSortPreferences();
                                      });
                                    },
                                  ),

                                  // Filtres combinés (whitelist + wallet)
                                  _buildFilterPopupMenu(
                                    context: context,
                                    icon: Icons.filter_alt,
                                    label: _getFilterLabel(),
                                    isActive: _filterNotInWallet ||
                                        !_showNonWhitelisted,
                                    items: [
                                      PopupMenuItem(
                                        value: "filter_header",
                                        enabled: false,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.filter_list,
                                                size: 20),
                                            const SizedBox(width: 8.0),
                                            const Text(
                                              "Filtres",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CheckedPopupMenuItem(
                                        value: 'filterNotInWallet',
                                        checked: _filterNotInWallet,
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                size: 20),
                                            const SizedBox(width: 8.0),
                                            Text(S
                                                .of(context)
                                                .filterNotInWallet),
                                          ],
                                        ),
                                      ),
                                      CheckedPopupMenuItem(
                                        value: 'showNonWhitelisted',
                                        checked: !_showNonWhitelisted,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.verified,
                                                size: 20),
                                            const SizedBox(width: 8.0),
                                            Text(S
                                                .of(context)
                                                .showOnlyWhitelisted),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      setState(() {
                                        if (value == 'filterNotInWallet') {
                                          _filterNotInWallet =
                                              !_filterNotInWallet;
                                        } else if (value ==
                                            'showNonWhitelisted') {
                                          _showNonWhitelisted =
                                              !_showNonWhitelisted;
                                        }
                                        _saveSortPreferences();
                                      });
                                    },
                                  ),

                                  // Espace flexible pour pousser le tri à droite
                                  const Spacer(),

                                  // Menu de tri
                                  Container(
                                    margin: EdgeInsets.zero,
                                    child: PopupMenuButton<String>(
                                      tooltip: _getSortLabel(context),
                                      onSelected: (String value) {
                                        setState(() {
                                          if (value == 'asc' ||
                                              value == 'desc') {
                                            _isAscending = (value == 'asc');
                                          } else {
                                            _sortOption = value;
                                          }
                                          _saveSortPreferences();
                                        });
                                      },
                                      offset: const Offset(0, 40),
                                      elevation: 8,
                                      color: Theme.of(context)
                                          .cardColor
                                          .withValues(alpha: 0.97),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.sort,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        CheckedPopupMenuItem(
                                          value: S.of(context).sortByName,
                                          checked: _sortOption ==
                                              S.of(context).sortByName,
                                          child: Text(S.of(context).sortByName),
                                        ),
                                        CheckedPopupMenuItem(
                                          value: S.of(context).sortByValue,
                                          checked: _sortOption ==
                                              S.of(context).sortByValue,
                                          child:
                                              Text(S.of(context).sortByValue),
                                        ),
                                        CheckedPopupMenuItem(
                                          value: S.of(context).sortByAPY,
                                          checked: _sortOption ==
                                              S.of(context).sortByAPY,
                                          child: Text(S.of(context).sortByAPY),
                                        ),
                                        CheckedPopupMenuItem(
                                          value: S
                                              .of(context)
                                              .sortByInitialLaunchDate,
                                          checked: _sortOption ==
                                              S
                                                  .of(context)
                                                  .sortByInitialLaunchDate,
                                          child: Text(S
                                              .of(context)
                                              .sortByInitialLaunchDate),
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
                    ),
                  ),
                )
              ];
            },
            body: filteredAndSortedTokens.isEmpty
                ? Center(child: Text(S.of(context).noTokensFound))
                : GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700 ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    itemCount: filteredAndSortedTokens.length,
                    itemBuilder: (context, index) {
                      final token = filteredAndSortedTokens[index];
                      final bool isInPortfolio = dataManager.portfolio.any(
                          (portfolioItem) =>
                              portfolioItem['uuid'].toLowerCase() ==
                              token['uuid'].toLowerCase());
                      final bool isWhitelisted = dataManager.whitelistTokens
                          .any((whitelisted) =>
                              whitelisted['token'].toLowerCase() ==
                              token['uuid'].toLowerCase());

                      return GestureDetector(
                        onTap: () => showTokenDetails(context, token),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .cardColor
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              // Image avec design modernisé
                              Stack(
                                children: [
                                  SizedBox(
                                    width: 130,
                                    height: double.infinity,
                                    child: kIsWeb
                                        ? ShowNetworkImage(
                                            imageSrc: token['imageLink'][0],
                                            mobileBoxFit: BoxFit.cover,
                                            mobileWidth: 130,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: token['imageLink'][0],
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1),
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40),
                                            ),
                                          ),
                                  ),

                                  // Indicateurs en haut de l'image (portfolio + whitelist)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isInPortfolio)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .account_balance_wallet,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    S
                                                        .of(context)
                                                        .presentInWallet,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const Spacer(),
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isWhitelisted
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Informations sur le token avec design amélioré
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // En-tête avec nom et pays
                                      Row(
                                        children: [
                                          if (token['country'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: Image.asset(
                                                'assets/country/${token['country'].toLowerCase()}.png',
                                                width: 24,
                                                height: 16,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(Icons.flag,
                                                      size: 18);
                                                },
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              token['shortName'] ??
                                                  S.of(context).nameUnavailable,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Affichage de la région
                                      if (token['regionCode'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            Parameters.getRegionDisplayName(
                                                token['regionCode']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                      const SizedBox(height: 4),

                                      // Informations de prix
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .cardColor
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  S.of(context).assetPrice,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                                  ),
                                                ),
                                                Text(
                                                  currencyUtils.formatCurrency(
                                                      token['totalInvestment'],
                                                      currencyUtils
                                                          .currencySymbol),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  S.of(context).tokenPrice,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                                  ),
                                                ),
                                                Text(
                                                  currencyUtils.formatCurrency(
                                                      token['tokenPrice'],
                                                      currencyUtils
                                                          .currencySymbol),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Spacer(),

                                      // Rendement attendu avec style iOS
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.trending_up,
                                              size: 14,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${token['annualPercentageYield'].toStringAsFixed(2)} %',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Statut de whitelist discret
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isWhitelisted
                                                ? Icons.verified_outlined
                                                : Icons.cancel_outlined,
                                            color: isWhitelisted
                                                ? Colors.green
                                                : Colors.red,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isWhitelisted
                                                ? S.of(context).tokenWhitelisted
                                                : S
                                                    .of(context)
                                                    .tokenNotWhitelisted,
                                            style: TextStyle(
                                              color: isWhitelisted
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text(S
                                                      .of(context)
                                                      .whitelistInfoTitle),
                                                  content: Text(S
                                                      .of(context)
                                                      .whitelistInfoContent),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text(
                                                          S.of(context).ok),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0),
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
