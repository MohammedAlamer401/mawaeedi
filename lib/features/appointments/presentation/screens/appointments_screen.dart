import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../controllers/appointments_controller.dart';
import '../../data/appointment_model.dart';
import '../widgets/appointment_actions.dart';
import '../widgets/appointment_card.dart';

/// كل المواعيد (القسم 4.3): مرشحات اليوم، القادمة، السابقة، المكتملة.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key, this.initialTab});

  /// اسم التبويب من الرابط (مثلاً `past` من تنبيه «مواعيد فاتت»).
  final String? initialTab;

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  late var _tab = _parse(widget.initialTab) ?? AppointmentTab.upcoming;

  static AppointmentTab? _parse(String? name) =>
      AppointmentTab.values.where((t) => t.name == name).firstOrNull;

  @override
  void didUpdateWidget(covariant AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tab = _parse(widget.initialTab);
    if (tab != null && widget.initialTab != oldWidget.initialTab) _tab = tab;
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(appointmentsByTabProvider(_tab));
    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newAppointment),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة موعد'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (final (i, tab) in AppointmentTab.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(tab.label),
                    selected: _tab == tab,
                    showCheckmark: false,
                    labelStyle: _tab == tab ? Theme.of(context).chipTheme.secondaryLabelStyle : null,
                    onSelected: (_) => setState(() => _tab = tab),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: list.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: EmptyState(icon: AppSvgIcons.info, title: 'تعذّر تحميل المواعيد'),
              ),
              data: (items) => items.isEmpty ? _empty(context) : _list(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final (title, message) = switch (_tab) {
      AppointmentTab.today => ('لا مواعيد اليوم', 'المواعيد المضافة لهذا اليوم تظهر هنا.'),
      AppointmentTab.upcoming => ('لا مواعيد قادمة', 'خطّط ليومك القادم بإضافة موعد.'),
      AppointmentTab.past => ('لا مواعيد فائتة', 'رائع! لم يفتك أي موعد.'),
      AppointmentTab.completed => ('لا مواعيد مكتملة بعد', 'عند إكمال موعد يظهر هنا.'),
    };
    final canAdd = _tab == AppointmentTab.today || _tab == AppointmentTab.upcoming;
    return SingleChildScrollView(
      child: EmptyState(
        icon: _tab == AppointmentTab.completed ? AppSvgIcons.check : AppSvgIcons.calendar,
        title: title,
        message: message,
        actionLabel: canAdd ? 'إضافة موعد' : null,
        onAction: canAdd ? () => context.push(AppRoutes.newAppointment) : null,
      ),
    );
  }

  /// قائمة مجمّعة حسب اليوم بعناوين فاصلة.
  Widget _list(List<Appointment> items) {
    final rows = <Widget>[];
    DateTime? lastDay;
    for (final a in items) {
      final day = DateFormatter.dateOnly(a.startAt);
      if (_tab != AppointmentTab.today && day != lastDay) {
        rows.add(Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4, rows.isEmpty ? 4 : 14, 4, 8),
          child: Text(
            DateFormatter.isSameDay(day, DateTime.now()) ? 'اليوم' : DateFormatter.full(day),
            style: context.text.labelMuted,
          ),
        ));
        lastDay = day;
      }
      rows
        ..add(AppointmentCard(
          appointment: a,
          showDay: false,
          onTap: () => showAppointmentSheet(context, a),
          onToggleComplete: () => toggleCompleted(context, ref, a),
        ))
        ..add(const SizedBox(height: 10));
    }
    return RefreshIndicator(
      onRefresh: () async => ref.read(appointmentsRevisionProvider.notifier).bump(),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: rows),
    );
  }
}
