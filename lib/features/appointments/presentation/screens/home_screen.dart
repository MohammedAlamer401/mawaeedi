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
import '../../controllers/appointments_controller.dart';
import '../../data/appointment_model.dart';
import '../widgets/appointment_actions.dart';
import '../widgets/appointment_card.dart';

/// الشاشة الرئيسية (القسم 4.1): تاريخ اليوم، ملخص، مواعيد اليوم والقادمة.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(appointmentsByTabProvider(AppointmentTab.today));
    final upcoming = ref.watch(upcomingPreviewProvider);
    final todayList = today.value ?? const <Appointment>[];
    final upcomingList = upcoming.value ?? const <Appointment>[];
    final loading = today.isLoading && !today.hasValue;
    final remainingToday = todayList.where((a) => !a.isCompleted).length;
    final nothing = !loading && todayList.isEmpty && upcomingList.isEmpty && upcoming.hasValue;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.read(appointmentsRevisionProvider.notifier).bump(),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
            children: [
              const _Header(),
              const SizedBox(height: 16),
              _TodayHero(
                count: todayList.length,
                remaining: remainingToday,
                upcoming: upcomingList.length,
                onTap: () => context.go(AppRoutes.appointments),
              ),
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
                  icon: AppSvgIcons.clock,
                  title: 'مواعيد اليوم',
                  trailing: todayList.isEmpty ? null : ArabicPlural.appointments(todayList.length),
                ),
                const SizedBox(height: 8),
                if (todayList.isEmpty)
                  _InlineNote('لا مواعيد اليوم — استمتع بيومك')
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
                const SizedBox(height: 14),
                _SectionHeader(
                  icon: AppSvgIcons.calendar,
                  title: 'المواعيد القادمة',
                  action: upcomingList.isEmpty ? null : ('عرض الكل', () => context.go(AppRoutes.appointments)),
                ),
                const SizedBox(height: 8),
                if (upcomingList.isEmpty)
                  _InlineNote('لا مواعيد قادمة بعد اليوم')
                else
                  for (final a in upcomingList) ...[
                    AppointmentCard(appointment: a, onTap: () => showAppointmentSheet(context, a)),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                _AddButton(onPressed: () => context.push(AppRoutes.newAppointment)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'صباح الخير' : 'مساء الخير';
    return Row(
      children: [
        const MawaeediLogo(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting 👋', style: context.text.caption),
              Text('مواعيدي', style: context.text.screenTitle),
            ],
          ),
        ),
        Text(DateFormatter.full(now), style: context.text.caption),
      ],
    );
  }
}

/// البطاقة الزرقاء الكبرى: عدد مواعيد اليوم والمتبقي منها والقادمة.
class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.count, required this.remaining, required this.upcoming, required this.onTap});

  final int count;
  final int remaining;
  final int upcoming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subtitle = count == 0
        ? 'يومك فارغ'
        : remaining == 0
            ? 'أنجزت كل مواعيد اليوم 🎉'
            : 'متبقٍّ: ${ArabicPlural.appointments(remaining)}';
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [p.primary, BrandColors.primaryDark],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                top: -40,
                end: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مواعيد اليوم',
                            style: AppTextStyles.style(15, FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: 4),
                          Text('$count', style: context.text.countLarge),
                          const SizedBox(height: 4),
                          Text(subtitle, style: AppTextStyles.style(13.5, FontWeight.w500, color: Colors.white)),
                          if (upcoming > 0)
                            Text(
                              'وبعده ${ArabicPlural.appointments(upcoming)} قادمة',
                              style: AppTextStyles.style(12.5, FontWeight.w400, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.trailing, this.action});

  final String icon;
  final String title;
  final String? trailing;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppSvgIcon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: context.text.cardTitle.copyWith(fontSize: 16))),
        if (trailing != null) Text(trailing!, style: context.text.caption),
        if (action case (final label, final onTap)) TextButton(onPressed: onTap, child: Text(label)),
      ],
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Text(text, style: context.text.labelMuted),
    );
  }
}

/// زر الإضافة بخلفية ناعمة كما في لوحة التصميم.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: p.primarySoft, foregroundColor: p.primary),
      icon: const Icon(Icons.add_rounded),
      label: const Text('إضافة موعد جديد'),
    );
  }
}
