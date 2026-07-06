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
      surfaceTint: Colors.transparent,
      outline: ApexColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ApexColors.paper,
      dialogTheme: const DialogThemeData(
        backgroundColor: ApexColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ApexRadius.lg)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ApexColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: ApexColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
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
        filled: true,
        fillColor: ApexColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ApexSpacing.md,
          vertical: ApexSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexRadius.sm),
          borderSide: const BorderSide(color: ApexColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexRadius.sm),
          borderSide: const BorderSide(color: ApexColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexRadius.sm),
          borderSide: const BorderSide(color: ApexColors.trackRed, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ApexColors.surface,
        indicatorColor: Color(0xFFFFE0DE),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
    );
  }
}
