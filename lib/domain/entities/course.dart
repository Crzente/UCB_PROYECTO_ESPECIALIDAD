class Course {
  final String id;
  final String name;
  final String? description;
  final String? code;
  final int credits;
  final String type; // 'theoretical', 'practical', 'mixed'
  final bool isMandatory;
  final String? teacherId; // Assigned teacher

  const Course({
    required this.id,
    required this.name,
    this.description,
    this.code, // New
    this.credits = 0, // New
    this.type = 'mixed', // New
    this.isMandatory = true, // New
    this.teacherId, // New
  });
}
