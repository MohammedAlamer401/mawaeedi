import 'package:flutter/material.dart';

import 'app_colors.dart';

/// أنماط النص.
///
/// خط Cairo مضمَّن كخط متغيّر (Variable Font)، لذا يجب تمرير محور الوزن
/// `wght` صراحةً مع كل [FontWeight] وإلا يُرسم بالوزن الافتراضي.
abstract final class AppTextStyles {
  static const fontFamily = 'Cairo';

  static TextStyle style(double size, FontWeight weight, {Color? color, double height = 1.5}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      color: color,
      height: height,
    );
  }

  /// أرقام جدولية حتى تصطف الأوقات في القوائم.
  static TextStyle tabular(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextTheme textTheme(AppPalette p) {
    return TextTheme(
      displayLarge: style(48, FontWeight.w700, color: p.textPrimary),
      displayMedium: style(40, FontWeight.w700, color: p.textPrimary),
      displaySmall: style(32, FontWeight.w700, color: p.textPrimary),
      headlineLarge: style(28, FontWeight.w600, color: p.textPrimary),
      headlineMedium: style(24, FontWeight.w600, color: p.textPrimary),
      headlineSmall: style(22, FontWeight.w600, color: p.textPrimary),
      titleLarge: style(20, FontWeight.w600, color: p.textPrimary),
      titleMedium: style(16, FontWeight.w600, color: p.textPrimary),
      titleSmall: style(14, FontWeight.w600, color: p.textPrimary),
      bodyLarge: style(16, FontWeight.w400, color: p.textPrimary),
      bodyMedium: style(15, FontWeight.w400, color: p.textPrimary),
      bodySmall: style(13, FontWeight.w400, color: p.textSecondary),
      labelLarge: style(15, FontWeight.w600, color: p.textPrimary),
      labelMedium: style(13, FontWeight.w500, color: p.textPrimary),
      labelSmall: style(12, FontWeight.w500, color: p.textPrimary),
    );
  }
}

/// أنماط النص الملوّنة حسب مظهر التطبيق الحالي.
class AppText {
  const AppText(this.p);

  final AppPalette p;

  TextStyle get screenTitle => AppTextStyles.style(22, FontWeight.w600, color: p.textPrimary);
  TextStyle get cardTitle => AppTextStyles.style(15, FontWeight.w600, color: p.textPrimary);
  TextStyle get body => AppTextStyles.style(15, FontWeight.w400, color: p.textPrimary);
  TextStyle get label => AppTextStyles.style(14, FontWeight.w500, color: p.textPrimary);
  TextStyle get labelMuted => AppTextStyles.style(14, FontWeight.w500, color: p.textSecondary);
  TextStyle get caption => AppTextStyles.style(12.5, FontWeight.w400, color: p.textSecondary);
  TextStyle get time => AppTextStyles.tabular(AppTextStyles.style(18, FontWeight.w700, color: p.primary, height: 1.2));
  TextStyle get countLarge =>
      AppTextStyles.tabular(AppTextStyles.style(44, FontWeight.w800, color: Colors.white, height: 1.1));
}

extension AppTextContext on BuildContext {
  AppText get text => AppText(palette);
}
