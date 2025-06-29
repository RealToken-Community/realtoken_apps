import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/currency_utils.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'dart:ui';

class WalletPopupWidget extends StatelessWidget {
  const WalletPopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyUtils = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final dataManager = Provider.of<DataManager>(context, listen: false);

    final List<Map<String, dynamic>> walletDetails =
        dataManager.perWalletBalances;
    final bool hasStaking =
        walletDetails.any((wallet) => (wallet['gnosisVaultReg'] ?? 0) > 0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragIndicator(context),
            _buildHeader(context, appState),
            _buildTotalBalanceCard(
                context, appState, currencyUtils, dataManager, hasStaking),
            _buildWalletDetailsHeader(context, appState),
            _buildWalletList(context, walletDetails, currencyUtils, appState),
          ],
        ),
      ),
    );
  }

  Widget _buildDragIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 22 + appState.getTextSizeOffset(),
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            S.of(context).wallet,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18 + appState.getTextSizeOffset(),
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(
      BuildContext context,
      AppState appState,
      CurrencyProvider currencyUtils,
      DataManager dataManager,
      bool hasStaking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).totalBalance,
            style: TextStyle(
              fontSize: 14 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCurrencyBalance(
                  context,
                  appState,
                  currencyUtils,
                  'assets/icons/usdc.png',
                  'USDC',
                  dataManager.gnosisUsdcBalance),
              _buildCurrencyBalance(
                  context,
                  appState,
                  currencyUtils,
                  'assets/icons/xdai.png',
                  'XDAI',
                  dataManager.gnosisXdaiBalance),
              _buildRegBalance(
                  context,
                  appState,
                  'assets/icons/reg.png',
                  'REG',
                  dataManager.gnosisRegBalance +
                      dataManager.gnosisVaultRegBalance,
                  hasStaking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBalance(
      BuildContext context,
      AppState appState,
      CurrencyProvider currencyUtils,
      String iconPath,
      String currency,
      double balance) {
    return Row(
      children: [
        Image.asset(iconPath,
            width: 28 + appState.getTextSizeOffset(),
            height: 28 + appState.getTextSizeOffset()),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: TextStyle(
                fontSize: 12 + appState.getTextSizeOffset(),
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
            Text(
              currencyUtils.formatCurrency(
                  currencyUtils.convert(balance), currencyUtils.currencySymbol),
              style: TextStyle(
                fontSize: 16 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegBalance(BuildContext context, AppState appState,
      String iconPath, String currency, double balance, bool hasStaking) {
    return Row(
      children: [
        Image.asset(iconPath,
            width: 28 + appState.getTextSizeOffset(),
            height: 28 + appState.getTextSizeOffset()),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: TextStyle(
                fontSize: 12 + appState.getTextSizeOffset(),
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
            Row(
              children: [
                Text(
                  balance.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (hasStaking)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.savings,
                      size: 16 + appState.getTextSizeOffset(),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletDetailsHeader(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          S.of(context).walletDetails,
          style: TextStyle(
            fontSize: 16 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletList(
      BuildContext context,
      List<Map<String, dynamic>> walletDetails,
      CurrencyProvider currencyUtils,
      AppState appState) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: walletDetails.length,
        itemBuilder: (context, index) => WalletItemWidget(
          walletInfo: walletDetails[index],
          currencyUtils: currencyUtils,
          appState: appState,
        ),
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }
}

class WalletItemWidget extends StatelessWidget {
  final Map<String, dynamic> walletInfo;
  final CurrencyProvider currencyUtils;
  final AppState appState;

  const WalletItemWidget({
    super.key,
    required this.walletInfo,
    required this.currencyUtils,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final String truncated = _truncateAddress(walletInfo['address']);
    final double gnosisReg = walletInfo['gnosisReg'];
    final double gnosisVaultReg = walletInfo['gnosisVaultReg'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletHeader(context, truncated),
            _buildWalletBalances(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHeader(BuildContext context, String truncated) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 14 + appState.getTextSizeOffset(),
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            truncated,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy_rounded,
            size: 14 + appState.getTextSizeOffset(),
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.6),
          ),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: () {
            // Logique pour copier l'adresse
          },
        ),
      ],
    );
  }

  Widget _buildWalletBalances(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCurrencyInfo(context, 'assets/icons/usdc.png', 'USDC',
            _getFormattedAmount('gnosisUsdc')),
        _buildCurrencyInfo(context, 'assets/icons/xdai.png', 'XDAI',
            _getFormattedAmount('gnosisXdai')),
        _buildRegInfo(context),
      ],
    );
  }

  Widget _buildCurrencyInfo(
      BuildContext context, String iconPath, String currency, String amount) {
    return Row(
      children: [
        Image.asset(iconPath,
            width: 20 + appState.getTextSizeOffset(),
            height: 20 + appState.getTextSizeOffset()),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: TextStyle(
                fontSize: 10 + appState.getTextSizeOffset(),
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14 + appState.getTextSizeOffset(),
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegInfo(BuildContext context) {
    final double gnosisReg = walletInfo['gnosisReg'];
    final double gnosisVaultReg = walletInfo['gnosisVaultReg'];
    final String gnosisRegTotal =
        (gnosisReg + gnosisVaultReg).toStringAsFixed(2);

    return Row(
      children: [
        Image.asset('assets/icons/reg.png',
            width: 20 + appState.getTextSizeOffset(),
            height: 20 + appState.getTextSizeOffset()),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "REG",
              style: TextStyle(
                fontSize: 10 + appState.getTextSizeOffset(),
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
            Row(
              children: [
                Text(
                  gnosisRegTotal,
                  style: TextStyle(
                    fontSize: 14 + appState.getTextSizeOffset(),
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (gnosisVaultReg > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.savings,
                      size: 14 + appState.getTextSizeOffset(),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _getFormattedAmount(String key) {
    return currencyUtils.getFormattedAmount(
      currencyUtils.convert(walletInfo[key]),
      currencyUtils.currencySymbol,
      appState.showAmounts,
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }
}
