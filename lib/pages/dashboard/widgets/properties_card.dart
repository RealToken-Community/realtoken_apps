import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/pages/dashboard/detailsPages/properties_details_page.dart';

class PropertiesCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const PropertiesCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return UIUtils.buildCard(
      S.of(context).properties,
      Icons.business_outlined,
      UIUtils.buildValueBeforeText(context, '${(dataManager.rentedUnits / dataManager.totalUnits * 100).toStringAsFixed(2)}%', S.of(context).rented, isLoading),
      [
        UIUtils.buildTextWithShimmer(
          '${dataManager.totalTokenCount}',
          S.of(context).properties,
          isLoading,
          context,
        ),
        UIUtils.buildTextWithShimmer(
          '${dataManager.walletTokenCount}',
          S.of(context).wallet,
          isLoading,
          context,
        ),
        Row(
          children: [
            UIUtils.buildTextWithShimmer(
              '${dataManager.rmmTokenCount.toInt()}',
              S.of(context).rmm,
              isLoading,
              context,
            ),
            SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(S.of(context).duplicate_title),
                      content: Text(
                        '${dataManager.duplicateTokenCount.toInt()} ${S.of(context).duplicate}',
                        style: TextStyle(fontSize: 13 + appState.getTextSizeOffset()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(S.of(context).close),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.info_outline, size: 15),
            ),
          ],
        ),
        UIUtils.buildTextWithShimmer(
          '${dataManager.rentedUnits} / ${dataManager.totalUnits}',
          'Rented units',
          isLoading,
          context,
        ),
      ],
      dataManager,
      context,
      hasGraph: true,
      rightWidget: Builder(
        builder: (context) {
          double rentedPercentage = dataManager.rentedUnits / dataManager.totalUnits * 100;
          if (rentedPercentage.isNaN || rentedPercentage < 0) {
            rentedPercentage = 0;
          }
          return _buildPieChart(rentedPercentage, context);
        },
      ),
      headerRightWidget: SizedBox(
        height: 36,
        width: 36,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertiesDetailsPage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(double rentedPercentage, BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120, // Largeur du camembert
      height: 90, // Hauteur du camembert
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90, // Pour placer la petite section en haut
          sections: [
            PieChartSectionData(
              value: rentedPercentage,
              color: Colors.green, // Couleur pour les unités louées
              title: '',
              radius: 23, // Taille de la section louée
              titleStyle: TextStyle(
                fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              gradient: LinearGradient(
                colors: [Colors.green.shade300, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            PieChartSectionData(
              value: 100 - rentedPercentage,
              color: theme.primaryColor, // Couleur pour les unités non louées
              title: '',
              radius: 17, // Taille de la section non louée
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.6),
                  theme.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
          sectionsSpace: 2, // Un léger espace entre les sections pour les démarquer
          centerSpaceRadius: 23, // Taille de l'espace central
        ),
        swapAnimationDuration: const Duration(milliseconds: 800), // Durée de l'animation
        swapAnimationCurve: Curves.easeInOut, // Courbe pour rendre l'animation fluide
      ),
    );
  }
}
