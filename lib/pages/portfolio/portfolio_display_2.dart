import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:realtoken_asset_tracker/modals/token_details/showTokenDetails.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/location_utils.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // Pour accéder à DataManager
import 'package:realtoken_asset_tracker/generated/l10n.dart'; // Import des traductions
import 'package:realtoken_asset_tracker/settings/manage_evm_addresses_page.dart'; // Import de la page de gestion des adresses EVM
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'package:show_network_image/show_network_image.dart'; // Import de AppState
import 'package:realtoken_asset_tracker/utils/widget_factory.dart';
import 'dart:ui';
import 'dart:math' as Math;
import 'dart:io';

class PortfolioDisplay2 extends StatefulWidget {
  final List<Map<String, dynamic>> portfolio;
  final bool isLoading;

  const PortfolioDisplay2({
    super.key, 
    required this.portfolio,
    this.isLoading = false,
  });

  @override
  PortfolioDisplay2State createState() => PortfolioDisplay2State();
}

class PortfolioDisplay2State extends State<PortfolioDisplay2> {
  /// Widget pour afficher une image avec gestion automatique de l'orientation
  Widget _buildImageWithOrientation(String imageUrl, {BoxFit fit = BoxFit.cover}) {
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
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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

  Widget _buildGaugeForRent(double rentValue, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          final bool showTextInside = rentValue >= 15; // Afficher le texte à l'intérieur seulement si >= 15%

          return Stack(
            children: [
              // Fond de la jauge
              Container(
                height: 16,
                width: maxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Partie remplie de la jauge
              Container(
                height: 16,
                width: Math.max(rentValue.clamp(0, 100) / 100 * maxWidth, 8), // Largeur minimum pour garantir les bords arrondis
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      Theme.of(context).primaryColor,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                // Texte du pourcentage à l'intérieur de la barre seulement si assez d'espace
                child: showTextInside
                    ? Center(
                        child: widget.isLoading 
                          ? ShimmerUtils.originalColorShimmer(
                              child: Text(
                                "${rentValue.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              color: Colors.white,
                            )
                          : Text(
                              "${rentValue.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 1,
                                    color: Colors.black.withValues(alpha: 0.5),
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
                  left: Math.max(rentValue.clamp(0, 100) / 100 * maxWidth, 8) + 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: widget.isLoading
                      ? ShimmerUtils.originalColorShimmer(
                          child: Text(
                            "${rentValue.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        )
                      : Text(
                          "${rentValue.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
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
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context);
    final filteredPortfolio = widget.portfolio;
    final widthScreen = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          filteredPortfolio.isEmpty
              ? Expanded(
                  child: Center(
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
                                  builder: (context) => const ManageEvmAddressesPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  ),
                )
              : Expanded(
                  child: AlignedGridView.count(
                    padding: const EdgeInsets.only(top: 8, bottom: 80, right: 16, left: 16),
                    crossAxisCount: widthScreen > 700 ? 2 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: filteredPortfolio.length,
                    itemBuilder: (context, index) {
                      final token = filteredPortfolio[index];
                      final isWallet = token['inWallet'] ?? false;
                      final isRMM = token['inRMM'] ?? false;
                      final city = LocationUtils.extractCity(token['fullName'] ?? '');

                      final rentStartDate = DateTime.tryParse(token['rentStartDate'] ?? '');
                      final bool isFutureRentStart = rentStartDate != null && rentStartDate.isAfter(DateTime.now());

                      final rentPercentage = (token['totalRentReceived'] != null && token['initialTotalValue'] != null && token['initialTotalValue'] != 0)
                          ? (token['totalRentReceived'] / token['initialTotalValue']) * 100
                          : 0.5;

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
                            child: Card(
                              color: Theme.of(context).cardColor,
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                          child: ColorFiltered(
                                            colorFilter: isFutureRentStart ? const ColorFilter.mode(Colors.black45, BlendMode.darken) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                            child: _buildImageWithOrientation(
                                              token['imageLink'][0],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (kIsWeb)
                                        Positioned.fill(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.translucent,
                                            onTap: () {
                                              showTokenDetails(context, token);
                                            },
                                          ),
                                        ),

                                      if (isFutureRentStart)
                                        Positioned.fill(
                                          child: Center(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: WidgetFactory.buildImageOverlay(
                                                context: context,
                                                text: S.of(context).rentStartFuture,
                                                fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Indicateurs en haut à gauche
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
                                                  fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                                ),
                                              const SizedBox(width: 6),
                                              if (isRMM)
                                                WidgetFactory.buildImageIndicator(
                                                  context: context,
                                                  text: 'RMM',
                                                  backgroundColor: const Color.fromARGB(150, 165, 100, 21),
                                                  fontSize: 10 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      // Ville en bas de l'image
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: ClipRRect(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(alpha: 0.6),
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                city,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.w600,
                                                  shadows: [
                                                    Shadow(
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 2,
                                                      color: Colors.black.withValues(alpha: 0.5),
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (token['country'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Image.asset(
                                                    'assets/country/${token['country'].toLowerCase()}.png',
                                                    width: 22 + appState.getTextSizeOffset(),
                                                    height: 22 + appState.getTextSizeOffset(),
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(Icons.flag, size: 22);
                                                    },
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                token['shortName'] ?? S.of(context).nameUnavailable,
                                                style: TextStyle(
                                                  fontSize: 16 + appState.getTextSizeOffset(),
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Barre de progression
                                        _buildGaugeForRent(rentPercentage, context),
                                        const SizedBox(height: 2),

                                        // Montant et APY
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: widget.isLoading
                                                ? ShimmerUtils.originalColorShimmer(
                                                    child: Text(
                                                      '${token['amount']?.toStringAsFixed(2) ?? '0.00'} / ${token['totalTokens'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                        fontSize: 12 + appState.getTextSizeOffset(),
                                                        fontWeight: FontWeight.w500,
                                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                                      ),
                                                    ),
                                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                                  )
                                                : Text(
                                                    '${token['amount']?.toStringAsFixed(2) ?? '0.00'} / ${token['totalTokens'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                      fontSize: 12 + appState.getTextSizeOffset(),
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.trending_up,
                                                  size: 14 + appState.getTextSizeOffset(),
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                                const SizedBox(width: 2),
                                                widget.isLoading
                                                  ? ShimmerUtils.originalColorShimmer(
                                                      child: Text(
                                                        '${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                                                        style: TextStyle(
                                                          fontSize: 13 + appState.getTextSizeOffset(),
                                                          fontWeight: FontWeight.w600,
                                                          color: Theme.of(context).primaryColor,
                                                        ),
                                                      ),
                                                      color: Theme.of(context).primaryColor,
                                                    )
                                                  : Text(
                                                      '${token['annualPercentageYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                                                      style: TextStyle(
                                                        fontSize: 13 + appState.getTextSizeOffset(),
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Valeurs totales
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    S.of(context).totalValue,
                                                    style: TextStyle(
                                                      fontSize: 11 + appState.getTextSizeOffset(),
                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  widget.isLoading
                                                    ? ShimmerUtils.originalColorShimmer(
                                                        child: Text(
                                                          currencyUtils.getFormattedAmount(
                                                            currencyUtils.convert(token['totalValue']),
                                                            currencyUtils.currencySymbol,
                                                            appState.showAmounts,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 13 + appState.getTextSizeOffset(),
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                                      )
                                                    : Text(
                                                        currencyUtils.getFormattedAmount(
                                                          currencyUtils.convert(token['totalValue']),
                                                          currencyUtils.currencySymbol,
                                                          appState.showAmounts,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 13 + appState.getTextSizeOffset(),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'YAM',
                                                    style: TextStyle(
                                                      fontSize: 11 + appState.getTextSizeOffset(),
                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      widget.isLoading
                                                        ? ShimmerUtils.originalColorShimmer(
                                                            child: Text(
                                                              currencyUtils.getFormattedAmount(
                                                                  currencyUtils.convert((token['yamAverageValue'] * token['amount'])), currencyUtils.currencySymbol, appState.showAmounts),
                                                              style: TextStyle(
                                                                fontSize: 13 + appState.getTextSizeOffset(),
                                                                fontWeight: FontWeight.w600,
                                                                color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                              ),
                                                            ),
                                                            color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                          )
                                                        : Text(
                                                            currencyUtils.getFormattedAmount(
                                                                currencyUtils.convert((token['yamAverageValue'] * token['amount'])), currencyUtils.currencySymbol, appState.showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 + appState.getTextSizeOffset(),
                                                              fontWeight: FontWeight.w600,
                                                              color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                            ),
                                                          ),
                                                      const SizedBox(width: 4),
                                                      widget.isLoading
                                                        ? ShimmerUtils.originalColorShimmer(
                                                            child: Text(
                                                              '(${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                                              style: TextStyle(
                                                                fontSize: 11 + appState.getTextSizeOffset(),
                                                                fontWeight: FontWeight.w500,
                                                                color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                              ),
                                                            ),
                                                            color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                          )
                                                        : Text(
                                                            '(${((token['yamAverageValue'] / token['tokenPrice'] - 1) * 100).toStringAsFixed(0)}%)',
                                                            style: TextStyle(
                                                              fontSize: 11 + appState.getTextSizeOffset(),
                                                              fontWeight: FontWeight.w500,
                                                              color: (token['yamAverageValue'] * token['amount']) >= token['totalValue'] ? Colors.green.shade600 : Colors.red.shade600,
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Section Revenus
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                S.of(context).revenue,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13 + appState.getTextSizeOffset(),
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        S.of(context).week,
                                                        style: TextStyle(
                                                          fontSize: 12 + appState.getTextSizeOffset(),
                                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                                        ),
                                                      ),
                                                      widget.isLoading
                                                        ? ShimmerUtils.originalColorShimmer(
                                                            child: Text(
                                                              currencyUtils.getFormattedAmount(currencyUtils.convert(token['dailyIncome'] * 7), currencyUtils.currencySymbol, appState.showAmounts),
                                                              style: TextStyle(
                                                                fontSize: 13 + appState.getTextSizeOffset(),
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                                          )
                                                        : Text(
                                                            currencyUtils.getFormattedAmount(currencyUtils.convert(token['dailyIncome'] * 7), currencyUtils.currencySymbol, appState.showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 + appState.getTextSizeOffset(),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        S.of(context).month,
                                                        style: TextStyle(
                                                          fontSize: 12 + appState.getTextSizeOffset(),
                                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                                        ),
                                                      ),
                                                      widget.isLoading
                                                        ? ShimmerUtils.originalColorShimmer(
                                                            child: Text(
                                                              currencyUtils.getFormattedAmount(currencyUtils.convert(token['monthlyIncome']), currencyUtils.currencySymbol, appState.showAmounts),
                                                              style: TextStyle(
                                                                fontSize: 13 + appState.getTextSizeOffset(),
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                                          )
                                                        : Text(
                                                            currencyUtils.getFormattedAmount(currencyUtils.convert(token['monthlyIncome']), currencyUtils.currencySymbol, appState.showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 + appState.getTextSizeOffset(),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        S.of(context).year,
                                                        style: TextStyle(
                                                          fontSize: 12 + appState.getTextSizeOffset(),
                                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                                        ),
                                                      ),
                                                      widget.isLoading
                                                        ? ShimmerUtils.originalColorShimmer(
                                                            child: Text(
                                                              currencyUtils.getFormattedAmount(currencyUtils.convert(token['yearlyIncome']), currencyUtils.currencySymbol, appState.showAmounts),
                                                              style: TextStyle(
                                                                fontSize: 13 + appState.getTextSizeOffset(),
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                                          )
                                                        : Text(
                                                            currencyUtils.getFormattedAmount(currencyUtils.convert(token['yearlyIncome']), currencyUtils.currencySymbol, appState.showAmounts),
                                                            style: TextStyle(
                                                              fontSize: 13 + appState.getTextSizeOffset(),
                                                              fontWeight: FontWeight.w600,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
