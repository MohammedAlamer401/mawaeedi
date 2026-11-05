/// تنسيق التاريخ والوقت بالعربية — ميلادي بأرقام غربية كما في «نسبتي».
abstract final class DateFormatter {
  static const months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  /// بترتيب [DateTime.weekday]: الإثنين = 1.
  static const weekdays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// `05/11/2026`.
  static String short(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  /// `5 نوفمبر 2026`.
  static String long(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

  /// `الخميس، 5 نوفمبر 2026`.
  static String full(DateTime d) => '${weekdays[d.weekday - 1]}، ${long(d)}';

  /// «اليوم» أو «غداً» أو «أمس» أو `الإثنين 9 نوفمبر` (مع السنة إن اختلفت).
  static String relativeDay(DateTime d) {
    final diff = dateOnly(d).difference(today()).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
    final sameYear = d.year == DateTime.now().year;
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}${sameYear ? '' : ' ${d.year}'}';
  }

  /// `10:30` بنظام 12 ساعة.
  static String clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_two(h)}:${_two(d.minute)}';
  }

  /// «صباحاً» أو «مساءً».
  static String period(DateTime d) => d.hour < 12 ? 'صباحاً' : 'مساءً';

  /// `10:30 صباحاً`.
  static String time(DateTime d) => '${clock(d)} ${period(d)}';
}
