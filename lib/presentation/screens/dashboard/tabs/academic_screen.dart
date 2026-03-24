import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/providers/course_provider.dart';
import '../../../../presentation/providers/group_provider.dart';
import '../../../../presentation/providers/course_bundle_provider.dart';
import '../../../../domain/entities/group.dart';
import '../../../../domain/entities/course.dart';
import 'group_detail_screen.dart';
import 'subject_detail_screen.dart';
import 'teacher_assignment_tab.dart';
import 'bundle_detail_screen.dart';
import '../../../../presentation/providers/student_provider.dart';
import '../../../../presentation/providers/enrollment_provider.dart';
import '../../../../domain/entities/student.dart';
import '../../../../domain/entities/enrollment.dart';
import '../../../../core/utils/rank_sorter.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      context.read<GroupProvider>().loadGroups();
      context.read<GroupProvider>().loadTeachers();
      context.read<CourseBundleProvider>().loadBundles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gestión Académica",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2563EB),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Materias (Catálogo)"),
                Tab(text: "Cursos Abiertos"),
                Tab(text: "Asignación Docente"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildSubjectsTab(context),
                _buildBundlesTab(),
                const TeacherAssignmentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundlesTab() {
    final bundleProvider = context.watch<CourseBundleProvider>();
    final groupProvider = context.watch<GroupProvider>();

    if (bundleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bundleProvider.bundles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No hay cursos abiertos",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCreateBundleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Abrir Nuevo Curso"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateBundleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("Abrir Nuevo Curso"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bundleProvider.bundles.length,
            itemBuilder: (context, index) {
              final bundle = bundleProvider.bundles[index];
              final bundleGroups = groupProvider.groups
                  .where((g) => g.bundleId == bundle.id)
                  .toList();

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.class_rounded, color: Colors.blue),
                  ),
                  title: Text(
                    bundle.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    "Gestión ${bundle.academicYear} • ${bundleGroups.length} Materias",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Ver Reporte y Alumnos",
                        icon: const Icon(
                          Icons.assessment_rounded,
                          color: Colors.indigo,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BundleDetailScreen(bundle: bundle),
                            ),
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF64748B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          if (val == 'add') {
                            _showAddSubjectToBundleDialog(
                              context,
                              bundle.id,
                              bundle.name,
                              bundle.academicYear,
                            );
                          } else if (val == 'enroll') {
                            _showEnrollStudentsDialog(
                              context,
                              bundle.id,
                              bundle.name,
                            );
                          } else if (val == 'delete') {
                            _showDeleteBundleDialog(
                              context,
                              bundle.id,
                              bundle.name,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          _buildPopupItem(
                            'add',
                            Icons.add_circle_outline,
                            "Agregar Materia",
                          ),
                          _buildPopupItem(
                            'enroll',
                            Icons.person_add_alt_1_outlined,
                            "Inscribir Alumnos",
                          ),
                          _buildPopupItem(
                            'delete',
                            Icons.delete_outline,
                            "Eliminar Curso",
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: const Color(0xFFF8FAFC),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lista de Materias",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (bundleGroups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  "No hay materias vinculadas",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF94A3B8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: bundleGroups.length,
                              itemBuilder: (context, i) {
                                final group = bundleGroups[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.auto_stories_rounded,
                                      size: 18,
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
                                      "Docente: ${group.teacherName ?? 'Sin asignar'}",
                                      style: GoogleFonts.poppins(fontSize: 11),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              _handleDeleteSubjectInBundle(
                                                context,
                                                group,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GroupDetailScreen(group: group),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleDeleteSubjectInBundle(BuildContext context, Group group) async {
    final groupProvider = context.read<GroupProvider>();
    final canDelete = await groupProvider.canDeleteGroup(group.id);

    if (!context.mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            "Materia con Alumnos",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: Text(
            "Esta materia tiene alumnos con notas registradas. No se puede eliminar hasta que el curso sea archivado por completo.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Entendido"),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Eliminar Materia",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "¿Desea eliminar '${group.courseName}' de este curso? Se perderán las configuraciones de evaluación para esta materia.",
          style: GoogleFonts.poppins(),
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

    if (confirm == true) {
      await groupProvider.deleteGroup(group.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Materia eliminada del curso")),
        );
      }
    }
  }

  void _showCreateBundleDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedYear = DateTime.now().year;
    final availableYears = List.generate(
      5,
      (index) => DateTime.now().year - 1 + index,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Nuevo Curso',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Curso',
                hintText: 'Ej: 1ro Secundaria A',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Gestión',
                border: OutlineInputBorder(),
              ),
              value: selectedYear,
              items: availableYears
                  .map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedYear = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await context.read<CourseBundleProvider>().createBundle(
                  nameController.text,
                  selectedYear,
                );
                if (context.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Crear Curso'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBundleDialog(
    BuildContext context,
    String bundleId,
    String bundleName,
  ) async {
    final bundleProvider = context.read<CourseBundleProvider>();
    final canDelete = await bundleProvider.canDeleteBundle(bundleId);

    if (!context.mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Eliminación Bloqueada',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: Text(
            'No se puede eliminar el curso "$bundleName" porque todavía tiene materias activas o alumnos con registros históricos. Retire las materias o asegúrese de que el curso esté vacío primero.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Eliminar Curso',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de eliminar el curso "$bundleName"? Esta acción eliminará el curso permanentemente ya que no contiene alumnos ni materias activas.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await bundleProvider.deleteBundle(bundleId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Curso eliminado")),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectToBundleDialog(
    BuildContext context,
    String bundleId,
    String bundleName,
    int year,
  ) {
    final groupProvider = context.read<GroupProvider>();
    final courseProvider = context.read<CourseProvider>();
    groupProvider.loadTeachers();

    String? selectedCourseId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(
              'Agregar Materia a $bundleName',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Materia (del catálogo)',
                      border: OutlineInputBorder(),
                    ),
                    items: courseProvider.courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCourseId = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCourseId != null) {
                    try {
                      await context.read<GroupProvider>().addGroup(
                        selectedCourseId!,
                        'unassigned',
                        bundleName,
                        year,
                        bundleId: bundleId,
                      );

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Materia agregada exitosamente"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("❌ Error: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Por favor seleccione una materia"),
                      ),
                    );
                  }
                },
                child: const Text('Agregar Materia'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEnrollStudentsDialog(
    BuildContext context,
    String bundleId,
    String bundleName,
  ) {
    // Trigger loads immediately
    context.read<StudentProvider>().loadStudents();
    context.read<EnrollmentProvider>().loadBundleEnrollments(bundleId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use Consumer to rebuild dialog when providers update (loading finishes)
        return Consumer2<StudentProvider, EnrollmentProvider>(
          builder: (context, studentProvider, enrollmentProvider, child) {
            final isLoading =
                studentProvider.isLoading || enrollmentProvider.isLoading;

            return _EnrollmentDialogContent(
              bundleId: bundleId,
              bundleName: bundleName,
              students: studentProvider.students,
              currentEnrollments: enrollmentProvider.enrollments,
              isLoading: isLoading,
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectsTab(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    if (courseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (courseProvider.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No hay materias registradas",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCourseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Nueva Materia"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Sorting logic: Primary by Code (case-insensitive), Secondary by Name
    final sortedCourses = List.from(courseProvider.courses)
      ..sort((a, b) {
        String codeA = (a.code ?? "").trim().toUpperCase();
        String codeB = (b.code ?? "").trim().toUpperCase();

        int codeCompare = codeA.compareTo(codeB);
        if (codeCompare != 0) return codeCompare;

        return a.name.trim().toLowerCase().compareTo(
          b.name.trim().toLowerCase(),
        );
      });

    return Column(
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Catálogo de Materias",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Gestiona las asignaturas base del sistema",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCourseDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Nueva Materia"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List area
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            itemCount: sortedCourses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final course = sortedCourses[index];
              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Row(
                      children: [
                        // Code Column
                        SizedBox(
                          width: 100,
                          child: Text(
                            course.code ?? "S/C",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        // Professional Separator
                        Container(
                          height: 24,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.grey.shade300,
                        ),
                        // Name/Description Column
                        Expanded(
                          child: Text(
                            course.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCourseDialog(context, course: course);
                        } else if (value == 'delete') {
                          _showDeleteCourseDialog(
                            context,
                            course.id,
                            course.name,
                          );
                        } else if (value == 'setup') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubjectDetailScreen(course: course),
                            ),
                          );
                        } else if (value == 'view') {
                          _showSubjectDetailsDialog(context, course);
                        }
                      },
                      itemBuilder: (context) => [
                        _buildPopupItem(
                          'view',
                          Icons.visibility_outlined,
                          "Ver detalle",
                        ),
                        _buildPopupItem('edit', Icons.edit_outlined, "Editar"),
                        _buildPopupItem(
                          'setup',
                          Icons.settings_outlined,
                          "Configurar evaluación",
                        ),
                        const PopupMenuDivider(),
                        _buildPopupItem(
                          'delete',
                          Icons.delete_outline,
                          "Eliminar",
                          color: Colors.red,
                        ),
                      ],
                    ),
                    onTap: () => _showSubjectDetailsDialog(context, course),
                  ),
                ),
              );
            },
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

  void _showSubjectDetailsDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Detalles de la Materia",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("Código", course.code ?? "S/C"),
              _detailRow("Nombre", course.name),
              _detailRow(
                "Tipo",
                course.type == 'theoretical'
                    ? 'Teórica'
                    : (course.type == 'practical' ? 'Práctica' : 'Mixta'),
              ),
              _detailRow("Créditos", course.credits.toString()),
              _detailRow("Obligatoria", course.isMandatory ? "Sí" : "No"),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Descripción:",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  course.description ?? "Sin descripción",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDialog(BuildContext context, {Course? course}) {
    final nameController = TextEditingController(text: course?.name);
    final descController = TextEditingController(text: course?.description);
    final codeController = TextEditingController(text: course?.code);
    final creditsController = TextEditingController(
      text: (course?.credits ?? 0).toString(),
    );

    String selectedType = course?.type ?? 'mixed';
    bool isMandatory = course?.isMandatory ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                course == null ? 'Nueva Materia' : 'Editar Materia',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: codeController,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  return newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                  );
                                }),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Código',
                                border: OutlineInputBorder(),
                                hintText: 'EJ: MAT-101',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'theoretical',
                                  child: Text("Teórica"),
                                ),
                                DropdownMenuItem(
                                  value: 'practical',
                                  child: Text("Práctica"),
                                ),
                                DropdownMenuItem(
                                  value: 'mixed',
                                  child: Text("Mixta"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: creditsController,
                              decoration: const InputDecoration(
                                labelText: 'Créditos',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Materia Obligatoria"),
                        value: isMandatory,
                        onChanged: (val) => setState(() => isMandatory = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final provider = context.read<CourseProvider>();
                      if (course == null) {
                        await provider.addCourse(
                          name: nameController.text,
                          description: descController.text,
                          code: codeController.text.trim().toUpperCase(),
                          credits: int.tryParse(creditsController.text) ?? 0,
                          type: selectedType,
                          isMandatory: isMandatory,
                        );
                      } else {
                        await provider.updateCourse(
                          id: course.id,
                          name: nameController.text,
                          description: descController.text,
                          code: codeController.text.trim().toUpperCase(),
                          credits: int.tryParse(creditsController.text) ?? 0,
                          type: selectedType,
                          isMandatory: isMandatory,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(course == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteCourseDialog(
    BuildContext context,
    String courseId,
    String courseName,
  ) async {
    final courseProvider = context.read<CourseProvider>();
    final canDelete = await courseProvider.canDeleteCourse(courseId);

    if (!context.mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Eliminación Bloqueada',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: Text(
            'Esta materia aún tiene cursos activos. No se puede eliminar hasta que se eliminen todos los cursos asociados.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Materia',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          '¿Está seguro de eliminar la materia "$courseName"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await courseProvider.deleteCourse(courseId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Materia eliminada')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentDialogContent extends StatefulWidget {
  final String bundleId;
  final String bundleName;
  final List<Student> students;
  final List<Enrollment> currentEnrollments;
  final bool isLoading;

  const _EnrollmentDialogContent({
    required this.bundleId,
    required this.bundleName,
    required this.students,
    required this.currentEnrollments,
    required this.isLoading,
  });

  @override
  State<_EnrollmentDialogContent> createState() =>
      _EnrollmentDialogContentState();
}

class _EnrollmentDialogContentState extends State<_EnrollmentDialogContent> {
  late Set<String> initialEnrolledIds;
  late Set<String> selectedStudentIds;
  bool isInitialized = false;
  bool isSaving = false;
  String searchQuery = "";

  // Optimization: Pre-calculated list and image cache
  List<Student> _filteredStudents = [];
  final Map<String, Uint8List> _decodedImages = {};

  @override
  void didUpdateWidget(covariant _EnrollmentDialogContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Initialize once data is ready and not already initialized
    if (!isInitialized && !widget.isLoading) {
      _initializeSelection();
      _updateFilteredStudents();
    } else if (isInitialized &&
        (oldWidget.students != widget.students ||
            oldWidget.isLoading != widget.isLoading)) {
      _updateFilteredStudents();
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _initializeSelection();
      _updateFilteredStudents();
    } else {
      // Start with empty sets if loading
      initialEnrolledIds = {};
      selectedStudentIds = {};
    }
  }

  void _updateFilteredStudents() {
    if (widget.isLoading) return;

    final filtered = widget.students.where((s) {
      final isUserActive = s.user?.status == 'active';
      final matchSearch =
          searchQuery.isEmpty ||
          (s.user?.name ?? "").toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          s.identityCard.contains(searchQuery);
      return isUserActive && matchSearch;
    }).toList();

    // Sort by Military Rank and Seniority
    final sorted = RankSorter.sortStudents(filtered);

    // Cache images
    for (var student in filtered) {
      if (student.profileImage != null &&
          student.profileImage!.isNotEmpty &&
          !_decodedImages.containsKey(student.id)) {
        try {
          _decodedImages[student.id] = base64Decode(student.profileImage!);
        } catch (e) {
          // Skip invalid images
        }
      }
    }

    setState(() {
      _filteredStudents = sorted;
    });
  }

  void _initializeSelection() {
    initialEnrolledIds = widget.currentEnrollments
        .map((e) => e.studentId)
        .toSet();
    selectedStudentIds = Set.from(initialEnrolledIds);
    isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final visibleIds = _filteredStudents.map((s) => s.id).toSet();
    final allSelected =
        visibleIds.isNotEmpty &&
        visibleIds.every((id) => selectedStudentIds.contains(id));

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestionar Inscripciones',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Text(
            widget.bundleName,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            TextField(
              enabled: !widget.isLoading,
              decoration: const InputDecoration(
                labelText: "Buscar Alumno",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) {
                setState(() => searchQuery = val);
                _updateFilteredStudents();
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_filteredStudents.length} listados",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                if (_filteredStudents.isNotEmpty)
                  TextButton(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            setState(() {
                              if (allSelected) {
                                selectedStudentIds.removeAll(visibleIds);
                              } else {
                                selectedStudentIds.addAll(visibleIds);
                              }
                            });
                          },
                    child: Text(
                      allSelected ? "Desseleccionar Todo" : "Seleccionar Todo",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: allSelected
                            ? Colors.red
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (widget.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: _filteredStudents.isEmpty
                  ? Center(
                      child: Text(
                        widget.isLoading
                            ? "Cargando..."
                            : "No se encontraron alumnos.",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final isSelected = selectedStudentIds.contains(
                          student.id,
                        );
                        final originallyEnrolled = initialEnrolledIds.contains(
                          student.id,
                        );

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isSelected,
                          enabled: !widget.isLoading,
                          activeColor: originallyEnrolled
                              ? Colors.green
                              : Colors.blue,
                          onChanged: widget.isLoading
                              ? null
                              : (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedStudentIds.add(student.id);
                                    } else {
                                      selectedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                          title: Text(
                            student.user?.name ?? "Sin Nombre",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            "${student.grade} ${student.specialty?.isNotEmpty == true ? '- ${student.specialty}' : ''}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 20,
                            backgroundColor: originallyEnrolled
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            backgroundImage:
                                _decodedImages.containsKey(student.id)
                                ? MemoryImage(_decodedImages[student.id]!)
                                : null,
                            child: !_decodedImages.containsKey(student.id)
                                ? Text(
                                    (student.user?.name ?? "A")
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: originallyEnrolled
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          onPressed: isSaving || !isInitialized
              ? null
              : () => _handleSave(context),
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Guardar Cambios"),
        ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final enrollmentProvider = context.read<EnrollmentProvider>();

    // Calculate differences
    final toEnroll = selectedStudentIds.difference(initialEnrolledIds);
    final toUnenroll = initialEnrolledIds.difference(selectedStudentIds);

    if (toEnroll.isEmpty && toUnenroll.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Confirmation if unenrolling
    if (toUnenroll.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmar cambios"),
          content: Text(
            "Se inscribirán ${toEnroll.length} alumnos.\nSe RETIRARÁN ${toUnenroll.length} alumnos (esto podría eliminar sus notas).",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Continuar"),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => isSaving = true);

    try {
      int added = 0;
      int removed = 0;
      List<String> errors = [];

      // Process Enrollments
      for (final sId in toEnroll) {
        try {
          await enrollmentProvider.enrollStudentInAcademicBundle(
            widget.bundleId,
            sId,
          );
          added++;
        } catch (e) {
          errors.add("Error inscribiendo alumno: $e");
        }
      }

      // Process Unenrollments
      for (final sId in toUnenroll) {
        try {
          await enrollmentProvider.unenrollStudentFromBundle(
            sId,
            widget.bundleId,
          );
          removed++;
        } catch (e) {
          errors.add("Error retirando alumno: $e");
        }
      }

      if (mounted) {
        Navigator.pop(context);

        String message = "Cambios guardados.";
        if (added > 0) message += " Inscritos: $added.";
        if (removed > 0) message += " Retirados: $removed.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errors.isEmpty ? Colors.green : Colors.orange,
          ),
        );

        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Avisos"),
              content: SingleChildScrollView(child: Text(errors.join("\n"))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Ok"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error general: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
