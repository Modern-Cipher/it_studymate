import 'package:material_ui/material_ui.dart';

class AppDate {
  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekdays = <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime value) => isSameDay(value, DateTime.now());

  static bool isTomorrow(DateTime value) =>
      isSameDay(value, DateTime.now().add(const Duration(days: 1)));

  static bool isPast(DateTime value) => value.isBefore(DateTime.now());

  static String fullDate(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${_months[value.month - 1]} ${value.day}';

  static String shortDate(DateTime value) =>
      '${_months[value.month - 1].substring(0, 3)} ${value.day}';

  static String time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minutes = value.minute.toString().padLeft(2, '0');
    final String suffix = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minutes $suffix';
  }

  static String dueLabel(DateTime value) {
    if (isToday(value)) return 'Today · ${time(value)}';
    if (isTomorrow(value)) return 'Tomorrow · ${time(value)}';
    return '${shortDate(value)} · ${time(value)}';
  }

  static String greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class AppFormat {
  static String duration(int seconds) {
    if (seconds <= 0) return '0m';
    final int totalMinutes = seconds ~/ 60;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String clock(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  static String percent(double value) => '${(value * 100).round()}%';
}

Color hexColor(String hex) {
  final String cleaned = hex.replaceAll('#', '').toUpperCase();
  final String normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(normalized, radix: 16));
}
