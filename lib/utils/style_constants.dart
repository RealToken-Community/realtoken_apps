import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:provider/provider.dart';

class StyleConstants {
  // Rayons de bordure standardisés
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double modalBorderRadius = 16.0;
  static const double smallBorderRadius = 6.0;

  // Espacement standardisé
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;

  // Marges standardisées
  static const double marginSmall = 4.0;
  static const double marginMedium = 8.0;
  static const double marginLarge = 12.0;
  static const double marginXLarge = 16.0;

  // Tailles d'icônes standardisées
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 28.0;

  // Épaisseurs de bordure
  static const double borderThin = 0.5;
  static const double borderMedium = 1.0;
  static const double borderThick = 2.0;

  // Ombres standardisées
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ];

  // Décoration de carte standardisée
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: cardShadow,
      );

  // Décoration de bouton standardisée
  static BoxDecoration buttonDecoration(BuildContext context,
          {Color? backgroundColor}) =>
      BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        boxShadow: subtleShadow,
      );

  // Décoration de modal standardisée
  static BoxDecoration modalDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(modalBorderRadius)),
        boxShadow: modalShadow,
      );

  // Styles de texte avec offset
  static TextStyle titleStyle(BuildContext context, double textSizeOffset) =>
      TextStyle(
        fontSize: 18 +
            Provider.of<AppState>(context, listen: false).getTextSizeOffset() +
            textSizeOffset,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      );

  static TextStyle subtitleStyle(BuildContext context, double textSizeOffset) =>
      TextStyle(
        fontSize: 16 +
            Provider.of<AppState>(context, listen: false).getTextSizeOffset() +
            textSizeOffset,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      );

  static TextStyle bodyStyle(BuildContext context, double textSizeOffset) =>
      TextStyle(
        fontSize: 14 +
            Provider.of<AppState>(context, listen: false).getTextSizeOffset() +
            textSizeOffset,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      );

  static TextStyle captionStyle(BuildContext context, double textSizeOffset) =>
      TextStyle(
        fontSize: 12 +
            Provider.of<AppState>(context, listen: false).getTextSizeOffset() +
            textSizeOffset,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7),
      );

  static TextStyle smallStyle(BuildContext context, double textSizeOffset) =>
      TextStyle(
        fontSize: 10 +
            Provider.of<AppState>(context, listen: false).getTextSizeOffset() +
            textSizeOffset,
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.7),
      );

  // Decorations spécialisées
  static BoxDecoration primaryColorDecoration(BuildContext context,
          {double opacity = 0.1}) =>
      BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(smallBorderRadius),
      );

  static BoxDecoration glassmorphismDecoration(BuildContext context,
          {double opacity = 0.05}) =>
      BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: opacity)
            : Colors.black.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: borderMedium,
        ),
      );

  // Constantes d'animation
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Courbes d'animation
  static const Curve animationCurve = Curves.easeInOut;
  static const Curve animationCurveFast = Curves.easeOut;

  // Contraintes de taille
  static const double maxModalHeight = 0.8;
  static const double minButtonHeight = 44.0;
  static const double standardAppBarHeight = 56.0;
}
