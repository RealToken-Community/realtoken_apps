import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/rmm/rmm_stats.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/wallet/wallet_stats.dart';
import 'package:realtoken_asset_tracker/pages/Statistics/rents/rents_stats.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class StatsSelectorPage extends StatefulWidget {
  const StatsSelectorPage({super.key});

  @override
  StatsSelectorPageState createState() => StatsSelectorPageState();
}

class StatsSelectorPageState extends State<StatsSelectorPage>
    with TickerProviderStateMixin {
  String _selectedStats = 'WalletStats';
  String _previousSelectedStats = 'WalletStats';

  // Couleurs spécifiques pour chaque sélecteur
  final Map<String, Color> _statsColors = {
    'WalletStats': Colors.blue,
    'RentsStats': Colors.green,
    'RMMStats': Colors.orange,
  };

  // Contrôleurs d'animation pour chaque sélecteur
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};

  // Contrôleurs pour l'animation du sélecteur
  late AnimationController _selectorAnimationController;
  late Animation<double> _selectorAnimation;
  bool _isSelectorVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSelectorAnimation();
  }

  void _initAnimations() {
    // Initialiser les contrôleurs d'animation pour chaque sélecteur
    for (String key in ['WalletStats', 'RentsStats', 'RMMStats']) {
      _animationControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
        value: key == _selectedStats ? 1.0 : 0.0,
      );

      _scaleAnimations[key] = Tween<double>(
        begin: 0.95, // Taille réduite
        end: 1.05, // Taille augmentée
      ).animate(
        CurvedAnimation(
          parent: _animationControllers[key]!,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  void _initSelectorAnimation() {
    _selectorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _selectorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectorAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs d'animation
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _selectorAnimationController.dispose();
    super.dispose();
  }

  void _updateAnimations(String newValue) {
    _previousSelectedStats = _selectedStats;
    _selectedStats = newValue;

    // Animer la réduction du sélecteur qui devient inactif
    if (_animationControllers[_previousSelectedStats] != null) {
      _animationControllers[_previousSelectedStats]!.reverse();
    }

    // Animer l'agrandissement du sélecteur qui devient actif
    if (_animationControllers[newValue] != null) {
      _animationControllers[newValue]!.forward();
    }
  }

  void _handleScroll(double offset) {
    const double threshold = 50.0; // Seuil de déclenchement

    if (offset > _lastScrollOffset + threshold && _isSelectorVisible) {
      // Scroll vers le bas - masquer le sélecteur
      setState(() {
        _isSelectorVisible = false;
      });
      _selectorAnimationController.reverse();
    } else if (offset < _lastScrollOffset - threshold && !_isSelectorVisible) {
      // Scroll vers le haut - afficher le sélecteur
      setState(() {
        _isSelectorVisible = true;
      });
      _selectorAnimationController.forward();
    }

    _lastScrollOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewPadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: false,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                AnimatedBuilder(
                  animation: _selectorAnimation,
                  builder: (context, child) {
                    return SliverAppBar(
                      floating: true,
                      snap: true,
                      expandedHeight:
                          (UIUtils.getSliverAppBarHeight(context) + 10) *
                              _selectorAnimation.value,
                      collapsedHeight: _selectorAnimation.value == 0 ? 0 : null,
                      toolbarHeight:
                          _selectorAnimation.value == 0 ? 0 : kToolbarHeight,
                      flexibleSpace: _selectorAnimation.value > 0
                          ? FlexibleSpaceBar(
                              background: Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Opacity(
                                      opacity: _selectorAnimation.value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4.0),
                                        child: _buildStatsSelector(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ];
            },
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _getSelectedStatsPageWithScrollListener(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSelector() {
    return Row(
      children: [
        _buildStatsChip(
            'WalletStats', S.of(context).wallet, Icons.account_balance_wallet),
        _buildStatsChip('RentsStats', S.of(context).rents, Icons.attach_money),
        _buildStatsChip('RMMStats', S.of(context).rmm, Icons.money),
      ],
    );
  }

  Widget _buildStatsChip(String value, String label, IconData icon) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedStats == value;
    Color chipColor = _statsColors[value] ?? Theme.of(context).primaryColor;

    double textSizeOffset = appState.getTextSizeOffset();
    TextStyle textStyle = TextStyle(
      fontSize: (isSelected ? 18 : 16) + textSizeOffset,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );

    double minWidth = isSelected
        ? _calculateTextWidth(context, label, textStyle)
        : 56; // Largeur minimale pour les icônes non sélectionnées

    // Utiliser l'animation d'échelle si disponible
    Widget animatedContent = _scaleAnimations.containsKey(value)
        ? AnimatedBuilder(
            animation: _scaleAnimations[value]!,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected ? _scaleAnimations[value]!.value : 1.0,
                child: child,
              );
            },
            child: isSelected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        style: textStyle.copyWith(color: Colors.white),
                        child: Text(label),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      icon,
                      color: Colors.grey, // Icônes inactives en gris
                      size: 20,
                    ),
                  ),
          )
        : isSelected
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    style: textStyle.copyWith(color: Colors.white),
                    child: Text(label),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  icon,
                  color: Colors.grey, // Icônes inactives en gris
                  size: 20,
                ),
              );

    return isSelected
        ? Expanded(
            // La chip sélectionnée prend toute la place restante
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _updateAnimations(value);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: animatedContent,
              ),
            ),
          )
        : ConstrainedBox(
            // Les chips non sélectionnées ont une largeur minimale
            constraints: BoxConstraints(minWidth: minWidth),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _updateAnimations(value);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: animatedContent,
              ),
            ),
          );
  }

  double _calculateTextWidth(
      BuildContext context, String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width +
        24; // Ajout de padding pour éviter que le texte touche les bords
  }

  Widget _getSelectedStatsPage() {
    switch (_selectedStats) {
      case 'WalletStats':
        return const WalletStats(key: ValueKey('WalletStats'));
      case 'RentsStats':
        return const RentsStats(key: ValueKey('RentsStats'));
      case 'RMMStats':
        return const RmmStats(key: ValueKey('RMMStats'));
      default:
        return const WalletStats(key: ValueKey('WalletStats'));
    }
  }

  Widget _getSelectedStatsPageWithScrollListener() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScroll(notification.metrics.pixels);
        }
        return false;
      },
      child: _getSelectedStatsPage(),
    );
  }
}
