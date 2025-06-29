import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/utils/text_utils.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';

Widget buildOthersTab(BuildContext context, Map<String, dynamic> token) {
  final appState = Provider.of<AppState>(context, listen: false);
  final dataManager = Provider.of<DataManager>(context, listen: false);
  // Vérifier si le token est whitelisté
  final bool isWhitelisted = dataManager.whitelistTokens.any(
    (w) => w['token'].toLowerCase() == token['uuid'].toLowerCase(),
  );
  // Vérifier si le token est présent dans le portefeuille
  final bool isInWallet = dataManager.portfolio.any(
    (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase(),
  );

  // Récupération de l'élément du portfolio correspondant à ce token (s'il existe)
  final portfolioItem = dataManager.portfolio.firstWhere(
    (p) => p['uuid'].toLowerCase() == token['uuid'].toLowerCase(),
    orElse: () => <String, dynamic>{},
  );
  // Extraction des wallets pour ce token, s'ils existent
  List<String> tokenWallets = [];
  if (portfolioItem.isNotEmpty && portfolioItem.containsKey('wallets')) {
    tokenWallets = List<String>.from(portfolioItem['wallets']);
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Blockchain
        _buildSectionCard(
          context,
          title: S.of(context).blockchain,
          children: [
            // Contrat Ethereum
            _buildContractRow(
              context,
              icon: 'assets/ethereum.png',
              label: S.of(context).ethereumContract,
              address: token['ethereumContract'] ?? S.of(context).notSpecified,
              onTap: () {
                final ethereumAddress = token['ethereumContract'] ?? '';
                if (ethereumAddress.isNotEmpty) {
                  UrlUtils.launchURL(
                      'https://etherscan.io/address/$ethereumAddress');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).notSpecified),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),

            const Divider(height: 1, thickness: 0.5),

            // Contrat Gnosis
            _buildContractRow(
              context,
              icon: 'assets/gnosis.png',
              label: S.of(context).gnosisContract,
              address: token['gnosisContract'] ?? S.of(context).notSpecified,
              onTap: () {
                final gnosisAddress = token['gnosisContract'] ?? '';
                if (gnosisAddress.isNotEmpty) {
                  UrlUtils.launchURL(
                      'https://gnosisscan.io/address/$gnosisAddress');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).notSpecified),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section Whitelist et status
        _buildSectionCard(
          context,
          title: S.of(context).other,
          children: [
            _buildStatusRow(
              context,
              icon: isWhitelisted ? Icons.check_circle : Icons.cancel,
              iconColor: isWhitelisted ? Colors.green : Colors.red,
              label: isWhitelisted
                  ? S.of(context).tokenWhitelisted
                  : S.of(context).tokenNotWhitelisted,
              textColor: isWhitelisted ? Colors.green : Colors.red,
            ),
            const Divider(height: 1, thickness: 0.5),
            _buildStatusRow(
              context,
              icon: isInWallet
                  ? Icons.account_balance_wallet
                  : Icons.account_balance_wallet_outlined,
              iconColor: isInWallet ? Colors.green : Colors.red,
              label: isInWallet
                  ? S.of(context).presentInWallet
                  : S.of(context).filterNotInWallet,
              textColor: isInWallet ? Colors.green : Colors.red,
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Section wallets
        _buildSectionCard(
          context,
          title: S.of(context).walletsContainingToken,
          children: tokenWallets.isNotEmpty
              ? tokenWallets.map((walletAddress) {
                  return Column(
                    children: [
                      _buildWalletRow(
                        context,
                        walletAddress: walletAddress,
                        showFull: appState.showAmounts,
                      ),
                      if (tokenWallets.last != walletAddress)
                        const Divider(height: 1, thickness: 0.5),
                    ],
                  );
                }).toList()
              : [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        S.of(context).notSpecified,
                        style: TextStyle(
                          fontSize: 14 + appState.getTextSizeOffset(),
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ],
        ),
      ],
    ),
  );
}

// Widget pour construire une section avec titre, comme dans property_tab.dart
Widget _buildSectionCard(BuildContext context,
    {required String title, required List<Widget> children}) {
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

// Widget pour les lignes de contrat
Widget _buildContractRow(
  BuildContext context, {
  required String icon,
  required String label,
  required String address,
  required Function() onTap,
}) {
  final appState = Provider.of<AppState>(context, listen: false);

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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    icon,
                    width: 20,
                    height: 20,
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
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            address,
            style: TextStyle(
              fontSize: 12 + appState.getTextSizeOffset(),
              fontFamily: 'Menlo', // Police monospace style iOS
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// Widget pour les lignes de statut
Widget _buildStatusRow(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String label,
  required Color textColor,
}) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14 + appState.getTextSizeOffset(),
            fontWeight: FontWeight.w300,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

// Widget pour les lignes de wallet
Widget _buildWalletRow(
  BuildContext context, {
  required String walletAddress,
  required bool showFull,
}) {
  final appState = Provider.of<AppState>(context, listen: false);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 18,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Option: Copier l'adresse au presse-papier
              // Clipboard.setData(ClipboardData(text: walletAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Adresse copiée'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                showFull
                    ? walletAddress
                    : TextUtils.truncateWallet(walletAddress),
                style: TextStyle(
                  fontSize: 12 + appState.getTextSizeOffset(),
                  fontFamily: 'Menlo', // Police monospace style iOS
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
