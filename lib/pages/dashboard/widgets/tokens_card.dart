import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/utils/ui_utils.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class TokensCard extends StatelessWidget {
  final bool showAmounts;
  final bool isLoading;

  const TokensCard({super.key, required this.showAmounts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);

    // Calculer la répartition par productType (somme des quantités)
    final realEstateCount = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'real_estate_rental'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    final loanCount = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'loan_income'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    final factoringCount = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'factoring_profitshare'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    final totalCount = realEstateCount + loanCount + factoringCount;

    return Stack(
      children: [
        UIUtils.buildCard(
          S.of(context).tokens,
          Icons.token_outlined,
          UIUtils.buildValueBeforeText(context, dataManager.totalTokens.toStringAsFixed(2) as String?, S.of(context).totalTokens, isLoading || dataManager.isLoadingMain),
          [
            _buildTokensTable(context, dataManager),
          ],
          dataManager,
          context,
          hasGraph: false, // Ne pas utiliser le graphique dans la carte
        ),
        Positioned(
          top: 30, // Position négative pour remonter le donut
          right: 12, // Alignement à droite
          child: _buildPieChart(realEstateCount, loanCount, factoringCount, totalCount, context),
        ),
      ],
    );
  }

  Widget _buildPieChart(double realEstateCount, double loanCount, double factoringCount, double totalCount, BuildContext context) {
    // Si pas de tokens, afficher un graphique vide
    if (totalCount == 0) {
      return SizedBox(
        width: 120,
        height: 90,
        child: Center(
          child: Icon(
            Icons.token_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    
    // Real Estate (vert)
    if (realEstateCount > 0) {
      sections.add(PieChartSectionData(
        value: realEstateCount,
        color: Colors.green,
        title: '',
        radius: 23,
        gradient: LinearGradient(
          colors: [Colors.green.shade300, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ));
    }
    
    // Loan Income (bleu - couleur du thème)
    if (loanCount > 0) {
      sections.add(PieChartSectionData(
        value: loanCount,
        color: Theme.of(context).primaryColor,
        title: '',
        radius: 23,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ));
    }
    
    // Factoring (orange)
    if (factoringCount > 0) {
      sections.add(PieChartSectionData(
        value: factoringCount,
        color: Colors.orange,
        title: '',
        radius: 23,
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ));
    }

    return SizedBox(
      width: 120,
      height: 90,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          sections: sections,
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 23,
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildTokensTable(BuildContext context, DataManager dataManager) {
    // Calculer la somme des quantités par productType et source
    final walletRealEstate = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'real_estate_rental' && 
      token['source'] == 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    
    final walletLoan = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'loan_income' && 
      token['source'] == 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    
    final walletFactoring = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'factoring_profitshare' && 
      token['source'] == 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    
    final rmmRealEstate = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'real_estate_rental' && 
      token['source'] != 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    
    final rmmLoan = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'loan_income' && 
      token['source'] != 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));
    
    final rmmFactoring = dataManager.portfolio.where((token) => 
      (token['productType'] ?? '').toLowerCase() == 'factoring_profitshare' && 
      token['source'] != 'wallet'
    ).fold<double>(0.0, (sum, token) => sum + ((token['amount'] as num?)?.toDouble() ?? 0.0));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 130), // Laisser de l'espace pour le donut (120px + 10px marge)
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(30), // Colonne icône
          1: FlexColumnWidth(1),   // Colonne Wallet
          2: FlexColumnWidth(1),   // Colonne RMM
        },
        children: [
          // Ligne d'en-tête
          TableRow(
            children: [
              const SizedBox(), // Espace vide pour la colonne icône
              _buildHeaderCell(S.of(context).wallet, context),
              _buildHeaderCell(S.of(context).rmm, context),
            ],
          ),
          // Ligne Real Estate
          TableRow(
            children: [
              _buildIconCell(Icons.home_outlined, _getRealEstateTableColor(), context),
              _buildValueCell(walletRealEstate, _getRealEstateTableColor(), context),
              _buildValueCell(rmmRealEstate, _getRealEstateTableColor(), context),
            ],
          ),
          // Ligne Loan
          TableRow(
            children: [
              _buildIconCell(Icons.account_balance_outlined, _getLoanTableColor(), context),
              _buildValueCell(walletLoan, _getLoanTableColor(), context),
              _buildValueCell(rmmLoan, _getLoanTableColor(), context),
            ],
          ),
          // Ligne Factoring
          TableRow(
            children: [
              _buildIconCell(Icons.business_center_outlined, _getFactoringTableColor(), context),
              _buildValueCell(walletFactoring, _getFactoringTableColor(), context),
              _buildValueCell(rmmFactoring, _getFactoringTableColor(), context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              color: Theme.of(context).brightness == Brightness.light 
                ? Colors.black54 
                : Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          color: Theme.of(context).brightness == Brightness.light 
            ? Colors.black87 
            : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDetailCell(String emoji, int count, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset()),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCell(IconData icon, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildValueCell(double count, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Text(
        count.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 12 + Provider.of<AppState>(context, listen: false).getTextSizeOffset(),
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Panel de couleurs spécifiques pour le tableau (différentes des cartes)
  Color _getRealEstateTableColor() {
    return Colors.teal.shade600; // Bleu-vert au lieu du vert des cartes
  }

  Color _getLoanTableColor() {
    return Colors.indigo.shade600; // Indigo au lieu du bleu des cartes
  }

  Color _getFactoringTableColor() {
    return Colors.deepPurple.shade600; // Violet au lieu de l'orange des cartes
  }
}
