import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/pages/propertiesForSale/PropertiesForSaleRealt.dart';
import 'package:realtoken_asset_tracker/pages/propertiesForSale/PropertiesForSaleSecondary.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';

class PropertiesForSalePage extends StatefulWidget {
  const PropertiesForSalePage({super.key});

  @override
  _PropertiesForSalePageState createState() => _PropertiesForSalePageState();
}

class _PropertiesForSalePageState extends State<PropertiesForSalePage> {
  String _selectedPage = 'RealT'; // Valeur par défaut

  // Couleurs spécifiques pour chaque sélecteur
  final Map<String, Color> _pageColors = {
    'RealT': Colors.blue,
    'Secondary': Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(S.of(context).properties_for_sale),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: UIUtils.getSliverAppBarHeight(context) - 25,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: _buildPageSelector(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
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
          child: _selectedPage == 'RealT'
              ? const PropertiesForSaleRealt(key: ValueKey('RealT'))
              : const PropertiesForSaleSecondary(key: ValueKey('Secondary')),
        ),
      ),
    );
  }

  Widget _buildPageSelector() {
    return Row(
      children: [
        _buildPageChip('RealT', S.of(context).realt, Icons.home),
        _buildPageChip('Secondary', S.of(context).secondary, Icons.swap_horiz),
      ],
    );
  }

  double _calculateTextWidth(
      BuildContext context, String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width + 24; // Ajout de padding pour l'esthétique
  }

  Widget _buildPageChip(String value, String label, IconData icon) {
    final appState = Provider.of<AppState>(context);
    bool isSelected = _selectedPage == value;
    Color chipColor = _pageColors[value] ?? Theme.of(context).primaryColor;

    double textSizeOffset = appState.getTextSizeOffset();
    TextStyle textStyle = TextStyle(
      fontSize: (isSelected ? 18 : 16) + textSizeOffset,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );

    double minWidth = isSelected
        ? _calculateTextWidth(context, label, textStyle)
        : 56; // Largeur minimale pour les icônes non sélectionnées

    return isSelected
        ? Expanded(
            // La Chip sélectionnée prend tout l'espace restant
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPage = value;
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
                child: Row(
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
                ),
              ),
            ),
          )
        : ConstrainedBox(
            // Les Chips non sélectionnées ont une largeur minimale
            constraints: BoxConstraints(minWidth: minWidth),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPage = value;
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
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.grey, // Icônes inactives en gris
                    size: 20,
                  ),
                ),
              ),
            ),
          );
  }
}
