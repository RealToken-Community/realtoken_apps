import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtoken_asset_tracker/modals/token_details/tabs/others_tab.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:show_network_image/show_network_image.dart';
import '../../pages/portfolio/FullScreenCarousel.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

import 'tabs/property_tab.dart';
import 'tabs/finance_tab.dart';
import 'tabs/market_tab.dart';
import 'tabs/insights_tab.dart';
import 'tabs/history_tab.dart';

void _openMapModal(BuildContext context, dynamic lat, dynamic lng) {
  final double? latitude = double.tryParse(lat.toString());
  final double? longitude = double.tryParse(lng.toString());

  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).invalidCoordinates)),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).viewOnMap),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    final googleStreetViewUrl = 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
                    UrlUtils.launchURL(googleStreetViewUrl);
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.streetview,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class TokenDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> token;
  final bool convertToSquareMeters;
  final ScrollController scrollController;

  const TokenDetailsWidget({
    super.key,
    required this.token,
    required this.convertToSquareMeters,
    required this.scrollController,
  });

  @override
  _TokenDetailsWidgetState createState() => _TokenDetailsWidgetState();
}

class _TokenDetailsWidgetState extends State<TokenDetailsWidget> with SingleTickerProviderStateMixin {
  int _currentCarouselIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(BuildContext context, int index) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    switch (index) {
      case 0:
        return buildPropertiesTab(context, widget.token, widget.convertToSquareMeters);
      case 1:
        return buildFinanceTab(context, widget.token, widget.convertToSquareMeters);
      case 2:
        return MarketTab(token: widget.token);
      case 3:
        return buildOthersTab(context, widget.token);
      case 4:
        return buildInsightsTab(context, widget.token);
      case 5:
        return buildHistoryTab(context, widget.token, dataManager.isLoadingTransactions);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    return DefaultTabController(
      length: 6,
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicateur de glissement
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                // Image et infos principales
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                  child: widget.token['imageLink'] != null && widget.token['imageLink'].isNotEmpty
                      ? Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final List<String> imageLinks = widget.token['imageLink'] is String ? [widget.token['imageLink']] : List<String>.from(widget.token['imageLink']);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenCarousel(
                                      imageLinks: imageLinks,
                                    ),
                                  ),
                                );
                              },
                              child: StatefulBuilder(builder: (context, setState) {
                                final List<String> imageLinks = widget.token['imageLink'] is String ? [widget.token['imageLink']] : List<String>.from(widget.token['imageLink']);
                                return Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: CarouselSlider(
                                        options: CarouselOptions(
                                          height: MediaQuery.of(context).size.height * 0.22,
                                          enableInfiniteScroll: imageLinks.length > 1,
                                          enlargeCenterPage: true,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _currentCarouselIndex = index;
                                            });
                                          },
                                          viewportFraction: 0.9,
                                        ),
                                        items: imageLinks.map<Widget>((imageUrl) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  spreadRadius: 1,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(15),
                                                  child: kIsWeb
                                                      ? ShowNetworkImage(imageSrc: imageUrl, mobileBoxFit: BoxFit.cover, mobileWidth: double.infinity)
                                                      : CachedNetworkImage(
                                                          imageUrl: imageUrl,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                                        ),
                                                ),
                                                if (kIsWeb)
                                                  Positioned.fill(
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior.translucent,
                                                      onTap: () {
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) => FullScreenCarousel(
                                                              imageLinks: imageLinks,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    if (imageLinks.length > 1)
                                      Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: imageLinks.asMap().entries.map((entry) {
                                            return Container(
                                              width: 8.0,
                                              height: 8.0,
                                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _currentCarouselIndex == entry.key ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.4),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        )
                      : Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                // Infos principales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du token et emplacement
                      Row(
                        children: [
                          if (widget.token['country'] != null)
                            Container(
                              margin: const EdgeInsets.only(right: 6.0),
                              child: Image.asset(
                                'assets/country/${widget.token['country'].toLowerCase()}.png',
                                width: 36 + appState.getTextSizeOffset(),
                                height: 36 + appState.getTextSizeOffset(),
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.flag, size: 28);
                                },
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.token['shortName'] ?? S.of(context).nameUnavailable,
                                style: TextStyle(
                                  fontSize: 16 + appState.getTextSizeOffset(),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.token['city'] != null || widget.token['regionCode'] != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14 + appState.getTextSizeOffset(),
                                      color: Colors.grey[600],
                                    ),
                                    // Drapeau de l'état américain si disponible
                                    if (widget.token['regionCode'] != null && widget.token['country']?.toLowerCase() == 'usa')
                                      Container(
                                        margin: const EdgeInsets.only(left: 4.0, right: 2.0),
                                        child: Image.asset(
                                          'assets/states/${widget.token['regionCode'].toLowerCase()}.png',
                                          width: 16 + appState.getTextSizeOffset(),
                                          height: 16 + appState.getTextSizeOffset(),
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.location_city,
                                              size: 14 + appState.getTextSizeOffset(),
                                              color: Colors.grey[600],
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(width: 2),
                                    Text(
                                      [
                                        widget.token['city'],
                                        widget.token['regionCode'] != null ? Parameters.getRegionDisplayName(widget.token['regionCode']) : null
                                      ].where((e) => e != null).join(', '),
                                      style: TextStyle(
                                        fontSize: 12 + appState.getTextSizeOffset(),
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Conteneur pour les informations financières
                      if (widget.token['amount'] != null || widget.token['totalValue'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8.0),
                          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Montant de tokens
                              if (widget.token['amount'] != null)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.token_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            S.of(context).amount,
                                            style: TextStyle(
                                              fontSize: 11 + appState.getTextSizeOffset(),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            widget.token['amount']?.toStringAsFixed(2) ?? "0",
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              // Séparateur vertical
                              if (widget.token['amount'] != null && widget.token['totalValue'] != null)
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              // Valeur totale
                              if (widget.token['totalValue'] != null)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Value",
                                            style: TextStyle(
                                              fontSize: 11 + appState.getTextSizeOffset(),
                                              color: Theme.of(context).primaryColor.withOpacity(0.8),
                                            ),
                                          ),
                                          Text(
                                            currencyUtils.formatCurrency(currencyUtils.convert(widget.token['totalValue']), currencyUtils.currencySymbol),
                                            style: TextStyle(
                                              fontSize: 14 + appState.getTextSizeOffset(),
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
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
                const SizedBox(height: 10),
              ],
            ),
          ),
          // TabBar sticky
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
                labelStyle: TextStyle(
                  fontSize: 12 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.normal,
                ),
                tabs: [
                  _buildTabSegment(icon: Icons.home_outlined, label: "Property"),
                  _buildTabSegment(icon: Icons.attach_money_outlined, label: "Finance"),
                  _buildTabSegment(icon: Icons.store_outlined, label: "Market"),
                  _buildTabSegment(icon: Icons.info_outline, label: "Info"),
                  _buildTabSegment(icon: Icons.insights_outlined, label: "Insights"),
                  _buildTabSegment(icon: Icons.history_outlined, label: "History"),
                ],
                onTap: (index) {
                  setState(() {}); // Pour rafraîchir le contenu de l'onglet
                },
              ),
            ),
          ),
          // Contenu de l'onglet sélectionné
          SliverToBoxAdapter(
            child: _buildTabContent(context, _tabController.index),
          ),
          // Padding bas pour permettre le scroll complet
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegment({required IconData icon, required String label}) {
    return Tab(
      height: 40,
      child: Icon(icon, size: 25),
    );
  }
}

// Délégate pour rendre la TabBar sticky
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => 35;
  @override
  double get maxExtent => 35;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.8) : Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

Future<void> showTokenDetails(BuildContext context, Map<String, dynamic> token) async {
  final dataManager = Provider.of<DataManager>(context, listen: false);
  final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
  final prefs = await SharedPreferences.getInstance();
  bool convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                
                 // hauteur de la barre d'action
                  TokenDetailsWidget(
                    token: token,
                    convertToSquareMeters: convertToSquareMeters,
                    scrollController: scrollController,
                  
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => UrlUtils.launchURL(token['marketplaceLink']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              textStyle: TextStyle(
                                fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                              ),
                            ),
                            child: Text(S.of(context).viewOnRealT),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _openMapModal(context, token['lat'], token['lng']),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              textStyle: TextStyle(fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
                            ),
                            child: Text(S.of(context).viewOnMap),
                          ),
                        ),
                      ],
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
