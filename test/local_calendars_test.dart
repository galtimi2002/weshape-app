// Bills in Iran, Ethiopia and Nepal use their own calendars: the month pickers show the local month
// first, then the Gregorian one it mostly falls in.

import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/i18n/local_calendars.dart';

void main() {
  test('Iran: Farvardin (21 March – 20 April) is April, Esfand is March', () {
    final c = localCalendarOf('IR')!;
    expect(c.monthFor(3), 'فروردین');
    expect(c.monthFor(2), 'اسفند');
    expect(c.monthFor(11), 'آذر'); // December
  });

  test('Ethiopia: Meskerem (11 September – 10 October) is September, Nehase is August', () {
    final c = localCalendarOf('et')!;
    expect(c.monthFor(8), 'መስከረም');
    expect(c.monthFor(7), 'ነሐሴ');
    expect(c.monthFor(0), 'ጥር'); // January
  });

  test('Nepal: Baisakh (mid-April – mid-May) is April, Chaitra is March', () {
    final c = localCalendarOf('NP')!;
    expect(c.monthFor(3), 'बैशाख');
    expect(c.monthFor(2), 'चैत');
  });

  test('every Gregorian month gets a different local month', () {
    for (final country in ['IR', 'ET', 'NP']) {
      final c = localCalendarOf(country)!;
      expect({for (var m = 0; m < 12; m++) c.monthFor(m)}, hasLength(12), reason: country);
    }
  });

  test('the label: local month, then ours; elsewhere just ours', () {
    expect(monthLabel(3, 'April', 'IR'), 'فروردین (April)');
    expect(monthLabel(3, 'április', 'HU'), 'április');
    expect(monthLabel(3, 'April', null), 'April');
  });
}
