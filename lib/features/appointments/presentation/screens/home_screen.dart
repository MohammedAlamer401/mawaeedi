import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/formatting/arabic_plural.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/summary_card.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../notifications/notifications_providers.dart';
import '../../../settings/data/settings_repository.dart';
import '../../controllers/appointments_controller.dart';
import '../../data/appointment_model.dart';
import '../widgets/appointment_actions.dart';
import '../widgets/appointment_card.dart';

/// الرئيسية (القسم 4.1) بترتيب «ملخص أعمالي» في «نسبتي»:
/// تحية، شارة التاريخ، بطاقات الملخص، أشرطة التنبيه، ثم القوائم.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(appointmentsByTabProvider(AppointmentTab.today));
    final upcoming = ref.watch(upcomingPreviewProvider);
    final upcomingAll = ref.watch(appointmentsByTabProvider(AppointmentTab.upcoming));
    final past = ref.watch(appointmentsByTabProvider(AppointmentTab.past));
    final blocked = ref.watch(remindersBlockedProvider);

    final todayList = today.value ?? const <Appointment>[];
    final upcomingList = upcoming.value ?? const <Appointment>[];
    final upcomingCount = upcomingAll.value?.length ?? 0;
    final now = DateTime.now();
    final doneToday = todayList.where((a) => a.isCompleted).length;
    final leftToday = todayList.where((a) => !a.isCompleted && !a.startAt.isBefore(now)).length;
    // الفائتة: من الأيام السابقة + ما فات وقته اليوم ولم يُكمَل.
    final missed = (past.value?.length ?? 0) + todayList.where((a) => a.isOverdue(now)).length;
    final loading = !today.hasValue || !upcoming.hasValue;
    final nothing = !loading && todayList.isEmpty && upcomingList.isEmpty && missed == 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.read(appointmentsRevisionProvider.notifier).bump(),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
            children: [
              const _Header(),
              const SizedBox(height: 12),
              Align(alignment: AlignmentDirectional.centerStart, child: _DateChip(date: now)),
              const SizedBox(height: 12),
              SummaryCard(
                title: 'مواعيد اليوم',
                value: '${todayList.length}',
                subtitle: todayList.isEmpty
                    ? 'لا مواعيد اليوم'
                    : leftToday == 0 && doneToday == todayList.length
                        ? 'أنجزت كل مواعيد اليوم 🎉'
                        : '${ArabicPlural.appointments(todayList.length)} في هذا اليوم',
                icon: Icons.event_note_rounded,
                large: true,
                onTap: () => context.go(AppRoutes.appointmentsTab(AppointmentTab.today.name)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'المكتملة منها',
                      value: '$doneToday',
                      icon: Icons.check_circle_rounded,
                      accent: p.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'المتبقي منها',
                      value: '$leftToday',
                      icon: Icons.schedule_rounded,
                      accent: p.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'المواعيد القادمة',
                value: ArabicPlural.appointments(upcomingCount),
                onTap: () => context.go(AppRoutes.appointmentsTab(AppointmentTab.upcoming.name)),
              ),
              if (missed > 0) ...[
                const SizedBox(height: 12),
                NoticeStrip(
                  icon: Icons.history_rounded,
                  text: 'مواعيد فات وقتها ولم تُكمَل',
                  trailing: '$missed',
                  background: p.warningSoft,
                  foreground: p.warning,
                  onTap: () => context.go(AppRoutes.appointmentsTab(AppointmentTab.past.name)),
                ),
              ],
              if (blocked) ...[
                const SizedBox(height: 12),
                NoticeStrip(
                  icon: Icons.notifications_off_rounded,
                  text: 'التذكيرات متوقفة — لن يصلك أي تنبيه',
                  background: p.errorSoft,
                  foreground: p.error,
                  onTap: () => context.go(AppRoutes.account),
                ),
              ],
              const SizedBox(height: 20),
              if (loading)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (nothing)
                EmptyState(
                  icon: AppSvgIcons.calendar,
                  title: 'لا توجد مواعيد بعد',
                  message: 'أضف موعدك الأول وسنذكّرك به في الوقت المناسب.',
                  actionLabel: 'أضف أول موعد',
                  onAction: () => context.push(AppRoutes.newAppointment),
                )
              else ...[
                _SectionHeader(
                  title: 'مواعيد اليوم',
                  onShowAll: todayList.isEmpty ? null : () => context.go(AppRoutes.appointmentsTab('today')),
                ),
                const SizedBox(height: 4),
                if (todayList.isEmpty)
                  const _InlineNote('لا مواعيد اليوم — استمتع بيومك')
                else
                  for (final a in todayList) ...[
                    AppointmentCard(
                      appointment: a,
                      showDay: false,
                      onTap: () => showAppointmentSheet(context, a),
                      onToggleComplete: () => toggleCompleted(context, ref, a),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 10),
                _SectionHeader(
                  title: 'المواعيد القادمة',
                  onShowAll: upcomingList.isEmpty ? null : () => context.go(AppRoutes.appointmentsTab('upcoming')),
                ),
                const SizedBox(height: 4),
                if (upcomingList.isEmpty)
                  const _InlineNote('لا مواعيد قادمة بعد اليوم')
                else
                  for (final a in upcomingList) ...[
                    AppointmentCard(appointment: a, onTap: () => showAppointmentSheet(context, a)),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.newAppointment),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة موعد'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// «مرحباً، محمد» فوق عنوان كبير، والصورة الدائرية بجانبها — كما في «نسبتي».
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(settingsProvider.select((s) => s.firstName));
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.account),
          customBorder: const CircleBorder(),
          child: const CurrentUserAvatar(radius: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(firstName == null ? 'مرحباً' : 'مرحباً، $firstName', style: context.text.caption.copyWith(fontSize: 14)),
              Text('ملخص يومي', style: AppTextStyles.style(26, FontWeight.w600, color: context.palette.textPrimary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// شارة التاريخ بنفس شكل زر الفترة في «نسبتي».
class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSvgIcon(AppSvgIcons.calendar, size: 20),
          const SizedBox(width: 8),
          Text(DateFormatter.full(date), style: AppTextStyles.tabular(context.text.label)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.text.labelMuted)),
              Text(value, style: AppTextStyles.tabular(context.text.cardTitle)),
              if (onTap != null) Icon(Icons.chevron_left_rounded, color: context.palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onShowAll});

  final String title;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.cardTitle.copyWith(fontSize: 16))),
        if (onShowAll != null) TextButton(onPressed: onShowAll, child: const Text('عرض الكل')),
      ],
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(text, style: context.text.labelMuted),
      ),
    );
  }
}
