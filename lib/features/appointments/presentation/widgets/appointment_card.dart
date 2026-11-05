import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../data/appointment_model.dart';

/// حالة الموعد المعروضة — النص ظاهر دائماً ولا يُكتفى باللون.
enum AppointmentBadge { scheduled, overdue, completed }

AppointmentBadge badgeOf(Appointment a, DateTime now) => a.isCompleted
    ? AppointmentBadge.completed
    : a.isOverdue(now)
        ? AppointmentBadge.overdue
        : AppointmentBadge.scheduled;

class StatusChip extends StatelessWidget {
  const StatusChip(this.badge, {super.key});

  final AppointmentBadge badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, background, foreground, icon) = switch (badge) {
      AppointmentBadge.scheduled => ('مجدول', p.primarySoft, p.primary, Icons.schedule_rounded),
      AppointmentBadge.overdue => ('فات وقته', p.warningSoft, p.warning, Icons.history_rounded),
      AppointmentBadge.completed => ('مكتمل', p.successSoft, p.success, Icons.check_circle_rounded),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.style(12, FontWeight.w600, color: foreground)),
        ],
      ),
    );
  }
}

/// بطاقة موعد في القوائم: الوقت في مربع جانبي، ثم العنوان واليوم والتذكير.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onToggleComplete,
    this.showDay = true,
  });

  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

  /// إخفاء اسم اليوم داخل قائمة «اليوم».
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = appointment;
    final badge = badgeOf(a, DateTime.now());
    final accent = switch (badge) {
      AppointmentBadge.scheduled => p.primary,
      AppointmentBadge.overdue => p.warning,
      AppointmentBadge.completed => p.success,
    };
    final done = a.isCompleted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 0, 12),
                child: Container(
                  width: 78,
                  decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.clock(a.startAt),
                        style: context.text.time.copyWith(color: done ? p.textSecondary : p.primary),
                      ),
                      Text(DateFormatter.period(a.startAt), style: context.text.caption),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        a.title,
                        style: context.text.cardTitle.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: p.textSecondary,
                          color: done ? p.textSecondary : p.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (showDay)
                            Flexible(
                              child: Text(
                                DateFormatter.relativeDay(a.startAt),
                                style: context.text.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (showDay && a.hasReminder) const SizedBox(width: 8),
                          if (a.hasReminder && !done)
                            Icon(Icons.notifications_active_rounded, size: 14, color: p.textSecondary),
                        ],
                      ),
                      if (badge != AppointmentBadge.scheduled) ...[
                        const SizedBox(height: 6),
                        StatusChip(badge),
                      ],
                    ],
                  ),
                ),
              ),
              if (onToggleComplete != null)
                Center(
                  child: IconButton(
                    tooltip: done ? 'إلغاء الإكمال' : 'تحديد كمكتمل',
                    onPressed: onToggleComplete,
                    icon: Icon(
                      done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: done ? p.success : p.border,
                      size: 28,
                    ),
                  ),
                ),
              Container(width: 4, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
