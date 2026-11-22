import '../../core/units/units.dart';
import 'currencies.dart';
import 'home_answers.dart';

/// What the app sends when an assessment is finished (backend `POST /api/v1/assessments`): the
/// answers, and what the report is to be written in, fixed now: the language, the country (formats,
/// currency), the units the assessment was answered in, the person's own calendar day, and the day
/// they started answering (today when not known).
Map<String, dynamic> submissionBody({
  required HomeAnswers answers,
  required String language,
  required String country,
  required UnitSystem units,
  required DateTime now,
}) {
  final place = answers.place;
  final address = [
    if (place != null && place.title.isNotEmpty) place.title,
    if (place != null && place.detail.isNotEmpty) place.detail,
  ].join(', ');
  String two(int v) => v.toString().padLeft(2, '0');
  String day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  return {
    'language': language,
    'country': country.toUpperCase(),
    'unitSystem': (answers.unitSystem ?? units).name.toUpperCase(),
    'currency': answers.currency ?? currencyOf(country),
    'madeOn': day(now),
    'startedOn': day(answers.startedOn ?? now),
    'address': address,
    'answers': answers.toJson(),
  };
}
