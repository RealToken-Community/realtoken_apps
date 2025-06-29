import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:realtoken_asset_tracker/utils/performance_utils.dart';

/// Utilitaires pour optimiser les performances des graphiques
class ChartPerformanceUtils {
  /// Échantillonne intelligemment les données pour éviter les graphiques surchargés
  static List<T> sampleData<T>(List<T> data, {int maxPoints = 100}) {
    if (data.length <= maxPoints) return data;

    final step = (data.length / maxPoints).ceil();
    final sampled = <T>[];

    // Toujours inclure le premier et dernier point
    sampled.add(data.first);

    for (int i = step; i < data.length - 1; i += step) {
      sampled.add(data[i]);
    }

    // Toujours inclure le dernier point
    if (data.length > 1) {
      sampled.add(data.last);
    }

    return sampled;
  }

  /// Cache les spots FlChart pour éviter les recalculs
  static List<FlSpot> getCachedSpots(String key, List<double> values) {
    const cacheDuration = Duration(minutes: 5);

    final cached = PerformanceUtils.getFromCache<List<FlSpot>>(key);
    if (cached != null) return cached;

    final spots = values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    PerformanceUtils.setCache(key, spots, cacheDuration);
    return spots;
  }

  /// Optimise les couleurs pour les graphiques avec cache
  static Color getCachedColor(String key, Color Function() colorGenerator) {
    const cacheDuration = Duration(hours: 1);

    final cached = PerformanceUtils.getFromCache<Color>(key);
    if (cached != null) return cached;

    final color = colorGenerator();
    PerformanceUtils.setCache(key, color, cacheDuration);
    return color;
  }

  /// Calcule efficacement les min/max pour les axes
  static MapEntry<double, double> getMinMaxWithPadding(
    List<double> values, {
    double paddingPercent = 0.1,
  }) {
    if (values.isEmpty) return const MapEntry(0.0, 1.0);

    double min = values.first;
    double max = values.first;

    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }

    final range = max - min;
    final padding = range * paddingPercent;

    return MapEntry(
      (min - padding).clamp(0.0, double.infinity),
      max + padding,
    );
  }

  /// Simplifie les paths complexes pour de meilleures performances
  static List<FlSpot> simplifyPath(List<FlSpot> spots,
      {double tolerance = 1.0}) {
    if (spots.length <= 3) return spots;

    final simplified = <FlSpot>[spots.first];

    for (int i = 1; i < spots.length - 1; i++) {
      final prev = simplified.last;
      final current = spots[i];
      final next = spots[i + 1];

      // Calculer la distance perpendiculaire du point actuel à la ligne prev-next
      final distance = _perpendicularDistance(current, prev, next);

      if (distance > tolerance) {
        simplified.add(current);
      }
    }

    simplified.add(spots.last);
    return simplified;
  }

  /// Calcule la distance perpendiculaire d'un point à une ligne
  static double _perpendicularDistance(
      FlSpot point, FlSpot lineStart, FlSpot lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;

    if (dx == 0 && dy == 0) {
      return (point.x - lineStart.x).abs() + (point.y - lineStart.y).abs();
    }

    final t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) /
        (dx * dx + dy * dy);
    final projection = FlSpot(
      lineStart.x + t * dx,
      lineStart.y + t * dy,
    );

    final distX = point.x - projection.x;
    final distY = point.y - projection.y;

    return (distX * distX + distY * distY).abs();
  }

  /// Optimise l'affichage des tooltips avec debouncing
  static void showTooltipDebounced(String key, VoidCallback showTooltip) {
    PerformanceUtils.debounce(
        key, const Duration(milliseconds: 300), showTooltip);
  }

  /// Batch les mises à jour des graphiques pour éviter les rebuilds multiples
  static final Map<String, List<VoidCallback>> _pendingUpdates = {};

  static void batchChartUpdate(String chartKey, VoidCallback update) {
    _pendingUpdates.putIfAbsent(chartKey, () => []).add(update);

    PerformanceUtils.debounce(
      'chart_batch_$chartKey',
      const Duration(milliseconds: 16), // ~60fps
      () => _flushChartUpdates(chartKey),
    );
  }

  static void _flushChartUpdates(String chartKey) {
    final updates = _pendingUpdates.remove(chartKey);
    if (updates != null) {
      for (final update in updates) {
        update();
      }
    }
  }

  /// Méthode pour nettoyer les ressources
  static void dispose() {
    _pendingUpdates.clear();
  }
}
