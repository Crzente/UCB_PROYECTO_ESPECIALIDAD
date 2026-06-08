import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/providers/student_provider.dart';
import '../../../../presentation/providers/user_management_provider.dart';
import '../../../../presentation/providers/group_provider.dart';
import '../../../../presentation/providers/enrollment_provider.dart';
import '../../../../presentation/providers/course_provider.dart'; // Added
import '../../../../presentation/providers/course_bundle_provider.dart';
import '../../../../domain/entities/enrollment.dart';
import '../../../../domain/entities/student.dart';
import '../../../../domain/entities/user.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
      context.read<UserManagementProvider>().loadUsers();
      context.read<GroupProvider>().loadGroups();
      context.read<CourseProvider>().loadCourses();
      context.read<CourseBundleProvider>().loadBundles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final students = studentProvider.students;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        Expanded(child: _buildStudentList(students, studentProvider.isLoading)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alumnos",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Gestión de Perfiles e Inscripciones",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showRegisterStudentDialog(context),
          icon: const Icon(Icons.person_add),
          label: const Text("Vincular Nuevo Alumno"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _handleStudentAction(
    BuildContext context,
    String action,
    Student student,
  ) {
    if (action == 'toggle_status') {
      _toggleStudentStatus(context, student);
    } else if (action == 'delete') {
      _handleDeleteStudent(context, student);
    } else if (action == 'enroll') {
      _showEnrollDialog(context, student);
    } else if (action == 'view_enrollments') {
      _showStudentEnrollmentsDialog(context, student);
    } else if (action == 'unenroll_all') {
      _handleUnenrollAll(context, student);
    } else if (action == 'view_profile') {
      _showStudentProfileDialog(context, student);
    } else if (action == 'edit') {
      _showEditProfileDialog(context, student);
    }
  }

  void _handleUnenrollAll(BuildContext context, Student student) async {
    final enrollmentProvider = context.read<EnrollmentProvider>();
    await enrollmentProvider.loadStudentEnrollments(student.userId);
    final enrollments = enrollmentProvider.studentEnrollments;

    if (enrollments.isEmpty) return;

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Anular Inscripciones"),
        content: Text(
          "¿Desea anular TODAS las inscripciones de ${student.user?.name}? Esta acción eliminará sus notas de forma permanente.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Anular Todo"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var e in enrollments) {
        await enrollmentProvider.unenrollStudent(e.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscripciones anuladas correctamente")),
        );
        // Refresh
        context.read<StudentProvider>().loadStudents();
      }
    }
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  void _toggleStudentStatus(BuildContext context, Student student) async {
    final isActive = student.status == 'active';
    final newStatus = isActive ? 'blocked' : 'active';

    final studentProvider = context.read<StudentProvider>();
    final userProvider = context.read<UserManagementProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? "Desactivar Alumno" : "Activar Alumno"),
        content: Text(
          "¿Desea ${isActive ? 'desactivar' : 'activar'} a ${student.user?.name ?? 'este alumno'} y su cuenta de usuario asociada?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? "Desactivar" : "Activar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Update Student status
      final updatedStudent = student.copyWith(status: newStatus);
      await studentProvider.updateStudent(updatedStudent);

      // 2. Update User status (synchronize)
      if (student.user != null) {
        final updatedUser = User(
          id: student.user!.id,
          email: student.user!.email,
          name: student.user!.name,
          role: student.user!.role,
          status: newStatus,
        );
        await userProvider.updateUser(updatedUser);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Alumno ${newStatus == 'active' ? 'activado' : 'desactivado'} correctamente",
            ),
          ),
        );
      }
    }
  }

  void _handleDeleteStudent(BuildContext context, Student student) async {
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final studentProvider = context.read<StudentProvider>();
    final userProvider = context.read<UserManagementProvider>();

    await enrollmentProvider.loadStudentEnrollments(student.userId);
    final hasEnrollments = enrollmentProvider.studentEnrollments.isNotEmpty;

    if (hasEnrollments) {
      // Rule: If has courses, cannot delete. Only deactivate.
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No se puede eliminar"),
          content: const Text(
            "Este alumno está o estuvo inscrito en uno o más cursos. No se puede eliminar. Se procederá a desactivarlo y desactivar su cuenta. ¿Desea continuar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Desactivar"),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        // Change status to blocked/desactivado
        final updatedStudent = Student(
          id: student.id,
          userId: student.userId,
          studentCode: student.studentCode,
          status: 'blocked',
          user: student.user,
        );
        await studentProvider.updateStudent(updatedStudent);

        if (student.user != null) {
          final updatedUser = User(
            id: student.user!.id,
            email: student.user!.email,
            name: student.user!.name,
            role: student.user!.role,
            status: 'blocked',
          );
          await userProvider.updateUser(updatedUser);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Alumno desactivado")));
        }
      }
    } else {
      // Rule: No courses, delete both.
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmar Eliminación"),
          content: const Text(
            "Este alumno no está inscrito en ningún curso. Su registro y la cuenta asociada serán eliminados. ¿Desea continuar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Eliminar"),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        // Delete student
        await studentProvider.deleteStudent(student.id);
        // Delete user
        await userProvider.deleteUser(student.userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Alumno y cuenta eliminados")),
          );
        }
      }
    }
  }

  Widget _buildStudentList(List<Student> students, bool isLoading) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No hay alumnos registrados",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        itemCount: students.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final student = students[index];
          final name = student.user?.name ?? "Desconocido";

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  backgroundImage:
                      (student.profileImage != null &&
                          student.profileImage!.isNotEmpty)
                      ? MemoryImage(base64Decode(student.profileImage!))
                      : null,
                  child:
                      (student.profileImage == null ||
                          student.profileImage!.isEmpty)
                      ? const Icon(Icons.school, color: Colors.blue)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: student.user?.status == 'active'
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Grado: ${student.grade.isEmpty ? 'Sin completar' : student.grade}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) =>
                  _handleStudentAction(context, value, student),
              itemBuilder: (context) {
                return [
                  _buildPopupItem(
                    'view_profile',
                    Icons.person_outline,
                    "Ver Perfil",
                  ),
                  _buildPopupItem('edit', Icons.edit_outlined, "Editar"),
                  _buildPopupItem(
                    'view_enrollments',
                    Icons.assignment_ind_outlined,
                    "Inscripciones",
                  ),
                  const PopupMenuDivider(),
                  _buildPopupItem(
                    'delete',
                    Icons.delete_outline,
                    "Eliminar",
                    color: Colors.red,
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }

  void _showStudentProfileDialog(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_circle, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Text(
              "Perfil del Alumno",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PROFILE IMAGE
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (student.profileImage != null &&
                            student.profileImage!.isNotEmpty)
                        ? MemoryImage(base64Decode(student.profileImage!))
                        : null,
                    child:
                        (student.profileImage == null ||
                            student.profileImage!.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                // DATOS PERSONALES
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DATOS PERSONALES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Divider(thickness: 2),
                _datoEstudiante(
                  'Nombres y apellidos',
                  student.user?.name ?? '-',
                ),
                _datoEstudiante(
                  'Fecha de nacimiento',
                  student.birthDate != null
                      ? "${student.birthDate!.day.toString().padLeft(2, '0')}/${student.birthDate!.month.toString().padLeft(2, '0')}/${student.birthDate!.year}"
                      : '-',
                ),
                _datoEstudiante('Carnet de Identidad', student.identityCard),
                _datoEstudiante('Carnet Militar', student.militaryCard),
                _datoEstudiante('Carnet de Seguro', student.insuranceCard),
                _datoEstudiante('Celular', student.phone),
                _datoEstudiante(
                  'Correo electrónico',
                  student.user?.email ?? '-',
                ),

                const SizedBox(height: 16),
                // SITUACIÓN MILITAR
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SITUACIÓN MILITAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Divider(thickness: 2),
                _datoEstudiante('Escalafón', _escalafonPorGrado(student.grade)),
                _datoEstudiante('Grado', student.grade),
                if (student.specialty != null && student.specialty!.isNotEmpty)
                  _datoEstudiante(
                    'Formación / Especialidad',
                    student.specialty!,
                  ),
                if (student.graduationYear != null &&
                    student.graduationYear!.isNotEmpty)
                  _datoEstudiante(
                    'Año de egreso II.MM.',
                    student.graduationYear!,
                  ),
                if (student.courseSeniority != null)
                  _datoEstudiante(
                    'Antigüedad en el curso',
                    student.courseSeniority!.toString(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Student student) {
    final nameCtrl = TextEditingController(text: student.user?.name);
    final identityCtrl = TextEditingController(text: student.identityCard);
    final militaryCardCtrl = TextEditingController(text: student.militaryCard);
    final insuranceCardCtrl = TextEditingController(
      text: student.insuranceCard,
    );
    final phoneCtrl = TextEditingController(text: student.phone);
    final specialtyCtrl = TextEditingController(text: student.specialty);
    final gradYearCtrl = TextEditingController(text: student.graduationYear);
    final seniorityCtrl = TextEditingController(
      text: student.courseSeniority?.toString(),
    );
    const Map<String, List<String>> gradosPorGrupo = {
      'Oficiales Superiores y Subalternos': [
        'Subteniente',
        'Teniente',
        'Capitán',
        'Mayor',
        'Teniente Coronel',
        'Coronel',
      ],
      'Suboficiales y Sargentos': [
        'Sargento Inicial',
        'Sargento Segundo',
        'Sargento Primero',
        'Suboficial Inicial',
        'Suboficial Segundo',
        'Suboficial Primero',
        'Suboficial Mayor',
      ],
    };

    String? selectedGroup;
    String selectedGrade = student.grade.isEmpty
        ? 'Subteniente'
        : student.grade;
    DateTime? selectedDate = student.birthDate;
    String? base64Image = student.profileImage;
    final picker = ImagePicker();

    // Detect group from current grade
    for (var entry in gradosPorGrupo.entries) {
      if (entry.value.contains(selectedGrade)) {
        selectedGroup = entry.key;
        break;
      }
    }
    selectedGroup ??= 'Oficiales Superiores y Subalternos';
    if (!gradosPorGrupo[selectedGroup]!.contains(selectedGrade)) {
      selectedGrade = gradosPorGrupo[selectedGroup]!.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            "Completar Perfil Académico",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROFILE IMAGE PICKER
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (base64Image != null && base64Image!.isNotEmpty)
                              ? MemoryImage(base64Decode(base64Image!))
                              : null,
                          child: (base64Image == null || base64Image!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () async {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 50,
                                maxWidth: 400,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setState(() {
                                  base64Image = base64Encode(bytes);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // DATOS PERSONALES HEADER
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DATOS PERSONALES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombres y apellidos",
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: identityCtrl,
                          decoration: const InputDecoration(
                            labelText: "Carnet Identidad",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime(2000),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Fecha de Nacimiento",
                            ),
                            child: Text(
                              selectedDate == null
                                  ? 'Seleccionar...'
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: militaryCardCtrl,
                          decoration: const InputDecoration(
                            labelText: "Carnet Militar",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: insuranceCardCtrl,
                          decoration: const InputDecoration(
                            labelText: "Carnet Seguro",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: "Celular"),
                  ),

                  const SizedBox(height: 24),
                  // SITUACIÓN MILITAR HEADER
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SITUACIÓN MILITAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: selectedGroup,
                    decoration: const InputDecoration(labelText: "Escalafón"),
                    items: gradosPorGrupo.keys
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedGroup = v!;
                        selectedGrade = gradosPorGrupo[v]!.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGrade,
                    decoration: const InputDecoration(labelText: "Grado"),
                    items: gradosPorGrupo[selectedGroup]!
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedGrade = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialtyCtrl,
                    decoration: const InputDecoration(
                      labelText: "Especialidad / Curso Militar",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradYearCtrl,
                    decoration: const InputDecoration(
                      labelText: "Año de egreso II.MM.",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: seniorityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Antigüedad en el curso",
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final userProvider = context.read<UserManagementProvider>();
                final studentProvider = context.read<StudentProvider>();

                // Update User Info (sync profile image and name)
                if (student.user != null) {
                  final updatedUser = User(
                    id: student.user!.id,
                    email: student.user!.email,
                    name: nameCtrl.text,
                    role: student.user!.role,
                    status: student.user!.status,
                    profileImage: base64Image,
                  );
                  await userProvider.updateUser(
                    updatedUser,
                  );
                }

                final updatedStudent = Student(
                  id: student.id,
                  userId: student.userId,
                  studentCode: student.studentCode,
                  status: student.status,
                  user: student.user?.copyWith(name: nameCtrl.text),
                  birthDate: selectedDate,
                  identityCard: identityCtrl.text,
                  militaryCard: militaryCardCtrl.text,
                  insuranceCard: insuranceCardCtrl.text,
                  phone: phoneCtrl.text,
                  grade: selectedGrade,
                  specialty: specialtyCtrl.text,
                  graduationYear: gradYearCtrl.text,
                  courseSeniority: int.tryParse(seniorityCtrl.text),
                  profileImage: base64Image,
                );
                await studentProvider.updateStudent(
                  updatedStudent,
                );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perfil actualizado")),
                  );
                }
              },
              child: const Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentEnrollmentsDialog(BuildContext context, Student student) {
    // Load enrollments for this student (using userId which is what's in enrollments table)
    context.read<EnrollmentProvider>().loadStudentEnrollments(student.userId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Inscripciones de ${student.user?.name ?? 'Alumno'}"),
        content: SizedBox(
          width: 500,
          child: Consumer<EnrollmentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.studentEnrollments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("El alumno no está inscrito en ningún curso."),
                );
              }

              // Group by Bundle Name or ID
              final grouped = <String, List<Enrollment>>{};
              for (var e in provider.studentEnrollments) {
                final key = e.bundleName ?? 'Sin Curso';
                grouped.putIfAbsent(key, () => []).add(e);
              }

              return ListView(
                shrinkWrap: true,
                children: grouped.entries.map((entry) {
                  final bundleName = entry.key;
                  final bundleEnrollments = entry.value;
                  final firstEnrollment = bundleEnrollments.first;
                  final status = firstEnrollment.status;

                  Color statusColor = Colors.green;
                  IconData statusIcon = Icons.check_circle;

                  if (status == 'Suspendido') {
                    statusColor = Colors.orange;
                    statusIcon = Icons.pause_circle_filled;
                  } else if (status == 'Retirado') {
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                  } else if (status == 'Finalizado') {
                    statusColor = Colors.blue;
                    statusIcon = Icons.flag;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          tileColor: statusColor.withValues(alpha: 0.1),
                          title: Row(
                            children: [
                              Text(
                                bundleName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "${bundleEnrollments.length} materias inscritas",
                          ),
                          trailing: null,
                        ),
                        ...bundleEnrollments.map((en) {
                          return ListTile(
                            dense: true,
                            enabled: status == 'En curso',
                            leading: Icon(
                              Icons.book,
                              size: 16,
                              color: status == 'En curso'
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                            ),
                            title: Text(
                              en.courseName ?? "Materia",
                              style: TextStyle(
                                color: status == 'En curso'
                                      ? Colors.black
                                      : Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              "Grupo: ${en.groupName ?? '-'}",
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _showRegisterStudentDialog(BuildContext context) {
    final userProvider = context.read<UserManagementProvider>();
    final studentProvider = context.read<StudentProvider>();

    // Filtrar candidatos: solo usuarios con rol 'student' que NO estén ya vinculados
    List<User> candidates = userProvider.users.where((u) {
      final isStudentRole = u.role == 'student';
      final alreadyLinked = studentProvider.students.any(
        (s) => s.userId == u.id,
      );
      return isStudentRole && !alreadyLinked;
    }).toList();
    User? selectedUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Vincular Persona como Alumno"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Seleccione una persona existente para crear su perfil académico.",
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                isExpanded: true,
                hint: const Text("Seleccionar Persona"),
                items: candidates
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text("${u.name} (${u.email})"),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedUser = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedUser != null) {
                  try {
                    // Safety check for student code generation
                    final idSnippet = selectedUser!.id.length >= 4
                        ? selectedUser!.id.substring(0, 4)
                        : selectedUser!.id;

                    final newStudent = Student(
                      id: selectedUser!.id,
                      userId: selectedUser!.id,
                      studentCode: "S-$idSnippet",
                      status: 'active',
                      user: selectedUser,
                    );

                    await context.read<StudentProvider>().createStudent(
                      newStudent,
                    );

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Perfil de alumno vinculado exitosamente",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Automatically show edit profile after linking
                      _showEditProfileDialog(context, newStudent);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error al vincular: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED DIALOG: Select "Course Bundle" (CourseBundle entity)
  void _showEnrollDialog(BuildContext context, Student student) async {
    final studentName = student.user?.name ?? "Alumno";
    final groupProvider = context.read<GroupProvider>();
    final bundleProvider = context.read<CourseBundleProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();

    // Load necessary data
    await enrollmentProvider.loadStudentEnrollments(student.userId);
    if (bundleProvider.bundles.isEmpty) {
      await bundleProvider.loadBundles();
    }

    String? selectedBundleId;
    List<dynamic> bundleSubjects = [];
    bool isAlreadyEnrolledInYear = false;
    String? existingCourseInYear;

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final bundles = bundleProvider.bundles;

          // Filter subjects for preview and check for duplicates
          if (selectedBundleId != null) {
            final bundle = bundles.firstWhere((b) => b.id == selectedBundleId);
            bundleSubjects = groupProvider.groups
                .where((g) => g.bundleId == selectedBundleId)
                .toList();

            // Check if student is already in THIS curso
            final matchesBundle = enrollmentProvider.studentEnrollments.where((
              e,
            ) {
              final enrol = e as dynamic;
              return enrol.bundleId == selectedBundleId;
            }).toList();

            if (matchesBundle.isNotEmpty) {
              isAlreadyEnrolledInYear = true;
              existingCourseInYear = bundle.name;
            } else {
              // Check if they are in ANOTHER bundle of the SAME YEAR
              final sameYearEnrol = enrollmentProvider.studentEnrollments.where(
                (e) {
                  final enrol = e as dynamic;
                  return enrol.academicYear == bundle.academicYear;
                },
              ).toList();

              if (sameYearEnrol.isNotEmpty) {
                isAlreadyEnrolledInYear = true;
                existingCourseInYear =
                    (sameYearEnrol.first as dynamic).bundleName ?? "Otro curso";
              } else {
                isAlreadyEnrolledInYear = false;
                existingCourseInYear = null;
              }
            }
          }

          return AlertDialog(
            title: Text(
              "Inscribir a $studentName",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "La inscripción es por CURSO. Seleccione el curso y el sistema inscribirá todas sus materias automáticamente.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Seleccione Curso:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (bundles.isEmpty)
                    const Text(
                      "No hay cursos abiertos disponibles.",
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text("Seleccione un Curso..."),
                      items: bundles.map((bundle) {
                        return DropdownMenuItem(
                          value: bundle.id,
                          child: Text(
                            "${bundle.name} (${bundle.academicYear})",
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedBundleId = val;
                        });
                      },
                    ),

                  if (selectedBundleId != null) ...[
                    const SizedBox(height: 16),
                    if (isAlreadyEnrolledInYear)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "El alumno ya está inscrito en '$existingCourseInYear'. Debe desinscribirlo para inscribirlo en un nuevo curso de esta gestión.",
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        "Materias incluidas (${bundleSubjects.length}):",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bundleSubjects.isEmpty)
                        const Text(
                          "Este curso no tiene materias registradas.",
                          style: TextStyle(color: Colors.orange),
                        )
                      else
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: bundleSubjects.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final group = bundleSubjects[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  group.courseName ?? "Materia",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  group.teacherName ?? "Sin docente",
                                ),
                                leading: const Icon(
                                  Icons.book,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              if (bundles.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  onPressed:
                      (selectedBundleId == null || isAlreadyEnrolledInYear)
                      ? null
                      : () async {
                          try {
                            Navigator.pop(ctx);

                            final bundle = bundles.firstWhere(
                              (b) => b.id == selectedBundleId,
                            );

                            await enrollmentProvider
                                .enrollStudentInAcademicBundle(
                                  bundle.id,
                                  student.userId,
                                );

                            if (context.mounted) {
                              context.read<StudentProvider>().loadStudents();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "✅ Éxito: Alumno inscrito en '${bundle.name}'.",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  label: const Text("Confirmar Inscripción"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  // --- PROFILE HELPERS ---

  String _escalafonPorGrado(String grado) {
    const oficiales = [
      'Subteniente',
      'Teniente',
      'Capitán',
      'Mayor',
      'Teniente Coronel',
      'Coronel',
    ];
    const suboficiales = [
      'Sargento Inicial',
      'Sargento Segundo',
      'Sargento Primero',
      'Suboficial Inicial',
      'Suboficial Segundo',
      'Suboficial Primero',
      'Suboficial Mayor',
    ];
    if (oficiales.contains(grado)) return 'Oficiales Superiores y Subalternos';
    if (suboficiales.contains(grado)) return 'Suboficiales y Sargentos';
    return '-';
  }

  Widget _datoEstudiante(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
