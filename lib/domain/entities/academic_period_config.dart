class AcademicPeriodConfig {
  final String id;
  final String name; // "Bimestre 1", "Semestre 2"
  final int orderIndex; // 1, 2, 3...
  final double defaultWeight; // 25.0

  const AcademicPeriodConfig({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.defaultWeight,
  });
}
