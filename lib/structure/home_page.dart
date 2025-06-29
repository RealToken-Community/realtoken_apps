import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/modals/agenda.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/utils/performance_utils.dart';
import 'package:realtoken_asset_tracker/utils/cache_constants.dart';
import 'dart:math';

import 'bottom_bar.dart';
import 'drawer.dart';
import 'package:realtoken_asset_tracker/pages/dashboard/dashboard_page.dart';
import 'package:realtoken_asset_tracker/pages/portfolio/portfolio_page.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/stats_selector_page.dart';
import 'package:realtoken_asset_tracker/pages/maps_page.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/donation_card_widget.dart';
import 'package:realtoken_asset_tracker/components/donation_widgets.dart';
import 'package:realtoken_asset_tracker/components/wallet_popup_widget.dart';
import 'package:realtoken_asset_tracker/services/api_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final GlobalKey _walletIconKey = GlobalKey(); // Clé pour obtenir la position de l'icône

  List<Map<String, dynamic>> portfolio = [];

  bool _donationPopupShown = false;

  @override
  void initState() {
    super.initState();
    final random = Random();

    // Ajout de la condition de probabilité
    if (random.nextInt(3) == 0) { // Génère 0, 1, ou 2. La condition est vraie pour 0 (1/3 des cas)
      final delaySeconds = 5 + random.nextInt(26); // 5 à 30 inclus
      Future.delayed(Duration(seconds: delaySeconds), _showDonationPopupIfNeeded);
    }
  }

  void _showDonationPopupIfNeeded() async {
    if (_donationPopupShown) return;
    if (!mounted) return;
    
    // Throttle pour éviter les appels répétitifs
    if (!PerformanceUtils.throttle('donation_popup_check', const Duration(seconds: 30))) {
      return;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.shouldShowDonationPopup) return;
    _donationPopupShown = true;
    
    // Mettre à jour le timestamp de la dernière popup affichée
    await appState.updateLastDonationPopupTimestamp();
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DonationPopupAsyncLoader();
      },
    );
  }

  double _getContainerHeight(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return bottomPadding > 0 ? 75 : 60;
  }

  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    PortfolioPage(),
    StatsSelectorPage(),
    MapsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAgendaModal(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final portfolio = dataManager.portfolio;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => AgendaCalendar(portfolio: portfolio),
    );
  }

  void _showWalletPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WalletPopupWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataManager = Provider.of<DataManager>(context);
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);

    final double walletTotal = dataManager.gnosisUsdcBalance + dataManager.gnosisXdaiBalance;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _pages.elementAt(_selectedIndex),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: UIUtils.getAppBarHeight(context),
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0.5,
                    actions: [
                      // Icône portefeuille avec un Popup Menu
                      IconButton(
                        key: _walletIconKey, // Associe la clé pour obtenir la position
                        icon: Icon(
                          Icons.account_balance_wallet,
                          size: 21 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => _showWalletPopup(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: InkWell(
                          onTap: () => _showWalletPopup(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Center(
                              child: Text(
                                currencyUtils.getFormattedAmount(
                                  currencyUtils.convert(walletTotal),
                                  currencyUtils.currencySymbol,
                                  appState.showAmounts, // Utilisation de showAmounts
                                ),
                                style: TextStyle(
                                  fontSize: 16 + appState.getTextSizeOffset(),
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          size: 19 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => _openAgendaModal(context),
                      ),
                      IconButton(
                        icon: Icon(
                          appState.showAmounts ? Icons.visibility : Icons.visibility_off,
                          size: 22 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => appState.toggleShowAmounts(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: _getContainerHeight(context),
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                  child: SafeArea(
                    top: false,
                    child: CustomBottomNavigationBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onThemeChanged: (value) {
          appState.updateTheme(value);
        },
      ),
    );
  }
}

// Widget interne pour gérer le chargement asynchrone du montant du wallet
class _DonationPopupAsyncLoader extends StatefulWidget {
  @override
  State<_DonationPopupAsyncLoader> createState() => _DonationPopupAsyncLoaderState();
}

class _DonationPopupAsyncLoaderState extends State<_DonationPopupAsyncLoader> {
  String? montant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletAmount();
  }

  Future<void> _fetchWalletAmount() async {
    const cacheKey = 'donation_wallet_amount';
    
    // Vérifier le cache d'abord avec PerformanceUtils
    final cachedAmount = PerformanceUtils.getFromCache<String>(cacheKey);
    if (cachedAmount != null) {
      setState(() {
        montant = cachedAmount;
        isLoading = false;
      });
      return;
    }

    const walletAddress = DonationWidgets.donationAddress;
    try {
      // Appel direct à ApiService.fetchRmmBalances pour une seule adresse
      final balances = await ApiService.fetchRmmBalancesForAddress(walletAddress);
      if (balances.isNotEmpty) {
        final wallet = balances.first;
        debugPrint('🎁 Donation wallet balance: ${wallet.toString()}');
        
        final double gnosisUsdc = wallet['gnosisUsdcBalance'] ?? 0.0;
        final double gnosisXdai = wallet['gnosisXdaiBalance'] ?? 0.0;
        final double usdcDeposit = wallet['usdcDepositBalance'] ?? 0.0;
        final double xdaiDeposit = wallet['xdaiDepositBalance'] ?? 0.0;
        final double total = gnosisUsdc + gnosisXdai + usdcDeposit + xdaiDeposit;
        
        final String formattedAmount = total.toStringAsFixed(2);
        
        // Mettre à jour le cache avec PerformanceUtils
        PerformanceUtils.setCache(cacheKey, formattedAmount, CacheConstants.donationAmountCache);
        
        if (mounted) {
          setState(() {
            montant = formattedAmount;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            montant = '0.00';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération montant donation: $e');
      if (mounted) {
        setState(() {
          montant = 'Erreur';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: DonationCardWidget(
                  montantWallet: montant,
                  isLoading: isLoading,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded, 
                    size: 28,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Fermer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
