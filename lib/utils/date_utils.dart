import 'package:intl/intl.dart';

class CustomDateUtils {
  // Méthode pour formater une date en une chaîne compréhensible
  static String formatReadableDate(String dateString) {
    try {
      // Parse la date depuis le format donné
      DateTime parsedDate = DateTime.parse(dateString);

      // Formater la date dans un format lisible, par exemple: 1 Dec 2024
      String formattedDate = DateFormat('d MMM yyyy').format(parsedDate);

      return formattedDate;
    } catch (e) {
      // Si une erreur survient, retourne la date d'origine
      return dateString;
    }
  }

  // Fonction utilitaire pour formater la date et le montant
  static String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  static String formatReadableDateWithTime(String dateString) {
    try {
      // Parse la date en UTC
      DateTime parsedDate = DateTime.parse(dateString).toUtc();
      // Convertit en heure locale
      DateTime localDate = parsedDate.toLocal();

      // Formate la date avec l'heure dans un format lisible: 1 Dec 2024 14:30:45
      String formattedDate =
          DateFormat('d MMM yyyy HH:mm:ss').format(localDate);

      return formattedDate;
    } catch (e) {
      // Si une erreur survient, retourne la date d'origine
      return dateString;
    }
  }

  static int weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber;
  }
}
