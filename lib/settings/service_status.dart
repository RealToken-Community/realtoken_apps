import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart'; // Import AppState

class ServiceStatusPage extends StatelessWidget {
  const ServiceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('realTokens');
    final appState = Provider.of<AppState>(context);

    // Récupérer toutes les clés qui commencent par "lastExecutionTime_"
    Map<String, String> executionTimesMap = {};
    for (var key in box.keys) {
      if (key.toString().startsWith('lastExecutionTime_')) {
        String? executionTime = box.get(key); // Récupérer la dernière exécution
        executionTimesMap[key.toString()] = executionTime!;
      }
    }

    // Variable pour suivre l'état des services
    bool allAreUpToDate = true; // Par défaut à true

    // Vérifier la condition allAreUpToDate avant d'afficher la liste
    executionTimesMap.forEach((key, time) {
      try {
        DateTime lastExecution = DateTime.parse(time);
        Duration difference = DateTime.now().difference(lastExecution);

        // Si un service n'est pas à jour (plus d'une heure), mettre allAreUpToDate à false
        if (difference.inHours >= 1) {
          allAreUpToDate = false;
        }
      } catch (e) {
        allAreUpToDate = false;
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(S.of(context).serviceStatusPage),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: executionTimesMap.isNotEmpty
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),

                _buildSectionHeader(
                    context, "État des services", CupertinoIcons.gauge),

                // Afficher le texte en fonction de allAreUpToDate
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: allAreUpToDate
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: allAreUpToDate
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allAreUpToDate
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.exclamationmark_circle,
                          color: allAreUpToDate ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            allAreUpToDate
                                ? S.of(context).allWorkCorrectly
                                : S.of(context).somethingWrong,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: allAreUpToDate ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _buildSettingsSection(
                  context,
                  children: executionTimesMap.entries.map((entry) {
                    String key = entry.key;
                    String time = entry.value;

                    // Supprimer le préfixe "lastExecutionTime_"
                    String displayKey =
                        key.replaceFirst('lastExecutionTime_', '');

                    // Convertir `time` en DateTime pour calculer la différence
                    DateTime lastExecution;
                    try {
                      lastExecution = DateTime.parse(time);
                    } catch (e) {
                      // Si une erreur de format de date se produit, on affiche un message d'erreur
                      return _buildServiceItem(
                        context: context,
                        title: displayKey,
                        subtitle: 'Erreur de format de date',
                        isUpToDate: false,
                        isFirst: executionTimesMap.entries.first.key == key,
                        isLast: executionTimesMap.entries.last.key == key,
                      );
                    }

                    Duration difference =
                        DateTime.now().difference(lastExecution);
                    bool isLessThanAnHour = difference.inHours < 1;

                    return _buildServiceItem(
                      context: context,
                      title: displayKey,
                      subtitle:
                          '${S.of(context).lastExecution} : ${CustomDateUtils.formatReadableDateWithTime(time)}',
                      isUpToDate: isLessThanAnHour,
                      isFirst: executionTimesMap.entries.first.key == key,
                      isLast: executionTimesMap.entries.last.key == key,
                    );
                  }).toList(),
                ),
              ],
            )
          : Center(
              child: Text(
                'Aucune exécution trouvée',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
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

  Widget _buildSettingsSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildServiceItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isUpToDate,
    required bool isFirst,
    required bool isLast,
  }) {
    final appState = Provider.of<AppState>(context);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              Icon(
                isUpToDate
                    ? CupertinoIcons.check_mark_circled
                    : CupertinoIcons.exclamationmark_circle,
                color: isUpToDate ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.0 + appState.getTextSizeOffset(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.0 + appState.getTextSizeOffset(),
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey.withValues(alpha: 0.3)),
          ),
      ],
    );
  }
}
