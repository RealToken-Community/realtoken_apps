import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<SupportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Support',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 +
                Provider.of<AppState>(context, listen: false)
                    .getTextSizeOffset(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIOSStyleCard(
                  context,
                  'GitHub support',
                  CupertinoIcons.globe,
                  'Contribuez ou signalez un problème sur GitHub :',
                  'Github isssues link',
                  'https://github.com/RealToken-Community/realtoken_apps/issues',
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset(),
                  iconColor: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 14),
                _buildIOSStyleCard(
                  context,
                  'Telegram support',
                  CupertinoIcons.paperplane_fill,
                  'Rejoignez-nous sur Telegram :',
                  'Telegram Link here',
                  'https://t.me/+ae_vCmnjg5JjNWQ0',
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset(),
                  iconColor: const Color(0xFF0088CC),
                ),
                const SizedBox(height: 14),
                _buildIOSStyleCard(
                  context,
                  'Discord support',
                  CupertinoIcons.chat_bubble_2_fill,
                  'Rejoignez-nous sur Discord :',
                  'Discord Link here',
                  'https://discord.com/channels/681940057183092737/681966628527013891',
                  Provider.of<AppState>(context, listen: false)
                      .getTextSizeOffset(),
                  iconColor: CupertinoColors.systemPurple,
                ),
                const SizedBox(height: 14),
                _buildDonationCard(context, appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSStyleCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    String linkText,
    String linkUrl,
    double textSizeOffset, {
    Color iconColor = CupertinoColors.systemBlue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => UrlUtils.launchURL(linkUrl),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
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
                      description,
                      style: TextStyle(
                        fontSize: 14 + textSizeOffset,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            linkText,
                            style: TextStyle(
                              fontSize: 14 + textSizeOffset,
                              color: CupertinoColors.systemBlue
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen
                        .resolveFrom(context)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.money_dollar_circle,
                    color: CupertinoColors.systemGreen.resolveFrom(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  S.of(context).supportProject,
                  style: TextStyle(
                    fontSize: 17,
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
                S.of(context).donationMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkTreeButton(
                context,
                Provider.of<AppState>(context, listen: false)
                    .getTextSizeOffset()),
            const SizedBox(height: 16),
            if (kIsWeb || (!kIsWeb && !Platform.isIOS))
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    _buildDonationButton(
                      context,
                      'PayPal',
                      CupertinoIcons.money_dollar,
                      CupertinoColors.systemBlue,
                      () => UrlUtils.launchURL(
                          'https://paypal.me/byackee?country.x=FR&locale.x=fr_FR'),
                      appState.getTextSizeOffset(),
                    ),
                    _buildDonationButton(
                      context,
                      'Buy Coffee',
                      CupertinoIcons.gift,
                      CupertinoColors.systemBrown,
                      () => UrlUtils.launchURL(
                          'https://buymeacoffee.com/byackee'),
                      appState.getTextSizeOffset(),
                      isImage: true,
                      imagePath: 'assets/bmc.png',
                    ),
                    _buildDonationButton(
                      context,
                      S.of(context).crypto,
                      CupertinoIcons.bitcoin,
                      CupertinoColors.systemOrange,
                      () => _showIOSCryptoAddressDialog(
                          context,
                          Provider.of<AppState>(context, listen: false)
                              .getTextSizeOffset()),
                      appState.getTextSizeOffset(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTreeButton(BuildContext context, double textSizeOffset) {
    return GestureDetector(
      onTap: () => UrlUtils.launchURL('https://linktr.ee/byackee'),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.link,
                color: CupertinoColors.systemBlue.resolveFrom(context),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'My linktree',
                style: TextStyle(
                  fontSize: 14 + textSizeOffset,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
    double textSizeOffset, {
    bool isImage = false,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage && imagePath != null)
              Image.asset(
                imagePath,
                height: 20,
                width: 20,
              )
            else
              Icon(
                icon,
                color: CupertinoColors.white,
                size: 18,
              ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14 + textSizeOffset,
                color: CupertinoColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIOSCryptoAddressDialog(
      BuildContext context, double textSizeOffset) {
    const cryptoAddress = '0xdc30b07aebaef3f15544a3801c6cb0f35f0118fc';

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            S.of(context).cryptoDonationAddress,
            style: TextStyle(
              fontSize: 15 + textSizeOffset,
              fontWeight: FontWeight.w600,
            ),
          ),
          message: Column(
            children: [
              Text(
                S.of(context).sendDonations,
                style: TextStyle(
                  fontSize: 14 + textSizeOffset,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  cryptoAddress,
                  style: TextStyle(
                    fontSize: 14 + textSizeOffset,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Menlo',
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: cryptoAddress));
                Navigator.of(context).pop();
                showCupertinoSnackBar(
                  context: context,
                  message: S.of(context).addressCopied,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_on_clipboard,
                    color: CupertinoColors.systemBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).copy,
                    style: TextStyle(fontSize: 16 + textSizeOffset),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              S.of(context).close,
              style: TextStyle(fontSize: 16 + textSizeOffset),
            ),
          ),
        );
      },
    );
  }

  void showCupertinoSnackBar(
      {required BuildContext context, required String message}) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2)).then((_) {
      overlayEntry.remove();
    });
  }
}
