import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtoken_asset_tracker/app_state.dart';
import 'package:realtoken_asset_tracker/components/donation_widgets.dart';

class DonationCardWidget extends StatelessWidget {
  final String? montantWallet;
  final bool isLoading;

  const DonationCardWidget(
      {super.key, this.montantWallet, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: DonationWidgets.buildCompleteSection(
        context: context,
        appState: appState,
        amount: montantWallet,
        isLoading: isLoading,
      ),
    );
  }
}
