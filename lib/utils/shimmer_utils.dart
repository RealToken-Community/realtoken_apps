import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Classe utilitaire pour des effets de shimmer améliorés
class ShimmerUtils {
  /// Crée un shimmer qui préserve la couleur originale du widget
  /// Cet effet applique un shimmer subtil tout en gardant la couleur d'origine
  static Widget originalColorShimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1200),
    Color? color,
  }) {
    return Stack(
      children: [
        // Le widget original sans modification
        child,

        // L'effet shimmer par-dessus avec un mode de fusion qui préserve les couleurs
        Positioned.fill(
          child: Shimmer.fromColors(
            baseColor: Colors.transparent,
            highlightColor: color != null
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.7),
            period: duration,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color != null
                        ? color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: const Alignment(-2.0, 0.0),
                  end: const Alignment(2.0, 0.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Crée un shimmer standard avec des couleurs personnalisées
  static Widget standardShimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: duration,
      child: child,
    );
  }
}
