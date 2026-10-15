/// Utility helper to parse and preserve booking dates and times accurately
/// between local wall-clock selections and UTC ISO 8601 strings required by the backend.
class BookingDateTimeHelper {
  /// Parses a user-selected DateTime and a 12-hour formatted time slot (e.g. "09:30 AM", "06:30 PM")
  /// and constructs a DateTime in the user's local timezone, then converts it to a UTC ISO 8601 string.
  ///
  /// This ensures that the user's intended local ritual hour/minute is accurately preserved.
  static String formatToIsoUtc({
    required DateTime date,
    required String timeSlot,
  }) {
    final parsedTime = parseTimeSlot(timeSlot);
    final localDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime.hour,
      parsedTime.minute,
      0,
    );
    return localDateTime.toUtc().toIso8601String();
  }

  /// Parses 12-hour string (e.g. "09:30 AM", "6:30 pm", "12:00 PM", "12:00 AM")
  /// into 24-hour hour and minute.
  static ({int hour, int minute}) parseTimeSlot(String timeSlot) {
    final trimmed = timeSlot.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Time slot cannot be empty');
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid time slot format: "$timeSlot". Expected format "HH:MM AM/PM"');
    }

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!.toUpperCase();

    if (hour < 1 || hour > 12) {
      throw FormatException('Invalid hour "$hour" in time slot: "$timeSlot"');
    }
    if (minute < 0 || minute > 59) {
      throw FormatException('Invalid minute "$minute" in time slot: "$timeSlot"');
    }

    if (period == 'PM' && hour < 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return (hour: hour, minute: minute);
  }

  /// Resolves the bookingTime string from payload data.
  /// Rejects missing or invalid input with a clear FormatException.
  /// NEVER silently falls back to a default datetime.
  static String resolveBookingTime(Map<String, dynamic> data) {
    if (data['bookingTime'] != null) {
      final str = data['bookingTime'].toString().trim();
      if (str.isEmpty) {
        throw const FormatException('bookingTime cannot be empty');
      }
      final parsed = DateTime.tryParse(str);
      if (parsed == null) {
        throw FormatException('Invalid bookingTime ISO format: "$str"');
      }
      return parsed.toUtc().toIso8601String();
    }

    if (data['date'] != null && data['timeSlot'] != null) {
      final rawDate = data['date'];
      DateTime dt;
      if (rawDate is DateTime) {
        dt = rawDate;
      } else if (rawDate is String) {
        final trimmedDate = rawDate.trim();
        if (trimmedDate.isEmpty) {
          throw const FormatException('date cannot be empty');
        }
        final parts = trimmedDate.split(RegExp(r'[/.-]'));
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            // DD/MM/YYYY
            dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } else {
          dt = DateTime.parse(trimmedDate);
        }
      } else {
        throw FormatException('Invalid date type: ${rawDate.runtimeType}');
      }

      return formatToIsoUtc(date: dt, timeSlot: data['timeSlot'].toString());
    }

    throw const FormatException('Missing required booking date and time selection');
  }

  /// Formats an ISO 8601 UTC string into a clean user-facing format (e.g. "15 Oct 2026, 09:30 AM")
  static String formatForDisplay(String? isoUtcString) {
    if (isoUtcString == null || isoUtcString.isEmpty) return 'Date & Time on Request';
    try {
      final dt = DateTime.parse(isoUtcString).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[dt.month - 1];
      final dayStr = dt.day.toString().padLeft(2, '0');
      final yearStr = dt.year.toString();

      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';

      return '$dayStr $monthStr $yearStr, ${hour12.toString().padLeft(2, '0')}:$minuteStr $period';
    } catch (_) {
      return isoUtcString;
    }
  }
}
