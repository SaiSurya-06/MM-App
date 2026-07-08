import 'package:intl/intl.dart';

class DateHelpers {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String toMonthString(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static DateTime parseMonthString(String monthStr) {
    final parts = monthStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month);
  }

  static String formatTime(String hhMm) {
    final parts = hhMm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final tempDate = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(tempDate);
  }
}
