import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// نافذة تأكيد؛ تعيد `true` عند الموافقة. [destructive] يلوّن زر التأكيد بالأحمر.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'إلغاء',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: context.palette.error) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// تأكيد الخروج من نموذج فيه تعديلات غير محفوظة.
Future<bool> confirmDiscardChanges(BuildContext context) => showConfirmDialog(
      context,
      title: 'تغييرات غير محفوظة',
      message: 'هل تريد الخروج دون حفظ التعديلات؟',
      confirmLabel: 'خروج دون حفظ',
      cancelLabel: 'متابعة التعديل',
      destructive: true,
    );

/// رسالة سريعة عائمة أسفل الشاشة.
void showAppSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
