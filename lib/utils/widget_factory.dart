import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/shimmer_utils.dart';
import 'dart:ui';

/// Factory pour construire des widgets standardisés et réduire la duplication
/// Inclut BackdropFilter, décorations de containers, et autres patterns répétitifs
class WidgetFactory {
  /// Widget pour créer un en-tête de section standardisé
  static Widget buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
      child: Row(
        children: [
          Container(
            height: 16,
            width: 4,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget optimisé BackdropFilter réutilisable avec cache
  static Widget buildOptimizedBackdropFilter({
    required Widget child,
    double sigmaX = 10,
    double sigmaY = 10,
    Color? backgroundColor,
    double? opacity = 0.3,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          color: backgroundColor?.withValues(alpha: opacity ?? 0.3),
          child: child,
        ),
      ),
    );
  }

  /// BackdropFilter pour les overlays de navigation (AppBar, BottomBar)
  static Widget buildNavigationBackdrop({
    required BuildContext context,
    required Widget child,
    double height = 60,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.black.withValues(alpha: 0.3) 
              : Colors.white.withValues(alpha: 0.3),
          child: child,
        ),
      ),
    );
  }

  /// BackdropFilter pour les indicateurs sur les images (Wallet, RMM, etc.)
  static Widget buildImageIndicator({
    required BuildContext context,
    required String text,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 10,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize + appState.getTextSizeOffset(),
            ),
          ),
        ),
      ),
    );
  }

  /// BackdropFilter pour les overlays de texte sur images (rent start future, etc.)
  static Widget buildImageOverlay({
    required BuildContext context,
    required String text,
    double fontSize = 12,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize + appState.getTextSizeOffset(),
            ),
          ),
        ),
      ),
    );
  }

  /// Décoration de carte standardisée avec ombre et gradient
  static BoxDecoration buildCardDecoration(BuildContext context, {
    double borderRadius = 16,
    bool withGradient = true,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ] : null,
      gradient: withGradient ? LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).cardColor,
          Theme.of(context).cardColor.withValues(alpha: 0.8),
        ],
      ) : null,
      color: withGradient ? null : Theme.of(context).cardColor,
    );
  }

  /// Décoration pour les containers de détails avec bordure
  static BoxDecoration buildDetailContainerDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.brightness == Brightness.light 
          ? Colors.grey.shade50 
          : theme.cardColor.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.brightness == Brightness.light 
            ? Colors.grey.shade200 
            : theme.dividerColor,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.brightness == Brightness.light 
              ? Colors.black.withValues(alpha: 0.02) 
              : Colors.black.withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Décoration pour les headers avec gradient primaire
  static BoxDecoration buildPrimaryGradientDecoration(BuildContext context, {
    double borderRadius = 24,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.primaryColor.withValues(alpha: 0.9),
          theme.primaryColor,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.2, 1.0],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: theme.primaryColor.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Widget memoized pour éviter les rebuilds inutiles des sections
  static Widget buildMemoizedSection({
    required String title,
    required List<Widget> children,
    required BuildContext context,
    String? cacheKey,
    Duration? cacheDuration,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeader(context, title),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  /// InputDecoration standardisée pour les champs de texte
  static InputDecoration buildStandardInputDecoration(BuildContext context, {
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Container avec BackdropFilter pour les modals
  static Widget buildModalContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 24,
    double maxHeightFactor = 0.8,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
      ),
      child: child,
    );
  }

  /// Indicateur de drag pour les modals
  static Widget buildDragIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withValues(alpha: 0.2) 
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Widget optimisé pour texte avec shimmer
  static Widget buildOptimizedTextWithShimmer({
    required BuildContext context,
    required String? value,
    required String label,
    required bool isLoading,
    TextStyle? valueStyle,
    TextStyle? labelStyle,
    double spacing = 12.0,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    final defaultValueStyle = valueStyle ?? TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: theme.textTheme.bodyLarge?.color,
      letterSpacing: -0.3,
      height: 1.1,
    );

    final defaultLabelStyle = labelStyle ?? TextStyle(
      fontSize: 14,
      color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
      letterSpacing: -0.2,
      height: 1.1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label, style: defaultLabelStyle),
          SizedBox(width: spacing),
          isLoading
              ? ShimmerUtils.originalColorShimmer(
                  child: Text(value ?? '', style: defaultValueStyle),
                  color: theme.textTheme.bodyLarge?.color,
                )
              : Text(value ?? '', style: defaultValueStyle),
        ],
      ),
    );
  }

  /// Widget pour valeur avec indicateur de balance (+ ou -)
  static Widget buildIndentedBalance({
    required BuildContext context,
    required String label,
    required double value,
    required String symbol,
    required bool isPositive,
    required bool isLoading,
    required bool showAmounts,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    String formattedAmount = showAmounts 
        ? (isPositive ? "+ ${value.toStringAsFixed(2)} $symbol" : "- ${value.toStringAsFixed(2)} $symbol")
        : (isPositive ? "+ " : "- ") + ('*' * 10);

    Color valueColor = isPositive
        ? const Color(0xFF34C759) // Vert iOS
        : const Color(0xFFFF3B30); // Rouge iOS

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 1.0, bottom: 1.0),
      child: Row(
        children: [
          isLoading
              ? ShimmerUtils.originalColorShimmer(
                  child: Text(
                    formattedAmount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: valueColor,
                    ),
                  ),
                  color: valueColor,
                )
              : Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: valueColor,
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: -0.2,
              color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour créer une carte de paramètres standardisée
  static Widget buildSettingsCard({
    required BuildContext context,
    required List<Widget> children,
    String? footnote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6, right: 16),
            child: Text(
              footnote,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  /// Widget pour un élément de paramètres standardisé
  static Widget buildSettingsItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
    Color? titleColor,
    IconData? leadingIcon,
    Color? leadingIconColor,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: leadingIconColor ?? Colors.blue, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.0 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w400,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.0 + appState.getTextSizeOffset(),
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    return Column(
      children: [
        onTap != null 
            ? GestureDetector(onTap: onTap, child: content)
            : content,
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Divider(
              height: 1, 
              thickness: 0.5, 
              color: Colors.grey.withValues(alpha: 0.3)
            ),
          ),
      ],
    );
  }
} 