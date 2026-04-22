// Testing for Google Calendar URLs.
//
// From the `game` directory run:
//   dart test test/gcal_url_test.dart

import 'package:game/api/game_client_dto.dart';
import 'package:game/utils/gcal_url.dart';
import 'package:test/test.dart';

CampusEventDto _campusEvent({
  required String id,
  required String title,
  required String description,
  required DateTime startTime,
  required DateTime endTime,
  required bool allDay,
  required String locationName,
}) {
  return CampusEventDto(
    id: id,
    title: title,
    description: description,
    startTime: startTime.toIso8601String(),
    endTime: endTime.toIso8601String(),
    allDay: allDay,
    locationName: locationName,
    latitude: 0,
    longitude: 0,
    categories: [CampusEventCategoriesDto.values.first],
    tags: const [],
    source: CampusEventSourceDto.values.first,
    checkInMethod: CampusEventCheckInMethodDto.values.first,
    pointsForAttendance: 0,
    featured: false,
    attendanceCount: 0,
    rsvpCount: 0,
  );
}

void main() {
  group('formatDates', () {
    test('timed event uses UTC timestamps', () {
      final start = DateTime(2025, 3, 29, 14, 30);
      final end = DateTime(2025, 3, 29, 15, 30);

      final dates = formatDates(start, end, allDayEvent: false);

      expect(dates, '${formatTime(start)}/${formatTime(end)}');
      expect(dates, contains('T'));
      expect(dates, endsWith('Z/${formatTime(end)}'.split('/').last));
    });

    test('all-day multi-day uses YYYYMMDD/YYYYMMDD', () {
      final start = DateTime(2025, 3, 29);
      final end = DateTime(2025, 3, 31);

      final dates = formatDates(start, end, allDayEvent: true);

      expect(dates, '${formatToAllDay(start)}/${formatToAllDay(end)}');
      expect(dates, isNot(contains('T')));
    });

    test('all-day single-day expands end date by one day', () {
      final single = DateTime(2025, 3, 29);

      final dates = formatDates(single, single, allDayEvent: true);

      final nextDay = DateTime(single.year, single.month, single.day)
          .add(const Duration(days: 1));
      expect(dates, '${formatToAllDay(single)}/${formatToAllDay(nextDay)}');
    });
  });

  group('getGcalUrl', () {
    test('builds expected Google Calendar event-edit URI', () {
      final ev = _campusEvent(
        id: '1',
        title: 'Sample timed event',
        description: 'Description line',
        startTime: DateTime(2025, 3, 29, 14, 30),
        endTime: DateTime(2025, 3, 29, 15, 30),
        allDay: false,
        locationName: 'Ithaca, NY',
      );

      final url = getGcalUrl(ev);
      print('Timed event URL: $url');
      final uri = Uri.parse(url);

      expect(uri.scheme, 'https');
      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/u/0/r/eventedit');

      final start = DateTime.parse(ev.startTime);
      final end = DateTime.parse(ev.endTime);
      expect(uri.queryParameters['text'], ev.title);
      expect(uri.queryParameters['details'], ev.description);
      expect(uri.queryParameters['location'], ev.locationName);
      expect(
        uri.queryParameters['dates'],
        formatDates(start, end, allDayEvent: ev.allDay),
      );
    });

    test('all-day event uses allDay flag', () {
      final ev = _campusEvent(
        id: '2',
        title: 'All day (flagged)',
        description: '',
        startTime: DateTime(2025, 3, 29, 12, 0),
        endTime: DateTime(2025, 3, 29, 12, 0),
        allDay: true,
        locationName: '',
      );

      final url = getGcalUrl(ev);
      print('All-day (flagged) URL: $url');
      final uri = Uri.parse(url);
      final dates = uri.queryParameters['dates']!;

      expect(dates, contains('/'));
      expect(dates, isNot(contains('T')));
    });
  });
}
