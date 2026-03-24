import '../../domain/entities/student.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/entities/enrollment.dart';

class RankSorter {
  static final Map<String, int> _rankOrder = {
    'Coronel': 1,
    'Teniente Coronel': 2,
    'Mayor': 3,
    'Capitán': 4,
    'Teniente': 5,
    'Subteniente': 6,
    'Suboficial Mayor': 7,
    'Suboficial Primero': 8,
    'Suboficial Segundo': 9,
    'Suboficial Inicial': 10,
    'Sargento Primero': 11,
    'Sargento Segundo': 12,
    'Sargento Inicial': 13,
    'Cadete': 14,
    'Alumno': 15,
  };

  /// Sorts a list of [Student] objects by military rank, graduation year and course seniority.
  static List<Student> sortStudents(List<Student> students) {
    // Make a mutable copy to sort
    final List<Student> sortedList = List.from(students);
    sortedList.sort(
      (a, b) => _compareRanks(
        a.grade,
        a.graduationYear,
        a.courseSeniority,
        b.grade,
        b.graduationYear,
        b.courseSeniority,
      ),
    );
    return sortedList;
  }

  /// Sorts a list of [Teacher] objects by military rank and graduation year.
  static List<Teacher> sortTeachers(List<Teacher> teachers) {
    final List<Teacher> sortedList = List.from(teachers);
    sortedList.sort(
      (a, b) => _compareRanks(
        a.grade,
        a.graduationYear,
        null,
        b.grade,
        b.graduationYear,
        null,
      ),
    );
    return sortedList;
  }

  /// Sorts a list of [Enrollment] objects by military rank, graduation year and course seniority.
  static List<Enrollment> sortEnrollments(List<Enrollment> enrollments) {
    final List<Enrollment> sortedList = List.from(enrollments);
    sortedList.sort(
      (a, b) => _compareRanks(
        a.grade ?? '',
        a.graduationYear,
        a.courseSeniority,
        b.grade ?? '',
        b.graduationYear,
        b.courseSeniority,
      ),
    );
    return sortedList;
  }

  /// Helper comparison function
  static int _compareRanks(
    String gradeA,
    String? graduationYearA,
    int? seniorityA,
    String gradeB,
    String? graduationYearB,
    int? seniorityB,
  ) {
    final ordenA = _rankOrder[gradeA] ?? 999;
    final ordenB = _rankOrder[gradeB] ?? 999;

    if (ordenA != ordenB) {
      return ordenA.compareTo(ordenB);
    }

    // If same rank, break tie by graduation year
    final anioA = int.tryParse(graduationYearA ?? '') ?? 9999;
    final anioB = int.tryParse(graduationYearB ?? '') ?? 9999;

    if (anioA != anioB) {
      return anioA.compareTo(anioB);
    }

    // If same graduation year, break tie by seniority in course (1 is most senior)
    final senA = seniorityA ?? 999;
    final senB = seniorityB ?? 999;
    return senA.compareTo(senB);
  }
}
