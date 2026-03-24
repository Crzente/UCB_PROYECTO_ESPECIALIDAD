class Grade {
  final String id;
  final String enrollmentId; // Links to Student + Group
  final String evaluationPeriodId; // Links to "Parcial 1"
  final double? score; // 8.5 or null

  const Grade({
    required this.id,
    required this.enrollmentId,
    required this.evaluationPeriodId,
    this.score,
  });
}
