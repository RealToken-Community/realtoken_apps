import 'package:realtoken_asset_tracker/pages/changelog_page.dart';
import 'package:realtoken_asset_tracker/pages/links_page.dart';
import 'package:realtoken_asset_tracker/pages/propertiesForSale/propertiesForSell_select.dart';
import 'package:realtoken_asset_tracker/pages/support_page.dart';
import 'package:realtoken_asset_tracker/settings/service_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/settings/settings_page.dart';
import 'package:realtoken_asset_tracker/pages/realtokens_page.dart';
import 'package:realtoken_asset_tracker/about.dart';
import 'package:realtoken_asset_tracker/pages/updates_page.dart';
import 'package:realtoken_asset_tracker/pages/realt_page.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/settings/manage_evm_addresses_page.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/drawer_menu_factory.dart';
import 'package:realtoken_asset_tracker/utils/performance_utils.dart';
import 'package:realtoken_asset_tracker/utils/cache_constants.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:convert';

import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/pages/tools_page.dart';

class CustomDrawer extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const CustomDrawer({required this.onThemeChanged, super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String? latestVersion;
  String? currentVersion;

  @override
  void initState() {
    super.initState();
    _fetchVersions();
  }

  Future<void> _fetchVersions() async {
    // Throttle pour éviter les appels répétitifs
    if (!PerformanceUtils.throttle('drawer_version_check', const Duration(minutes: 30))) {
      // Charger depuis le cache si disponible
      final cachedCurrent = PerformanceUtils.getFromCache<String>('current_version');
      final cachedLatest = PerformanceUtils.getFromCache<String>('latest_version');
      if (cachedCurrent != null && cachedLatest != null) {
        setState(() {
          currentVersion = cachedCurrent;
          latestVersion = cachedLatest;
        });
      }
      return;
    }

    try {
      // Récupérer la version actuelle de l'application
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVer = packageInfo.version;
      
      // Mettre en cache et setState pour la version actuelle
      PerformanceUtils.setCache('current_version', currentVer, CacheConstants.versionCache);
      setState(() {
        currentVersion = currentVer;
      });

      // Vérifier le cache pour la version latest d'abord
      final cachedLatest = PerformanceUtils.getFromCache<String>('latest_version');
      if (cachedLatest != null) {
        setState(() {
          latestVersion = cachedLatest;
        });
        return; // Pas besoin de refetch si on a déjà le cache
      }

      // Récupérer la dernière version depuis GitHub seulement si pas en cache
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/RealToken-Community/realtoken_apps/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final tagName = releaseData['tag_name'];
        final latestVer = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        // Mettre en cache et setState
        PerformanceUtils.setCache('latest_version', latestVer, CacheConstants.versionCache);
        if (mounted) {
          setState(() {
            latestVersion = latestVer;
          });
        }
        debugPrint('✅ Version latest mise à jour: $latestVer');
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération versions: $e');
    }
  }

  Future<void> _requestReview(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;
    bool isReviewRequested = false;

    try {
      // Vérifie si l'API de notation est disponible
      final isAvailable = await inAppReview.isAvailable();
      if (isAvailable && !Platform.isAndroid) {
        // L'API fonctionne en mode release
        await inAppReview.requestReview();
        isReviewRequested = true;
      }
    } catch (e) {
      // Gère toute exception qui peut survenir
      isReviewRequested = false;
    }

    // Si la demande de notation n'est pas disponible ou échoue
    if (!isReviewRequested) {
      _showReviewNotAvailablePopup(context);
    }
  }

  void _showReviewNotAvailablePopup(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            S.of(context).thankYouForFeedback,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            S.of(context).reviewRequestUnavailable,
            style: TextStyle(fontSize: 14 + Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).noThanks),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await InAppReview.instance.openStoreListing();
              },
              isDefaultAction: true,
              child: Text(S.of(context).yesWithPleasure),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Drawer(
          child: ClipRRect(
            child: Column(
              children: [
                // En-tête avec sa propre SafeArea
                Material(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          UrlUtils.launchURL('https://realt.co/marketplace/');
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Image.asset(
                                    'assets/logo_community.png',
                                    width: 36,
                                    height: 36,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RealToken Asset Tracker',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18 + appState.getTextSizeOffset(),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        S.of(context).appDescription,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14 + appState.getTextSizeOffset(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                           ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu dans un Expanded + ScrollView
                Expanded(
                  child: Stack(
                    children: [
                      // Décaler le contenu vers le haut pour créer un chevauchement
                      Positioned(
                        top: -16,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground.resolveFrom(context),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),

                                  // Section Comptes
                                  DrawerMenuFactory.buildMenuSection(
                                    context: context,
                                    title: 'Comptes',
                                    appState: appState,
                                    items: [
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.person_crop_circle_fill,
                                        title: S.of(context).manageEvmAddresses,
                                        page: const ManageEvmAddressesPage(),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Section Fonctionnalités
                                  DrawerMenuFactory.buildMenuSection(
                                    context: context,
                                    title: 'Fonctionnalités',
                                    appState: appState,
                                    items: [
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.house_fill,
                                        title: S.of(context).propertiesForSale,
                                        page: const PropertiesForSalePage(),
                                        iconColor: Colors.teal,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.list_bullet,
                                        title: S.of(context).realTokensList,
                                        page: const RealTokensPage(),
                                        iconColor: Colors.blue,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.arrow_clockwise_circle_fill,
                                        title: S.of(context).recentChanges,
                                        page: const UpdatesPage(),
                                        iconColor: Colors.orange,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.graph_square_fill,
                                        title: 'RealT stats',
                                        page: const RealtPage(),
                                        iconColor: Colors.purple,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.link,
                                        title: S.of(context).links,
                                        page: const LinksPage(),
                                        iconColor: Colors.indigo,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.wrench_fill,
                                        title: S.of(context).toolsTitle,
                                        page: const ToolsPage(),
                                        iconColor: Colors.deepPurple,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Section Support & Paramètres
                                  DrawerMenuFactory.buildMenuSection(
                                    context: context,
                                    title: 'Support & Paramètres',
                                    appState: appState,
                                    items: [
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.gauge,
                                        title: S.of(context).serviceStatus,
                                        page: const ServiceStatusPage(),
                                        iconColor: Colors.red,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.chat_bubble_text_fill,
                                        title: S.of(context).support,
                                        page: const SupportPage(),
                                        iconColor: Colors.green,
                                      ),
                                      DrawerMenuFactory.createMenuItem(
                                        icon: CupertinoIcons.star_fill,
                                        title: S.of(context).rateApp,
                                        iconColor: CupertinoColors.systemYellow,
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await _requestReview(context);
                                        },
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.settings,
                                        title: S.of(context).settings,
                                        page: const SettingsPage(),
                                        iconColor: Colors.grey,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Section À propos
                                  DrawerMenuFactory.buildMenuSection(
                                    context: context,
                                    title: S.of(context).about,
                                    appState: appState,
                                    items: [
                                      DrawerMenuFactory.createModalItem(
                                        context: context,
                                        icon: CupertinoIcons.arrow_up_doc_fill,
                                        title: S.of(context).changelog,
                                        modal: const ChangelogPage(),
                                        iconColor: Colors.amber,
                                        modalHeight: 0.8,
                                      ),
                                      DrawerMenuFactory.createPageNavItem(
                                        context: context,
                                        icon: CupertinoIcons.info_circle_fill,
                                        title: S.of(context).about,
                                        page: const AboutPage(),
                                        iconColor: Colors.blue,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
