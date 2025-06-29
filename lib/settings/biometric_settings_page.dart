import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  _BiometricSettingsPageState createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  String _biometricType = '';
  bool _isLoading = true;
  bool _isTesting = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Vérification des capacités biométriques...';
    });

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final availableBiometrics = await _biometricService.getAvailableBiometrics();
      final biometricType = await _biometricService.getBiometricTypeName();

      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _availableBiometrics = availableBiometrics;
        _biometricType = biometricType;
        _statusMessage = isAvailable ? 'Votre appareil prend en charge $_biometricType' : 'Votre appareil ne prend pas en charge l\'authentification biométrique';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: Impossible de vérifier la biométrie';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });
  }

  Future<void> _testBiometricAuth() async {
    setState(() {
      _isTesting = true;
      _statusMessage = 'Test d\'authentification...';
    });

    try {
      final authenticated = await _biometricService.authenticate(reason: 'Ceci est un test d\'authentification biométrique');

      setState(() {
        _statusMessage = authenticated ? 'Test réussi! L\'authentification biométrique fonctionne correctement.' : 'Échec du test. Veuillez réessayer.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors du test: ${e.toString()}';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Authentification biométrique'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (!_isLoading && _isBiometricAvailable)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _initBiometrics,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(_statusMessage),
              ],
            ))
          : ListView(
              children: [
                const SizedBox(height: 12),
                _buildSectionHeader(context, "Sécurité", CupertinoIcons.lock),
                if (!_isBiometricAvailable) _buildErrorCard() else _buildSettingsCard(),
                const SizedBox(height: 24),
                if (_isBiometricAvailable && _isBiometricEnabled) _buildTestSection(),
              ],
            ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Biométrie non disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Votre appareil ne supporte pas l\'authentification biométrique ou aucune donnée biométrique n\'est enregistrée dans les paramètres de l\'appareil.',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Redirection vers les paramètres du système
              try {
                AppSettings.openAppSettings(type: AppSettingsType.security);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Impossible d\'ouvrir les paramètres. Veuillez les configurer manuellement.')),
                );
              }
            },
            child: Text('Configurer dans les paramètres système'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return _buildSettingsSection(
      context,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getBiometricIcon(),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _biometricType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activer l\'authentification biométrique',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isBiometricEnabled,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (bool value) async {
                      if (value) {
                        await _authenticateWithBiometrics();
                      } else {
                        await _saveSetting(false);
                        setState(() {
                          _statusMessage = 'Authentification biométrique désactivée';
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tester l\'authentification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Vous pouvez tester l\'authentification biométrique pour vérifier qu\'elle fonctionne correctement.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: _isTesting
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _testBiometricAuth,
                    icon: Icon(_getBiometricIcon()),
                    label: Text('Tester maintenant'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _statusMessage = 'Authentification en cours...';
    });

    final authenticated = await _biometricService.authenticate(reason: 'Authentifiez-vous pour activer la biométrie');

    if (authenticated) {
      await _saveSetting(true);
      setState(() {
        _statusMessage = 'Authentification biométrique activée avec succès';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication biométrique activée')),
      );
    } else {
      setState(() {
        _statusMessage = 'Échec de l\'authentification. Veuillez réessayer.';
      });
    }
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else {
      return CupertinoIcons.lock_shield;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
