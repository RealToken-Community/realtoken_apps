import 'package:flutter/material.dart';

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
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet_rounded), label: 'Portfolio'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistiques'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
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
