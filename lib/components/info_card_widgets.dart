import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtoken_asset_tracker/utils/style_constants.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:provider/provider.dart';

/// Factory pour créer des cartes d'information standardisées
class InfoCardWidgets {
  /// Construit un header de section standardisé
  static Widget buildSectionHeader(
      BuildContext context, String title, double textSizeOffset) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20 +
              Provider.of<AppState>(context, listen: false)
                  .getTextSizeOffset() +
              textSizeOffset,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }

  /// Construit une carte d'information standardisée avec icône et textes
  static Widget buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double textSizeOffset,
    String? linkUrl,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: StyleConstants.cardDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(StyleConstants.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconContainer(context, icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child:
                  _buildTextContent(context, title, subtitle, textSizeOffset),
            ),
            if (linkUrl != null || onTap != null)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
          ],
        ),
      ),
    );

    // Rendre la carte cliquable si nécessaire
    if (linkUrl != null) {
      return GestureDetector(
        onTap: () => UrlUtils.launchURL(linkUrl),
        child: card,
      );
    } else if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  /// Construit une carte de remerciements avec icône coeur
  static Widget buildThanksCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double textSizeOffset,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(StyleConstants.cardBorderRadius),
        boxShadow: StyleConstants.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconContainer(context, CupertinoIcons.heart_fill,
                CupertinoColors.systemPink.resolveFrom(context)),
            const SizedBox(width: 14),
            Expanded(
              child:
                  _buildTextContent(context, title, subtitle, textSizeOffset),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte de lien spécialisée avec icône et URL
  static Widget buildLinkCard(
    BuildContext context, {
    required String title,
    required String url,
    required double textSizeOffset,
    IconData icon = CupertinoIcons.link,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () => UrlUtils.launchURL(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        decoration: StyleConstants.cardDecoration(context),
        child: Padding(
          padding: EdgeInsets.all(StyleConstants.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconContainer(context, icon, iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15 +
                            Provider.of<AppState>(context, listen: false)
                                .getTextSizeOffset() +
                            textSizeOffset,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url,
                      style: TextStyle(
                        fontSize: 14 +
                            Provider.of<AppState>(context, listen: false)
                                .getTextSizeOffset() +
                            textSizeOffset,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une carte statistique avec valeur mise en évidence
  static Widget buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String title,
    required double textSizeOffset,
    Color? valueColor,
    Color? iconColor,
    Color? cardColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final finalCardColor =
        cardColor ?? (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: finalCardColor,
        borderRadius: BorderRadius.circular(StyleConstants.modalBorderRadius),
        boxShadow: StyleConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: iconColor ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22 +
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset() +
                  textSizeOffset,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14 +
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset() +
                  textSizeOffset,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de support/donation simplifiée
  static Widget buildSupportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double textSizeOffset,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: StyleConstants.cardDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(StyleConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIconContainer(context, CupertinoIcons.money_dollar_circle,
                    CupertinoColors.systemGreen.resolveFrom(context)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17 +
                        Provider.of<AppState>(context, listen: false)
                            .getTextSizeOffset() +
                        textSizeOffset,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14 +
                      Provider.of<AppState>(context, listen: false)
                          .getTextSizeOffset() +
                      textSizeOffset,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTHODES PRIVÉES UTILITAIRES ---

  /// Construit le container d'icône standardisé
  static Widget _buildIconContainer(
      BuildContext context, IconData icon, Color? iconColor) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(StyleConstants.buttonBorderRadius),
      ),
      child: Icon(
        icon,
        color: iconColor ?? CupertinoColors.systemBlue.resolveFrom(context),
        size: 22,
      ),
    );
  }

  /// Construit le contenu textuel standardisé (titre + sous-titre)
  static Widget _buildTextContent(BuildContext context, String title,
      String subtitle, double textSizeOffset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15 +
                Provider.of<AppState>(context, listen: false)
                    .getTextSizeOffset() +
                textSizeOffset,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14 +
                Provider.of<AppState>(context, listen: false)
                    .getTextSizeOffset() +
                textSizeOffset,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}
