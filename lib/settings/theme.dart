import 'package:flutter/material.dart';

ThemeData getLightTheme(Color primaryColor) {
  return ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[100],
    cardColor: Colors.white,
    secondaryHeaderColor: Colors.grey[300],
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.grey[750]),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0.5,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white),
  );
}

ThemeData getDarkTheme(Color primaryColor) {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    secondaryHeaderColor: Color.fromARGB(255, 78, 78, 78).withValues(alpha: 0.4),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey[400]),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      elevation: 0.5,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey[900],
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.black),
  );
}
