import 'package:flutter/material.dart';

import 'apex_tokens.dart';

class ApexTheme {
  const ApexTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ApexColors.trackRed,
      brightness: Brightness.light,
    ).copyWith(
      primary: ApexColors.trackRed,
      secondary: ApexColors.signalAmber,
      surface: ApexColors.surface,
      outline: ApexColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ApexColors.paper,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: ApexColors.paper,
        foregroundColor: ApexColors.asphalt,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ApexColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ApexColors.outline),
          borderRadius: BorderRadius.circular(ApexRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(ApexTouchTarget.min, ApexTouchTarget.min),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ApexRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexRadius.sm),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ApexColors.surface,
        indicatorColor: Color(0xFFFFE0DE),
      ),
    );
  }
}
