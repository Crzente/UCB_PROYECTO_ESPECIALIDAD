import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/military_rank_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/providers/teacher_provider.dart';
import '../../../../presentation/providers/user_management_provider.dart';
import '../../../../presentation/providers/group_provider.dart';
import '../../../../presentation/providers/course_bundle_provider.dart';
import '../../../../domain/entities/teacher.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/entities/group.dart';

class TeacherManagementTab extends StatefulWidget {
  const TeacherManagementTab({super.key});

  @override
  State<TeacherManagementTab> createState() => _TeacherManagementTabState();
}

class _TeacherManagementTabState extends State<TeacherManagementTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().loadTeachers();
      context.read<UserManagementProvider>().loadUsers();
      context.read<GroupProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final teachers = teacherProvider.teachers;
    final allGroups = groupProvider.groups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        Expanded(
          child: _buildTeacherList(
            teachers,
            allGroups,
            teacherProvider.isLoading,
          ),
        ),
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
              "Docentes",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Gestión Académica de Docentes",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showRegisterTeacherDialog(context),
          icon: const Icon(Icons.person_add_alt),
          label: const Text("Vincular Docente"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
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

  Widget _buildTeacherList(
    List<Teacher> teachers,
    List<Group> allGroups,
    bool isLoading,
  ) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No hay docentes registrados",
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        itemCount: teachers.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          final name = teacher.user?.name ?? "Desconocido";
          // Use full grade for display
          final gradeDisplay = teacher.grade.isNotEmpty
              ? teacher.grade
              : 'Sin Grado';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage:
                      (teacher.profileImage != null &&
                          teacher.profileImage!.isNotEmpty)
                      ? MemoryImage(base64Decode(teacher.profileImage!))
                      : null,
                  child:
                      (teacher.profileImage == null ||
                          teacher.profileImage!.isEmpty)
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
                      color: teacher.user?.status == 'active'
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
              "Grado: $gradeDisplay",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) =>
                  _handleTeacherAction(context, value, teacher),
              itemBuilder: (context) {
                return [
                  _buildPopupItem(
                    'view_profile',
                    Icons.person_outline,
                    "Ver Perfil",
                  ),
                  _buildPopupItem(
                    'edit_profile',
                    Icons.edit_outlined,
                    "Editar Perfil",
                  ),
                  _buildPopupItem(
                    'view_assignments',
                    Icons.list_alt,
                    "Ver Carga Académica",
                  ),
                  _buildPopupItem('delete', Icons.delete_outline, "Eliminar"),
                ];
              },
            ),
          );
        },
      ),
    );
  }

  void _showTeacherAssignmentsDialog(
    BuildContext context,
    Teacher teacher,
    List<Group> allGroups,
  ) {
    // ... same content as before ...
    final assignments = allGroups
        .where((g) => g.teacherId == teacher.id)
        .toList();
    final bundleProvider = context.read<CourseBundleProvider>();
    final bundles = bundleProvider.bundles;

    // Grouping logic
    final Map<String, List<Group>> groupedByBundle = {};
    for (var g in assignments) {
      final bId = g.bundleId ?? 'unassigned';
      groupedByBundle.putIfAbsent(bId, () => []).add(g);
    }

    final sortedBundleIds = groupedByBundle.keys.toList()
      ..sort((a, b) {
        if (a == 'unassigned') return 1;
        if (b == 'unassigned') return -1;
        final bA = bundles.cast<dynamic>().firstWhere(
          (b) => b.id == a,
          orElse: () => null,
        );
        final bB = bundles.cast<dynamic>().firstWhere(
          (b) => b.id == b,
          orElse: () => null,
        );
        return (bA?.name ?? '').compareTo(bB?.name ?? '');
      });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Carga Académica: ${teacher.user?.name ?? ''}",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: assignments.isEmpty
            ? SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    "Sin materias asignadas actualmente.",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedBundleIds.length,
                  itemBuilder: (ctx, bIdx) {
                    final bundleId = sortedBundleIds[bIdx];
                    final bundleGroups = groupedByBundle[bundleId]!;
                    final bundle = bundles.cast<dynamic>().firstWhere(
                      (b) => b.id == bundleId,
                      orElse: () => null,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.class_rounded,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bundle?.name ?? "Materias Independientes",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...bundleGroups.map((group) {
                          return Container(
                            margin: const EdgeInsets.only(left: 12, bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.auto_stories_rounded,
                                size: 16,
                                color: Colors.blue,
                              ),
                              title: Text(
                                group.courseName ?? 'Materia',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                "Grupo: ${group.name} • Gestión: ${group.year}",
                                style: GoogleFonts.poppins(fontSize: 11),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                      ],
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

  void _handleTeacherAction(
    BuildContext context,
    String action,
    Teacher teacher,
  ) {
    if (action == 'toggle_status') {
      _toggleTeacherStatus(context, teacher);
    } else if (action == 'view_profile') {
      _showTeacherProfileDialog(context, teacher);
    } else if (action == 'edit_profile') {
      _showEditProfileDialog(context, teacher);
    } else if (action == 'view_assignments') {
      final allGroups = context.read<GroupProvider>().groups;
      _showTeacherAssignmentsDialog(context, teacher, allGroups);
    } else if (action == 'delete') {
      _handleDeleteTeacher(context, teacher);
    }
  }

  void _showTeacherProfileDialog(BuildContext context, Teacher teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_circle, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Text(
              "Perfil del Docente",
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
                        (teacher.profileImage != null &&
                            teacher.profileImage!.isNotEmpty)
                        ? MemoryImage(base64Decode(teacher.profileImage!))
                        : null,
                    child:
                        (teacher.profileImage == null ||
                            teacher.profileImage!.isEmpty)
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
                _datoDocente('Nombres y apellidos', teacher.user?.name ?? '-'),
                _datoDocente(
                  'Fecha de nacimiento',
                  teacher.birthDate != null
                      ? "${teacher.birthDate!.day.toString().padLeft(2, '0')}/${teacher.birthDate!.month.toString().padLeft(2, '0')}/${teacher.birthDate!.year}"
                      : '-',
                ),
                _datoDocente('Carnet de Identidad', teacher.identityCard),
                _datoDocente('Carnet Militar', teacher.militaryCard),
                _datoDocente('Carnet de Seguro', teacher.insuranceCard),
                _datoDocente('Celular', teacher.phone),
                _datoDocente('Correo electrónico', teacher.user?.email ?? '-'),

                const SizedBox(height: 16),
                // SITUACIÓN MILITAR/ACADÉMICA
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'INFORMACIÓN ACADÉMICA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Divider(thickness: 2),
                _datoDocente(
                  'Escalafón',
                  MilitaryRankUtils.obtenerEscalafon(teacher.grade),
                ),
                _datoDocente('Grado', teacher.grade),
                _datoDocente('Especialidad/Arma', teacher.specialty ?? '-'),
                _datoDocente('Año de egreso', teacher.graduationYear ?? '-'),
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

  Widget _datoDocente(String label, String value) {
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

  void _showEditProfileDialog(BuildContext context, Teacher teacher) {
    final nameCtrl = TextEditingController(text: teacher.user?.name);
    final identityCtrl = TextEditingController(text: teacher.identityCard);
    final phoneCtrl = TextEditingController(text: teacher.phone);
    final insuranceCardCtrl = TextEditingController(
      text: teacher.insuranceCard,
    );
    final militaryCardCtrl = TextEditingController(text: teacher.militaryCard);
    final specialtyCtrl = TextEditingController(text: teacher.specialty);
    final gradYearCtrl = TextEditingController(text: teacher.graduationYear);

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

    String selectedGrade = teacher.grade.isNotEmpty
        ? teacher.grade
        : 'Subteniente';
    String? selectedGroup;
    DateTime? selectedDate = teacher.birthDate;
    String? base64Image = teacher.profileImage;
    final picker = ImagePicker();

    // Detect group from current grade (Student logic)
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
        builder: (ctx, setState) {
          Future<void> pickImage() async {
            try {
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 400,
                imageQuality: 50,
              );
              if (image != null) {
                final bytes = await image.readAsBytes();
                setState(() {
                  base64Image = base64Encode(bytes);
                });
              }
            } catch (e) {
              debugPrint('Error picking image: $e');
            }
          }

          return AlertDialog(
            title: Text(
              "Completar Perfil Docente",
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
                              onTap: pickImage,
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
                                initialDate: selectedDate ?? DateTime(1980),
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
                    // INFO ACADÉMICA / MILITAR
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
                      value: selectedGroup,
                      decoration: const InputDecoration(labelText: "Escalafón"),
                      items: gradosPorGrupo.keys
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
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
                      value: selectedGrade,
                      decoration: const InputDecoration(labelText: "Grado"),
                      items: gradosPorGrupo[selectedGroup]!
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedGrade = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specialtyCtrl,
                      decoration: const InputDecoration(
                        labelText: "Arma o Especialidad",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: gradYearCtrl,
                      decoration: const InputDecoration(
                        labelText: "Año de Egreso",
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
                  // Update User Info if name changed
                  if (teacher.user != null &&
                      nameCtrl.text != teacher.user!.name) {
                    final updatedUser = teacher.user!.copyWith(
                      name: nameCtrl.text,
                    );
                    await context.read<UserManagementProvider>().updateUser(
                      updatedUser,
                    );
                  }

                  final updatedTeacher = teacher.copyWith(
                    grade: selectedGrade,
                    specialty: specialtyCtrl.text,
                    graduationYear: gradYearCtrl.text,
                    identityCard: identityCtrl.text,
                    phone: phoneCtrl.text,
                    birthDate: selectedDate,
                    militaryCard: militaryCardCtrl.text,
                    insuranceCard: insuranceCardCtrl.text,
                    profileImage: base64Image,
                  );

                  await context.read<TeacherProvider>().updateTeacher(
                    updatedTeacher,
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Perfil actualizado correctamente"),
                      ),
                    );
                  }
                },
                child: const Text("Guardar Cambios"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleTeacherStatus(BuildContext context, Teacher teacher) async {
    final isActive = teacher.status == 'active';
    final newStatus = isActive ? 'blocked' : 'active';

    final teacherProvider = context.read<TeacherProvider>();
    final userProvider = context.read<UserManagementProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? "Desactivar Docente" : "Activar Docente"),
        content: Text(
          "¿Desea ${isActive ? 'desactivar' : 'activar'} a ${teacher.user?.name ?? 'este docente'} y su cuenta de usuario asociada?",
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
      // 1. Update Teacher status
      final updatedTeacher = Teacher(
        id: teacher.id,
        userId: teacher.userId,
        teacherCode: teacher.teacherCode,
        status: newStatus,
        user: teacher.user,
      );
      await teacherProvider.updateTeacher(updatedTeacher);

      // 2. Update User status (synchronize)
      if (teacher.user != null) {
        final updatedUser = User(
          id: teacher.user!.id,
          email: teacher.user!.email,
          name: teacher.user!.name,
          role: teacher.user!.role,
          status: newStatus,
        );
        await userProvider.updateUser(updatedUser);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Docente ${newStatus == 'active' ? 'activado' : 'desactivado'} correctamente",
            ),
          ),
        );
      }
    }
  }

  void _handleDeleteTeacher(BuildContext context, Teacher teacher) async {
    final groupProvider = context.read<GroupProvider>();
    // Check if teacher has assigned groups (historical or current)
    final hasGroups = groupProvider.groups.any(
      (g) => g.teacherId == teacher.id,
    );

    if (hasGroups) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No se puede eliminar"),
          content: const Text(
            "Este docente está o estuvo asignado a una o más materias. No se puede eliminar. Se procederá a desactivarlo y desactivar su cuenta. ¿Desea continuar?",
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
        final updatedTeacher = Teacher(
          id: teacher.id,
          userId: teacher.userId,
          teacherCode: teacher.teacherCode,
          status: 'blocked',
          user: teacher.user,
        );
        await context.read<TeacherProvider>().updateTeacher(updatedTeacher);

        if (teacher.user != null) {
          final updatedUser = User(
            id: teacher.user!.id,
            email: teacher.user!.email,
            name: teacher.user!.name,
            role: teacher.user!.role,
            status: 'blocked',
          );
          await context.read<UserManagementProvider>().updateUser(updatedUser);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Docente desactivado")));
        }
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmar Eliminación"),
          content: const Text(
            "Este docente no tiene historial académico vinculado. Su registro y la cuenta asociada serán eliminados. ¿Desea continuar?",
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
        await context.read<TeacherProvider>().deleteTeacher(teacher.id);
        await context.read<UserManagementProvider>().deleteUser(teacher.userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Docente y cuenta eliminados")),
          );
        }
      }
    }
  }

  void _showRegisterTeacherDialog(BuildContext context) {
    final userProvider = context.read<UserManagementProvider>();
    final teacherProvider = context.read<TeacherProvider>();

    // Filtrar candidatos: solo usuarios con rol 'teacher' que NO estén ya vinculados
    // Usamos el getter isTeacher para mayor seguridad
    List<User> candidates = userProvider.users.where((u) {
      final isTeacherRole = u.isTeacher;
      final alreadyLinked = teacherProvider.teachers.any(
        (t) => t.userId == u.id,
      );
      return isTeacherRole && !alreadyLinked;
    }).toList();
    User? selectedUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Vincular Persona como Docente"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Seleccione una persona existente para registrarla como docente.",
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
                  final newTeacher = Teacher(
                    id: selectedUser!.id,
                    userId: selectedUser!.id,
                    teacherCode: "T-${selectedUser!.id.substring(0, 4)}",
                    status: 'active',
                  );

                  // Create teacher
                  await context.read<TeacherProvider>().createTeacher(
                    newTeacher,
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);

                    // Show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Docente registrado. Por favor complete su perfil.",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Open edit dialog immediately to fill profile
                    _showEditProfileDialog(context, newTeacher);
                  }
                }
              },
              child: const Text("Registrar y Llenar Perfil"),
            ),
          ],
        ),
      ),
    );
  }
}
