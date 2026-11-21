/// Calendars that bills use instead of the Gregorian one (decided with Timi, 2026-11-21): in Iran the
/// Solar Hijri (Persian) calendar, in Ethiopia the Ethiopian one, in Nepal Bikram Sambat. The month
/// pickers there show the local month, with the Gregorian month it mostly falls in after it; the
/// answers stay Gregorian months (0–11).
///
/// Each local month starts in the second half of a Gregorian month, so it mostly covers the next
/// one: Farvardin (21 March – 20 April) is April, Meskerem (11 September – 10 October) is September,
/// Baisakh (about 14 April – 14 May) is April. Ethiopia's short 13th month (Pagume, 6–10 September)
/// is left out; bills are for the twelve.
class LocalCalendar {
  const LocalCalendar(this.months, this.firstGregorian);

  /// The local months in order, from the first of the year.
  final List<String> months;

  /// The Gregorian month (0–11) the first local month mostly falls in.
  final int firstGregorian;

  /// The local month that mostly falls in Gregorian month [m] (0–11).
  String monthFor(int m) => months[(m - firstGregorian) % 12];
}

const _persian = LocalCalendar([
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
], 3);

const _ethiopian = LocalCalendar([
  'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት', 'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ',
], 8);

const _nepali = LocalCalendar([
  'बैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 'पुस', 'माघ', 'फागुन', 'चैत',
], 3);

/// The calendar bills use in [country], or null for the Gregorian one.
LocalCalendar? localCalendarOf(String? country) => switch (country?.toUpperCase()) {
      'IR' => _persian,
      'ET' => _ethiopian,
      'NP' => _nepali,
      _ => null,
    };

/// "فروردین (April)" where bills use another calendar; just "April" elsewhere.
String monthLabel(int m, String gregorianName, String? country) {
  final local = localCalendarOf(country);
  return local == null ? gregorianName : '${local.monthFor(m)} ($gregorianName)';
}
