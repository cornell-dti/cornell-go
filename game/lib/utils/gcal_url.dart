/// Takes event fields (title, description, startTime, endTime, locationName) and returns a Google Calendar URL
/// Separate file from utility_functions.dart so can run gcal_url_test.dart without needing any flutter dart:ui

String getGcalUrl(String title, String description, DateTime startTime,
    DateTime endTime, String locationName) {
  final dates = formatDates(startTime, endTime);
  return Uri(
    scheme: 'https',
    host: 'calendar.google.com',
    path: '/calendar/u/0/r/eventedit',
    queryParameters: <String, String>{
      'text': title,
      'dates': dates,
      'details': description,
      'location': locationName,
    },
  ).toString();
}

/// Google Calendar days have format YYYYMMDD/YYYYMMDD for all day events and starts and ends at midnight of the first day and
/// midnight at the day following the last day (ex. 3/29 midnight to 3/31 midnight is an all day event from 3/29-3/30)
/// Timed events: YYYYMMDDTHHmmssZ (T "time follows", Z for Zulu aka UTC)
/// Assumes a timed event is in EST (since it will take place in Ithaca, NY), and converts to UTC for gcal format
/// 

String formatDates(DateTime startTime, DateTime endTime) {
  if (isMidnight(startTime) && isMidnight(endTime)) {
    // all day event
    final startYmd = allDay(startTime);
    var endYmd = allDay(endTime);
    if (startYmd == endYmd) {
      // change end date to one day after since exclusive
      final localStart = startTime.toLocal();
      final nextDay = DateTime(
        localStart.year,
        localStart.month,
        localStart.day,
      ).add(const Duration(days: 1));
      endYmd = allDay(nextDay);
    }
    return '$startYmd/$endYmd';
  } // timed event
  return '${formatTime(startTime)}/${formatTime(endTime)}';
}

bool isMidnight(DateTime d) {
  return d.hour == 0 && d.minute == 0 && d.second == 0 && d.microsecond == 0;
}

String allDay(DateTime d) {
  final l = d.toLocal(); //convert to local date
  final y = l.year.toString().padLeft(4, '0');
  final m = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  return '$y$m$day';
}

String formatTime(DateTime d) {
  final u = d.toUtc();
  final y = u.year.toString().padLeft(4, '0');
  final m = u.month.toString().padLeft(2, '0');
  final day = u.day.toString().padLeft(2, '0');
  final h = u.hour.toString().padLeft(2, '0');
  final min = u.minute.toString().padLeft(2, '0');
  final s = u.second.toString().padLeft(2, '0');
  return '$y$m${day}T$h$min${s}Z';
}
