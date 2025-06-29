import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:show_network_image/show_network_image.dart';

class PropertiesForSaleRealt extends StatefulWidget {
  const PropertiesForSaleRealt({super.key});

  @override
  _PropertiesForSaleRealtState createState() => _PropertiesForSaleRealtState();
}

class _PropertiesForSaleRealtState extends State<PropertiesForSaleRealt> {
  @override
  void initState() {
    super.initState();
    final dataManager = Provider.of<DataManager>(context, listen: false);
    dataManager.fetchAndStorePropertiesForSale();
  }

  Widget _buildGaugeForRent(double rentValue, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 12,
                    width: maxWidth,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 12,
                    width: rentValue.clamp(0, 100) / 100 * maxWidth,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      "${rentValue.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final propertiesForSale = dataManager.propertiesForSale;

    return Scaffold(
      body: propertiesForSale.isEmpty
          ? Center(
              child: Text(
                S.of(context).noPropertiesForSale,
                style: TextStyle(
                  fontSize: 16 +
                      Provider.of<AppState>(context, listen: false)
                          .getTextSizeOffset(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : AlignedGridView.count(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 80, left: 16, right: 16),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: propertiesForSale.length,
              itemBuilder: (context, index) {
                final property = propertiesForSale[index];

                final imageUrl = (property['imageLink'] != null &&
                        property['imageLink'] is List &&
                        property['imageLink'].isNotEmpty)
                    ? property['imageLink'][0]
                    : '';
                final title =
                    property['shortName'] ?? S.of(context).nameUnavailable;
                final double stock =
                    (property['stock'] as num?)?.toDouble() ?? 0.0;

                final double tokenPrice =
                    (property['tokenPrice'] as num?)?.toDouble() ?? 0.0;
                final double annualPercentageYield =
                    (property['annualPercentageYield'] as num?)?.toDouble() ??
                        0.0;

                final double totalTokens =
                    (property['totalTokens'] as num?)?.toDouble() ?? 0.0;

                final country = property['country'] ?? 'unknown';

                final city = property['city'] ?? 'unknown';
                final status = property['status'] ?? 'Unknown';
                final sellPercentage =
                    (totalTokens - stock) / totalTokens * 100;

                return GestureDetector(
                  onTap: () {
                    // Implémentez l'action au clic sur la carte
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                        errorWidget: (context, url, error) =>
                                            const Icon(CupertinoIcons.photo,
                                                color:
                                                    CupertinoColors.systemGrey),
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: status == 'Available'
                                        ? CupertinoColors.activeGreen
                                        : CupertinoColors.systemRed,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (country != 'unknown')
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                        .withValues(alpha: 0.2)
                                                    : Colors.black.withValues(
                                                        alpha: 0.05),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.asset(
                                              'assets/country/${Parameters.getCountryFileName(country)}.png',
                                              width: 24,
                                              height: 24,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(CupertinoIcons.flag,
                                                    size: 24,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      size: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      city,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildGaugeForRent(sellPercentage, context),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${stock.toInt()} / ${totalTokens.toInt()}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Prix',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyUtils.formatCurrency(
                                                tokenPrice,
                                                currencyUtils.currencySymbol),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rendement',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${annualPercentageYield.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  CupertinoColors.activeGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => UrlUtils.launchURL(
                                      property['marketplaceLink']),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Acheter cette propriété',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                );
              },
            ),
    );
  }
}
