/// Takes event fields (title, description, startTime, endTime, locationName) and returns a Google Calendar URL
/// Separate file from utility_functions.dart so can run gcal_url_test.dart without needing any flutter dart:ui

import 'package:game/api/game_client_dto.dart';

String getGcalUrl(CampusEventDto event) {
  final startTime = DateTime.parse(event.startTime);
  final endTime = DateTime.parse(event.endTime);
  final dates = formatDates(startTime, endTime, allDayEvent: event.allDay);
  return Uri(
    scheme: 'https',
    host: 'calendar.google.com',
    path: '/calendar/u/0/r/eventedit',
    queryParameters: <String, String>{
      'text': event.title,
      'dates': dates,
      'details': event.description,
      'location': event.locationName,
    },
  ).toString();
}

/// Google Calendar days have format YYYYMMDD/YYYYMMDD for all day events and starts and ends at midnight of the first day and
/// midnight at the day following the last day (ex. 3/29 midnight to 3/31 midnight is an all day event from 3/29-3/30)
/// Timed events: YYYYMMDDTHHmmssZ (T "time follows", Z for Zulu aka UTC)
/// Assumes a timed event is in EST (since it will take place in Ithaca, NY), and converts to UTC for gcal format
/// 

String formatDates(
  DateTime startTime,
  DateTime endTime, {
  required bool allDayEvent,
}) {
  if (allDayEvent) {
    // all day event
    final startYmd = formatToAllDay(startTime);
    var endYmd = formatToAllDay(endTime);
    if (startYmd == endYmd) {
      // change end date to one day after since exclusive
      final nextDay = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      ).add(const Duration(days: 1));
      endYmd = formatToAllDay(nextDay);
    }
    return '$startYmd/$endYmd';
  } // timed event
  return '${formatTime(startTime)}/${formatTime(endTime)}';
}


String formatToAllDay(DateTime date) {
  final yr = date.year.toString().padLeft(4, '0');
  final mon = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$yr$mon$day';
}

String formatTime(DateTime date) {
  final universalTime = date.toUtc();
  final yr = universalTime.year.toString().padLeft(4, '0');
  final mon = universalTime.month.toString().padLeft(2, '0');
  final day = universalTime.day.toString().padLeft(2, '0');
  final hr = universalTime.hour.toString().padLeft(2, '0');
  final min = universalTime.minute.toString().padLeft(2, '0');
  final sec = universalTime.second.toString().padLeft(2, '0');
  return '$yr$mon${day}T$hr$min${sec}Z';
}
