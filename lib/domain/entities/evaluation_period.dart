class EvaluationPeriod {
  final String id;
  final String groupId;
  final String name; // e.g. "Bimestre 1", "Parcial 1"
  final double weight; // e.g. 25.0 (percent)

  const EvaluationPeriod({
    required this.id,
    required this.groupId,
    required this.name,
    required this.weight,
  });
}
