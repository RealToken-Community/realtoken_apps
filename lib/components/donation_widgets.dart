import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/utils/style_constants.dart';
import 'package:provider/provider.dart';

/// Factory pour créer tous les widgets de donation de manière uniforme
class DonationWidgets {
  
  /// Constantes de couleurs pour les boutons de donation
  static const Color buyMeACoffeeColor = Color(0xFFFFDD00);
  static const Color paypalColor = Color(0xFF0070ba);
  static const Color cryptoBackgroundLight = Color(0xFFF4F4F4);
  
  /// Adresse de donation crypto
  static const String donationAddress = '0xdc30b07aebaef3f15544a3801c6cb0f35f0118fc';
  
  /// URLs de donation
  static const String buyMeACoffeeUrl = 'https://buymeacoffee.com/byackee';
  static const String paypalUrl = 'https://paypal.me/byackee?country.x=FR&locale.x=fr_FR';

  /// Construit le widget d'affichage du montant de donation avec loading
  static Widget buildAmountDisplay({
    required BuildContext context,
    required AppState appState,
    String? amount,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16 + appState.getTextSizeOffset()),
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    if (amount != null && amount.isNotEmpty) {
      return Column(
        children: [
          Text(
            S.of(context).donationTotal,
            style: TextStyle(
              fontSize: 15 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4 + appState.getTextSizeOffset()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 28 + appState.getTextSizeOffset(),
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 6 + appState.getTextSizeOffset()),
              Padding(
                padding: EdgeInsets.only(bottom: 2 + appState.getTextSizeOffset()),
                child: Text(
                  'USD',
                  style: TextStyle(
                    fontSize: 15 + appState.getTextSizeOffset(),
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4 + appState.getTextSizeOffset()),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Construit le titre principal avec emoji
  static Widget buildTitle({
    required BuildContext context,
    required AppState appState,
  }) {
    return Text(
      "${S.of(context).supportProject} ❤️",
      style: TextStyle(
        fontSize: 24 + appState.getTextSizeOffset(),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.headlineSmall?.color,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Construit le message de description
  static Widget buildDescription({
    required BuildContext context,
    required AppState appState,
  }) {
    return Text(
      S.of(context).donationMessage,
      style: TextStyle(
        fontSize: 14 + appState.getTextSizeOffset(),
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Construit le bouton Buy Me a Coffee
  static Widget buildBuyMeACoffeeButton({
    required BuildContext context,
    required AppState appState,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Text(
          "☕",
          style: TextStyle(fontSize: 16 + appState.getTextSizeOffset()),
        ),
        label: Text(
          "Buy Me a Coffee",
          style: TextStyle(
            fontSize: 15 + appState.getTextSizeOffset(),
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buyMeACoffeeColor,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: 10 + appState.getTextSizeOffset(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleConstants.buttonBorderRadius),
          ),
          elevation: 0,
        ),
        onPressed: () => UrlUtils.launchURL(buyMeACoffeeUrl),
      ),
    );
  }

  /// Construit le bouton PayPal
  static Widget buildPaypalButton({
    required BuildContext context,
    required AppState appState,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Text(
          "💳",
          style: TextStyle(fontSize: 16 + appState.getTextSizeOffset()),
        ),
        label: Text(
          S.of(context).paypal,
          style: TextStyle(
            fontSize: 15 + appState.getTextSizeOffset(),
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: paypalColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: 10 + appState.getTextSizeOffset(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleConstants.buttonBorderRadius),
          ),
          elevation: 0,
        ),
        onPressed: () => UrlUtils.launchURL(paypalUrl),
      ),
    );
  }

  /// Construit la section crypto avec copie d'adresse
  static Widget buildCryptoSection({
    required BuildContext context,
    required AppState appState,
  }) {
    return Column(
      children: [
        Text(
          S.of(context).cryptoDonation,
          style: TextStyle(
            fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        SizedBox(height: 4 + appState.getTextSizeOffset()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : cryptoBackgroundLight,
            borderRadius: BorderRadius.circular(StyleConstants.smallBorderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SelectableText(
                  donationAddress,
                  style: TextStyle(
                    fontSize: 12 + appState.getTextSizeOffset(),
                    fontFamily: 'Menlo',
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                ),
                tooltip: S.of(context).copy,
                onPressed: () => _copyAddressToClipboard(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le message de remerciement
  static Widget buildThankYouMessage({
    required BuildContext context,
    required AppState appState,
  }) {
    return Text(
      S.of(context).everyContributionCounts,
      style: TextStyle(
        fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Construit un divider standard
  static Widget buildDivider({required BuildContext context}) {
    return Divider(
      color: Theme.of(context).dividerColor,
      thickness: 1,
    );
  }

  /// Construit un espaceur vertical basé sur la taille de texte
  static Widget buildSpacer({
    required AppState appState,
    double baseHeight = 8.0,
  }) {
    return SizedBox(height: baseHeight + appState.getTextSizeOffset());
  }

  /// Widget complet pour section donation (réutilisable)
  static Widget buildCompleteSection({
    required BuildContext context,
    required AppState appState,
    String? amount,
    bool isLoading = false,
    bool showTitle = true,
    bool showAmount = true,
    bool showButtons = true,
    bool showCrypto = true,
    bool showThankYou = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showTitle) ...[
          buildTitle(context: context, appState: appState),
          buildSpacer(appState: appState, baseHeight: 4),
        ],
        
        if (showAmount)
          buildAmountDisplay(
            context: context,
            appState: appState,
            amount: amount,
            isLoading: isLoading,
          ),
        
        buildSpacer(appState: appState),
        buildDescription(context: context, appState: appState),
        buildSpacer(appState: appState),
        buildDivider(context: context),
        buildSpacer(appState: appState),

        if (showButtons) ...[
          buildBuyMeACoffeeButton(context: context, appState: appState),
          buildSpacer(appState: appState, baseHeight: 10),
          buildPaypalButton(context: context, appState: appState),
          buildSpacer(appState: appState, baseHeight: 10),
        ],

        if (showCrypto) ...[
          buildCryptoSection(context: context, appState: appState),
          buildSpacer(appState: appState),
        ],

        if (showThankYou)
          buildThankYouMessage(context: context, appState: appState),
      ],
    );
  }

  /// Méthode privée pour copier l'adresse dans le clipboard
  static Future<void> _copyAddressToClipboard(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: donationAddress));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).addressCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 