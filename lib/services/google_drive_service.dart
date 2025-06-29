import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import 'package:realtoken_asset_tracker/utils/data_fetch_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  drive.DriveApi? _driveApi;

  /// Vérifier la connexion et initialiser l'API Google Drive
  Future<void> initDrive() async {
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signInSilently();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final auth.AuthClient client = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken('Bearer', googleAuth.accessToken!,
              DateTime.now().add(Duration(hours: 1)).toUtc()),
          googleAuth.idToken,
          _googleSignIn.scopes,
        ),
      );
      _driveApi = drive.DriveApi(client);
    }
  }

  Future<void> deleteFileFromGoogleDrive(String fileName) async {
    if (_driveApi == null) {
      debugPrint("❌ Google Drive API non initialisée.");
      return;
    }

    try {
      // Rechercher le fichier par son nom dans le dossier appDataFolder
      final drive.FileList fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("❌ Aucun fichier trouvé avec le nom : $fileName");
        return;
      }

      // Supprimer le fichier trouvé
      final String fileId = fileList.files!.first.id!;
      await _driveApi!.files.delete(fileId);

      debugPrint("✅ Fichier '$fileName' supprimé avec succès de Google Drive.");
    } catch (e) {
      debugPrint("❌ Erreur lors de la suppression du fichier : $e");
    }
  }

  /// Vérifier si Google Drive est connecté
  bool isGoogleDriveConnected() {
    return _driveApi != null;
  }

  /// Connexion à Google Drive
  Future<void> connectToGoogleDrive() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      await initDrive();
    }
  }

  /// Déconnexion de Google Drive
  Future<void> disconnectFromGoogleDrive() async {
    await _googleSignIn.disconnect();
    _driveApi = null;
  }

  Future<void> syncGoogleDrive(BuildContext context) async {
    if (_driveApi == null) {
      debugPrint("❌ Google Drive n'est pas connecté !");
      return;
    }

    debugPrint("🔄 Téléchargement des données depuis Google Drive...");
    Map<String, dynamic>? driveData = await downloadBackupFromGoogleDrive();

    if (driveData != null) {
      // Nettoyer les données de Google Drive
      for (var entry in driveData.entries) {
        driveData[entry.key] = cleanJsonString(entry.value);
      }
    }

    debugPrint("📂 Chargement des données locales...");
    Map<String, dynamic> localData = await _loadLocalData();

    // Si les données locales sont vides, on ne fait que l'importation sans upload
    if (localData.isEmpty && driveData != null) {
      debugPrint(
          "📥 Importation des données de Google Drive dans l'application...");
      await _restoreLocalBackup(
          "${(await getApplicationDocumentsDirectory()).path}/realToken_Backup.zip");
      return;
    }

    debugPrint("🔀 Fusion des données...");
    Map<String, dynamic> mergedData = _mergeData(localData, driveData);

    // 🔹 Assurer que les données sont bien enregistrées dans Hive
    debugPrint(
        "📌 Contenu fusionné après merge (avant stockage dans Hive) : ${jsonEncode(mergedData)}");
    await _storeMergedDataInHive(mergedData);

    DataFetchUtils.refreshData(context);

    // Si les données locales sont vides après fusion, ne pas uploader
    if (mergedData.isEmpty) {
      debugPrint("⚠️ Aucune donnée à sauvegarder sur Google Drive.");
      return;
    }

    debugPrint("📤 Envoi des données fusionnées sur Google Drive...");
    await backupToGoogleDrive();

    debugPrint("✅ Synchronisation avec Google Drive terminée.");
  }

  Future<void> _storeMergedDataInHive(Map<String, dynamic> mergedData) async {
    debugPrint("📦 Stockage des données fusionnées dans Hive...");

    var balanceHistoryBox = await Hive.openBox('balanceHistory');
    var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
    var customInitPricesBox = await Hive.openBox('customInitPrices');
    var customRoiBox = await Hive.openBox('roiValueArchive');
    var customApyBox = await Hive.openBox('apyValueArchive');
    var customYamBox = await Hive.openBox('YamMarket');

    Future<void> storeWithoutDuplicates(Box box, String key) async {
      if (mergedData.containsKey(key)) {
        // debugPrint("🔍 Clés à stocker dans '$key' : ${mergedData[key].keys}");

        Map<String, dynamic> existingData =
            Map<String, dynamic>.from(box.toMap());
        Map<String, dynamic> newData =
            Map<String, dynamic>.from(mergedData[key]);

        newData.forEach((dataKey, value) {
          // ✅ Si la clé n'existe pas, on l'ajoute directement
          if (!existingData.containsKey(dataKey)) {
            debugPrint("📝 Ajout dans '$key' : $dataKey -> $value");
            box.put(dataKey, value);
          } else {
            // ✅ Si la clé existe, comparer les timestamps
            dynamic existingValue = existingData[dataKey];

            // Gérer les cas où les valeurs sont des listes d'objets avec des timestamps
            if (existingValue is List && value is List) {
              List<dynamic> updatedList = List.from(existingValue);

              for (var newItem in value) {
                if (newItem is Map && newItem.containsKey('timestamp')) {
                  // Extraire le timestamp du nouvel élément
                  String newTimestamp = newItem['timestamp'];

                  // Vérifier si un élément avec le même timestamp existe déjà
                  bool exists = updatedList.any((existingItem) =>
                      existingItem is Map &&
                      existingItem.containsKey('timestamp') &&
                      existingItem['timestamp'] == newTimestamp);

                  if (!exists) {
                    debugPrint(
                        "➕ Ajouté (nouveau timestamp) dans '$key' : $newItem");
                    updatedList.add(newItem);
                  }
                }
              }
              // Mettre à jour la liste dans Hive
              box.put(dataKey, updatedList);
            } else if (value is Map) {
              // Gérer les objets Map individuellement
              value.forEach((subKey, subValue) {
                if (!existingValue.containsKey(subKey) ||
                    (existingValue[subKey]['timestamp'] ?? '') <
                        (subValue['timestamp'] ?? '')) {
                  debugPrint(
                      "🔄 Mise à jour (timestamp plus récent) dans '$key' : $subKey -> $subValue");
                  existingValue[subKey] = subValue;
                }
              });
              box.put(dataKey, existingValue);
            } else {
              debugPrint(
                  "⚠️ Valeur ignorée (format non pris en charge) : $dataKey -> $value");
            }
          }
        });

        // debugPrint("📊 Contenu final de Hive pour '$key' : ${box.toMap()}");
      } else {
        debugPrint("⚠️ Aucun nouveau contenu pour '$key', pas d'ajout.");
      }
    }

    await storeWithoutDuplicates(balanceHistoryBox, 'balanceHistory');
    await storeWithoutDuplicates(walletValueArchiveBox, 'walletValueArchive');
    await storeWithoutDuplicates(customInitPricesBox, 'customInitPrices');
    await storeWithoutDuplicates(customRoiBox, 'roiValueArchive');
    await storeWithoutDuplicates(customApyBox, 'apyValueArchive');
    await storeWithoutDuplicates(customYamBox, 'customYam');

    debugPrint("✅ Stockage terminé.");
  }

  /// Télécharger et lire les données de Google Drive
  /// Téléchargement et restauration des données depuis Google Drive
  /// Télécharger un fichier depuis Google Drive et retourner les données sous forme de Map
  Future<Map<String, dynamic>?> downloadBackupFromGoogleDrive() async {
    if (_driveApi == null) {
      debugPrint("❌ Google Drive API non initialisée.");
      return null;
    }

    try {
      debugPrint("🔽 Recherche du fichier sur Google Drive...");
      final drive.FileList fileList = await _driveApi!.files.list(
        q: "name = 'realToken_Backup.zip' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("❌ Aucun fichier trouvé sur Google Drive !");
        return null;
      }

      final String fileId = fileList.files!.first.id!;
      debugPrint("📂 Fichier trouvé: ID = $fileId, téléchargement en cours...");

      final drive.Media fileData = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final Directory directory = await getApplicationDocumentsDirectory();
      final File localFile = File("${directory.path}/realToken_Backup.zip");

      final List<int> dataStore = [];
      await for (var data in fileData.stream) {
        dataStore.addAll(data);
      }

      await localFile.writeAsBytes(dataStore);
      debugPrint("✅ Téléchargement terminé, fichier sauvegardé localement");

      // Extraire et nettoyer les données du fichier ZIP
      return await _extractAndCleanBackupData(localFile.path);
    } catch (e) {
      debugPrint("❌ Erreur lors du téléchargement depuis Google Drive : $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _extractAndCleanBackupData(
      String zipFilePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final File zipFile = File(zipFilePath);

    if (!await zipFile.exists()) {
      debugPrint("❌ Le fichier ZIP n'existe pas !");
      return null;
    }

    final List<int> bytes = zipFile.readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    Map<String, dynamic> extractedData = {};

    for (var file in archive) {
      final String fileName = file.name;
      final String jsonContent = utf8.decode(file.content as List<int>);

      debugPrint("📂 Fichier extrait : $fileName");

      // Nettoyer les chaînes JSON corrompues
      dynamic cleanedData = cleanJsonString(jsonContent);

      if (cleanedData is Map || cleanedData is List) {
        extractedData[fileName] = cleanedData;
      } else {
        debugPrint("⚠️ Le fichier $fileName ne contient pas de JSON valide.");
      }
    }

    debugPrint(
        "✅ Extraction et nettoyage terminés, données récupérées "); //: $extractedData
    return extractedData;
  }

  /// Extraire les données depuis un fichier ZIP et les retourner sous forme de Map
  Future<Map<String, dynamic>?> _extractBackupData(String zipFilePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final File zipFile = File(zipFilePath);

    if (!await zipFile.exists()) {
      debugPrint("❌ Le fichier ZIP n'existe pas !");
      return null;
    }

    final List<int> bytes = zipFile.readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    Map<String, dynamic> extractedData = {};

    for (var file in archive) {
      final String fileName = file.name;
      final String jsonContent = utf8.decode(file.content as List<int>);

      debugPrint("📂 Fichier extrait : $fileName");

      // Nettoyer les chaînes JSON corrompues
      dynamic cleanedData = cleanJsonString(jsonContent);

      if (cleanedData is Map || cleanedData is List) {
        extractedData[fileName] = cleanedData;
      } else {
        debugPrint("⚠️ Le fichier $fileName ne contient pas de JSON valide.");
      }
    }

    debugPrint("✅ Extraction terminée, données récupérées : $extractedData");
    return extractedData;
  }

  dynamic cleanJsonString(dynamic value) {
    if (value is String) {
      try {
        // Décoder uniquement si c'est une chaîne JSON valide
        if (value.startsWith("{") || value.startsWith("[")) {
          return jsonDecode(value);
        }
      } catch (e) {
        debugPrint("❌ Erreur lors du nettoyage de la chaîne JSON : $e");
      }
    }
    return value;
  }

  /// Restaurer les données depuis un fichier ZIP
  Future<void> _restoreLocalBackup(String zipFilePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final File zipFile = File(zipFilePath);

    if (!await zipFile.exists()) {
      debugPrint("❌ Le fichier ZIP n'existe pas !");
      return;
    }

    try {
      debugPrint("📦 Extraction du fichier ZIP...");
      final List<int> bytes = zipFile.readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      for (var file in archive) {
        String jsonContent = utf8.decode(file.content as List<int>);

        if (file.name == 'balanceHistoryBackup.json') {
          debugPrint("📥 Chargement des données de balanceHistory...");
          var box = await Hive.openBox('balanceHistory');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'walletValueArchiveBackup.json') {
          debugPrint("📥 Chargement des données de walletValueArchive...");
          var box = await Hive.openBox('walletValueArchive');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'customInitPricesBackup.json') {
          debugPrint("📥 Chargement des données de customInitPrices...");
          var box = await Hive.openBox('customInitPrices');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'customRoiBackup.json') {
          debugPrint("📥 Chargement des données de roiValueArchive...");
          var box = await Hive.openBox('roiValueArchive');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'customApyBackup.json') {
          debugPrint("📥 Chargement des données de apyValueArchive...");
          var box = await Hive.openBox('apyValueArchive');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'customYamBackup.json') {
          debugPrint("📥 Chargement des données de YamMarket...");
          var box = await Hive.openBox('YamMarket');
          await box.putAll(jsonDecode(jsonContent));
        } else if (file.name == 'preferencesBackup.json') {
          debugPrint("📥 Chargement des préférences depuis Google Drive...");
          Map<String, dynamic> drivePreferences = jsonDecode(jsonContent);

          if (drivePreferences.isNotEmpty) {
            _storeMergedPreferences(drivePreferences);
          } else {
            debugPrint(
                "⚠️ Google Drive ne contient pas de préférences, on garde celles en local.");
          }
        }
      }

      debugPrint("✅ Restauration terminée.");
    } catch (e) {
      debugPrint("❌ Erreur lors de la restauration : $e");
    }
  }

  /// Charger les données locales depuis Hive et SharedPreferences
  Future<Map<String, dynamic>> _loadLocalData() async {
    Map<String, dynamic> localData = {};

    var balanceHistoryBox = await Hive.openBox('balanceHistory');
    var walletValueArchiveBox = await Hive.openBox('walletValueArchive');

    localData['balanceHistory'] = balanceHistoryBox.toMap();
    localData['walletValueArchive'] = walletValueArchiveBox.toMap();

    final prefs = await SharedPreferences.getInstance();
    localData['preferences'] = {
      'ethAddresses': prefs.getStringList('evmAddresses') ?? [],
      'selectedCurrency': prefs.getString('selectedCurrency'),
      'convertToSquareMeters': prefs.getBool('convertToSquareMeters') ?? false,
    };

    return localData;
  }

  dynamic sanitizeValue(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, sanitizeValue(val)));
    } else if (value is List) {
      return value.map(sanitizeValue).toList();
    } else if (value is num) {
      // Convertir en double et gérer les cas spéciaux
      double doubleValue = value.toDouble();
      if (doubleValue.isNaN || doubleValue.isInfinite) {
        return 0.0;
      }
      return doubleValue;
    }
    return value;
  }

  Future<void> _storeMergedPreferences(
      Map<String, dynamic> mergedPreferences) async {
    debugPrint(
        "📦 Sauvegarde des préférences fusionnées dans SharedPreferences...");

    final prefs = await SharedPreferences.getInstance();

    // 🔹 Stocker les adresses ETH
    await prefs.setStringList('evmAddresses',
        List<String>.from(mergedPreferences['ethAddresses'] ?? []));

    // 🔹 Stocker userIdToAddresses (sans double sérialisation)
    if (mergedPreferences['userIdToAddresses'] != null) {
      if (mergedPreferences['userIdToAddresses'] is String) {
        // Vérifier si la chaîne est déjà un JSON
        try {
          jsonDecode(mergedPreferences[
              'userIdToAddresses']); // Test si c'est déjà un JSON
          await prefs.setString(
              'userIdToAddresses', mergedPreferences['userIdToAddresses']);
        } catch (e) {
          // Sinon, encoder une seule fois
          await prefs.setString('userIdToAddresses',
              jsonEncode(mergedPreferences['userIdToAddresses']));
        }
      } else {
        await prefs.setString('userIdToAddresses',
            jsonEncode(mergedPreferences['userIdToAddresses']));
      }
    }

    // 🔹 Stocker la devise sélectionnée
    if (mergedPreferences['selectedCurrency'] != null) {
      await prefs.setString(
          'selectedCurrency', mergedPreferences['selectedCurrency']);
    }

    // 🔹 Stocker la préférence de conversion en mètres carrés
    await prefs.setBool('convertToSquareMeters',
        mergedPreferences['convertToSquareMeters'] ?? false);

    debugPrint("✅ Sauvegarde des préférences terminée !");
  }

  dynamic decodeJsonIfNeeded(dynamic data, String key) {
    if (data is String) {
      try {
        debugPrint("🔍 Tentative de décodage JSON pour '$key'...");
        return jsonDecode(data); // Décodage de la chaîne en JSON
      } catch (e) {
        debugPrint("❌ Erreur lors du décodage de '$key' : $e");
        return {}; // Retourner un objet vide pour éviter les erreurs
      }
    }
    return data; // Retourne tel quel si ce n'est pas une String JSON
  }

  /// Fusionner les données locales et celles de Google Drive
  Map<String, dynamic> _mergeData(
      Map<String, dynamic> localData, Map<String, dynamic>? driveData) {
    if (driveData == null) {
      debugPrint(
          "⚠️ Aucune donnée trouvée sur Google Drive, utilisation des données locales.");
      return localData;
    }

    debugPrint("🔄 Fusion des données locales et Drive...");

    Map<String, dynamic> mergedData = Map<String, dynamic>.from(localData);

    void mergeBox(String boxKey, String backupKey) {
      if (!driveData.containsKey(backupKey) || driveData[backupKey] == null) {
        debugPrint(
            "⚠️ Clé '$backupKey' absente ou vide dans Google Drive, rien à fusionner.");
        return;
      }

      mergedData.putIfAbsent(boxKey, () => <String, dynamic>{});
      var driveBoxData = driveData[backupKey];

      if (driveBoxData is! Map) {
        debugPrint(
            "⚠️ Mauvais format pour '$backupKey', conversion en Map vide.");
        driveBoxData = <String, dynamic>{};
      }

      Map<String, dynamic> driveBoxMap =
          Map<String, dynamic>.from(driveBoxData);

      driveBoxMap.forEach((key, driveList) {
        if (key.toString().trim().isEmpty) {
          debugPrint("⚠️ Ignoré : Clé vide dans '$backupKey'.");
          return;
        }

        // Correction si driveList est un Map au lieu d'une liste
        if (driveList is Map) {
          debugPrint(
              "⚠️ Correction : '$key' est une Map, on la transforme en Liste.");
          driveList = driveList.entries
              .map((e) => {'key': e.key, 'value': e.value})
              .toList();
        } else if (driveList is! List) {
          debugPrint(
              "⚠️ '$key' a un type inattendu (${driveList.runtimeType}), conversion en liste vide.");
          driveList = [];
        }

        // Initialiser la clé s'il n'y a rien en local
        mergedData[boxKey].putIfAbsent(key, () => []);

        // Vérification si mergedData[boxKey][key] est bien une liste
        if (mergedData[boxKey][key] is! List) {
          debugPrint(
              "⚠️ Correction : '$key' contient un mauvais type dans Hive, conversion en liste vide.");
          mergedData[boxKey][key] = [];
        }

        List<dynamic> localList = List<dynamic>.from(mergedData[boxKey][key]);

        Set<String> existingTimestamps = localList
            .where((e) => e is Map && e.containsKey('timestamp'))
            .map((e) => e['timestamp'].toString())
            .toSet();

        if (driveList is List) {
          for (var entry in driveList) {
            if (entry is Map && entry.containsKey('timestamp')) {
              String timestamp = entry['timestamp'].toString();
              if (!existingTimestamps.contains(timestamp)) {
                localList.add(entry);
              }
            }
          }
        }

        mergedData[boxKey][key] = localList;
      });
    }

    // Appliquer la fusion pour chaque catégorie
    mergeBox('balanceHistory', 'balanceHistoryBackup.json');
    mergeBox('walletValueArchive', 'walletValueArchiveBackup.json');
    mergeBox('customInitPrices', 'customInitPricesBackup.json');
    mergeBox('roiValueArchive', 'customRoiBackup.json');
    mergeBox('apyValueArchive', 'customApyBackup.json');
    mergeBox('YamMarket', 'customYamBackup.json');

    // 🔹 Fusionner les préférences
    if (driveData.containsKey('preferencesBackup.json')) {
      debugPrint("🔹 Fusion des préférences...");
      Map<String, dynamic> drivePreferences =
          Map<String, dynamic>.from(driveData['preferencesBackup.json'] ?? {});
      Map<String, dynamic> localPreferences =
          Map<String, dynamic>.from(localData['preferences'] ?? {});

      Set<String> mergedEthAddresses = {
        ...?localPreferences['ethAddresses'],
        ...?drivePreferences['ethAddresses']
      };

      Map<String, dynamic> mergedPreferences = {
        'ethAddresses': mergedEthAddresses.toList(),
        'userIdToAddresses': localPreferences['userIdToAddresses'] ??
            drivePreferences['userIdToAddresses'],
        'selectedCurrency': localPreferences['selectedCurrency'] ??
            drivePreferences['selectedCurrency'],
        'convertToSquareMeters': localPreferences['convertToSquareMeters'] ??
            drivePreferences['convertToSquareMeters'] ??
            false,
      };

      mergedData['preferences'] = mergedPreferences;

      _storeMergedPreferences(mergedPreferences);
    }

    debugPrint("✅ Fusion terminée.");
    return mergedData;
  }

  /// Sauvegarder les données fusionnées sur Google Drive
  /// Sauvegarde et envoi sur Google Drive
  Future<void> backupToGoogleDrive() async {
    if (_driveApi == null) {
      debugPrint("❌ Google Drive API non initialisée.");
      return;
    }

    try {
      // Ouvrir les boîtes Hive
      var balanceHistoryBox = await Hive.openBox('balanceHistory');
      var walletValueArchiveBox = await Hive.openBox('walletValueArchive');
      var customInitPricesBox = await Hive.openBox('customInitPrices');
      var customRoiBox = await Hive.openBox('roiValueArchive');
      var customApyBox = await Hive.openBox('apyValueArchive');
      var customYamBox = await Hive.openBox('YamMarket');

      // Convertir les données en JSON
      Map<String, dynamic> jsonData = {
        'balanceHistoryBackup.json': balanceHistoryBox.toMap(),
        'walletValueArchiveBackup.json': walletValueArchiveBox.toMap(),
        'customInitPricesBackup.json': customInitPricesBox.toMap(),
        'customRoiBackup.json': customRoiBox.toMap(),
        'customApyBackup.json': customApyBox.toMap(),
        'customYamBackup.json': customYamBox.toMap(),
      };

      // Obtenir les préférences stockées dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      jsonData['preferencesBackup.json'] = {
        'ethAddresses': prefs.getStringList('evmAddresses') ?? [],
        'userIdToAddresses': jsonDecode(prefs.getString('userIdToAddresses') ??
            '{}'), // Décoder si nécessaire
        'selectedCurrency': prefs.getString('selectedCurrency'),
        'convertToSquareMeters':
            prefs.getBool('convertToSquareMeters') ?? false,
      };

      // Nettoyer les données avant de créer le fichier ZIP
      for (var entry in jsonData.entries) {
        jsonData[entry.key] = cleanJsonString(entry.value);
      }

      // Créer le fichier ZIP
      final archive = Archive();
      for (var entry in jsonData.entries) {
        String jsonContent = jsonEncode(entry.value);
        archive.addFile(ArchiveFile(
            entry.key, jsonContent.length, utf8.encode(jsonContent)));
      }

      // Sauvegarder le fichier ZIP
      final directory = await getApplicationDocumentsDirectory();
      final zipFilePath = path.join(directory.path, 'realToken_Backup.zip');
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(ZipEncoder().encode(archive));

      // Envoyer le fichier ZIP sur Google Drive
      final drive.File fileToUpload = drive.File();
      fileToUpload.name = 'realToken_Backup.zip';
      fileToUpload.parents = ['appDataFolder'];

      final media = drive.Media(zipFile.openRead(), await zipFile.length());
      await _driveApi!.files.create(fileToUpload, uploadMedia: media);

      debugPrint("✅ Fichier sauvegardé sur Google Drive.");
    } catch (e) {
      debugPrint("❌ Erreur lors de la sauvegarde sur Google Drive : $e");
    }
  }

  Future<void> importFromGoogleDrive() async {
    if (_driveApi == null) {
      debugPrint("❌ Google Drive API non initialisée.");
      return;
    }

    try {
      debugPrint("🔽 Recherche du fichier sur Google Drive...");
      final drive.FileList fileList =
          await _driveApi!.files.list(spaces: 'appDataFolder');

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("❌ Aucun fichier trouvé sur Google Drive !");
        return;
      }

      final String fileId = fileList.files!.first.id!;
      debugPrint("📂 Fichier trouvé: ID = $fileId, téléchargement en cours...");

      final drive.Media fileData = await _driveApi!.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final directory = await getApplicationDocumentsDirectory();
      final File localFile = File("${directory.path}/realToken_Backup.zip");

      final List<int> dataStore = [];
      await for (var data in fileData.stream) {
        dataStore.addAll(data);
      }

      await localFile.writeAsBytes(dataStore);
      debugPrint(
          "✅ Téléchargement terminé, fichier sauvegardé localement : ${localFile.path}");

      debugPrint("📦 Extraction et fusion des données...");
      await _restoreLocalBackup(localFile.path);
    } catch (e) {
      debugPrint("❌ Erreur lors du téléchargement depuis Google Drive : $e");
    }
  }
}
