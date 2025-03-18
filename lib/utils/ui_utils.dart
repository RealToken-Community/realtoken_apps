import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/managers/data_manager.dart';
import 'package:realtokens/app_state.dart';
import 'package:realtokens/generated/l10n.dart';
import 'package:realtokens/pages/dashboard/detailsPages/properties_details_page.dart';
import 'package:realtokens/pages/dashboard/detailsPages/rent_details_page.dart';
import 'package:realtokens/pages/dashboard/detailsPages/rmm_details_page.dart';
import 'package:realtokens/pages/dashboard/detailsPages/portfolio_details_page.dart';
import 'package:shimmer/shimmer.dart';

class UIUtils {
  static double getAppBarHeight(BuildContext context) {
    double pixelRatio =
        MediaQuery.of(context).devicePixelRatio; // Ratio de densité
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
        return orientation == Orientation.portrait
            ? kToolbarHeight
            : kToolbarHeight; // Exemple d'ajustement en paysage
      } else if (longestSide > 2000) {
        // Grands téléphones
        return orientation == Orientation.portrait
            ? kToolbarHeight + 40
            : kToolbarHeight; // Exemple d'ajustement en paysage
      } else {
        // Taille par défaut pour les téléphones standards
        return orientation == Orientation.portrait
            ? kToolbarHeight
            : kToolbarHeight - 10; // Exemple d'ajustement en paysage
      }
    } else {
      // Par défaut pour desktop
      return kToolbarHeight + 20;
    }
  }

  static double getSliverAppBarHeight(BuildContext context) {
    double baseHeight = getAppBarHeight(context);

    double pixelRatio =
        MediaQuery.of(context).devicePixelRatio; // Ratio de densité
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
        return orientation == Orientation.portrait
            ? baseHeight + 25
            : baseHeight + 25; // Ajustement en paysage pour les tablettes
      } else if (longestSide > 2500) {
        // Grands téléphones
        return orientation == Orientation.portrait
            ? baseHeight - 15
            : baseHeight +
                40; // Ajustement en paysage pour les grands téléphones
      } else {
        // Taille par défaut pour téléphones standards
        return orientation == Orientation.portrait
            ? baseHeight + 30
            : baseHeight +
                45; // Ajustement en paysage pour téléphones standards
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec l'icône des paramètres à droite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: getIconColor(title, context),
                      size: 24 + appState.getTextSizeOffset(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (headerRightWidget != null) headerRightWidget,
              ],
            ),
            const SizedBox(height: 6),
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
                        padding: const EdgeInsets.only(left: 8.0),
                        child: firstChild,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: otherChildren,
                        ),
                      ),
                    ],
                  ),
                ),
                // Graphique si présent
                if (hasGraph && rightWidget != null) rightWidget,
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour obtenir la couleur en fonction du titre traduit
  static Color getIconColor(String title, BuildContext context) {
    final String translatedTitle =
        title.trim(); // Supprime les espaces éventuels

    if (translatedTitle == S.of(context).rents) {
      return Colors.green;
    } else if (translatedTitle == S.of(context).tokens) {
      return Colors.orange;
    } else if (translatedTitle == S.of(context).rmm) {
      return Colors.teal;
    } else if (translatedTitle == S.of(context).properties) {
      return Colors.blue;
    } else if (translatedTitle == S.of(context).portfolio) {
      return Colors.blueGrey;
    } else {
      return Colors.blue; // Couleur par défaut
    }
  }

  static Widget buildValueBeforeText(
      BuildContext context, String? value, String text, bool isLoading,
      {bool highlightPercentage = false}) {
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
            ? Shimmer.fromColors(
                baseColor:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ??
                        Colors.grey[300]!,
                highlightColor:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                        Colors.grey[100]!,
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 16 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 16 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
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
                      ),
                    ),
                    TextSpan(
                      text: '($percentageText%)',
                      style: TextStyle(
                        fontSize: 13 + appState.getTextSizeOffset(),
                        color: percentageColor,
                        fontWeight: FontWeight.bold,
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
                ),
              ),
      ],
    );
  }

  static Widget buildTextWithShimmer(
      String? value, String label, bool isLoading, BuildContext context) {
    final theme = Theme.of(context);

    // Couleurs pour le shimmer adaptées au thème
    final baseColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.2) ??
        Colors.grey[300]!;
    final highlightColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
            Colors.grey[100]!;

    return Row(
      children: [
        // Partie label statique
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        // Partie valeur dynamique avec ou sans shimmer
        isLoading
            ? Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              )
            : Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
      ],
    );
  }
}
