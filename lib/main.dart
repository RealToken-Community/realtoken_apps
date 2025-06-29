import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/services/biometric_service.dart';
import 'package:realtoken_asset_tracker/services/google_drive_service.dart';
import 'package:realtoken_asset_tracker/structure/home_page.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'managers/data_manager.dart';
import 'settings/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app_state.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 Importation de dotenv
import 'managers/archive_manager.dart';
import 'managers/apy_manager.dart';
import 'screens/lock_screen.dart';
import 'utils/data_fetch_utils.dart';
import 'utils/preference_keys.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load(fileName: "env_config.txt"); // 🔥 Nouveau fichier
    debugPrint("✅ Variables d'environnement chargées avec succès !");
  } catch (e) {
    debugPrint("❌ Erreur lors du chargement de dotenv: $e");
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      debugPrint("✅ Firebase initialisé !");
    }
  } catch (e, stacktrace) {
    debugPrint("❌ Erreur Firebase : $e");
    debugPrint("📌 Stacktrace : $stacktrace");
  }

  await Hive.initFlutter();

  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('mapStore').manage.create();
  }

  await Future.wait([
    Hive.openBox('realTokens'),
    Hive.openBox('balanceHistory'),
    Hive.openBox('walletValueArchive'),
    Hive.openBox('roiValueArchive'),
    Hive.openBox('apyValueArchive'),
    Hive.openBox('rentedArchive'),
    Hive.openBox('HealthAndLtvValueArchive'),
    Hive.openBox('customInitPrices'),
    Hive.openBox('YamMarket'),
    Hive.openBox('YamHistory'),
  ]);

  final archiveManager = ArchiveManager();
  final apyManager = ApyManager();
  final dataManager = DataManager();
  final currencyProvider = CurrencyProvider();
  final appState = AppState();

  // Connecter DataManager à AppState
  appState.dataManager = dataManager;

  // ✅ Attendre que `loadSelectedCurrency()` récupère la bonne valeur avant de démarrer l'app
  await currencyProvider.loadSelectedCurrency();

  final prefs = await SharedPreferences.getInstance();
  final bool autoSyncEnabled = prefs.getBool('autoSync') ?? false;

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager),
        ChangeNotifierProvider(
            create: (_) =>
                CurrencyProvider()), // ✅ Assurez-vous que CurrencyProvider est bien ici
        ChangeNotifierProvider(create: (_) => appState),
      ],
      child: MyApp(autoSyncEnabled: autoSyncEnabled),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool autoSyncEnabled;
  const MyApp({super.key, required this.autoSyncEnabled});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DataManager dataManager;
  final bool _requireConsent = false;
  DateTime? _lastSyncTime;
  final _googleDriveService = GoogleDriveService();
  bool _isGoogleDriveConnected = false;
  bool _autoSyncEnabled = false;
  bool _isAuthenticated = false;
  final BiometricService _biometricService = BiometricService();
  DateTime? _lastAuthTime;
  AppLifecycleState _lastLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dataManager = Provider.of<DataManager>(context, listen: false);
    _checkAuthentication();
    _checkGoogleDriveConnection();
    _autoSyncEnabled = widget.autoSyncEnabled;

    // Charger les données initiales de l'application
    _loadInitialData();

    if (!kIsWeb) {
      initOneSignal();
    } else {
      debugPrint("🚫 OneSignal non activé sur le Web.");
    }
  }

  // Méthode pour charger les données initiales de l'application
  Future<void> _loadInitialData() async {
    debugPrint("📱 Chargement initial des données de l'application...");
    try {
      // Utiliser loadDataWithCache pour une meilleure réactivité
      await DataFetchUtils.loadDataWithCache(context);
      debugPrint("✅ Chargement initial des données terminé");
    } catch (e) {
      debugPrint("❌ Erreur lors du chargement initial des données: $e");
    }
  }

  Future<void> _checkAuthentication() async {
    final biometricEnabled = await _biometricService.isBiometricEnabled();

    // Si la biométrie n'est pas activée, on considère l'utilisateur comme authentifié
    if (!biometricEnabled) {
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    // Si l'utilisateur est déjà authentifié, vérifier s'il s'est authentifié récemment (moins de 10 minutes)
    if (_lastAuthTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastAuthTime!);

      // Si moins de 10 minutes ont passé depuis la dernière authentification,
      // ne pas redemander d'authentification
      if (difference.inMinutes < 10) {
        setState(() {
          _isAuthenticated = true;
        });
        return;
      }
    }

    // Dans les autres cas, l'utilisateur doit s'authentifier
    setState(() {
      _isAuthenticated = false;
    });
  }

  void setAuthenticated(bool value) {
    setState(() {
      _isAuthenticated = value;
      if (value) {
        _lastAuthTime = DateTime.now();
      }
    });
  }

  Future<void> _checkGoogleDriveConnection() async {
    await _googleDriveService.initDrive();
    setState(() {
      _isGoogleDriveConnected = _googleDriveService.isGoogleDriveConnected();
    });
  }

  void initOneSignal() {
    if (kIsWeb) {
      debugPrint("🚫 OneSignal désactivé sur le Web");
      return; // Ne pas exécuter OneSignal sur le Web
    }
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(_requireConsent);
    OneSignal.initialize("e7059f66-9c12-4d21-a078-edaf1a203dea");

    // Vérifier si l'utilisateur a déjà refusé les notifications
    _checkAndRequestNotificationPermission();

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
          'Notification reçue en premier plan : ${event.notification.jsonRepresentation()}');
      event.preventDefault();
      event.notification.display();
    });
    OneSignal.Notifications.addClickListener((event) {
      debugPrint(
          'Notification cliquée : ${event.notification.jsonRepresentation()}');
    });
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint(
          'Utilisateur inscrit aux notifications : ${state.current.jsonRepresentation()}');
    });
  }

  Future<void> _checkAndRequestNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRefusedNotifications =
        prefs.getBool(PreferenceKeys.hasRefusedNotifications) ?? false;
    final hasAskedNotifications =
        prefs.getBool(PreferenceKeys.hasAskedNotifications) ?? false;

    // Si l'utilisateur a déjà refusé, ne pas redemander
    if (hasRefusedNotifications) {
      debugPrint(
          "🚫 L'utilisateur a déjà refusé les notifications, pas de nouvelle demande");
      return;
    }

    // Si on n'a jamais demandé, ou si l'utilisateur n'a pas explicitement refusé, demander
    if (!hasAskedNotifications) {
      debugPrint("📱 Première demande d'autorisation de notifications");
      await prefs.setBool(PreferenceKeys.hasAskedNotifications, true);

      final hasPermission =
          await OneSignal.Notifications.requestPermission(true);

      // Si la permission a été refusée, sauvegarder cette information
      if (!hasPermission) {
        await prefs.setBool(PreferenceKeys.hasRefusedNotifications, true);
        debugPrint(
            "🚫 Permissions de notifications refusées par l'utilisateur");
      } else {
        debugPrint("✅ Permissions de notifications accordées");
        // Réinitialiser le flag de refus au cas où l'utilisateur accepterait après avoir refusé
        await prefs.setBool(PreferenceKeys.hasRefusedNotifications, false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sauvegarder l'état précédent avant de le mettre à jour
    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      // Demander l'authentification UNIQUEMENT si l'application était en arrière-plan (inactive ou paused)
      // et qu'elle revient au premier plan après un certain temps
      if (previousState == AppLifecycleState.paused ||
          previousState == AppLifecycleState.inactive) {
        final now = DateTime.now();
        final needsAuth = _lastAuthTime == null ||
            now.difference(_lastAuthTime!).inMinutes >=
                5; // Redemander après 5 minutes

        if (needsAuth) {
          _checkAuthentication();
        }
      }

      // Toujours recharger les données
      _reloadData();
    }
  }

  void _reloadData() async {
    debugPrint("🔄 Mise à jour des données après reprise de l'application...");
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    try {
      // Utiliser refreshData pour une mise à jour légère mais complète
      await DataFetchUtils.refreshData(context);
    } catch (e) {
      debugPrint("❌ Erreur lors de la mise à jour des données: $e");
    }

    await _loadAutoSyncPreference();

    if (_autoSyncEnabled) {
      debugPrint("🟢 AutoSync activé: $_autoSyncEnabled");
      _checkAndSyncGoogleDrive();
    } else {
      debugPrint("🔴 AutoSync désactivé: $_autoSyncEnabled");
    }
  }

  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool autoSync = prefs.getBool('autoSync') ?? false;
    print("⚙️ Chargement autoSync: $autoSync");
    setState(() {
      _autoSyncEnabled = autoSync;
    });
  }

  Future<void> _checkAndSyncGoogleDrive() async {
    if (_isGoogleDriveConnected) {
      final now = DateTime.now();
      if (_lastSyncTime == null || now.difference(_lastSyncTime!).inHours > 1) {
        debugPrint("🔄 Synchronisation avec Google Drive en cours...");
        await _googleDriveService.syncGoogleDrive(context);
        _lastSyncTime = now;
      } else {
        debugPrint("✅ Synchronisation non nécessaire");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Initialiser Parameters avec AppState
        Parameters.initAppState(context);

        return MaterialApp(
          title: 'RealToken mobile app',
          locale: Locale(appState.selectedLanguage),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: getLightTheme(appState.primaryColor),
          darkTheme: getDarkTheme(appState.primaryColor),
          themeMode: appState.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: _isAuthenticated
              ? const MyHomePage()
              : LockScreen(
                  onAuthenticated: () => setAuthenticated(true),
                ),
        );
      },
    );
  }
}
