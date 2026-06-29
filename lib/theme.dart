import 'package:flutter/material.dart';

/// A simple Material 3 theme with an indigo seed color.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
