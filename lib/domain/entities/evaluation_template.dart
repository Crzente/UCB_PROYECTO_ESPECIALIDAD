class EvaluationTemplate {
  final String id;
  final String courseId;
  final String name;
  final double weight;

  EvaluationTemplate({
    required this.id,
    required this.courseId,
    required this.name,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'course_id': courseId, 'name': name, 'weight': weight};
  }

  factory EvaluationTemplate.fromMap(Map<String, dynamic> map) {
    return EvaluationTemplate(
      id: map['id'],
      courseId: map['course_id'],
      name: map['name'],
      weight: (map['weight'] as num).toDouble(),
    );
  }
}
