import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/formatting/arabic_plural.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/notifications/permission_flow.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../settings/data/settings_repository.dart';
import '../../controllers/appointments_controller.dart';
import '../../data/appointment_model.dart';
import '../../data/appointment_repository.dart';

/// إضافة موعد أو تعديله (القسم 4.2).
class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({super.key, this.appointmentId});

  /// `null` للإضافة.
  final int? appointmentId;

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();

  late final Future<Appointment?> _initial = widget.appointmentId == null
      ? Future.value(null)
      : ref.read(appointmentRepositoryProvider).getAppointment(widget.appointmentId!);

  Appointment? _original;
  var _loaded = false;
  DateTime? _date = DateFormatter.today();
  TimeOfDay? _time;
  int? _reminder = 15;
  var _dirty = false;
  var _saving = false;
  var _submitted = false;

  bool get _editing => widget.appointmentId != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _fill(Appointment? a) {
    if (_loaded) return;
    _loaded = true;
    if (a == null) return;
    _original = a;
    _title.text = a.title;
    _notes.text = a.notes ?? '';
    _date = DateFormatter.dateOnly(a.startAt);
    _time = TimeOfDay.fromDateTime(a.startAt);
    _reminder = a.reminderMinutes;
  }

  DateTime? get _startAt =>
      _date == null || _time == null ? null : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  void _touch(VoidCallback change) => setState(() {
        change();
        _dirty = true;
      });

  Future<void> _pickDate() async {
    final today = DateFormatter.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 10, 12, 31),
      helpText: 'تاريخ الموعد',
      cancelText: 'إلغاء',
      confirmText: 'تم',
    );
    if (picked != null) _touch(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
      helpText: 'وقت الموعد',
      cancelText: 'إلغاء',
      confirmText: 'تم',
    );
    if (picked != null) _touch(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    final startAt = _startAt;
    if (!valid || startAt == null) return;

    // تنبيه قبل حفظ موعد في الماضي (القسم 5) — فقط إن تغيّر وقته.
    final timeChanged = _original == null || _original!.startAt != startAt;
    if (timeChanged && startAt.isBefore(DateTime.now())) {
      final proceed = await showConfirmDialog(
        context,
        title: 'موعد في الماضي',
        message: 'وقت هذا الموعد قد مضى، ولن يصلك تذكير به. هل تريد حفظه على أي حال؟',
        confirmLabel: 'حفظ على أي حال',
        cancelLabel: 'تعديل الوقت',
      );
      if (!proceed) return;
    }

    if (!mounted) return;
    if (_reminder != null && ref.read(settingsProvider).notificationsEnabled) {
      await ensureNotificationPermission(context, ref);
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final draft = (_original ??
            Appointment(title: '', startAt: startAt, createdAt: now, updatedAt: now))
        .copyWith(
      title: _title.text.trim(),
      notes: () => _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      startAt: startAt,
      reminderMinutes: () => _reminder,
    );
    try {
      final (_, outcome) = await ref.read(appointmentsControllerProvider).save(draft);
      if (!mounted) return;
      setState(() => _dirty = false);
      showAppSnackBar(context, switch (outcome) {
        ReminderOutcome.scheduled => 'تم حفظ الموعد وجدولة التذكير',
        ReminderOutcome.none => 'تم حفظ الموعد',
        ReminderOutcome.disabledInSettings => 'تم حفظ الموعد — التذكيرات متوقفة من الإعدادات',
        ReminderOutcome.permissionDenied => 'تم حفظ الموعد، لكن التذكير لن يصل حتى تفعيل الإشعارات',
      });
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'تعذّر حفظ الموعد. حاول مرة أخرى.');
    }
  }

  Future<void> _confirmLeave() async {
    if (await confirmDiscardChanges(context) && mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 18);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_editing ? 'تعديل الموعد' : 'موعد جديد')),
        body: FutureBuilder(
          future: _initial,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_editing && snapshot.data == null) {
              return Center(child: Text('هذا الموعد لم يعد موجوداً', style: context.text.labelMuted));
            }
            _fill(snapshot.data);
            return Form(
              key: _formKey,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'عنوان الموعد',
                      required: true,
                      controller: _title,
                      hint: 'مثال: موعد الطبيب',
                      maxLength: 100,
                      autofocus: !_editing,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب عنوان الموعد' : null,
                    ),
                    gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PickerField(
                            label: 'التاريخ',
                            required: true,
                            icon: Icons.calendar_month_rounded,
                            value: _date == null ? null : DateFormatter.short(_date!),
                            errorText: _submitted && _date == null ? 'اختر التاريخ' : null,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PickerField(
                            label: 'الوقت',
                            required: true,
                            icon: Icons.schedule_rounded,
                            value: _startAt == null ? null : DateFormatter.time(_startAt!),
                            errorText: _submitted && _time == null ? 'اختر الوقت' : null,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    if (_date != null) ...[
                      const SizedBox(height: 6),
                      Text(DateFormatter.full(_date!), style: context.text.caption),
                    ],
                    gap,
                    const FieldLabel('التذكير'),
                    const SizedBox(height: 8),
                    _ReminderPicker(value: _reminder, onChanged: (v) => _touch(() => _reminder = v)),
                    if (_reminder != null && _startAt != null) ...[
                      const SizedBox(height: 8),
                      _ReminderHint(startAt: _startAt!, minutes: _reminder!),
                    ],
                    gap,
                    LabeledField(
                      label: 'ملاحظات',
                      controller: _notes,
                      hint: 'اختياري',
                      maxLength: 500,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(_editing ? 'حفظ التعديلات' : 'حفظ الموعد'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: () => Navigator.maybePop(context), child: const Text('إلغاء')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  static String _label(int? m) => switch (m) {
        null => 'بدون تذكير',
        60 => 'ساعة',
        _ => '$m د',
      };

  @override
  Widget build(BuildContext context) {
    final chip = Theme.of(context).chipTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in reminderOptions)
          ChoiceChip(
            label: Text(_label(m)),
            avatar: m == null ? const Icon(Icons.notifications_off_outlined, size: 18) : null,
            selected: value == m,
            showCheckmark: false,
            labelStyle: value == m ? chip.secondaryLabelStyle : null,
            onSelected: (_) => onChanged(m),
          ),
      ],
    );
  }
}

/// يوضح متى سيصل التذكير بالضبط.
class _ReminderHint extends StatelessWidget {
  const _ReminderHint({required this.startAt, required this.minutes});

  final DateTime startAt;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final at = startAt.subtract(Duration(minutes: minutes));
    final passed = at.isBefore(DateTime.now());
    return Row(
      children: [
        Icon(Icons.notifications_active_rounded, size: 16, color: passed ? p.warning : p.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            passed
                ? 'وقت التذكير مضى؛ ستُنبَّه عند بدء الموعد إن لم يفت'
                : '${ArabicPlural.reminder(minutes)} · ${DateFormatter.relativeDay(at)} ${DateFormatter.time(at)}',
            style: context.text.caption.copyWith(color: passed ? p.warning : null),
          ),
        ),
      ],
    );
  }
}
