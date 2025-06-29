import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/services/biometric_service.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;
  String _biometricType = 'Biométrie';
  bool _authFailed = false;
  bool _isCheckingPrevAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Vérifier si une authentification récente existe déjà
    _checkPreviousAuthentication().then((_) {
      // Si toujours à l'écran, charger les types biométriques et lancer l'auth
      if (mounted && !_isCheckingPrevAuth) {
        _loadBiometricType();
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPreviousAuthentication() async {
    // Vérifier si on doit vraiment demander une authentification
    final shouldAuth = await _biometricService.shouldAuthenticate();

    // Si pas besoin d'authentification, passer directement à l'application
    if (!shouldAuth) {
      widget.onAuthenticated();
      return;
    }

    setState(() {
      _isCheckingPrevAuth = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'application revient au premier plan et que l'authentification a échoué,
    // réessayer automatiquement
    if (state == AppLifecycleState.resumed && _authFailed) {
      _authenticate();
    }
  }

  Future<void> _loadBiometricType() async {
    final biometricType = await _biometricService.getBiometricTypeName();
    setState(() {
      _biometricType = biometricType;
    });
  }

  Future<void> _authenticate() async {
    // Ne pas démarrer une nouvelle authentification si une est déjà en cours
    // ou si on est encore en train de vérifier l'authentification précédente
    if (_isAuthenticating || _isCheckingPrevAuth) return;

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    try {
      final authenticated = await _biometricService.authenticate(reason: 'Veuillez vous authentifier pour accéder à l\'application');

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _authFailed = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur d\'authentification: $e');
      setState(() {
        _authFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si on est encore en train de vérifier l'authentification précédente,
    // afficher un indicateur de chargement
    if (_isCheckingPrevAuth) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo_community.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(S.of(context).verifyingAuthentication),
            ],
          ),
        ),
      );
    }

    IconData icon = Icons.fingerprint;

    if (_biometricType.contains('faciale')) {
      icon = Icons.face;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou image de l'application
              Image.asset(
                'assets/logo_community.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 48),
              Text(
                'RealToken App',
                style: TextStyle(
                  fontSize: 24 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.of(context).pleaseAuthenticateToAccess,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Afficher soit un indicateur de progression, soit le bouton d'authentification
              _isAuthenticating
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _authenticate,
                          icon: Icon(icon, size: 24),
                          label: Text(S.of(context).authenticateWithBiometric(_biometricType)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_authFailed) ...[
                          const SizedBox(height: 16),
                          Text(
                            S.of(context).biometricAuthenticationFailed,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => widget.onAuthenticated(),
                            child: Text(S.of(context).continueWithoutAuthentication),
                          ),
                        ],
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
