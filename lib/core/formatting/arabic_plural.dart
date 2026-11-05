/// صيغ العدد العربية للمعدود (مفرد، مثنى، جمع 3–10، تمييز مفرد لما فوق 10).
abstract final class ArabicPlural {
  static String appointments(int count) => switch (count) {
        0 => 'لا مواعيد',
        1 => 'موعد واحد',
        2 => 'موعدان',
        <= 10 => '$count مواعيد',
        _ => '$count موعداً',
      };

  static String minutes(int count) => switch (count) {
        1 => 'دقيقة',
        2 => 'دقيقتين',
        <= 10 => '$count دقائق',
        _ => '$count دقيقة',
      };

  /// «قبل الموعد بـ 15 دقيقة» أو «قبل الموعد بساعة».
  static String reminder(int minutes) {
    if (minutes == 0) return 'عند بدء الموعد';
    if (minutes == 60) return 'قبل الموعد بساعة';
    if (minutes == 120) return 'قبل الموعد بساعتين';
    if (minutes == 1440) return 'قبل الموعد بيوم';
    return 'قبل الموعد بـ ${ArabicPlural.minutes(minutes)}';
  }
}
