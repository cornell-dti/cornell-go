// Manual testing for Google Calendar URLs.
//
// From the `game` directory run:
//   dart run test/gcal_url_test.dart

import 'package:game/utils/gcal_url.dart';

void main() {
  // Timed event (local wall clock — same as typical app DateTime)
  final timedStart = DateTime(2025, 3, 29, 14, 30);
  final timedEnd = DateTime(2025, 3, 29, 15, 30);
  print('timed');
  print('dates: ${formatDates(timedStart, timedEnd)}');
  print(getGcalUrl(
    'Sample timed event',
    'Description line',
    timedStart,
    timedEnd,
    'Ithaca, NY',
  ));
  print('');

  // Time event that lasts multiple days
  final timedStart1 = DateTime(2025, 3, 29, 1, 30);
  final timedEnd1 = DateTime(2025, 3, 31, 12, 30);
  print('timed');
  print('dates: ${formatDates(timedStart1, timedEnd1)}');
  print(getGcalUrl(
    'Sample timed event 1',
    'Heyy what\'s up eveyrone! \n How you doing?',
    timedStart1,
    timedEnd1,
    'Bailey Hall',
  ));
  print('');

  // All-day (both at local midnight) midnight 3/29 to midnight 3/31, so 3/29-3/30
  final allDayStart = DateTime(2025, 3, 29);
  final allDayEnd = DateTime(2025, 3, 31);
  print('all-day (two midnights)');
  print('dates: ${formatDates(allDayStart, allDayEnd)}');
  print(getGcalUrl(
    'Sample all-day',
    '',
    allDayStart,
    allDayEnd,
    '',
  ));
  print('');

  // Single calendar day all-day
  final single = DateTime(2025, 3, 29);
  print('all-day same start/end midnight');
  print('dates: ${formatDates(single, single)}');
  print(getGcalUrl('One day', '', single, single, ''));
}
