import 'package:flutter/material.dart';

class ApexColors {
  const ApexColors._();

  static const Color asphalt = Color(0xFF121417);
  static const Color trackRed = Color(0xFFE53935);
  static const Color signalAmber = Color(0xFFFFB300);
  static const Color grassGreen = Color(0xFF2E7D32);
  static const Color paper = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE5E7EB);
  /// Backdrop behind novice track map illustrations.
  static const Color trackMapBackdropNovice = Color(0xFFF8F8F8);
  /// Backdrop behind experienced track map illustrations.
  static const Color trackMapBackdropExperienced = Color(0xFFE8E8E8);
  /// Backdrop behind loyalty card illustration.
  static const Color loyaltyCardBackdrop = Color(0xFF121417);
}

class ApexSpacing {
  const ApexSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class ApexRadius {
  const ApexRadius._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

class ApexTouchTarget {
  const ApexTouchTarget._();

  static const double min = 44;
}

class ApexButtonStyles {
  const ApexButtonStyles._();

  static ButtonStyle get filledRed => FilledButton.styleFrom(
        backgroundColor: ApexColors.trackRed,
        foregroundColor: Colors.white,
      );

  static ButtonStyle get outlinedRed => OutlinedButton.styleFrom(
        foregroundColor: ApexColors.trackRed,
        side: const BorderSide(color: ApexColors.trackRed),
      );

  static ButtonStyle get textRed => TextButton.styleFrom(
        foregroundColor: ApexColors.trackRed,
      );
}
