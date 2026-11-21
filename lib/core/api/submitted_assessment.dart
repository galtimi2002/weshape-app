/// A finished assessment the backend has kept (POST /api/v1/assessments).
class SubmittedAssessment {
  const SubmittedAssessment({required this.reportNumber, required this.madeOn, required this.validUntil});

  factory SubmittedAssessment.fromJson(Map<String, dynamic> json) => SubmittedAssessment(
        reportNumber: json['reportNumber'] as String,
        madeOn: DateTime.parse(json['madeOn'] as String),
        validUntil: DateTime.parse(json['validUntil'] as String),
      );

  /// WSE-year-month-number, e.g. WSE-2026-11-00417.
  final String reportNumber;

  /// The day it was made, and the last day the report is valid (the last day of the month before,
  /// a year on).
  final DateTime madeOn;
  final DateTime validUntil;
}
