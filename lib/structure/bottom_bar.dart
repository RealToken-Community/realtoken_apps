import 'package:flutter/material.dart';
import 'package:realtoken_asset_tracker/generated/l10n.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard), label: S.of(context).dashboard),
        BottomNavigationBarItem(
            icon: const Icon(Icons.wallet_rounded),
            label: S.of(context).portfolio),
        BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart), label: S.of(context).analytics),
        BottomNavigationBarItem(
            icon: const Icon(Icons.map), label: S.of(context).maps),
      ],
      currentIndex: selectedIndex,
      elevation: 0,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.transparent,
      type: BottomNavigationBarType.fixed,
      onTap: onItemTapped,
    );
  }
}
