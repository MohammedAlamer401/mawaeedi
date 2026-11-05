import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/formatting/arabic_plural.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/summary_card.dart';
import '../appointments/controllers/appointments_controller.dart';
import '../appointments/data/appointment_model.dart';
import '../appointments/presentation/widgets/appointment_actions.dart';
import '../settings/data/settings_repository.dart';
import 'notifications_providers.dart';

/// تبويب «الإشعارات»: التذكيرات القادمة وما وصل خلال آخر 7 أيام.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// تصفير الشارة يتم في شريط التنقل عند فتح التبويب (AppShell).
class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final upcoming = ref.watch(upcomingRemindersProvider);
    final recent = ref.watch(recentRemindersProvider);
    final blocked = ref.watch(remindersBlockedProvider);
    final seenAt = ref.watch(settingsProvider.select((s) => s.previousSeenAt));
    final p = context.palette;

    final upcomingList = upcoming.value ?? const <Appointment>[];
    final recentList = recent.value ?? const <Appointment>[];
    final loading = !upcoming.hasValue || !recent.hasValue;

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(appointmentsRevisionProvider.notifier).bump(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (blocked) ...[
              NoticeStrip(
                icon: Icons.notifications_off_rounded,
                text: 'التذكيرات متوقفة، فلن يصلك أي تنبيه',
                background: p.warningSoft,
                foreground: p.warning,
                onTap: () => context.go(AppRoutes.account),
              ),
              const SizedBox(height: 16),
            ],
            if (loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (upcomingList.isEmpty && recentList.isEmpty)
              EmptyState(
                icon: AppSvgIcons.bell,
                title: 'لا توجد تذكيرات',
                message: 'عند إضافة موعد بتذكير يظهر هنا وقت وصول التنبيه.',
                actionLabel: 'إضافة موعد',
                onAction: () => context.push(AppRoutes.newAppointment),
              )
            else ...[
              _SectionTitle('القادمة', count: upcomingList.length),
              if (upcomingList.isEmpty)
                const _Hint('لا تذكيرات مجدولة حالياً')
              else
                _Group(children: [for (final a in upcomingList) _ReminderTile(appointment: a, upcoming: true)]),
              _SectionTitle('وصلت خلال آخر 7 أيام', count: recentList.length),
              if (recentList.isEmpty)
                const _Hint('لم يصلك أي تذكير مؤخراً')
              else
                _Group(children: [
                  for (final a in recentList)
                    _ReminderTile(
                      appointment: a,
                      upcoming: false,
                      unread: seenAt == null || a.remindAt!.isAfter(seenAt),
                    ),
                ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.appointment, required this.upcoming, this.unread = false});

  final Appointment appointment;
  final bool upcoming;
  final bool unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final a = appointment;
    final at = a.remindAt!;
    final when = '${DateFormatter.relativeDay(at)} ${DateFormatter.time(at)}';
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: upcoming ? p.primarySoft : (a.isCompleted ? p.successSoft : p.surfaceMuted),
          shape: BoxShape.circle,
        ),
        child: Icon(
          upcoming
              ? Icons.notifications_active_rounded
              : a.isCompleted
                  ? Icons.check_rounded
                  : Icons.notifications_rounded,
          color: upcoming ? p.primary : (a.isCompleted ? p.success : p.textSecondary),
          size: 22,
        ),
      ),
      title: Text(
        a.title,
        style: context.text.cardTitle.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        upcoming
            ? 'يصلك $when · ${ArabicPlural.reminder(a.reminderMinutes!)}'
            : 'وصل $when · الموعد ${DateFormatter.time(a.startAt)}',
        style: AppTextStyles.tabular(context.text.caption),
      ),
      trailing: unread
          ? Container(width: 10, height: 10, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle))
          : null,
      onTap: () => showAppointmentSheet(context, a),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: context.text.labelMuted)),
          if (count > 0) Text('$count', style: AppTextStyles.tabular(context.text.labelMuted)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(text, style: context.text.labelMuted),
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(indent: 72),
            child,
          ],
        ],
      ),
    );
  }
}
