import '../../domain/entities/evaluation_period.dart';

class EvaluationPeriodModel extends EvaluationPeriod {
  const EvaluationPeriodModel({
    required String id,
    required String groupId,
    required String name,
    required double weight,
  }) : super(id: id, groupId: groupId, name: name, weight: weight);

  factory EvaluationPeriodModel.fromMap(Map<String, dynamic> map) {
    return EvaluationPeriodModel(
      id: map['id'],
      groupId: map['group_id'],
      name: map['name'],
      weight: (map['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'group_id': groupId, 'name': name, 'weight': weight};
  }

  factory EvaluationPeriodModel.fromEntity(EvaluationPeriod period) {
    return EvaluationPeriodModel(
      id: period.id,
      groupId: period.groupId,
      name: period.name,
      weight: period.weight,
    );
  }
}
