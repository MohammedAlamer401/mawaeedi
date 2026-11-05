import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// بطاقة ملخص كما في «نسبتي»: عنوان صغير بأيقونة، وقيمة واضحة، ووصف اختياري.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accent,
    this.large = false,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = accent ?? p.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(title, style: context.text.labelMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.tabular(AppTextStyles.style(
                  large ? 32 : 20,
                  FontWeight.w700,
                  color: large ? p.textPrimary : color,
                  height: 1.25,
                )),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: context.text.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط تنبيه داخل التطبيق بلون ناعم (مثل «غير محصّل حتى الآن» في «نسبتي»).
class NoticeStrip extends StatelessWidget {
  const NoticeStrip({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: context.text.label.copyWith(color: foreground))),
              if (trailing != null)
                Text(trailing!, style: AppTextStyles.tabular(context.text.cardTitle.copyWith(color: foreground))),
              if (onTap != null) Icon(Icons.chevron_left_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
