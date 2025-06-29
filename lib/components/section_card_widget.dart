import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/style_constants.dart';

/// Widget commun pour créer des cartes de section standardisées
/// Remplace toutes les méthodes _buildSectionCard dupliquées
class SectionCardWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? margin;
  final EdgeInsets? titlePadding;
  final EdgeInsets? contentPadding;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;

  const SectionCardWidget({
    super.key,
    required this.title,
    required this.children,
    this.margin,
    this.titlePadding,
    this.contentPadding,
    this.titleColor,
    this.titleFontSize,
    this.titleFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: StyleConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: titlePadding ?? const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: (titleFontSize ?? 18) + appState.getTextSizeOffset(),
                fontWeight: titleFontWeight ?? FontWeight.bold,
                color: titleColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          Padding(
            padding: contentPadding ?? EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Widget commun pour créer des lignes de détails standardisées
/// Remplace les méthodes _buildDetailRow dupliquées
class DetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final bool isExpenseItem;
  final EdgeInsets? padding;
  final double? iconSize;
  final double? labelFontSize;
  final double? valueFontSize;
  final FontWeight? labelFontWeight;
  final FontWeight? valueFontWeight;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.isExpenseItem = false,
    this.padding,
    this.iconSize,
    this.labelFontSize,
    this.valueFontSize,
    this.labelFontWeight,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                isExpenseItem
                    ? Icon(
                        icon,
                        size: iconSize ?? 14,
                        color: iconColor ?? Colors.blue,
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: iconSize ?? 18,
                          color: iconColor ?? Colors.blue,
                        ),
                      ),
              SizedBox(width: isExpenseItem ? 6 : 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: (labelFontSize ?? 14) + appState.getTextSizeOffset(),
                  fontWeight: labelFontWeight ?? FontWeight.w300,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: (valueFontSize ?? 14) + appState.getTextSizeOffset(),
              fontWeight: valueFontWeight ?? FontWeight.w400,
              color: isExpenseItem 
                  ? Colors.red 
                  : (textColor ?? Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
} 