import '../../domain/entities/student.dart';
import '../../domain/entities/user.dart';
import 'user_model.dart';

class StudentModel extends Student {
  const StudentModel({
    required String id,
    required String userId,
    String studentCode = '',
    String status = 'active',
    User? user,
    DateTime? birthDate,
    String identityCard = '',
    String militaryCard = '',
    String insuranceCard = '',
    String phone = '',
    String grade = '',
    String? specialty,
    String? graduationYear,
    int? courseSeniority,
    String? profileImage,
  }) : super(
         id: id,
         userId: userId,
         studentCode: studentCode,
         status: status,
         user: user,
         birthDate: birthDate,
         identityCard: identityCard,
         militaryCard: militaryCard,
         insuranceCard: insuranceCard,
         phone: phone,
         grade: grade,
         specialty: specialty,
         graduationYear: graduationYear,
         courseSeniority: courseSeniority,
         profileImage: profileImage,
       );

  factory StudentModel.fromMap(Map<String, dynamic> map, {User? user}) {
    return StudentModel(
      id: map['id'],
      userId: map['user_id'],
      studentCode: map['student_code'] ?? '',
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
      courseSeniority: map['course_seniority'],
      profileImage: map['profile_image'],
      user:
          user ??
          (map['user_name'] != null
              ? UserModel(
                  id: map['user_id'],
                  email: map['user_email'] ?? '',
                  name: map['user_name'] ?? '',
                  role: 'student', // inferred
                  status: map['user_status'] ?? 'active',
                )
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'student_code': studentCode,
      'status': status,
      'birth_date': birthDate?.toIso8601String(),
      'identity_card': identityCard,
      'military_card': militaryCard,
      'insurance_card': insuranceCard,
      'phone': phone,
      'grade': grade,
      'specialty': specialty,
      'graduation_year': graduationYear,
      'course_seniority': courseSeniority,
      'profile_image': profileImage,
    };
  }
}
