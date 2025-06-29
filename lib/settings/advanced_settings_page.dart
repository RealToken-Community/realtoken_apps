import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  _AdvancedSettingsPageState createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  int _daysLimit = 30;
  double _apyReactivity = 0.2; // Valeur par défaut pour la réactivité de l'APY

  Future<void> _clearCacheAndData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache et données supprimés')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(S.of(context).advanced),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader(context, "Historique YAM", CupertinoIcons.chart_bar_alt_fill),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                title: S.of(context).yamHistory,
                subtitle: "${S.of(context).daysLimit}: $_daysLimit days",
                trailing: const Icon(CupertinoIcons.pencil, size: 14, color: Colors.grey),
                onTap: () => _showNumberPicker(context),
                isFirst: true,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(context, "Réactivité APY", CupertinoIcons.waveform_path),
          _buildSettingsSection(
            context,
            footnote: 'Ajustez la sensibilité du calcul d\'APY aux variations récentes',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  children: [
                    Text('Lisse', style: TextStyle(fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset())),
                    Expanded(
                      child: Slider.adaptive(
                        value: _apyReactivity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _apyReactivity = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _saveApyReactivity(value);
                          appState.adjustApyReactivity(value);
                        },
                      ),
                    ),
                    Text('Réactif', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 12.0),
                child: Text(
                  _getApyReactivityLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(context, "Gestion des données", CupertinoIcons.delete),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                title: 'Effacer le cache et les données',
                trailing: const Icon(CupertinoIcons.delete, color: Colors.red, size: 14),
                onTap: () => _showDeleteConfirmation(context),
                isFirst: true,
                isLast: true,
                titleColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
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
    String? footnote,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
        ),
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6, right: 16),
            child: Text(
              footnote,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
    Color? titleColor,
  }) {
    final appState = Provider.of<AppState>(context);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.0 + appState.getTextSizeOffset(),
                          fontWeight: FontWeight.w400,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null)
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
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.3)),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir effacer toutes les données et le cache? Cette action est irréversible.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Supprimer'),
            onPressed: () {
              Navigator.pop(context);
              _clearCacheAndData(context);
            },
          ),
        ],
      ),
    );
  }

  // Fonction pour obtenir un libellé descriptif en fonction de la valeur de réactivité
  String _getApyReactivityLabel() {
    if (_apyReactivity < 0.2) {
      return 'Très lisse';
    } else if (_apyReactivity < 0.4) {
      return 'Lisse';
    } else if (_apyReactivity < 0.6) {
      return 'Équilibré';
    } else if (_apyReactivity < 0.8) {
      return 'Réactif';
    } else {
      return 'Très réactif';
    }
  }

  void _showNumberPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        int tempDaysLimit = _daysLimit;
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text("Annuler", style: TextStyle(color: CupertinoColors.destructiveRed)),
                    ),
                    Text(
                      "Jours d'historique",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _daysLimit = tempDaysLimit;
                        });
                        _saveDaysLimit(_daysLimit);
                        Navigator.pop(context);
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 35,
                  onSelectedItemChanged: (index) {
                    tempDaysLimit = index + 1;
                  },
                  scrollController: FixedExtentScrollController(initialItem: _daysLimit - 1),
                  children: List.generate(365, (index) {
                    return Center(
                      child: Text(
                        "${index + 1} jours",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _daysLimit = prefs.getInt('daysLimit') ?? 30;
      _apyReactivity = prefs.getDouble('apyReactivity') ?? 0.2;
    });
  }

  Future<void> _saveDaysLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daysLimit', value);
  }

  Future<void> _saveApyReactivity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('apyReactivity', value);
  }
}
