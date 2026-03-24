import '../../domain/entities/grade.dart';

class GradeModel extends Grade {
  const GradeModel({
    required String id,
    required String enrollmentId,
    required String evaluationPeriodId,
    double? score,
  }) : super(
         id: id,
         enrollmentId: enrollmentId,
         evaluationPeriodId: evaluationPeriodId,
         score: score,
       );

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'],
      enrollmentId: map['enrollment_id'],
      evaluationPeriodId: map['evaluation_period_id'],
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enrollment_id': enrollmentId,
      'evaluation_period_id': evaluationPeriodId,
      'score': score,
    };
  }

  factory GradeModel.fromEntity(Grade grade) {
    return GradeModel(
      id: grade.id,
      enrollmentId: grade.enrollmentId,
      evaluationPeriodId: grade.evaluationPeriodId,
      score: grade.score,
    );
  }
}
