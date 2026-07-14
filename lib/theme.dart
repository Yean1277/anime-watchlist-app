import 'package:flutter/material.dart';

/// 宵 / YOI design tokens — a dark-only "soft Japanese" system: matcha accent on
/// ink surfaces, big rounded shapes, a single easing curve. See the design spec
/// (§1 + §5.2). Everything visual routes through these tokens — never hard-code
/// a color, radius, or duration.

// ─────────────────────────────────────────────────────────── color ──
class AppColor {
  AppColor._();

  static const bg = Color(0xFF15171A); // 墨 sumi — app background
  static const surface = Color(0xFF1E2126); // 消炭 keshizumi — card
  static const surfaceRaised = Color(0xFF272B31); // 薄墨 usumi — raised
  static const accent = Color(0xFFB9D4A0); // 抹茶 matcha — accent
  static const accentHi = Color(0xFFC9E0AE); // gradient start
  static const accentLo = Color(0xFFAFCB95); // gradient end
  static const onAccent = Color(0xFF171B16); // ink on matcha/sakura
  static const secondary = Color(0xFFE8B0B4); // 桜 sakura — new / favorite
  static const text = Color(0xFFECEDE8); // 白練 shironeri
  static const textMuted = Color(0xFF8C918B); // 鼠 nezumi
  static const border = Color(0x14ECEDE8); // 8% hairline
  static const track = Color(0x17ECEDE8); // 9% progress track
  static const slotEmpty = Color(0x12ECEDE8); // 7% empty episode cell
  static const scrim = Color(0x8015171A); // 50% ink — on-cover buttons

  /// hero card / 達成率 card fill — fixed 160° matcha gradient.
  static const accentGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [accentHi, accentLo],
  );

  /// Matcha glow used instead of shadow-elevation on accent surfaces.
  static List<BoxShadow> get accentGlow => const [
        BoxShadow(
          color: Color(0x8CB9D4A0),
          blurRadius: 44,
          spreadRadius: -26,
          offset: Offset(0, 22),
        ),
      ];

  /// CTA button glow (tighter than [accentGlow]).
  static List<BoxShadow> get ctaGlow => const [
        BoxShadow(
          color: Color(0xB3B9D4A0),
          blurRadius: 30,
          spreadRadius: -16,
          offset: Offset(0, 14),
        ),
      ];
}

// ────────────────────────────────────────────────────────── radius ──
class AppRadius {
  AppRadius._();
  static const double xs = 8; // episode cell
  static const double sm = 12; // cover thumb
  static const double md = 18; // show card
  static const double lg = 26; // hero / progress card
  static const double xl = 34; // bottom sheet
  static const double full = 999; // chip / pill / avatar
}

// ─────────────────────────────────────────────────────────── space ──
class AppSpace {
  AppSpace._();
  static const double screenX = 16; // screen left/right padding
  static const double cardGap = 10; // gap between show cards
}

// ────────────────────────────────────────────────────────── motion ──
class AppMotion {
  AppMotion._();
  static const curve = Cubic(0.2, 0.8, 0.2, 1.0); // the one and only curve
  static const press = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 340);
  static const bar = Duration(milliseconds: 550);
  static const ring = Duration(milliseconds: 800);
  static const ripple = Duration(milliseconds: 750);
  static const float = Duration(milliseconds: 1000);
}

// ─────────────────────────────────────────────────────────── type ──
const _jp = 'ZenMaruGothic'; // titles + all JP/CJK — "the source of soft"
const _num = 'Outfit'; // numbers + english labels only
const List<String> _fallback = ['NotoSansTC', 'Inter'];

class AppText {
  AppText._();

  static const display = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 21,
      fontWeight: FontWeight.w900,
      letterSpacing: .42,
      height: 1.30,
      color: AppColor.text);
  static const titleL = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 17,
      fontWeight: FontWeight.w900,
      letterSpacing: .34,
      height: 1.35,
      color: AppColor.text);
  static const titleM = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: .45,
      height: 1.40,
      color: AppColor.text);
  static const titleS = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: .28,
      height: 1.40,
      color: AppColor.text);
  static const body = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 12,
      height: 1.60,
      color: AppColor.text);
  static const caption = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 11,
      height: 1.50,
      color: AppColor.textMuted);

  /// Furigana — the identity mark. 8px, wide .32em tracking, muted. Decorative
  /// only: never the sole carrier of essential information (spec §1.2).
  static const furigana = TextStyle(
      fontFamily: _jp,
      fontFamilyFallback: _fallback,
      fontSize: 8,
      letterSpacing: 2.56, // 8 × .32em
      height: 1.0,
      color: AppColor.textMuted);

  static const numXL = TextStyle(
      fontFamily: _num,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -.38,
      height: 1.0,
      color: AppColor.text);
  static const numM = TextStyle(
      fontFamily: _num,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -.30,
      height: 1.0,
      color: AppColor.text);
  static const numS = TextStyle(
      fontFamily: _num,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: AppColor.text);
  static const label = TextStyle(
      fontFamily: _num,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: .40,
      height: 1.0,
      color: AppColor.textMuted);
}

// ─────────────────────────────────────────────────────────── theme ──
/// The single YOI theme. Dark only — there is no light variant by design.
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColor.bg,
    fontFamily: _jp,
    colorScheme: const ColorScheme.dark(
      surface: AppColor.bg,
      onSurface: AppColor.text,
      onSurfaceVariant: AppColor.textMuted,
      primary: AppColor.accent,
      onPrimary: AppColor.onAccent,
      secondary: AppColor.secondary,
      onSecondary: AppColor.onAccent,
      error: Color(0xFFD19A9E),
    ),
    // Custom ripple/press feedback (Pressable) replaces Material splash.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: AppText.display.copyWith(fontSize: 24, letterSpacing: .48),
      titleLarge: AppText.titleL,
      titleMedium: AppText.titleM,
      titleSmall: AppText.titleS,
      bodyMedium: AppText.body,
      bodySmall: AppText.caption,
      labelSmall: AppText.label,
    ),
  );
}
