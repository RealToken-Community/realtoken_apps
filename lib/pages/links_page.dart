import 'package:realtoken_asset_tracker/managers/data_manager.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/utils/url_utils.dart';
import 'package:realtoken_asset_tracker/app_state.dart';

class LinksPage extends StatefulWidget {
  const LinksPage({super.key});

  @override
  RealtPageState createState() => RealtPageState();
}

class RealtPageState extends State<LinksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataManager>(context, listen: false).fetchAndStoreAllTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Links',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17 + Provider.of<AppState>(context).getTextSizeOffset(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIOSStyleCard(
                  'assets/icons/RMM.jpg',
                  'RMM (RealToken Money Market)',
                  'https://rmm.realtoken.network',
                  S.of(context).rmm_description,
                ),
                const SizedBox(height: 14),
                _buildIOSStyleCard(
                  'assets/icons/YAM.jpg',
                  'YAM (You And Me)',
                  'https://yam.realtoken.network',
                  S.of(context).rmm_description,
                ),
                const SizedBox(height: 14),
                _buildIOSStyleCard(
                  'assets/logo_community.png',
                  'Wiki Community',
                  'https://community-realt.gitbook.io/tuto-community',
                  S.of(context).wiki_community_description,
                ),
                const SizedBox(height: 14),
                _buildIOSStyleCard(
                  'assets/DAO.png',
                  'RealToken governance Forum',
                  'https://forum.realtoken.community',
                  S.of(context).dao_description,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSStyleCard(
    String imagePath,
    String linkText,
    String linkUrl,
    String description,
  ) {
    return GestureDetector(
      onTap: () => UrlUtils.launchURL(linkUrl),
      child: Container(
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            linkText,
                            style: TextStyle(
                              fontSize: 16 + Provider.of<AppState>(context).getTextSizeOffset(),
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemBlue.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14 + Provider.of<AppState>(context).getTextSizeOffset(),
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
          ),
        ),
      ),
    );
  }
}
