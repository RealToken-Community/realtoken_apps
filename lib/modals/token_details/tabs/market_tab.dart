import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/modals/token_details/showTokenDetails.dart';

class MarketTab extends StatefulWidget {
  final Map<String, dynamic> token;
  final bool isModal;

  const MarketTab({super.key, required this.token, this.isModal = false});

  @override
  _MarketTabState createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  String selectedOfferType = "tout";
  String selectedSortOption = "delta";
  bool ascending = true;
  bool isTabBarSticky =
      false; // Nouvel état pour suivre si la TabBar est sticky

  // Définition des couleurs iOS
  final Color _iosPrimaryColor = const Color(0xFF007AFF); // Bleu iOS
  final Color _iosSuccessColor = const Color(0xFF34C759); // Vert iOS
  final Color _iosWarningColor = const Color(0xFFFF9500); // Orange iOS
  final Color _iosDangerColor = const Color(0xFFFF3B30); // Rouge iOS
  final Color _iosLabelColor = const Color(0xFF000000); // Noir iOS pour text
  final Color _iosSecondaryLabelColor = const Color(0xFF8E8E93); // Gris iOS
  final Color _iosBackgroundColor = const Color(0xFFF2F2F7); // Background iOS
  final Color _iosSurfaceColor = const Color(0xFFFFFFFF); // Surface iOS

  ScrollController? _parentScrollController;

  @override
  void initState() {
    super.initState();
    // Écouter le ScrollController de la page parent pour détecter quand la TabBar devient sticky
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Récupérer directement le ScrollController du widget parent
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    // Trouver le contrôleur de défilement parent
    final ancestor =
        context.findAncestorWidgetOfExactType<TokenDetailsWidget>();
    if (ancestor != null) {
      setState(() {
        _parentScrollController = ancestor.scrollController;
        _parentScrollController?.addListener(_checkTabBarSticky);
      });
    }
  }

  @override
  void dispose() {
    // Nettoyer le listener
    if (_parentScrollController != null) {
      _parentScrollController!.removeListener(_checkTabBarSticky);
    }
    super.dispose();
  }

  // Vérifier si la TabBar est devenue sticky
  void _checkTabBarSticky() {
    if (_parentScrollController != null) {
      // On considère que la TabBar est sticky quand le défilement dépasse un certain seuil
      final shouldBeSticky = _parentScrollController!.offset > 180;
      if (shouldBeSticky != isTabBarSticky) {
        setState(() {
          isTabBarSticky = shouldBeSticky;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    // Utilisation des couleurs du thème si disponibles
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Si c'est une modale plein écran séparée
    if (widget.isModal) {
      return _buildModalContent(
          appState, dataManager, currencyUtils, isDarkMode);
    }

    // Si c'est intégré dans la page de détails du token
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de filtres en haut - fixe
          _buildFilterBar(isDarkMode, appState),

          // Contenu principal avec liste défilante qui s'active quand la TabBar est sticky
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFilteredOffers(
                  dataManager, widget.token['uuid'], selectedOfferType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(
                      snapshot.error.toString(), isDarkMode);
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget(appState, isDarkMode);
                } else {
                  final offers = _getSortedOffers(snapshot.data!);

                  // Utiliser un ListView avec ScrollPhysics adaptatif selon l'état de la TabBar
                  return ListView(
                    // Changer la physique selon si la TabBar est sticky ou non
                    physics: isTabBarSticky
                        ? const BouncingScrollPhysics() // Activer le défilement quand la TabBar est sticky
                        : const NeverScrollableScrollPhysics(), // Désactiver le défilement sinon
                    children: [
                      // Titre de la section
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8.0, top: 16.0, bottom: 8.0),
                        child: Text(
                          S.of(context).secondary_offers_related_to_token,
                          style: TextStyle(
                            fontSize: 18 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),

                      // Construction de toutes les offres dans le ListView
                      ...offers.map((offer) {
                        final bool isTokenWhitelisted =
                            dataManager.whitelistTokens.any(
                          (whitelisted) =>
                              whitelisted['token'].toLowerCase() ==
                              widget.token['uuid'].toLowerCase(),
                        );

                        if (selectedOfferType == "vente" ||
                            (selectedOfferType == "tout" &&
                                offer['token_to_buy'] == null)) {
                          return _buildIOSSaleOfferCard(
                              context,
                              appState,
                              currencyUtils,
                              offer,
                              isTokenWhitelisted,
                              isDarkMode);
                        } else if (selectedOfferType == "achat" ||
                            (selectedOfferType == "tout" &&
                                offer['token_to_buy'] != null)) {
                          return _buildIOSPurchaseOfferCard(
                              context,
                              appState,
                              currencyUtils,
                              offer,
                              isTokenWhitelisted,
                              isDarkMode);
                        } else {
                          return const SizedBox
                              .shrink(); // Ne devrait jamais arriver
                        }
                      }),

                      // Espace en bas
                      const SizedBox(height: 16),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Contenu pour l'affichage modal plein écran
  Widget _buildModalContent(AppState appState, DataManager dataManager,
      CurrencyProvider currencyUtils, bool isDarkMode) {
    return Column(
      children: [
        // Header pour la vue modale - fixe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black : _iosSurfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).offers_list_header,
                style: TextStyle(
                  fontSize: 17 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : _iosLabelColor,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.xmark,
                  color: isDarkMode ? Colors.white : _iosLabelColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Barre de filtres
        _buildFilterBar(isDarkMode, appState),

        // Contenu principal
        Expanded(
          child: Container(
            color: isDarkMode ? Colors.black : _iosBackgroundColor,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Titre de la section
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 20, bottom: 10),
                  child: Text(
                    S.of(context).secondary_offers_related_to_token,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20 + appState.getTextSizeOffset(),
                      letterSpacing: -0.5,
                      color: isDarkMode ? Colors.white : _iosLabelColor,
                    ),
                  ),
                ),

                // Liste des offres
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getFilteredOffers(
                      dataManager, widget.token['uuid'], selectedOfferType),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(
                          snapshot.error.toString(), isDarkMode);
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyWidget(appState, isDarkMode);
                    } else {
                      final offers = _getSortedOffers(snapshot.data!);
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: offers.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final offer = offers[index];
                          final bool isTokenWhitelisted =
                              dataManager.whitelistTokens.any(
                            (whitelisted) =>
                                whitelisted['token'].toLowerCase() ==
                                widget.token['uuid'].toLowerCase(),
                          );

                          // Render appropriate card based on offer type
                          if (selectedOfferType == "vente") {
                            return _buildIOSSaleOfferCard(
                                context,
                                appState,
                                currencyUtils,
                                offer,
                                isTokenWhitelisted,
                                isDarkMode);
                          } else if (selectedOfferType == "achat") {
                            return _buildIOSPurchaseOfferCard(
                                context,
                                appState,
                                currencyUtils,
                                offer,
                                isTokenWhitelisted,
                                isDarkMode);
                          } else {
                            if (offer['token_to_buy'] == null) {
                              return _buildIOSSaleOfferCard(
                                  context,
                                  appState,
                                  currencyUtils,
                                  offer,
                                  isTokenWhitelisted,
                                  isDarkMode);
                            } else {
                              return _buildIOSPurchaseOfferCard(
                                  context,
                                  appState,
                                  currencyUtils,
                                  offer,
                                  isTokenWhitelisted,
                                  isDarkMode);
                            }
                          }
                        },
                      );
                    }
                  },
                ),

                // Espace en bas
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Barre de filtres commune
  Widget _buildFilterBar(bool isDarkMode, AppState appState) {
    return Container(
      height: 44, // Hauteur fixe pour la barre de filtres
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : _iosSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filtres
          _buildIOSSegmentedControl(),

          // Options de tri
          Row(
            children: [
              Text(
                S.of(context).sort_label,
                style: TextStyle(
                  fontSize:
                      13 + Provider.of<AppState>(context).getTextSizeOffset(),
                  color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
                ),
              ),
              const SizedBox(width: 8),
              _buildIOSDropdown(context, isDarkMode),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                child: Icon(
                  ascending
                      ? CupertinoIcons.arrow_up
                      : CupertinoIcons.arrow_down,
                  size: 18,
                  color: isDarkMode ? Colors.white : _iosPrimaryColor,
                ),
                onPressed: () {
                  setState(() {
                    ascending = !ascending;
                  });
                },
              ),

              // Bouton pour ouvrir en plein écran
              if (!widget.isModal)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Icon(
                    CupertinoIcons.fullscreen,
                    size: 18,
                    color: isDarkMode ? Colors.white : _iosPrimaryColor,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black : _iosSurfaceColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child:
                                MarketTab(token: widget.token, isModal: true),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour l'erreur
  Widget _buildErrorWidget(String errorMessage, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 50,
            color: _iosDangerColor,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).error_occurred(errorMessage),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour l'état vide
  Widget _buildEmptyWidget(AppState appState, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 50,
            color: isDarkMode ? Colors.white30 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).no_market_offers_available,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : _iosSecondaryLabelColor,
            ),
          ),
        ],
      ),
    );
  }

  // Tri des offres
  List<Map<String, dynamic>> _getSortedOffers(
      List<Map<String, dynamic>> offers) {
    offers.sort((a, b) {
      if (selectedSortOption == "date") {
        final dateA = a['creationDate'];
        final dateB = b['creationDate'];
        return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      } else {
        final deltaA = ((a['token_value'] / a['token_price'] - 1) * 100);
        final deltaB = ((b['token_value'] / b['token_price'] - 1) * 100);
        return ascending ? deltaA.compareTo(deltaB) : deltaB.compareTo(deltaA);
      }
    });
    return offers;
  }

  // iOS-style segmented control
  Widget _buildIOSSegmentedControl() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("tout", CupertinoIcons.rectangle_grid_1x2_fill,
              selectedOfferType == "tout", context),
          const SizedBox(width: 8),
          _buildFilterChip("vente", CupertinoIcons.shopping_cart,
              selectedOfferType == "vente", context),
          const SizedBox(width: 8),
          _buildFilterChip("achat", CupertinoIcons.tag_fill,
              selectedOfferType == "achat", context),
        ],
      ),
    );
  }

  // Widget pour créer un filtre chip style iOS
  Widget _buildFilterChip(
      String type, IconData icon, bool isSelected, BuildContext context,
      {VoidCallback? onTap, Color? customColor}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = customColor ??
        (isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
            : isDarkMode
                ? const Color(0xFF1C1C1E)
                : Colors.white);

    return GestureDetector(
      onTap: onTap ??
          () {
            setState(() {
              selectedOfferType = type;
            });
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              offset: const Offset(0, 2),
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
          ],
        ),
      ),
    );
  }

  // iOS-style dropdown
  Widget _buildIOSDropdown(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: DropdownButton<String>(
        value: selectedSortOption == "delta" ? "delta" : "date",
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down,
            color: Theme.of(context).primaryColor, size: 18),
        items: [
          DropdownMenuItem(
            value: "delta",
            child: Text(
              S.of(context).sort_delta,
              style: TextStyle(
                fontSize:
                    13 + Provider.of<AppState>(context).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DropdownMenuItem(
            value: "date",
            child: Text(
              S.of(context).sort_date,
              style: TextStyle(
                fontSize:
                    13 + Provider.of<AppState>(context).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Divider entre options de tri et ordre
          const DropdownMenuItem(
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
                const SizedBox(width: 3),
                Text(
                  "Ascendant",
                  style: TextStyle(
                    fontSize:
                        13 + Provider.of<AppState>(context).getTextSizeOffset(),
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
                const SizedBox(width: 3),
                Text(
                  "Descendant",
                  style: TextStyle(
                    fontSize:
                        13 + Provider.of<AppState>(context).getTextSizeOffset(),
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
    );
  }

  // iOS-style sale offer card
  Widget _buildIOSSaleOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
    bool isDarkMode,
  ) {
    final baseYield =
        double.tryParse(widget.token['annualPercentageYield'].toString()) ?? 0;
    final initialPrice =
        double.tryParse(widget.token['initPrice'].toString()) ?? 0;
    final offerPrice = double.tryParse(offer['token_value'].toString()) ?? 0;

    if (baseYield <= 0 || initialPrice <= 0 || offerPrice <= 0) {
      return const SizedBox();
    }

    final newYield = baseYield * (initialPrice / offerPrice);
    final premiumPercentage =
        ((offerPrice - initialPrice) / initialPrice) * 100;
    final roiWeeks = (premiumPercentage * 52) / baseYield;

    final double deltaValue =
        ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Détermination de la couleur selon le delta
    Color deltaColor;
    if (deltaValue >= 1 && deltaValue <= 7) {
      deltaColor = _iosWarningColor;
    } else if (deltaValue > 7) {
      deltaColor = _iosDangerColor;
    } else {
      deltaColor = _iosSuccessColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
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
                    // Warning si non whitelisté
                    if (!isTokenWhitelisted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _iosDangerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _iosDangerColor.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: _iosDangerColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                S.of(context).not_whitelisted_warning,
                                style: TextStyle(
                                  color: _iosDangerColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // En-tête avec ID et date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF3A3A3C)
                                  : Colors.grey[100],
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
                            padding: const EdgeInsets.symmetric(
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
                      padding: const EdgeInsets.all(8),
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
                                  color: const Color(0xFF007AFF), // Bleu iOS
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
                      padding: const EdgeInsets.all(8),
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
                                  color: const Color(0xFF007AFF), // Bleu iOS
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
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500)
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
                                  color: const Color(0xFFFF9500), // Orange iOS
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
                                ? const Color(0xFF007AFF)
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
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
                    Widget icon = const SizedBox();

                    if (offer['token_to_pay'] ==
                            '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                        offer['token_to_pay'] ==
                            '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                      icon = Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
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
                      icon = Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
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

                    return icon;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSPurchaseOfferCard(
    BuildContext context,
    AppState appState,
    CurrencyProvider currencyUtils,
    Map<String, dynamic> offer,
    bool isTokenWhitelisted,
    bool isDarkMode,
  ) {
    final double deltaValue =
        ((offer['token_value'] / offer['token_price'] - 1) * 100);

    // Définir les couleurs selon le delta
    Color deltaColor = deltaValue < 0
        ? _iosSuccessColor // Vert iOS pour les offres où on peut acheter moins cher
        : _iosDangerColor; // Rouge iOS pour les offres où il faut payer plus cher

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Opacity(
        opacity: isTokenWhitelisted ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning si non whitelisté
                    if (!isTokenWhitelisted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _iosDangerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _iosDangerColor.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: _iosDangerColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                S.of(context).not_whitelisted_warning,
                                style: TextStyle(
                                  color: _iosDangerColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12 + appState.getTextSizeOffset(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // En-tête avec ID et date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF3A3A3C)
                                  : Colors.grey[100],
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF3A3A3C)
                                  : Colors.grey[100],
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
                      padding: const EdgeInsets.all(8),
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
                          ? _iosSuccessColor
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: double.infinity,
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
                    Widget icon = const SizedBox();

                    if (offer['token_to_pay'] ==
                            '0x0ca4f5554dd9da6217d62d8df2816c82bba4157b' ||
                        offer['token_to_pay'] ==
                            '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d') {
                      icon = Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
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
                      icon = Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
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

                    return icon;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget pour les boîtes d'information
  Widget _buildIOSInfoBox(
    BuildContext context,
    AppState appState,
    String label,
    String value,
    Color valueColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : valueColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10 + appState.getTextSizeOffset(),
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Fonction pour récupérer les offres filtrées selon le type
Future<List<Map<String, dynamic>>> _getFilteredOffers(
  DataManager dataManager,
  String tokenUuid,
  String offerType,
) async {
  List<Map<String, dynamic>> filteredOffers =
      dataManager.yamMarket.where((offer) {
    bool matchToken = offer['token_to_sell'] == tokenUuid.toLowerCase() ||
        offer['token_to_buy'] == tokenUuid.toLowerCase();
    if (!matchToken) return false;
    if (offerType == "vente") {
      return offer['token_to_buy'] == null;
    } else if (offerType == "achat") {
      return offer['token_to_buy'] != null;
    }
    return true;
  }).toList();

  return filteredOffers;
}
