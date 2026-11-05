import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/formatting/arabic_plural.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../controllers/appointments_controller.dart';
import '../../data/appointment_model.dart';
import 'appointment_card.dart';

/// إكمال الموعد أو التراجع عنه مع رسالة وزر «تراجع».
Future<void> toggleCompleted(BuildContext context, WidgetRef ref, Appointment a) async {
  final controller = ref.read(appointmentsControllerProvider);
  final completed = !a.isCompleted;
  await controller.setCompleted(a, completed);
  if (!context.mounted) return;
  showAppSnackBar(
    context,
    completed ? 'أحسنت! تم إكمال الموعد' : 'أُعيد الموعد إلى المجدولة',
    action: SnackBarAction(
      label: 'تراجع',
      onPressed: () => controller.setCompleted(a, !completed),
    ),
  );
}

/// حذف الموعد بعد تأكيد واضح، ويُلغى إشعاره معه.
Future<bool> deleteWithConfirm(BuildContext context, WidgetRef ref, Appointment a) async {
  final ok = await showConfirmDialog(
    context,
    title: 'حذف الموعد',
    message: 'سيُحذف «${a.title}» ويُلغى تذكيره. لا يمكن التراجع عن الحذف.',
    confirmLabel: 'حذف',
    destructive: true,
  );
  if (!ok) return false;
  await ref.read(appointmentsControllerProvider).delete(a);
  if (context.mounted) showAppSnackBar(context, 'تم حذف الموعد');
  return true;
}

/// تفاصيل الموعد في لوحة سفلية مع الإجراءات: إكمال، تعديل، حذف.
Future<void> showAppointmentSheet(BuildContext context, Appointment appointment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AppointmentSheet(appointment: appointment, parent: context),
  );
}

class _AppointmentSheet extends ConsumerWidget {
  const _AppointmentSheet({required this.appointment, required this.parent});

  final Appointment appointment;

  /// سياق الشاشة الأصلية؛ يبقى صالحاً بعد إغلاق اللوحة لعرض الرسائل والتنقل.
  final BuildContext parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(a.title, style: context.text.screenTitle.copyWith(fontSize: 20))),
                const SizedBox(width: 8),
                StatusChip(badgeOf(a, DateTime.now())),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: p.surfaceMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _InfoLine(icon: AppSvgIcons.calendar, label: 'التاريخ', value: DateFormatter.full(a.startAt)),
                    _InfoLine(icon: AppSvgIcons.clock, label: 'الوقت', value: DateFormatter.time(a.startAt)),
                    _InfoLine(
                      icon: AppSvgIcons.bell,
                      label: 'التذكير',
                      value: a.reminderMinutes == null ? 'بدون تذكير' : ArabicPlural.reminder(a.reminderMinutes!),
                    ),
                  ],
                ),
              ),
            ),
            if (a.notes != null && a.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('ملاحظات', style: context.text.labelMuted),
              const SizedBox(height: 4),
              Text(a.notes!, style: context.text.body),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await toggleCompleted(parent, ref, a);
              },
              style: a.isCompleted
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: p.success,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? p.background : Colors.white,
                    ),
              icon: Icon(a.isCompleted ? Icons.undo_rounded : Icons.check_rounded),
              label: Text(a.isCompleted ? 'إعادة إلى المجدولة' : 'تحديد كمكتمل'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      parent.push(AppRoutes.editAppointment(a.id!));
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await deleteWithConfirm(parent, ref, a);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: p.error),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: AppSvgIcon(icon, size: 22),
      title: Text(label, style: context.text.caption),
      subtitle: Text(value, style: AppTextStyles.tabular(context.text.label)),
    );
  }
}
