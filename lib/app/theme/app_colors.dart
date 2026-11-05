import 'package:flutter/material.dart';

/// ألوان الهوية الثابتة — القسم 6 في وثيقة التحليل.
abstract final class BrandColors {
  static const primary = Color(0xFF246BFE);
  static const primaryDark = Color(0xFF123B8A);
  static const background = Color(0xFFF5F8FF);
  static const white = Color(0xFFFFFFFF);
}

/// رموز الألوان (Tokens) للوضعين الفاتح والداكن.
///
/// تُقرأ من الثيم عبر `context.palette` حتى تتبدل مع مظهر التطبيق.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
  });

  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;

  static const light = AppPalette(
    primary: BrandColors.primary,
    primaryDark: BrandColors.primaryDark,
    primarySoft: Color(0xFFE5EEFF),
    background: BrandColors.background,
    surface: BrandColors.white,
    surfaceMuted: Color(0xFFEEF3FC),
    textPrimary: Color(0xFF162036),
    textSecondary: Color(0xFF66728A),
    border: Color(0xFFE1E8F4),
    success: Color(0xFF16845B),
    successSoft: Color(0xFFE3F3EC),
    warning: Color(0xFFB96A12),
    warningSoft: Color(0xFFFBEFE0),
    error: Color(0xFFC63D4F),
    errorSoft: Color(0xFFFBE7EA),
  );

  static const dark = AppPalette(
    primary: Color(0xFF6A9BFF),
    primaryDark: Color(0xFFB9CFFF),
    primarySoft: Color(0xFF1C2C52),
    background: Color(0xFF0E1524),
    surface: Color(0xFF161F33),
    surfaceMuted: Color(0xFF1D2740),
    textPrimary: Color(0xFFE8EDF7),
    textSecondary: Color(0xFF9AA6BD),
    border: Color(0xFF26324D),
    success: Color(0xFF4CC495),
    successSoft: Color(0xFF15372B),
    warning: Color(0xFFE7A659),
    warningSoft: Color(0xFF3A2A16),
    error: Color(0xFFF07A8A),
    errorSoft: Color(0xFF3D1C23),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      primarySoft: l(primarySoft, other.primarySoft),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      border: l(border, other.border),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
