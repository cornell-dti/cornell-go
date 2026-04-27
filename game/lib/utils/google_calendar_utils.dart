import 'package:url_launcher/url_launcher.dart';

String _gcalUtcSegment(DateTime dt) {
  final u = dt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}'
      '${two(u.month)}'
      '${two(u.day)}'
      'T'
      '${two(u.hour)}'
      '${two(u.minute)}'
      '${two(u.second)}'
      'Z';
}

String _gcalAllDayYmd(DateTime local) {
  final d = DateTime(local.year, local.month, local.day);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}${two(d.month)}${two(d.day)}';
}

/// Builds the Google Calendar "create event" URL (`action=TEMPLATE`).
Uri googleCalendarCreateUri({
  required String title,
  required String location,
  required DateTime start,
  required DateTime end,
  String? details,
  required bool allDay,
}) {
  final String dates;
  if (allDay) {
    final startDay = DateTime(start.year, start.month, start.day);
    var endDay = DateTime(end.year, end.month, end.day);
    if (endDay.isBefore(startDay)) endDay = startDay;
    final exclusiveEnd = endDay.add(const Duration(days: 1));
    dates = '${_gcalAllDayYmd(startDay)}/${_gcalAllDayYmd(exclusiveEnd)}';
  } else {
    var endAdj = end.isAfter(start) ? end : start.add(const Duration(hours: 1));
    dates = '${_gcalUtcSegment(start)}/${_gcalUtcSegment(endAdj)}';
  }

  final params = <String, String>{
    'action': 'TEMPLATE',
    'text': title,
    'dates': dates,
    'location': location,
  };
  final d = details?.trim();
  if (d != null && d.isNotEmpty) {
    params['details'] = d;
  }

  return Uri.https('calendar.google.com', '/calendar/render', params);
}

/// Opens Google Calendar (app or browser) with a prefilled new event.
Future<bool> openGoogleCalendarCreateEvent({
  required String title,
  required String location,
  required DateTime start,
  required DateTime end,
  String? details,
  required bool allDay,
}) {
  final uri = googleCalendarCreateUri(
    title: title,
    location: location,
    start: start,
    end: end,
    details: details,
    allDay: allDay,
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
