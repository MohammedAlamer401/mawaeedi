import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/settings/data/settings_repository.dart';

/// صورة المستخدم كما في «نسبتي»: دائرة ناعمة بالحرف الأول من الاسم.
class CurrentUserAvatar extends ConsumerWidget {
  const CurrentUserAvatar({super.key, this.radius = 24});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final name = ref.watch(settingsProvider.select((s) => s.firstName));
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.primarySoft,
      child: name == null
          ? Icon(Icons.person_rounded, color: p.primary, size: radius)
          : Text(
              name.characters.first,
              style: AppTextStyles.style(radius * 0.85, FontWeight.w700, color: p.primary, height: 1.2),
            ),
    );
  }
}
