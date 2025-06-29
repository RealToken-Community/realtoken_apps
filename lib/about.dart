import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/info_card_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final textSizeOffset =
        Provider.of<AppState>(context, listen: false).getTextSizeOffset();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          S.of(context).about,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 +
                Provider.of<AppState>(context, listen: false)
                    .getTextSizeOffset(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListView(
            children: <Widget>[
              // Section Application
              InfoCardWidgets.buildSectionHeader(
                context,
                S.of(context).application,
                textSizeOffset,
              ),

              InfoCardWidgets.buildInfoCard(
                context,
                icon: CupertinoIcons.info_circle,
                title: "Name",
                subtitle: S.of(context).appName,
                textSizeOffset: textSizeOffset,
              ),

              FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  return InfoCardWidgets.buildInfoCard(
                    context,
                    icon: CupertinoIcons.checkmark_seal,
                    title: S.of(context).version,
                    subtitle: snapshot.data ?? 'Chargement...',
                    textSizeOffset: textSizeOffset,
                  );
                },
              ),

              InfoCardWidgets.buildInfoCard(
                context,
                icon: CupertinoIcons.person,
                title: S.of(context).author,
                subtitle: 'Byackee',
                textSizeOffset: textSizeOffset,
                linkUrl: 'https://linktr.ee/byackee',
              ),

              InfoCardWidgets.buildLinkCard(
                context,
                title: 'Linktree',
                url: 'https://linktr.ee/byackee',
                textSizeOffset: textSizeOffset,
                icon: CupertinoIcons.link,
              ),

              const Divider(height: 1),

              // Section Remerciements
              InfoCardWidgets.buildSectionHeader(
                context,
                S.of(context).thanks,
                textSizeOffset,
              ),

              InfoCardWidgets.buildThanksCard(
                context,
                title: S.of(context).thankYouMessage,
                subtitle: S.of(context).specialThanks,
                textSizeOffset: textSizeOffset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
