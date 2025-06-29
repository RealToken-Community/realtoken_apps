import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class ChartOptionsUtils {
  /// Construit le sélecteur de type de graphique (barre ou ligne)
  static Widget buildChartTypeSelector({
    required BuildContext context,
    required bool isBarChart,
    required Function(bool) onChartTypeChanged,
    required VoidCallback onClose,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
          child: Text(
            S.of(context).chartType,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17 + appState.getTextSizeOffset(),
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            leading: Icon(
              CupertinoIcons.chart_bar,
              color: primaryColor.withValues(alpha: 0.8),
              size: 22,
            ),
            title: Text(
              S.of(context).barChart,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15 + appState.getTextSizeOffset(),
                letterSpacing: -0.4,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: isBarChart
                ? Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: primaryColor,
                    size: 18,
                  )
                : null,
            onTap: () {
              onChartTypeChanged(true);
              onClose();
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            leading: Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: primaryColor.withValues(alpha: 0.8),
              size: 22,
            ),
            title: Text(
              S.of(context).lineChart,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15 + appState.getTextSizeOffset(),
                letterSpacing: -0.4,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: !isBarChart
                ? Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: primaryColor,
                    size: 18,
                  )
                : null,
            onTap: () {
              onChartTypeChanged(false);
              onClose();
            },
          ),
        ),
      ],
    );
  }
  
  /// Construit le sélecteur de plage temporelle
  static Widget buildTimeRangeSelector({
    required BuildContext context,
    required String selectedTimeRange,
    required Function(String) onTimeRangeChanged,
    required VoidCallback onClose,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
          child: Text(
            "Plage de temps",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17 + appState.getTextSizeOffset(),
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  "Toutes les données",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedTimeRange == 'all'
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onTimeRangeChanged('all');
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  "3 mois",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedTimeRange == '3months'
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onTimeRangeChanged('3months');
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  "6 mois",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedTimeRange == '6months'
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onTimeRangeChanged('6months');
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  "12 mois",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedTimeRange == '12months'
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onTimeRangeChanged('12months');
                  onClose();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Construit le sélecteur de période d'affichage
  static Widget buildPeriodSelector({
    required BuildContext context,
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
    required VoidCallback onClose,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
          child: Text(
            "Période d'affichage",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17 + appState.getTextSizeOffset(),
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar_today,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  S.of(context).day,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedPeriod == S.of(context).day
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onPeriodChanged(S.of(context).day);
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar_badge_plus,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  S.of(context).week,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedPeriod == S.of(context).week
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onPeriodChanged(S.of(context).week);
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar_circle,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  S.of(context).month,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedPeriod == S.of(context).month
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onPeriodChanged(S.of(context).month);
                  onClose();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                leading: Icon(
                  CupertinoIcons.calendar_circle_fill,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 22,
                ),
                title: Text(
                  S.of(context).year,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15 + appState.getTextSizeOffset(),
                    letterSpacing: -0.4,
                    color: textColor,
                  ),
                ),
                trailing: selectedPeriod == S.of(context).year
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: primaryColor,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  onPeriodChanged(S.of(context).year);
                  onClose();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Méthode pour construire le modal d'options complet
  static void showOptionsModal({
    required BuildContext context,
    required bool isBarChart,
    required Function(bool) onChartTypeChanged,
    required String selectedTimeRange,
    required Function(String) onTimeRangeChanged,
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
    VoidCallback? onEditPressed,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poignée de la modal
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sélecteur de type de graphique
                      buildChartTypeSelector(
                        context: context,
                        isBarChart: isBarChart,
                        onChartTypeChanged: onChartTypeChanged,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      
                      // Sélecteur de plage de temps
                      buildTimeRangeSelector(
                        context: context,
                        selectedTimeRange: selectedTimeRange,
                        onTimeRangeChanged: onTimeRangeChanged,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      
                      // Sélecteur de période
                      buildPeriodSelector(
                        context: context,
                        selectedPeriod: selectedPeriod,
                        onPeriodChanged: onPeriodChanged,
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      
                      if (onEditPressed != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        SizedBox(
                          height: 44,
                          child: ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                            leading: Icon(
                              CupertinoIcons.pencil,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                              size: 22,
                            ),
                            title: Text(
                              S.of(context).edit,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15 + appState.getTextSizeOffset(),
                                letterSpacing: -0.4,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              onEditPressed();
                            },
                          ),
                        ),
                      ],
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