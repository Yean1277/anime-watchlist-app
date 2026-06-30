import 'package:flutter/material.dart';

/// App accent (purple) used across pills, selected nav, and highlights.
const Color kAccent = Color(0xFF6C5CE7);

/// Card background colors, exposed so widgets can match the theme without
/// depending on version-specific CardTheme typing.
const Color kLightCard = Colors.white;
const Color kDarkCard = Color(0xFF1E1E26);

Color cardColorFor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kDarkCard : kLightCard;

/// Builds the light theme used by the redesign — soft grey canvas, bold type.
ThemeData buildLightTheme() {
  const surface = Color(0xFFF4F4F8);
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.light,
  ).copyWith(surface: surface);
  return _common(scheme, scaffold: surface, card: kLightCard);
}

/// Dark counterpart to [buildLightTheme].
ThemeData buildDarkTheme() {
  const surface = Color(0xFF121218);
  final scheme = ColorScheme.fromSeed(
    seedColor: kAccent,
    brightness: Brightness.dark,
  ).copyWith(surface: surface);
  return _common(scheme, scaffold: surface, card: kDarkCard);
}

ThemeData _common(ColorScheme scheme,
    {required Color scaffold, required Color card}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
  );
  return base.copyWith(
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: Colors.transparent,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
  );
}
