import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:realtokens/structure/home_page.dart';
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

void main() async {
  final logger = Logger(); // Initialiser une instance de logger
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
      widgetsBinding: widgetsBinding); // Préserver le splash screen natif

  // Utilisez un bloc try-catch pour vérifier et initialiser Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    logger.w(e);
  }

  await Hive.initFlutter();

  // Conditionner le chargement de FMTC uniquement si l'application n'est pas exécutée sur le Web
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
    Hive.openBox('customInitPrices'),
    Hive.openBox('YamMarket'),
    Hive.openBox('YamHistory'),
  ]);

  // Initialisation de DataManager
  final dataManager = DataManager();

  // Charger les premières opérations en parallèle
  dataManager.updateGlobalVariables();
  dataManager.loadSelectedCurrency();
  dataManager.loadUserIdToAddresses();

  FlutterNativeSplash
      .remove(); // Supprimer le splash screen natif après l'initialisation

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager),
        ChangeNotifierProvider(
            create: (_) => AppState()), // AppState for global settings
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DataManager dataManager;
  final bool _requireConsent = false;
  static final logger = Logger(); // Initialiser une instance de logger

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialiser le DataManager ou le récupérer via Provider si déjà initialisé
    dataManager = Provider.of<DataManager>(context, listen: false);

    // Initialiser OneSignal avec l'App ID
    initOneSignal();
  }

  void initOneSignal() {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    // Configuration de OneSignal avec le consentement requis ou non
    OneSignal.consentRequired(_requireConsent);
    OneSignal.initialize("e7059f66-9c12-4d21-a078-edaf1a203dea");

    // Demander l'autorisation de notification
    OneSignal.Notifications.requestPermission(true);

    // Configuration des gestionnaires de notifications et d'état utilisateur
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      logger.i(
          'Notification reçue en premier plan : ${event.notification.jsonRepresentation()}');
      event.preventDefault(); // Empêche l'affichage automatique si nécessaire
      event.notification.display(); // Affiche manuellement la notification
    });

    OneSignal.Notifications.addClickListener((event) {
      logger.i(
          'Notification cliquée : ${event.notification.jsonRepresentation()}');
    });

    OneSignal.User.pushSubscription.addObserver((state) {
      logger.i(
          'Utilisateur inscrit aux notifications : ${state.current.jsonRepresentation()}');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'application est revenue au premier plan
      _reloadData();
    }
  }

  void _reloadData() async {
    // Recharger les données nécessaires
    await Future.wait([
      dataManager.updateGlobalVariables(),
      dataManager.loadSelectedCurrency(),
      dataManager.loadUserIdToAddresses(),
    ]);
    await dataManager.fetchAndCalculateData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
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
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: appState.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: const MyHomePage(),
        );
      },
    );
  }
}
