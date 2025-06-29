import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  _AppearanceSettingsPageState createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late String _selectedColor;
  final Map<String, Color> _colorOptions = {
    'blue': Colors.blue,
    'orange': Color.fromRGBO(237, 137, 32, 1),
    'pink': Colors.purple,
    'green': Colors.green,
    'grey': Colors.grey,
    'blueGrey': Colors.blueGrey,
    'red': Colors.red,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'amber': Colors.amber,
    'deepPurple': Colors.deepPurple,
    'lightBlue': Colors.lightBlue,
    'lime': Colors.lime,
    'brown': Colors.brown,
    'cyan': Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _loadPrimaryColor();
  }

  Future<void> _loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedColor = prefs.getString('primaryColor') ?? 'blue';
    });
  }

  Future<void> _updatePrimaryColor(String colorName) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updatePrimaryColor(colorName);
    setState(() {
      _selectedColor = colorName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).themeUpdated(colorName))),
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
        title: Text(S.of(context).appearance),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader(context, "Thème", CupertinoIcons.sun_max),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                title: "",
                trailing: null,
                isFirst: true,
                isLast: true,
                customContent: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildModernThemeSelector(context, appState),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(
              context, "Couleur principale", CupertinoIcons.color_filter),
          _buildSettingsSection(
            context,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _colorOptions.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _updatePrimaryColor(entry.key),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value,
                          border: _selectedColor == entry.key
                              ? Border.all(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.grey,
                                  width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionHeader(
              context, "Affichage", CupertinoIcons.textformat_size),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                title: S.of(context).textSize,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appState.selectedTextSize,
                        style: TextStyle(
                          fontSize: 13.0 + appState.getTextSizeOffset(),
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                  onPressed: () => _showTextSizePicker(context, appState),
                ),
                isFirst: true,
                isLast: false,
              ),
              _buildSettingsItem(
                context,
                title: S.of(context).language,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getLanguageName(appState.selectedLanguage, context),
                        style: TextStyle(
                          fontSize: 13.0 + appState.getTextSizeOffset(),
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                  onPressed: () => _showLanguagePicker(context, appState),
                ),
                isFirst: false,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String languageCode, BuildContext context) {
    switch (languageCode) {
      case 'en':
        return S.of(context).english;
      case 'fr':
        return S.of(context).french;
      case 'es':
        return S.of(context).spanish;
      case 'it':
        return S.of(context).italian;
      case 'pt':
        return S.of(context).portuguese;
      case 'zh':
        return S.of(context).chinese;
      case 'ru':
        return S.of(context).russian;
      default:
        return S.of(context).english;
    }
  }

  void _showTextSizePicker(BuildContext context, AppState appState) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3), width: 0.5)),
                color: isDarkMode(context)
                    ? const Color(0xFF2C2C2E)
                    : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("Annuler",
                        style: TextStyle(
                            fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("OK",
                        style: TextStyle(
                            fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 35,
                onSelectedItemChanged: (index) {
                  appState.updateTextSize(Parameters.textSizeOptions[index]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Taille du texte mise à jour: ${Parameters.textSizeOptions[index]}')),
                  );
                },
                scrollController: FixedExtentScrollController(
                  initialItem: Parameters.textSizeOptions
                      .indexOf(appState.selectedTextSize),
                ),
                children: Parameters.textSizeOptions
                    .map((size) => Center(
                          child: Text(size, style: TextStyle(fontSize: 15)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, AppState appState) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3), width: 0.5)),
                color: isDarkMode(context)
                    ? const Color(0xFF2C2C2E)
                    : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("Annuler",
                        style: TextStyle(
                            fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("OK",
                        style: TextStyle(
                            fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 35,
                onSelectedItemChanged: (index) {
                  String languageCode = Parameters.languages[index];
                  appState.updateLanguage(languageCode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(S.of(context).languageUpdated(
                            _getLanguageName(languageCode, context)))),
                  );
                },
                scrollController: FixedExtentScrollController(
                  initialItem:
                      Parameters.languages.indexOf(appState.selectedLanguage),
                ),
                children: Parameters.languages
                    .map((languageCode) => Center(
                          child: Text(_getLanguageName(languageCode, context),
                              style: TextStyle(fontSize: 15)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    Widget? trailing,
    required bool isFirst,
    required bool isLast,
    Widget? customContent,
  }) {
    final appState = Provider.of<AppState>(context);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(10) : Radius.zero,
      bottom: isLast ? const Radius.circular(10) : Radius.zero,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
          ),
          child: Column(
            children: [
              if (title.isNotEmpty || trailing != null)
                Row(
                  children: [
                    if (title.isNotEmpty)
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.0 + appState.getTextSizeOffset(),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    if (trailing != null) trailing,
                  ],
                ),
              if (customContent != null) customContent,
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Divider(
                height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.3)),
          ),
      ],
    );
  }

  Widget _buildModernThemeSelector(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 270,
      height: 60,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.3)
            : Colors.grey.shade200.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background selector indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: appState.themeMode == 'light'
                ? 0
                : appState.themeMode == 'dark'
                    ? 87
                    : 174,
            child: Container(
              width: 86,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeOption(
                context: context,
                icon: CupertinoIcons.sun_max_fill,
                label: S.of(context).light,
                isSelected: appState.themeMode == 'light',
                onTap: () {
                  appState.updateThemeMode('light');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(S.of(context).themeUpdated('light'))),
                  );
                },
              ),
              _buildThemeOption(
                context: context,
                icon: CupertinoIcons.moon_fill,
                label: S.of(context).dark,
                isSelected: appState.themeMode == 'dark',
                onTap: () {
                  appState.updateThemeMode('dark');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).themeUpdated('dark'))),
                  );
                },
              ),
              _buildThemeOption(
                context: context,
                icon: CupertinoIcons.device_phone_portrait,
                label: 'Auto',
                isSelected: appState.themeMode == 'auto',
                onTap: () {
                  appState.updateThemeMode('auto');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).themeUpdated('auto'))),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
      {required BuildContext context,
      required IconData icon,
      required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    final textColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
