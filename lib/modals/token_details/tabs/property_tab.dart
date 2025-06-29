import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/utils/date_utils.dart';
import 'package:realtoken_asset_tracker/utils/location_utils.dart';
import 'package:realtoken_asset_tracker/utils/parameters.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';

Widget buildPropertiesTab(BuildContext context, Map<String, dynamic> token, bool convertToSquareMeters) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section loyers
        _buildSectionCard(
          context,
          title: S.of(context).rents,
          children: [
            _buildRentalStatusRow(
              context,
              token: token,
              appState: appState,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildRentStartDateRow(
              context,
              token: token,
              appState: appState,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).section8paid,
              '${((token['section8paid']) / (token['grossRentMonth']) * 100).toStringAsFixed(2)}%',
              icon: Icons.attach_money,
              iconColor: Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section caractéristiques
        _buildSectionCard(
          context,
          title: S.of(context).characteristics,
          children: [
            _buildDetailRow(
              context,
              S.of(context).constructionYear,
              token['constructionYear']?.toString() ?? S.of(context).notSpecified,
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).propertyType,
              Parameters.getPropertyTypeName(token['propertyType'] ?? -1, context),
              icon: Icons.home,
              iconColor: Colors.teal,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).rentalType,
              token['rentalType']?.toString() ?? S.of(context).notSpecified,
              icon: Icons.assignment,
              iconColor: Colors.amber,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).bedroomBath,
              token['bedroomBath']?.toString() ?? S.of(context).notSpecified,
              icon: Icons.bed,
              iconColor: Colors.indigo,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).lotSize,
              LocationUtils.formatSquareFeet(
                token['lotSize']?.toDouble() ?? 0,
                convertToSquareMeters,
              ),
              icon: Icons.landscape,
              iconColor: Colors.green,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildDetailRow(
              context,
              S.of(context).squareFeet,
              LocationUtils.formatSquareFeet(
                token['squareFeet']?.toDouble() ?? 0,
                convertToSquareMeters,
              ),
              icon: Icons.square_foot,
              iconColor: Colors.deepPurple,
            ),
          ],
        ),
      ],
    ),
  );
}

// Méthode pour construire une section avec carte
Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18 + Provider.of<AppState>(context).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Column(children: children),
      ],
    ),
  );
}

// Méthode pour construire les lignes de détails
Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? icon, Color? iconColor}) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? Colors.blue,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w300,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w400,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    ),
  );
}

// Méthode spécifique pour la ligne d'état de location
Widget _buildRentalStatusRow(BuildContext context, {required Map<String, dynamic> token, required AppState appState}) {
  final rentedUnits = token['rentedUnits'] ?? 0;
  final totalUnits = token['totalUnits'] ?? 1;
  final occupancyRate = (rentedUnits / totalUnits * 100).round();

  final statusColor = UIUtils.getRentalStatusColor(rentedUnits, totalUnits);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    size: 18,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
          S.of(context).rented,
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            Text(
              '$rentedUnits / $totalUnits',
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Jauge d'occupation
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double maxWidth = constraints.maxWidth;
              return Row(
                children: [
                  Container(
                    height: 8,
                    width: occupancyRate * 0.01 * maxWidth,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${occupancyRate.toString()}% ' "Occupation",
              style: TextStyle(
                fontSize: 12 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Méthode spécifique pour la ligne de date de début de location
Widget _buildRentStartDateRow(BuildContext context, {required Map<String, dynamic> token, required AppState appState}) {
  final rentStartDate = token['rentStartDate'] ?? '';
  final isActive = DateTime.parse(rentStartDate).isBefore(DateTime.now());
  final statusColor = isActive ? Colors.green : Colors.red;
  final statusText = isActive ? "Actif" : "En attente";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.date_range,
                size: 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              S.of(context).rentStartDate,
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w300,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              CustomDateUtils.formatReadableDate(rentStartDate),
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w400,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12 + appState.getTextSizeOffset(),
                  fontWeight: FontWeight.w400,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
