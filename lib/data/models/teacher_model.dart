import '../../domain/entities/teacher.dart';
import '../../domain/entities/user.dart';
import 'user_model.dart';

class TeacherModel extends Teacher {
  const TeacherModel({
    required super.id,
    required super.userId,
    super.teacherCode = '',
    super.status = 'active',
    super.user,
    super.birthDate,
    super.identityCard = '',
    super.militaryCard = '',
    super.insuranceCard = '',
    super.phone = '',
    super.grade = '',
    super.specialty,
    super.graduationYear,
    super.profileImage,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, {User? user}) {
    return TeacherModel(
      id: map['id'],
      userId: map['user_id'],
      teacherCode: map['teacher_code'] ?? '',
      status: map['status'] ?? 'active',
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'])
          : null,
      identityCard: map['identity_card'] ?? '',
      militaryCard: map['military_card'] ?? '',
      insuranceCard: map['insurance_card'] ?? '',
      phone: map['phone'] ?? '',
      grade: map['grade'] ?? '',
      specialty: map['specialty'],
      graduationYear: map['graduation_year'],
      profileImage: map['profile_image'],
      user:
          user ??
          (map['user_name'] != null
              ? UserModel(
                  id: map['user_id'],
                  email: map['user_email'] ?? '',
                  name: map['user_name'] ?? '',
                  role: 'teacher',
                  status: map['user_status'] ?? 'active',
                )
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'teacher_code': teacherCode,
      'status': status,
      'birth_date': birthDate?.toIso8601String(),
      'identity_card': identityCard,
      'military_card': militaryCard,
      'insurance_card': insuranceCard,
      'phone': phone,
      'grade': grade,
      'specialty': specialty,
      'graduation_year': graduationYear,
      'profile_image': profileImage,
    };
  }
}
