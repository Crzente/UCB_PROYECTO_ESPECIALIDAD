import 'user.dart';

class Student {
  final String id;
  final String userId;
  final String studentCode;
  final String status;
  final User? user;

  // New Fields
  final DateTime? birthDate;
  final String identityCard;
  final String militaryCard;
  final String insuranceCard;
  final String phone;
  final String grade;
  final String? specialty;
  final String? graduationYear;
  final int? courseSeniority;
  final String? profileImage; // Base64 or Path

  const Student({
    required this.id,
    required this.userId,
    this.studentCode = '',
    this.status = 'active',
    this.user,
    this.birthDate,
    this.identityCard = '',
    this.militaryCard = '',
    this.insuranceCard = '',
    this.phone = '',
    this.grade = '',
    this.specialty,
    this.graduationYear,
    this.courseSeniority,
    this.profileImage,
  });

  Student copyWith({
    String? id,
    String? userId,
    String? studentCode,
    String? status,
    User? user,
    DateTime? birthDate,
    String? identityCard,
    String? militaryCard,
    String? insuranceCard,
    String? phone,
    String? grade,
    String? specialty,
    String? graduationYear,
    int? courseSeniority,
    String? profileImage,
  }) {
    return Student(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentCode: studentCode ?? this.studentCode,
      status: status ?? this.status,
      user: user ?? this.user,
      birthDate: birthDate ?? this.birthDate,
      identityCard: identityCard ?? this.identityCard,
      militaryCard: militaryCard ?? this.militaryCard,
      insuranceCard: insuranceCard ?? this.insuranceCard,
      phone: phone ?? this.phone,
      grade: grade ?? this.grade,
      specialty: specialty ?? this.specialty,
      graduationYear: graduationYear ?? this.graduationYear,
      courseSeniority: courseSeniority ?? this.courseSeniority,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
