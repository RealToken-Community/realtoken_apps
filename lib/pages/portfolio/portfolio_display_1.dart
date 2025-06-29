import 'package:flutter/foundation.dart';
import 'package:realtoken_asset_tracker/modals/token_details/showTokenDetails.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/location_utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/settings/manage_evm_addresses_page.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/widget_factory.dart';
import 'dart:ui';
import 'dart:math' as Math;
import 'dart:io';

class PortfolioDisplay1 extends StatelessWidget {
  final List<Map<String, dynamic>> portfolio;
  final bool isLoading;

  const PortfolioDisplay1({
    super.key,
    required this.portfolio,
    this.isLoading = false,
  });

  /// Widget pour afficher une image avec gestion automatique de l'orientation
  Widget _buildImageWithOrientation(String imageUrl,
      {BoxFit fit = BoxFit.cover}) {
    if (kIsWeb) {
      return ShowNetworkImage(
        imageSrc: imageUrl,
        mobileBoxFit: fit,
      );
    }

    // Pour Android, utiliser Image.network avec filterQuality pour une meilleure gestion
    if (Platform.isAndroid) {
      return Image.network(
        imageUrl,
        fit: fit,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
        // Forcer le décodage avec orientation correcte
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // Pour iOS et autres plateformes, utiliser CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorWidget: (context, url, error) => const Icon(Icons.error),
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Méthode pour construire la jauge de rentabilité
  Widget _buildGaugeForRent(double rentValue, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth =
              constraints.maxWidth; // Utiliser la largeur complète
          final bool showTextInside = rentValue >=
              15; // Afficher le texte à l'intérieur seulement si >= 15%

          return Stack(
            children: [
              // Fond de la jauge
              Container(
                height: 14,
                width: maxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Partie remplie de la jauge
              Container(
                height: 14,
                width: Math.max(rentValue.clamp(0, 100) / 100 * maxWidth,
                    8), // Largeur minimum de 8px pour garantir les bords arrondis
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      Theme.of(context).primaryColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    bottomLeft: const Radius.circular(8),
                    topRight: Radius.circular(rentValue < 5 ? 0 : 8),
                    bottomRight: Radius.circular(rentValue < 5 ? 0 : 8),
                  ),
                ),
                // Texte du pourcentage à l'intérieur de la barre seulement si assez d'espace
                child: showTextInside
                    ? Center(
                        child: isLoading
                            ? ShimmerUtils.originalColorShimmer(
                                child: Text(
                                  "${rentValue.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 10 +
                                        Provider.of<AppState>(context,
                                                listen: false)
                                            .getTextSizeOffset(),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 1),
                                        blurRadius: 1,
                                        color:
                                            Colors.black.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                                color: Colors.white,
                              )
                            : Text(
                                "${rentValue.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 10 +
                                      Provider.of<AppState>(context,
                                              listen: false)
                                          .getTextSizeOffset(),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                      )
                    : null,
              ),
              // Texte du pourcentage visible en dehors de la barre seulement si < 15%
              if (!showTextInside)
                Positioned(
                  left:
                      Math.max(rentValue.clamp(0, 100) / 100 * maxWidth, 8) + 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: isLoading
                        ? ShimmerUtils.originalColorShimmer(
                            child: Text(
                              "${rentValue.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 10 +
                                    Provider.of<AppState>(context,
                                            listen: false)
                                        .getTextSizeOffset(),
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          )
                        : Text(
                            "${rentValue.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 10 +
                                  Provider.of<AppState>(context, listen: false)
                                      .getTextSizeOffset(),
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: portfolio.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.of(context).noDataAvailable,
                      style: TextStyle(
                        fontSize: 18 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ManageEvmAddressesPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        S.of(context).manageAddresses,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 80, right: 16, left: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 190 * (1 + (appState.getTextSizeOffset() / 35)),
              ),
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final token = portfolio[index];
                final isWallet = token['inWallet'] ?? false;
                final isRMM = token['inRMM'] ?? false;
                final city = LocationUtils.extractCity(token['fullName'] ?? '');

                // Vérifier si la date de 'rent_start' est dans le futur
                final rentStartDate = DateTime.parse(
                    token['rentStartDate'] ?? DateTime.now().toString());
                final bool isFutureRentStart =
                    rentStartDate.isAfter(DateTime.now());

                // Récupérer les loyers cumulés de tous les wallets pour ce token
                String tokenId = token['uuid']?.toLowerCase() ?? '';
                double totalRentReceived = tokenId.isNotEmpty
                    ? dataManager.cumulativeRentsByToken[tokenId] ??
                        token['totalRentReceived'] ??
                        0
                    : token['totalRentReceived'] ?? 0;

                final rentPercentage = (token['initialTotalValue'] != null &&
                        token['initialTotalValue'] != 0)
                    ? (totalRentReceived / token['initialTotalValue']) * 100
                    : 0.5;

                // Récupérer le nombre de wallets possédant ce token
                int walletCount = tokenId.isNotEmpty
                    ? dataManager.getWalletCountForToken(tokenId)
                    : 0;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => showTokenDetails(context, token),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Image avec la ville et le statut de location
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  ColorFiltered(
                                    colorFilter: isFutureRentStart
                                        ? const ColorFilter.mode(
                                            Colors.black45, BlendMode.darken)
                                        : const ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.multiply),
                                    child: SizedBox(
                                      width: kIsWeb ? 150 : 120,
                                      height: double.infinity,
                                      child: _buildImageWithOrientation(
                                        token['imageLink'][0],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  // ✅ Superposition d'un GestureDetector transparent uniquement sur Web
                                  if (kIsWeb)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          print("✅ Image cliquée sur Web !");
                                          showTokenDetails(context, token);
                                        },
                                      ),
                                    ),

                                  // ✅ Superposition du texte si 'rent_start' est dans le futur
                                  if (isFutureRentStart)
                                    Positioned.fill(
                                      child: Center(
                                        child: WidgetFactory.buildImageOverlay(
                                          context: context,
                                          text: S.of(context).rentStartFuture,
                                          fontSize: 12 +
                                              Provider.of<AppState>(context,
                                                      listen: false)
                                                  .getTextSizeOffset(),
                                        ),
                                      ),
                                    ),
                                  // Indicateur isWallet / isRMM en haut à gauche
                                  if (isWallet || isRMM)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Row(
                                        children: [
                                          if (isWallet)
                                            WidgetFactory.buildImageIndicator(
                                              context: context,
                                              text: S.of(context).wallet,
                                              fontSize: 10 +
                                                  Provider.of<AppState>(context,
                                                          listen: false)
                                                      .getTextSizeOffset(),
                                            ),
                                          const SizedBox(width: 6),
                                          if (isRMM)
                                            WidgetFactory.buildImageIndicator(
                                              context: context,
                                              text: 'RMM',
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      150, 165, 100, 21),
                                              fontSize: 10 +
                                                  Provider.of<AppState>(context,
                                                          listen: false)
                                                      .getTextSizeOffset(),
                                            ),
                                        ],
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: ClipRRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 3, sigmaY: 3),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black
                                                    .withValues(alpha: 0.6),
                                              ],
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: UIUtils
                                                      .getRentalStatusColor(
                                                    token['rentedUnits'] ?? 0,
                                                    token['totalUnits'] ?? 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: UIUtils
                                                          .getRentalStatusColor(
                                                        token['rentedUnits'] ??
                                                            0,
                                                        token['totalUnits'] ??
                                                            1,
                                                      ).withValues(alpha: 0.5),
                                                      blurRadius: 6,
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  city,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14 +
                                                        appState
                                                            .getTextSizeOffset(),
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 2,
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (token['country'] != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 6),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    child: Image.asset(
                                                      'assets/country/${token['country'].toLowerCase()}.png',
                                                      width: 22 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      height: 22 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                            Icons.flag,
                                                            size: 22);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  token['shortName'] ??
                                                      S
                                                          .of(context)
                                                          .nameUnavailable,
                                                  style: TextStyle(
                                                    fontSize: 16 +
                                                        appState
                                                            .getTextSizeOffset(),
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: rentPercentage != null
                                          ? _buildGaugeForRent(
                                              rentPercentage, context)
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: isLoading
                                              ? ShimmerUtils
                                                  .originalColorShimmer(
                                                  child: Text(
                                                    '${token['amount']?.toStringAsFixed(2) ?? '0.00'} / ${token['totalTokens'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 12 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                )
                                              : Text(
                                                  '${token['amount']?.toStringAsFixed(2) ?? '0.00'} / ${token['totalTokens'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    fontSize: 12 +
                                                        appState
                                                            .getTextSizeOffset(),
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.trending_up,
                                              size: 14 +
                                                  appState.getTextSizeOffset(),
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 2),
                                            isLoading
                                                ? ShimmerUtils
                                                    .originalColorShimmer(
                                                    child: Text(
                                                      '${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                                                      style: TextStyle(
                                                        fontSize: 13 +
                                                            appState
                                                                .getTextSizeOffset(),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  )
                                                : Text(
                                                    '${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                                                    style: TextStyle(
                                                      fontSize: 13 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                S.of(context).totalValue,
                                                style: TextStyle(
                                                  fontSize: 11 +
                                                      appState
                                                          .getTextSizeOffset(),
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              isLoading
                                                  ? ShimmerUtils
                                                      .originalColorShimmer(
                                                      child: Text(
                                                        currencyUtils
                                                            .getFormattedAmount(
                                                          currencyUtils.convert(
                                                              token[
                                                                  'totalValue']),
                                                          currencyUtils
                                                              .currencySymbol,
                                                          appState.showAmounts,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 13 +
                                                              appState
                                                                  .getTextSizeOffset(),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                    )
                                                  : Text(
                                                      currencyUtils
                                                          .getFormattedAmount(
                                                        currencyUtils.convert(
                                                            token[
                                                                'totalValue']),
                                                        currencyUtils
                                                            .currencySymbol,
                                                        appState.showAmounts,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 13 +
                                                            appState
                                                                .getTextSizeOffset(),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'YAM',
                                                style: TextStyle(
                                                  fontSize: 11 +
                                                      appState
                                                          .getTextSizeOffset(),
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  isLoading
                                                      ? ShimmerUtils
                                                          .originalColorShimmer(
                                                          child: Text(
                                                            currencyUtils.getFormattedAmount(
                                                                currencyUtils
                                                                    .convert((token[
                                                                            'yamAverageValue'] *
                                                                        token[
                                                                            'amount'])),
                                                                currencyUtils
                                                                    .currencySymbol,
                                                                appState
                                                                    .showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 +
                                                                  appState
                                                                      .getTextSizeOffset(),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: (token['yamAverageValue'] *
                                                                          token[
                                                                              'amount']) >=
                                                                      token[
                                                                          'totalValue']
                                                                  ? Colors.green
                                                                      .shade600
                                                                  : Colors.red
                                                                      .shade600,
                                                            ),
                                                          ),
                                                          color: (token['yamAverageValue'] *
                                                                      token[
                                                                          'amount']) >=
                                                                  token[
                                                                      'totalValue']
                                                              ? Colors.green
                                                                  .shade600
                                                              : Colors
                                                                  .red.shade600,
                                                        )
                                                      : Text(
                                                          currencyUtils.getFormattedAmount(
                                                              currencyUtils
                                                                  .convert((token[
                                                                          'yamAverageValue'] *
                                                                      token[
                                                                          'amount'])),
                                                              currencyUtils
                                                                  .currencySymbol,
                                                              appState
                                                                  .showAmounts),
                                                          style: TextStyle(
                                                            fontSize: 13 +
                                                                appState
                                                                    .getTextSizeOffset(),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: (token['yamAverageValue'] *
                                                                        token[
                                                                            'amount']) >=
                                                                    token[
                                                                        'totalValue']
                                                                ? Colors.green
                                                                    .shade600
                                                                : Colors.red
                                                                    .shade600,
                                                          ),
                                                        ),
                                                  const SizedBox(width: 4),
                                                  isLoading
                                                      ? ShimmerUtils
                                                          .originalColorShimmer(
                                                          child: Text(
                                                            '(${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                                            style: TextStyle(
                                                              fontSize: 11 +
                                                                  appState
                                                                      .getTextSizeOffset(),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: (token['yamAverageValue'] *
                                                                          token[
                                                                              'amount']) >=
                                                                      token[
                                                                          'totalValue']
                                                                  ? Colors.green
                                                                      .shade600
                                                                  : Colors.red
                                                                      .shade600,
                                                            ),
                                                          ),
                                                          color: (token['yamAverageValue'] *
                                                                      token[
                                                                          'amount']) >=
                                                                  token[
                                                                      'totalValue']
                                                              ? Colors.green
                                                                  .shade600
                                                              : Colors
                                                                  .red.shade600,
                                                        )
                                                      : Text(
                                                          '(${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                                          style: TextStyle(
                                                            fontSize: 11 +
                                                                appState
                                                                    .getTextSizeOffset(),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: (token['yamAverageValue'] *
                                                                        token[
                                                                            'amount']) >=
                                                                    token[
                                                                        'totalValue']
                                                                ? Colors.green
                                                                    .shade600
                                                                : Colors.red
                                                                    .shade600,
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            S.of(context).revenue,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13 +
                                                  appState.getTextSizeOffset(),
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    S.of(context).week,
                                                    style: TextStyle(
                                                      fontSize: 12 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                  isLoading
                                                      ? ShimmerUtils
                                                          .originalColorShimmer(
                                                          child: Text(
                                                            currencyUtils.getFormattedAmount(
                                                                currencyUtils
                                                                    .convert(
                                                                        token['dailyIncome'] *
                                                                            7),
                                                                currencyUtils
                                                                    .currencySymbol,
                                                                appState
                                                                    .showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 +
                                                                  appState
                                                                      .getTextSizeOffset(),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        )
                                                      : Text(
                                                          currencyUtils.getFormattedAmount(
                                                              currencyUtils
                                                                  .convert(token[
                                                                          'dailyIncome'] *
                                                                      7),
                                                              currencyUtils
                                                                  .currencySymbol,
                                                              appState
                                                                  .showAmounts),
                                                          style: TextStyle(
                                                            fontSize: 13 +
                                                                appState
                                                                    .getTextSizeOffset(),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    S.of(context).month,
                                                    style: TextStyle(
                                                      fontSize: 12 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                  isLoading
                                                      ? ShimmerUtils
                                                          .originalColorShimmer(
                                                          child: Text(
                                                            currencyUtils.getFormattedAmount(
                                                                currencyUtils
                                                                    .convert(token[
                                                                        'monthlyIncome']),
                                                                currencyUtils
                                                                    .currencySymbol,
                                                                appState
                                                                    .showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 +
                                                                  appState
                                                                      .getTextSizeOffset(),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        )
                                                      : Text(
                                                          currencyUtils.getFormattedAmount(
                                                              currencyUtils
                                                                  .convert(token[
                                                                      'monthlyIncome']),
                                                              currencyUtils
                                                                  .currencySymbol,
                                                              appState
                                                                  .showAmounts),
                                                          style: TextStyle(
                                                            fontSize: 13 +
                                                                appState
                                                                    .getTextSizeOffset(),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    S.of(context).year,
                                                    style: TextStyle(
                                                      fontSize: 12 +
                                                          appState
                                                              .getTextSizeOffset(),
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color,
                                                    ),
                                                  ),
                                                  isLoading
                                                      ? ShimmerUtils
                                                          .originalColorShimmer(
                                                          child: Text(
                                                            currencyUtils.getFormattedAmount(
                                                                currencyUtils
                                                                    .convert(token[
                                                                        'yearlyIncome']),
                                                                currencyUtils
                                                                    .currencySymbol,
                                                                appState
                                                                    .showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 +
                                                                  appState
                                                                      .getTextSizeOffset(),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                        )
                                                      : Text(
                                                          currencyUtils.getFormattedAmount(
                                                              currencyUtils
                                                                  .convert(token[
                                                                      'yearlyIncome']),
                                                              currencyUtils
                                                                  .currencySymbol,
                                                              appState
                                                                  .showAmounts),
                                                          style: TextStyle(
                                                            fontSize: 13 +
                                                                appState
                                                                    .getTextSizeOffset(),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                  ),
                );
              },
            ),
    );
  }
}
