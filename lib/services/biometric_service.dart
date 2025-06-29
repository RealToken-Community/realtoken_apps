import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _lastSuccessfulAuth;

  factory BiometricService() {
    return _instance;
  }

  BiometricService._internal();

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometricEnabled') ?? false;
  }

  Future<DateTime?> getLastSuccessfulAuth() {
    return Future.value(_lastSuccessfulAuth);
  }

  Future<bool> shouldAuthenticate() async {
    // Si la biométrie n'est pas activée, ne pas demander d'authentification
    if (!await isBiometricEnabled()) {
      return false;
    }

    // Si aucune authentification réussie récente, demander une authentification
    if (_lastSuccessfulAuth == null) {
      return true;
    }

    // Si une authentification réussie est intervenue dans les dernières minutes,
    // ne pas redemander d'authentification
    final now = DateTime.now();
    final difference = now.difference(_lastSuccessfulAuth!);

    // Ne pas redemander si moins de 5 minutes se sont écoulées
    return difference.inMinutes >= 5;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la biométrie: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des biométries disponibles: $e');
      return [];
    }
  }

  Future<String> getBiometricTypeName() async {
    final availableBiometrics = await getAvailableBiometrics();

    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Reconnaissance faciale';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Empreinte digitale';
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return 'Authentification forte';
    } else if (availableBiometrics.contains(BiometricType.weak)) {
      return 'Authentification basique';
    } else {
      return 'Biométrie';
    }
  }

  Future<bool> authenticate({String reason = 'Veuillez vous authentifier pour continuer'}) async {
    // Si la biométrie n'est pas disponible ou pas activée, considérer comme authentifié
    if (!await isBiometricAvailable() || !await isBiometricEnabled()) {
      return true;
    }

    // Si une authentification récente existe et est valide, ne pas redemander
    if (_lastSuccessfulAuth != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSuccessfulAuth!);

      // Si moins de 30 secondes se sont écoulées depuis la dernière authentification réussie,
      // considérer l'utilisateur comme déjà authentifié (évite les appels répétés)
      if (difference.inSeconds < 30) {
        return true;
      }
    }

    try {
      // Forcer la fermeture de tout dialogue précédent
      await _localAuth.stopAuthentication();

      // Attendre un court instant pour s'assurer que tout dialogue précédent est fermé
      await Future.delayed(const Duration(milliseconds: 300));

      // Lancer l'authentification avec des options plus strictes
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true, // Indique que c'est une transaction sensible
          useErrorDialogs: true, // Utiliser les dialogues d'erreur du système
        ),
      );

      // Si l'authentification a réussi, enregistrer le moment
      if (result) {
        _lastSuccessfulAuth = DateTime.now();
      }

      return result;
    } catch (e) {
      debugPrint('Erreur lors de l\'authentification: $e');
      // En cas d'erreur, on considère que l'authentification a échoué
      return false;
    }
  }
}
