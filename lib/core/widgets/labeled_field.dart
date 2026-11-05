import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// تسمية الحقل مع `*` للإلزامي.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required) TextSpan(text: ' *', style: TextStyle(color: context.palette.error)),
        ],
      ),
      style: context.text.label,
    );
  }
}

/// حقل نصي بتسمية ثابتة أعلاه ورسالة خطأ تحته.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : null,
          autofocus: autofocus,
          style: context.text.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.body.copyWith(color: context.palette.textSecondary),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// عنوان قسم داخل النموذج بلون أساسي (مثل «الحساب» في «نسبتي»).
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.style(16, FontWeight.w600, color: context.palette.primary));
}

/// حقل اختيار (تاريخ أو وقت) بنفس شكل الحقول النصية، يفتح منتقياً عند الضغط.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.required = false,
    this.errorText,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              errorText: errorText,
              suffixIcon: Icon(icon, color: p.textSecondary, size: 24),
              hintText: 'اختر',
              hintStyle: context.text.body.copyWith(color: p.textSecondary),
            ),
            child: Text(value ?? '', style: AppTextStyles.tabular(context.text.body), maxLines: 1),
          ),
        ),
      ],
    );
  }
}
