import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weshape_app/core/api/api_client.dart';
import 'package:weshape_app/core/api/api_exception.dart';
import 'package:weshape_app/core/auth/demo_auth_service.dart';
import 'package:weshape_app/core/units/units.dart';
import 'package:weshape_app/features/assessment/home_answers.dart';
import 'package:weshape_app/features/assessment/submission.dart';

/// Sending a finished assessment (backend POST /api/v1/assessments; decided with Timi, 2026-11-21).
void main() {
  HomeAnswers sample() => HomeAnswers()
    ..unitSystem = UnitSystem.metric
    ..audience = Audience.home
    ..place = const AssessmentPlace(lat: 46.7712, lon: 23.5897, title: 'Strada X 29', detail: 'Cluj-Napoca')
    ..priority = Priority.upfront;

  group('what is sent', () {
    test('the answers, with the language, country, units, currency and the person\'s own day', () {
      final a = sample();
      final body = submissionBody(
        answers: a,
        language: 'hu',
        country: 'ro',
        units: UnitSystem.us, // the profile now; the assessment keeps the units it was answered in
        now: DateTime(2026, 3, 7, 23, 50),
      );
      expect(body['language'], 'hu');
      expect(body['country'], 'RO');
      expect(body['unitSystem'], 'METRIC');
      expect(body['currency'], 'RON', reason: 'no currency picked: the country\'s');
      expect(body['madeOn'], '2026-03-07', reason: 'the local calendar day, two digits for month and day');
      expect(body['startedOn'], '2026-03-07', reason: 'not known: the same day');
      expect(body['address'], 'Strada X 29, Cluj-Napoca');
      expect(body['answers'], a.toJson());
      expect(jsonDecode(jsonEncode(body)), isA<Map<String, dynamic>>(), reason: 'it must go as JSON');
      a.dispose();
    });

    test('a currency picked in the questions wins; units not yet fixed take the profile\'s', () {
      final a = sample()
        ..currency = 'EUR'
        ..unitSystem = null;
      final body = submissionBody(answers: a, language: 'en', country: 'RO', units: UnitSystem.us, now: DateTime(2026));
      expect(body['currency'], 'EUR');
      expect(body['unitSystem'], 'US');
      a.dispose();
    });

    test('the day the answers were started is sent, and kept with the answers', () {
      final a = sample()..startedOn = DateTime(2026, 3, 1, 9);
      final body = submissionBody(answers: a, language: 'en', country: 'RO', units: UnitSystem.metric, now: DateTime(2026, 3, 7));
      expect(body['startedOn'], '2026-03-01');
      expect(HomeAnswers.fromJsonForTest(a.toJson()).startedOn, DateTime(2026, 3, 1, 9));
      a.dispose();
    });

    test('a place without a name sends an empty address', () {
      final a = sample()..place = const AssessmentPlace(lat: 1, lon: 2);
      expect(submissionBody(answers: a, language: 'en', country: 'DE', units: UnitSystem.metric, now: DateTime(2026))['address'], '');
      a.dispose();
    });
  });

  group('the call', () {
    test('posts the body and reads the report number and dates', () async {
      late http.Request sent;
      final api = ApiClient(
        authService: DemoAuthService(),
        baseUrl: 'http://api.test',
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({'reportNumber': 'WSE-2026-11-00417', 'madeOn': '2026-11-14', 'validUntil': '2027-10-31'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final saved = await api.submitAssessment({'language': 'en', 'answers': <String, dynamic>{}});
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://api.test/api/v1/assessments');
      expect(jsonDecode(sent.body), {'language': 'en', 'answers': <String, dynamic>{}});
      expect(saved.reportNumber, 'WSE-2026-11-00417');
      expect(saved.madeOn, DateTime(2026, 11, 14));
      expect(saved.validUntil, DateTime(2027, 10, 31));
    });

    test('a refused assessment comes back as an error with the faults', () async {
      final api = ApiClient(
        authService: DemoAuthService(),
        baseUrl: 'http://api.test',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({'message': 'The assessment is not complete', 'fieldErrors': {'answers.priority': 'missing'}}),
              400,
            )),
      );
      await expectLater(
        api.submitAssessment({}),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.fieldErrors['answers.priority'], 'fault', 'missing')),
      );
    });
  });
}
