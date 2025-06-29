import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'package:realtoken_asset_tracker/utils/widget_factory.dart';

class UIUtils {
  static double getAppBarHeight(BuildContext context) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio; // Ratio de densité
    double longestSide = MediaQuery.of(context).size.longestSide * pixelRatio;
    double shortestSide = MediaQuery.of(context).size.shortestSide * pixelRatio;

    if (kIsWeb) {
      // Taille pour le Web, ajustée pour écrans larges
      return longestSide > 1200 ? kToolbarHeight : kToolbarHeight;
    } else if (Platform.isAndroid) {
      if (shortestSide >= 1500) {
        // Tablettes (toute orientation)
        return kToolbarHeight;
      } else if (longestSide > 2000) {
        // Grands téléphones
        return kToolbarHeight + 15;
      } else {
        // Taille par défaut pour les téléphones standards
        return kToolbarHeight + 10;
      }
    } else if (Platform.isIOS) {
      var orientation = MediaQuery.of(context).orientation;

      if (shortestSide >= 1500) {
        // Tablettes (toute orientation)
        return orientation == Orientation.portrait ? kToolbarHeight : kToolbarHeight; // Exemple d'ajustement en paysage
      } else if (longestSide > 2000) {
        // Grands téléphones
        return orientation == Orientation.portrait ? kToolbarHeight + 40 : kToolbarHeight; // Exemple d'ajustement en paysage
      } else {
        // Taille par défaut pour les téléphones standards
        return orientation == Orientation.portrait ? kToolbarHeight : kToolbarHeight - 10; // Exemple d'ajustement en paysage
      }
    } else {
      // Par défaut pour desktop
      return kToolbarHeight + 20;
    }
  }

  static double getSliverAppBarHeight(BuildContext context) {
    double baseHeight = getAppBarHeight(context);

    double pixelRatio = MediaQuery.of(context).devicePixelRatio; // Ratio de densité
    double longestSide = MediaQuery.of(context).size.longestSide * pixelRatio;
    double shortestSide = MediaQuery.of(context).size.shortestSide * pixelRatio;

    if (kIsWeb) {
      // SliverAppBar pour le Web
      return longestSide > 2500 ? baseHeight + 50 : baseHeight + 50;
    } else if (Platform.isAndroid) {
      if (shortestSide >= 1500) {
        // Tablettes
        return baseHeight + 30;
      } else if (longestSide > 2500) {
        // Grands téléphones
        return baseHeight + 10;
      } else {
        // Taille par défaut
        return baseHeight + 20;
      }
    } else if (Platform.isIOS) {
      var orientation = MediaQuery.of(context).orientation;

      if (shortestSide >= 1500) {
        // Tablettes
        return orientation == Orientation.portrait ? baseHeight + 25 : baseHeight + 25; // Ajustement en paysage pour les tablettes
      } else if (longestSide > 2500) {
        // Grands téléphones
        return orientation == Orientation.portrait ? baseHeight - 15 : baseHeight + 40; // Ajustement en paysage pour les grands téléphones
      } else {
        // Taille par défaut pour téléphones standards
        return orientation == Orientation.portrait ? baseHeight + 30 : baseHeight + 45; // Ajustement en paysage pour téléphones standards
      }
    } else {
      // Par défaut pour desktop
      return baseHeight + 20;
    }
  }

  static Color shadeColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
      1,
    );
  }

// Méthode pour déterminer la couleur de la pastille en fonction du taux de location
  static Color getRentalStatusColor(int rentedUnits, int totalUnits) {
    if (rentedUnits == 0) {
      return Colors.red; // Aucun logement loué
    } else if (rentedUnits == totalUnits) {
      return Colors.green; // Tous les logements sont loués
    } else {
      return Colors.orange; // Partiellement loué
    }
  }

  static Widget buildCard(
    String title,
    IconData icon,
    Widget firstChild,
    List<Widget> otherChildren,
    DataManager dataManager,
    BuildContext context, {
    bool hasGraph = false,
    Widget? rightWidget, // Widget pour le graphique
    Widget? headerRightWidget, // Widget pour l'icône dans l'en-tête (ex: paramètres)
  }) {
    final appState = Provider.of<AppState>(context);
    // Début de la logique responsive pour le graphique
    final screenWidth = MediaQuery.of(context).size.width;
    double graphMaxWidth = 120;
    double graphMinWidth = 50;
    bool showGraph = true;

    if (screenWidth < 320) {
      showGraph = false; // Trop petit, on masque le graphique
    } else if (screenWidth < 400) {
      graphMaxWidth = 80;
      graphMinWidth = 30;
    }
    // Fin de la logique responsive pour le graphique
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.3,
      shadowColor: Theme.of(context).brightness == Brightness.light ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.05),
      color: Theme.of(context).brightness == Brightness.light ? Colors.white : Color(0xFF1C1C1E),
      margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec l'icône des paramètres à droite
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: getIconColor(title, context).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: getIconColor(title, context),
                          size: 20 + appState.getTextSizeOffset(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  if (headerRightWidget != null) headerRightWidget,
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Contenu principal de la carte
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne principale avec les informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: firstChild,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: otherChildren,
                        ),
                      ),
                    ],
                  ),
                ),
                // Graphique si présent
                if (hasGraph && rightWidget != null && showGraph)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 8.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: graphMaxWidth,
                          minWidth: graphMinWidth,
                        ),
                        child: rightWidget,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour obtenir la couleur en fonction du titre traduit
  static Color getIconColor(String title, BuildContext context) {
    final String translatedTitle = title.trim(); // Supprime les espaces éventuels

    if (translatedTitle == S.of(context).rents) {
      return Color(0xFF34C759); // Vert iOS
    } else if (translatedTitle == S.of(context).tokens) {
      return Color(0xFFFF9500); // Orange iOS
    } else if (translatedTitle == S.of(context).rmm) {
      return Color(0xFF5AC8FA); // Bleu clair iOS
    } else if (translatedTitle == S.of(context).properties) {
      return Color(0xFF007AFF); // Bleu iOS
    } else if (translatedTitle == S.of(context).portfolio) {
      return Color(0xFF5856D6); // Violet iOS
    } else if (translatedTitle == S.of(context).nextRondays) {
      return Color(0xFFFF2D55); // Rose iOS
    } else if (translatedTitle == 'Estate') {
      return Colors.teal.shade600; // Bleu-vert pour Real Estate
    } else if (translatedTitle == 'Loan') {
      return Colors.indigo.shade600; // Indigo pour Loan Income
    } else if (translatedTitle == 'Factoring') {
      return Colors.deepPurple.shade600; // Violet pour Factoring
    } else {
      return Color(0xFF007AFF); // Bleu iOS par défaut
    }
  }

  static Widget buildValueBeforeText(BuildContext context, String? value, String text, bool isLoading, {bool highlightPercentage = false}) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    String percentageText = '';
    Color percentageColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    if (highlightPercentage) {
      final regex = RegExp(r'\(([-+]?\d+)%\)');
      final match = regex.firstMatch(text);
      if (match != null) {
        percentageText = match.group(1)!;
        final percentageValue = double.tryParse(percentageText) ?? 0;
        percentageColor = percentageValue >= 0 ? Colors.green : Colors.red;
      }
    }

    return Row(
      children: [
        isLoading
            ? ShimmerUtils.originalColorShimmer(
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 16 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                    height: 1.1,
                  ),
                ),
                color: theme.textTheme.bodyLarge?.color,
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 16 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.1,
                ),
              ),
        const SizedBox(width: 6),
        highlightPercentage && percentageText.isNotEmpty
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: text.split('(').first,
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: theme.textTheme.bodyLarge?.color,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: '($percentageText%)',
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: percentageColor,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 13 + appState.getTextSizeOffset(),
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.1,
                ),
              ),
      ],
    );
  }

  static Widget buildTextWithShimmer(String? value, String text, bool isLoading, BuildContext context) {
    // Utiliser le WidgetFactory optimisé
    return WidgetFactory.buildOptimizedTextWithShimmer(
      context: context,
      value: value,
      label: text,
      isLoading: isLoading,
    );
  }
}
