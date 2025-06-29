import 'package:realtoken_asset_tracker/generated/l10n.dart';

/// Utilitaires pour le parsing et la gestion des données de localisation
/// Factorisation du parsing de fullName répétitif dans l'application
class LocationUtils {
  /// Extrait la ville depuis un fullName formaté
  static String extractCity(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length >= 2 ? parts[1].trim() : S.current.unknownCity;
  }

  /// Extrait la région depuis un fullName formaté
  static String extractRegion(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length >= 3
        ? parts[2].trim().substring(0, 2)
        : S.current.unknown.toLowerCase();
  }

  /// Extrait le pays depuis un fullName formaté
  static String extractCountry(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length == 4 ? parts[3].trim() : "USA"; // Pays par défaut
  }

  /// Parse complètement un fullName et retourne toutes les informations de localisation
  static Map<String, String> parseFullName(String fullName) {
    final parts = fullName.split(',');
    return {
      'city': parts.length >= 2 ? parts[1].trim() : S.current.unknownCity,
      'regionCode': parts.length >= 3
          ? parts[2].trim().substring(0, 2)
          : S.current.unknown.toLowerCase(),
      'country': parts.length == 4 ? parts[3].trim() : "USA",
    };
  }

  /// Formate les pieds carrés en mètres carrés ou garde les pieds carrés
  static String formatSquareFeet(double sqft, bool convertToSquareMeters) {
    if (convertToSquareMeters) {
      double squareMeters =
          sqft * 0.092903; // Conversion des pieds carrés en m²
      return '${squareMeters.toStringAsFixed(2)} m²';
    } else {
      return '${sqft.toStringAsFixed(2)} sqft';
    }
  }

  /// Vérifie si une ville doit être extraite depuis le fullName
  static bool shouldUseCityFromFullname(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.length >= 2;
  }

  /// Extrait le nom de la propriété (première partie avant la virgule)
  static String extractPropertyName(String fullName) {
    List<String> parts = fullName.split(',');
    return parts.isNotEmpty ? parts[0].trim() : fullName;
  }
}
