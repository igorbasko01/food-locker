import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.teal,
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.teal,
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    elevation: 8,
  ),
);
