import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/style_constants.dart';

class DrawerMenuFactory {
  /// Crée une section de menu complète avec titre et éléments
  static Widget buildMenuSection({
    required BuildContext context,
    required String title,
    required AppState appState,
    required List<DrawerMenuItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: StyleConstants.marginLarge, vertical: StyleConstants.marginSmall),
      decoration: StyleConstants.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, title, appState),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return buildMenuItem(
              context: context,
              item: item,
              appState: appState,
              isFirst: index == 0,
              isLast: index == items.length - 1,
            );
          }),
        ],
      ),
    );
  }

  /// Crée un titre de section
  static Widget _buildSectionTitle(BuildContext context, String title, AppState appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StyleConstants.paddingMedium,
        StyleConstants.paddingSmall + 2,
        StyleConstants.paddingMedium,
        StyleConstants.paddingMedium - 4,
      ),
      child: Text(
        title,
        style: StyleConstants.titleStyle(context, appState.getTextSizeOffset()).copyWith(
          fontSize: 18 + appState.getTextSizeOffset(),
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Crée un élément de menu individuel
  static Widget buildMenuItem({
    required BuildContext context,
    required DrawerMenuItem item,
    required AppState appState,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(StyleConstants.buttonBorderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StyleConstants.paddingLarge,
                vertical: StyleConstants.paddingSmall,
              ),
              child: Row(
                children: [
                  _buildMenuIcon(context, item),
                  const SizedBox(width: StyleConstants.paddingMedium),
                  Expanded(
                    child: Text(
                      item.title,
                      style: StyleConstants.bodyStyle(context, appState.getTextSizeOffset()).copyWith(
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: StyleConstants.iconSmall,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  /// Crée l'icône d'un élément de menu
  static Widget _buildMenuIcon(BuildContext context, DrawerMenuItem item) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (item.iconColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(StyleConstants.buttonBorderRadius),
      ),
      child: Icon(
        item.icon,
        size: 18,
        color: item.iconColor ?? Theme.of(context).primaryColor,
      ),
    );
  }

  /// Crée un diviseur entre les éléments
  static Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: StyleConstants.borderThin,
      indent: 60,
    );
  }

  /// Factory pour créer rapidement des éléments de menu standard
  static DrawerMenuItem createMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return DrawerMenuItem(
      icon: icon,
      title: title,
      onTap: onTap,
      iconColor: iconColor,
    );
  }

  /// Factory pour les éléments de navigation de page
  static DrawerMenuItem createPageNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
    Color? iconColor,
  }) {
    return DrawerMenuItem(
      icon: icon,
      title: title,
      iconColor: iconColor,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }

  /// Factory pour les éléments avec modal bottom sheet
  static DrawerMenuItem createModalItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget modal,
    Color? iconColor,
    double? modalHeight,
  }) {
    return DrawerMenuItem(
      icon: icon,
      title: title,
      iconColor: iconColor,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(StyleConstants.modalBorderRadius + 4)),
          ),
          builder: (BuildContext context) {
            return SizedBox(
              height: modalHeight ?? MediaQuery.of(context).size.height * StyleConstants.maxModalHeight,
              child: modal,
            );
          },
        );
      },
    );
  }
}

/// Classe de données pour un élément de menu du drawer
class DrawerMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });
} 