import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:show_network_image/show_network_image.dart';

class PropertiesForSaleSecondary extends StatefulWidget {
  const PropertiesForSaleSecondary({super.key});

  @override
  _PropertiesForSaleSecondaryState createState() =>
      _PropertiesForSaleSecondaryState();
}

class _PropertiesForSaleSecondaryState
    extends State<PropertiesForSaleSecondary> {
  String? lastUpdateTime;
  bool isSearching = false;
  String searchQuery = '';
  bool hideNonWhitelisted = false;

  final TextEditingController searchController = TextEditingController();

  // Variables pour le filtre par type d'offre
  String selectedOfferType = "tout";

  // Variables de tri
  String selectedSortOption = "delta";
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    // Différer la mise à jour des données après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataFetchUtils.refreshData(context);
    });
    final box = Hive.box('realTokens');
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  Future<void> _refreshData() async {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await DataFetchUtils.refreshData(context);
    await dataManager.fetchAndStorePropertiesForSale();
    final box = Hive.box('realTokens');
    setState(() {
      lastUpdateTime = box.get('lastUpdateTime_YamMarket') as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Regroupement des offres par propriété avec filtres et tri
    final groupedOffers = <String, List<Map<String, dynamic>>>{};
    for (var offer in dataManager.yamMarket) {
      // Filtrer par type d'offre
      if (selectedOfferType == "vente" && offer['token_to_buy'] != null)
        continue;
      if (selectedOfferType == "achat" && offer['token_to_buy'] == null)
        continue;

      // Si on veut cacher les offres non whitelistées, on vérifie
      if (hideNonWhitelisted) {
        final String? tokenIdentifier =
            offer['token_to_sell'] ?? offer['token_to_buy'];
        final bool isOfferWhitelisted = dataManager.whitelistTokens.any(
            (whitelisted) =>
                whitelisted['token'].toLowerCase() ==
                tokenIdentifier?.toLowerCase());
        if (!isOfferWhitelisted) continue;
      }

      final shortName = offer['shortName']?.toLowerCase() ?? '';
      if (!shortName.contains(searchQuery.toLowerCase())) continue;
      String tokenKey = (offer['token_to_sell'] ?? offer['token_to_buy']) ?? '';
      if (groupedOffers.containsKey(tokenKey)) {
        groupedOffers[tokenKey]!.add(offer);
      } else {
        groupedOffers[tokenKey] = [offer];
      }
    }

    // Appliquer le tri sur chaque groupe
    groupedOffers.forEach((key, offers) {
      offers.sort((a, b) {
        if (selectedSortOption == "date") {
          final dateA = a['creationDate'];
          final dateB = b['creationDate'];
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } else {
          final deltaA = ((a['token_value'] / a['token_price'] - 1) * 100);
          final deltaB = ((b['token_value'] / b['token_price'] - 1) * 100);
          return ascending
              ? deltaA.compareTo(deltaB)
              : deltaB.compareTo(deltaA);
        }
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Color(0xFFF2F2F7) // iOS light background
          : Color(0xFF000000), // iOS dark background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche et affichage de la dernière mise à jour dans un style iOS
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSearching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '${S.of(context).last_update} ${CustomDateUtils.formatReadableDateWithTime(lastUpdateTime!)}',
                        style: TextStyle(
                          fontSize: 12 + appState.getTextSizeOffset(),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Color(0xFFE5E5EA) // iOS search bar background light
                          : Color(0xFF1C1C1E), // iOS search bar background dark
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isSearching
                        ? TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: S.of(context).search_hint,
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey, size: 18),
                                onPressed: () {
                                  setState(() {
                                    searchController.clear();
                                    isSearching = false;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Icon(Icons.search,
                                      color: Colors.grey, size: 20),
                                ),
                                Text(
                                  S.of(context).search_hint,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Filtres et contrôles de tri modernisés
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Étiquettes de type d'offre - partie gauche
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("tout", Icons.all_inclusive,
                              selectedOfferType == "tout", context),
                          const SizedBox(width: 8),
                          _buildFilterChip("vente", Icons.add_shopping_cart,
                              selectedOfferType == "vente", context),
                          const SizedBox(width: 8),
                          _buildFilterChip("achat", Icons.sell,
                              selectedOfferType == "achat", context),
                          const SizedBox(width: 8),
                          // Contrôle de visibilité
                          _buildFilterChip(
                            hideNonWhitelisted ? "whitelisted" : "all",
                            hideNonWhitelisted
                                ? Icons.visibility_off
                                : Icons.visibility,
                            false,
                            context,
                            onTap: () {
                              setState(() {
                                hideNonWhitelisted = !hideNonWhitelisted;
                              });
                            },
                            customColor: hideNonWhitelisted
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu déroulant de tri combiné style iOS - partie droite
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: DropdownButton<String>(
                      value: selectedSortOption == "delta" ? "delta" : "date",
                      underline: SizedBox(),
                      isDense: true,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Theme.of(context).primaryColor, size: 18),
                      items: [
                        DropdownMenuItem(
                          value: "delta",
                          child: Text(
                            S.of(context).sort_delta,
                            style: TextStyle(
                              fontSize: 13 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "date",
                          child: Text(
                            S.of(context).sort_date,
                            style: TextStyle(
                              fontSize: 13 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Divider entre options de tri et ordre
                        DropdownMenuItem(
                          enabled: false,
                          child: Divider(height: 1, thickness: 1),
                        ),
                        // Options d'ordre
                        DropdownMenuItem(
                          value: "asc",
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_upward,
                                  size: 14,
                                  color: ascending
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey),
                              SizedBox(width: 3),
                              Text(
                                "Ascendant",
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  color: ascending
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "desc",
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward,
                                  size: 14,
                                  color: !ascending
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey),
                              SizedBox(width: 3),
                              Text(
                                "Descendant",
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  color: !ascending
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            if (value == "asc") {
                              ascending = true;
                            } else if (value == "desc") {
                              ascending = false;
                            } else {
                              selectedSortOption = value;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groupedOffers.isEmpty
                  ? Center(
                      child: Text(
                        S.of(context).no_market_offers_available,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Choisir 2 colonnes si la largeur est supérieure à 700, sinon 1 colonne
                        int crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                        return MasonryGridView.count(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          padding: const EdgeInsets.all(16),
                          itemCount: groupedOffers.keys.length,
                          itemBuilder: (context, index) {
                            String tokenKey =
                                groupedOffers.keys.elementAt(index);
                            List<Map<String, dynamic>> offers =
                                groupedOffers[tokenKey]!;
                            final imageUrl =
                                (offers.first['imageLink'] != null &&
                                        offers.first['imageLink'] is List &&
                                        offers.first['imageLink'].isNotEmpty)
                                    ? offers.first['imageLink'][0]
                                    : '';
                            final shortName =
                                offers.first['shortName'] ?? 'N/A';
                            final country = offers.first['country'] ?? 'USA';
                            final String? tokenIdentifier =
                                offers.first['token_to_sell'] ??
                                    offers.first['token_to_buy'];
                            final bool isWhitelisted =
                                dataManager.whitelistTokens.any((whitelisted) =>
                                    whitelisted['token'].toLowerCase() ==
                                    tokenIdentifier?.toLowerCase());

                            // Card style iOS
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.white
                                    : Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image avec overlay pour les badges
                                    if (imageUrl.isNotEmpty)
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: kIsWeb
                                                ? ShowNetworkImage(
                                                    imageSrc: imageUrl,
                                                    mobileBoxFit: BoxFit.cover,
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                          ),
                                          // Badge style iOS pour whitelisted
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isWhitelisted
                                                    ? Colors.green
                                                        .withValues(alpha: 0.8)
                                                    : Colors.red
                                                        .withValues(alpha: 0.8),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isWhitelisted
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    color: Colors.white,
                                                    size: 10,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    isWhitelisted
                                                        ? S
                                                            .of(context)
                                                            .tokenWhitelisted
                                                        : S
                                                            .of(context)
                                                            .tokenNotWhitelisted,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9 +
                                                          Provider.of<AppState>(
                                                                  context,
                                                                  listen: false)
                                                              .getTextSizeOffset(),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    // Infos et offres
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Nom de la propriété avec icône pays à gauche
                                          Row(
                                            children: [
                                              Image.asset(
                                                'assets/country/${Parameters.getCountryFileName(country)}.png',
                                                width: 16,
                                                height: 16,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(Icons.flag,
                                                      size: 16);
                                                },
                                              ),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  shortName,
                                                  style: TextStyle(
                                                    fontSize: 16 +
                                                        appState
                                                            .getTextSizeOffset(),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Affichage des offres pour ce groupe
                                          ...offers.map((offer) {
                                            bool isTokenWhitelisted = true;
                                            if (selectedOfferType == "vente") {
                                              return _buildSaleOfferCard(
                                                  context,
                                                  appState,
                                                  currencyUtils,
                                                  offer,
                                                  isTokenWhitelisted);
                                            } else if (selectedOfferType ==
                                                "achat") {
                                              return _buildPurchaseOfferCard(
                                                  context,
                                                  appState,
                                                  currencyUtils,
                                                  offer,
                                                  isTokenWhitelisted);
                                            } else {
                                              if (offer['token_to_buy'] ==
                                                  null) {
                                                return _buildSaleOfferCard(
                                                    context,
                                                    appState,
                                                    currencyUtils,
                                                    offer,
                                                    isTokenWhitelisted);
                                              } else {
                                                return _buildPurchaseOfferCard(
                                                    context,
                                                    appState,
                                                    currencyUtils,
                                                    offer,
                                                    isTokenWhitelisted);
                                              }
                                            }
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour créer un filtre chip style iOS
  Widget _buildFilterChip(
      String type, IconData icon, bool isSelected, BuildContext context,
      {VoidCallback? onTap, Color? customColor}) {
    final color = customColor ??
        (isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
            : Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Color(0xFF1C1C1E));

    return GestureDetector(
      onTap: onTap ??
          () {
            setState(() {
              selectedOfferType = type;
            });
          },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            if (type == "whitelisted" || type == "all") SizedBox(width: 4),
            if (type == "whitelisted")
              Text(
                "Whitelisted",
                style: TextStyle(
                  fontSize: 12 +
                      Provider.of<AppState>(context, listen: false)
                          .getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              ),
            if (type == "all")
              Text(
                "Tous",
                style: TextStyle(
                  fontSize: 12 +
                      Provider.of<AppState>(context, listen: false)
                          .getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fonction de construction d'une carte d'offre "Sell"
  Widget _buildSaleOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    // Vérification du statut du token
    final String? tokenIdentifier =
        offer['token_to_sell'] ?? offer['token_to_buy'];
    final bool isTokenWhitelisted = dataManager.whitelistTokens.any(
        (whitelisted) =>
            whitelisted['token'].toLowerCase() ==
            tokenIdentifier?.toLowerCase());
    final baseYield =
        double.tryParse(offer['annualPercentageYield']?.toString() ?? '0') ?? 0;
    final initialPrice =
        double.tryParse(offer['token_price']?.toString() ?? '0') ?? 0;
    final offerPrice =
        double.tryParse(offer['token_value']?.toString() ?? '0') ?? 0;

    if (baseYield <= 0 || initialPrice <= 0 || offerPrice <= 0)
      return const SizedBox();

    final newYield = baseYield * (initialPrice / offerPrice);
    final premiumPercentage =
        ((offerPrice - initialPrice) / initialPrice) * 100;
    final roiWeeks = (premiumPercentage * 52) / baseYield;
    final double deltaValue =
        ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Définir les couleurs selon le delta avec une palette plus iOS
    Color deltaColor;
    if (deltaValue >= 1 && deltaValue <= 7) {
      deltaColor = Color(0xFFFF9500); // Orange iOS
    } else if (deltaValue > 7) {
      deltaColor = Color(0xFFFF3B30); // Rouge iOS
    } else {
      deltaColor = Color(0xFF34C759); // Vert iOS
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Color(0xFFEEEEF0) // Gris plus distinct en mode clair
                : Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec ID et date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${S.of(context).offer_id}: ${offer['id_offer']}',
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CustomDateUtils.formatReadableDate(
                                  offer['creationDate']),
                              style: TextStyle(
                                fontSize: 10 + appState.getTextSizeOffset(),
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Informations sur le montant et le delta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Montant du token
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[100]
                                  : Color(0xFF3A3A3C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).token_amount,
                                  style: TextStyle(
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${offer['token_amount']?.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Delta price
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: deltaColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).delta_price,
                                  style: TextStyle(
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      deltaValue < 0
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: deltaColor,
                                      size: 12,
                                    ),
                                    Text(
                                      '${deltaValue.abs().toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontSize:
                                            14 + appState.getTextSizeOffset(),
                                        fontWeight: FontWeight.bold,
                                        color: deltaColor,
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

                    const SizedBox(height: 8),

                    // Comparaison des prix
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withValues(alpha: 0.1),
                            deltaColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).current_price,
                                style: TextStyle(
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currencyUtils.formatCurrency(
                                    initialPrice, currencyUtils.currencySymbol),
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF), // Bleu iOS
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                S.of(context).offer_price,
                                style: TextStyle(
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currencyUtils.formatCurrency(
                                    offerPrice, currencyUtils.currencySymbol),
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: deltaColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Comparaison des yields
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withValues(alpha: 0.1),
                            deltaColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).current_yield,
                                style: TextStyle(
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${baseYield.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF), // Bleu iOS
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                S.of(context).new_yield,
                                style: TextStyle(
                                  fontSize: 10 + appState.getTextSizeOffset(),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${newYield.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 13 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: deltaColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ROI et bouton d'action
                    Row(
                      children: [
                        // ROI badge
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9500)
                                  .withValues(alpha: 0.2), // Orange iOS
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                S
                                    .of(context)
                                    .roi_label(roiWeeks.toStringAsFixed(1)),
                                style: TextStyle(
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9500), // Orange iOS
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Bouton d'achat style iOS
                        Expanded(
                          child: Material(
                            borderRadius: BorderRadius.circular(10),
                            color: isTokenWhitelisted
                                ? Color(0xFF007AFF)
                                : Colors.grey,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: isTokenWhitelisted
                                  ? () {
                                      UrlUtils.launchURL(
                                          'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                                    }
                                  : null,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    S.of(context).buy_token,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          12 + appState.getTextSizeOffset(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge de paiement
              Positioned(
                top: 10,
                right: 10,
                child: Builder(
                  builder: (context) {
                    if (offer['token_to_pay'] ==
                            '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                        offer['token_to_pay'] ==
                            '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                      return Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/xdai.png',
                          width: 18,
                          height: 18,
                        ),
                      );
                    } else if (offer['token_to_pay'] ==
                            '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                        offer['token_to_pay'] ==
                            '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                      return Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/usdc.png',
                          width: 16,
                          height: 16,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction de construction d'une carte d'offre "Buy"
  Widget _buildPurchaseOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
  ) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final String? tokenIdentifier =
        offer['token_to_sell'] ?? offer['token_to_buy'];
    final bool isTokenWhitelisted = dataManager.whitelistTokens.any(
        (whitelisted) =>
            whitelisted['token'].toLowerCase() ==
            tokenIdentifier?.toLowerCase());

    final double deltaValue =
        ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Définir les couleurs selon le delta avec une palette plus iOS
    Color deltaColor =
        ((offer['token_value'] / offer['token_price'] - 1) * 100) < 0
            ? Color(0xFFFF3B30) // Rouge iOS
            : Color(0xFF34C759); // Vert iOS

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Color(0xFFEEEEF0) // Gris plus distinct en mode clair
                : Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec ID et date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${S.of(context).offer_id}: ${offer['id_offer']}',
                              style: TextStyle(
                                fontSize: 12 + appState.getTextSizeOffset(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CustomDateUtils.formatReadableDate(
                                  offer['creationDate']),
                              style: TextStyle(
                                fontSize: 10 + appState.getTextSizeOffset(),
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Informations principales
                    Row(
                      children: [
                        // Montant du token
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[100]
                                  : Color(0xFF3A3A3C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).token_amount,
                                  style: TextStyle(
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${offer['token_amount']?.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Valeur du token
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[100]
                                  : Color(0xFF3A3A3C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).token_value,
                                  style: TextStyle(
                                    fontSize: 10 + appState.getTextSizeOffset(),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  currencyUtils.formatCurrency(
                                      currencyUtils
                                          .convert(offer['token_value']),
                                      currencyUtils.currencySymbol),
                                  style: TextStyle(
                                    fontSize: 14 + appState.getTextSizeOffset(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Delta
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${S.of(context).delta_price}: ',
                            style: TextStyle(
                              fontSize: 12 + appState.getTextSizeOffset(),
                              color: Colors.grey[700],
                            ),
                          ),
                          Icon(
                            deltaValue < 0
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: deltaColor,
                            size: 14,
                          ),
                          Text(
                            '${deltaValue.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 14 + appState.getTextSizeOffset(),
                              fontWeight: FontWeight.bold,
                              color: deltaColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bouton d'action style iOS
                    Material(
                      borderRadius: BorderRadius.circular(10),
                      color: isTokenWhitelisted
                          ? Color(0xFF34C759)
                          : Colors.grey, // Vert iOS
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isTokenWhitelisted
                            ? () {
                                UrlUtils.launchURL(
                                    'https://yambyofferid.netlify.app/?offerId=${offer['id_offer']}');
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              S.of(context).sell_token,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12 + appState.getTextSizeOffset(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de paiement
              Positioned(
                top: 10,
                right: 10,
                child: Builder(
                  builder: (context) {
                    if (offer['token_to_pay'] ==
                            '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                        offer['token_to_pay'] ==
                            '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                      return Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/xdai.png',
                          width: 18,
                          height: 18,
                        ),
                      );
                    } else if (offer['token_to_pay'] ==
                            '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' ||
                        offer['token_to_pay'] ==
                            '0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1') {
                      return Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/usdc.png',
                          width: 16,
                          height: 16,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
