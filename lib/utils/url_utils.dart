import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static Future<void> launchURL(String url) async {
    debugPrint(
        'Tentative d\'ouverture de l\'URL: $url'); // Log pour capturer l'URL
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView, // Ouvre dans un navigateur externe
        );
      } else {
        throw 'Impossible de lancer l\'URL : $url';
      }
    } catch (e) {
      debugPrint('Erreur lors du lancement de l\'URL: $e');
    }
  }
}
