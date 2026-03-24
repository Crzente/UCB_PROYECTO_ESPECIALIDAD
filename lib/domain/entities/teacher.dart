import 'user.dart';

class Teacher {
  final String id;
  final String userId;
  final String teacherCode;
  final String status;
  final User? user;

  // Profile Fields (same as Student)
  final DateTime? birthDate;
  final String identityCard;
  final String militaryCard;
  final String insuranceCard;
  final String phone;
  final String grade;
  final String? specialty;
  final String? graduationYear;
  final String? profileImage; // Base64 or Path

  const Teacher({
    required this.id,
    required this.userId,
    this.teacherCode = '',
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
    this.profileImage,
  });

  Teacher copyWith({
    String? id,
    String? userId,
    String? teacherCode,
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
    String? profileImage,
  }) {
    return Teacher(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teacherCode: teacherCode ?? this.teacherCode,
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
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
