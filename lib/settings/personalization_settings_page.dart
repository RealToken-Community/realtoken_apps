import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/services/api_service.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';

class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  _PersonalizationSettingsPageState createState() => _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState extends State<PersonalizationSettingsPage> {
  Map<String, dynamic> _currencies = {};
  final TextEditingController _adjustmentController = TextEditingController();
  final TextEditingController _initialInvestmentAdjustmentController = TextEditingController();

  Future<void> _saveConvertToSquareMeters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('convertToSquareMeters', value);
    setState(() {
      Parameters.convertToSquareMeters = value;
    });
  }

  Future<void> _saveShowTotalInvested(bool value) async {
    Parameters.setShowTotalInvested(value);
    setState(() {});
  }

  Future<void> _saveShowNetTotal(bool value) async {
    Parameters.setShowNetTotal(value);
    setState(() {});
  }

  Future<void> _saveShowYamProjection(bool value) async {
    Parameters.setShowYamProjection(value);
    setState(() {});
  }

  Future<void> _saveManualAdjustment(double value) async {
    Parameters.setManualAdjustment(value);
    setState(() {
      _adjustmentController.text = value.toString();
    });

    if (!mounted) return;
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData();
  }

  Future<void> _saveInitialInvestmentAdjustment(double value) async {
    Parameters.setInitialInvestmentAdjustment(value);
    setState(() {
      _initialInvestmentAdjustmentController.text = value.toString();
    });

    if (!mounted) return;
    final dataManager = Provider.of<DataManager>(context, listen: false);
    await dataManager.fetchAndCalculateData();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchCurrencies();
    _adjustmentController.text = Parameters.manualAdjustment.toString();
    _initialInvestmentAdjustmentController.text = Parameters.initialInvestmentAdjustment.toString();
  }

  @override
  void dispose() {
    _adjustmentController.dispose();
    _initialInvestmentAdjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(S.of(context).personalization),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),

          // Portfolio Settings
          _buildSectionHeader(context, S.of(context).portfolio, CupertinoIcons.chart_bar_square),
          _buildSettingsSection(
            context,
            children: [
              _buildSwitchItem(
                context,
                title: S.of(context).showTotalInvested,
                value: Parameters.showTotalInvested,
                onChanged: _saveShowTotalInvested,
                isFirst: true,
              ),
              _buildSwitchItem(
                context,
                title: S.of(context).showNetTotal,
                value: Parameters.showNetTotal,
                onChanged: _saveShowNetTotal,
                subtitle: S.of(context).showNetTotalDescription,
              ),
              _buildSwitchItem(
                context,
                title: S.of(context).showYamProjection,
                value: Parameters.showYamProjection,
                onChanged: _saveShowYamProjection,
                subtitle: S.of(context).yamProjectionDescription,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Units Settings
          _buildSectionHeader(context, S.of(context).units, CupertinoIcons.arrow_right_arrow_left),
          _buildSettingsSection(
            context,
            children: [
              _buildSwitchItem(
                context,
                title: S.of(context).convertSqft,
                value: Parameters.convertToSquareMeters,
                onChanged: _saveConvertToSquareMeters,
                isFirst: true,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Currency Settings
          _buildSectionHeader(context, S.of(context).currency, CupertinoIcons.money_dollar_circle),
          _buildSettingsSection(
            context,
            children: [
              _buildSettingsItem(
                context,
                title: S.of(context).selectCurrency,
                trailing: _currencies.isNotEmpty
                    ? Consumer<CurrencyProvider>(
                        builder: (context, currencyProvider, child) {
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyProvider.selectedCurrency.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14.0 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
                                    color: Colors.grey,
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                              ],
                            ),
                            onPressed: () => _showCurrencyPicker(context, currencyProvider),
                          );
                        },
                      )
                    : const CupertinoActivityIndicator(radius: 8),
                isFirst: true,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Adjustments
          _buildSectionHeader(context, "Ajustements", CupertinoIcons.slider_horizontal_3),
          _buildCompactAdjustments(context),
        ],
      ),
    );
  }

  Widget _buildCompactAdjustments(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Manuel Adjustment
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).manualAdjustment,
                  style: TextStyle(
                    fontSize: 15.0 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  S.of(context).manualAdjustmentDescription,
                  style: TextStyle(
                    fontSize: 12.0 + appState.getTextSizeOffset(),
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _adjustmentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(CupertinoIcons.money_dollar, color: Colors.grey, size: 16),
                        ),
                        placeholder: S.of(context).amount,
                        decoration: BoxDecoration(
                          color: isDarkMode(context) ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.zero),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.zero, right: Radius.circular(6)),
                      minSize: 0,
                      onPressed: () {
                        final String text = _adjustmentController.text;
                        double? value = double.tryParse(text);
                        if (value != null) {
                          _saveManualAdjustment(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).adjustmentSaved)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).enterValidNumber)),
                          );
                        }
                      },
                      child: SizedBox(
                        height: 36,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              S.of(context).save,
                              style: TextStyle(
                                fontSize: 12.0 + appState.getTextSizeOffset(),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Initial Investment Adjustment
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ajustement investissement initial",
                  style: TextStyle(
                    fontSize: 15.0 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Ajuster le montant pour les calculs de rendement",
                  style: TextStyle(
                    fontSize: 12.0 + appState.getTextSizeOffset(),
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _initialInvestmentAdjustmentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(CupertinoIcons.money_dollar, color: Colors.grey, size: 16),
                        ),
                        placeholder: S.of(context).amount,
                        decoration: BoxDecoration(
                          color: isDarkMode(context) ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.zero),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.zero, right: Radius.circular(6)),
                      minSize: 0,
                      onPressed: () {
                        final String text = _initialInvestmentAdjustmentController.text;
                        double? value = double.tryParse(text);
                        if (value != null) {
                          _saveInitialInvestmentAdjustment(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Ajustement enregistré")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).enterValidNumber)),
                          );
                        }
                      },
                      child: SizedBox(
                        height: 36,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              S.of(context).save,
                              style: TextStyle(
                                fontSize: 12.0 + appState.getTextSizeOffset(),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
    String? subtitle,
    Widget? trailing,
    bool isFirst = false,
    bool isLast = false,
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
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3)),
          ),
      ],
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return _buildSettingsItem(
      context,
      title: title,
      subtitle: subtitle,
      trailing: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Theme.of(context).primaryColor,
        ),
      ),
      isFirst: isFirst,
      isLast: isLast,
    );
  }

  void _showCurrencyPicker(BuildContext context, CurrencyProvider currencyProvider) {
    final appState = Provider.of<AppState>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
                color: isDarkMode(context) ? const Color(0xFF2C2C2E) : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("Annuler", style: TextStyle(fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("OK", style: TextStyle(fontSize: 14)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 30,
                onSelectedItemChanged: (index) {
                  final String currencyKey = _currencies.keys.elementAt(index);
                  currencyProvider.updateConversionRate(currencyKey, _currencies);
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _currencies.keys.toList().indexOf(currencyProvider.selectedCurrency),
                ),
                children: _currencies.keys
                    .map((key) => Center(
                          child: Text(
                            key.toUpperCase(),
                            style: TextStyle(fontSize: 16),
                          ),
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

  Future<void> _fetchCurrencies() async {
    try {
      final currencies = await ApiService.fetchCurrencies();
      if (!mounted) return;
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies')),
      );
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      Parameters.convertToSquareMeters = prefs.getBool('convertToSquareMeters') ?? false;
      Parameters.selectedCurrency = prefs.getString('selectedCurrency') ?? 'usd';

      _adjustmentController.text = Parameters.manualAdjustment.toString();
      _initialInvestmentAdjustmentController.text = Parameters.initialInvestmentAdjustment.toString();
    });
  }
}
