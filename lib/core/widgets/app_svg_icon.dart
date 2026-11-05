import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// مسارات أيقونات SVG الخاصة بالتطبيق (assets/icons، شبكة 64×64).
abstract final class AppSvgIcons {
  static const _base = 'assets/icons';

  static const home = '$_base/home.svg';
  static const calendar = '$_base/calendar.svg';
  static const settings = '$_base/settings.svg';
  static const add = '$_base/add.svg';
  static const clock = '$_base/clock.svg';
  static const bell = '$_base/bell.svg';
  static const check = '$_base/check.svg';
  static const edit = '$_base/edit.svg';
  static const delete = '$_base/delete.svg';
  static const theme = '$_base/theme.svg';
  static const info = '$_base/info.svg';
  static const alarm = '$_base/alarm.svg';
  static const profile = '$_base/profile.svg';
}

/// أيقونة SVG بألوانها الأصلية، والحالة غير النشطة تُعرض رمادية ([muted]).
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.asset, {super.key, this.size = 24, this.muted = false, this.semanticLabel});

  final String asset;
  final double size;
  final bool muted;
  final String? semanticLabel;

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    return muted ? ColorFiltered(colorFilter: _grayscale, child: icon) : icon;
  }
}

/// شعار التطبيق (أيقونة مواعيدي).
class MawaeediLogo extends StatelessWidget {
  const MawaeediLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/brand/app_icon.svg', width: size, height: size, semanticsLabel: 'مواعيدي');
  }
}
