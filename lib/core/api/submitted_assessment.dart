/// A finished assessment the backend has kept (POST /api/v1/assessments).
class SubmittedAssessment {
  const SubmittedAssessment({required this.reportNumber, required this.madeOn, required this.validUntil, this.address = ''});

  factory SubmittedAssessment.fromJson(Map<String, dynamic> json) => SubmittedAssessment(
        reportNumber: json['reportNumber'] as String,
        madeOn: DateTime.parse(json['madeOn'] as String),
        validUntil: DateTime.parse(json['validUntil'] as String),
        address: json['address'] as String? ?? '',
      );

  /// The place as the app named it when it was sent ("Strada X 29, Cluj-Napoca"); may be empty.
  final String address;

  /// WSE-year-month-number, e.g. WSE-2026-11-00417.
  final String reportNumber;

  /// The day it was made, and the last day the report is valid (the last day of the month before,
  /// a year on).
  final DateTime madeOn;
  final DateTime validUntil;
}
