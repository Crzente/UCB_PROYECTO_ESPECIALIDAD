import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/providers/group_provider.dart';
import '../../../../presentation/providers/course_bundle_provider.dart';
import '../../../../domain/entities/group.dart';
import '../../../../domain/entities/user.dart';

class TeacherAssignmentTab extends StatefulWidget {
  const TeacherAssignmentTab({super.key});

  @override
  State<TeacherAssignmentTab> createState() => _TeacherAssignmentTabState();
}

class _TeacherAssignmentTabState extends State<TeacherAssignmentTab> {
  int? _selectedYear;
  String? _selectedBundleId;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseBundleProvider>().loadBundles();
      context.read<GroupProvider>().loadGroups();
      context.read<GroupProvider>().loadTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundleProvider = context.watch<CourseBundleProvider>();
    final groupProvider = context.watch<GroupProvider>();

    // Available years from bundles
    final years =
        bundleProvider.bundles.map((b) => b.academicYear).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    // Correct selection if needed to avoid Dropdown errors
    if (years.isNotEmpty &&
        (_selectedYear == null || !years.contains(_selectedYear))) {
      _selectedYear = years.first;
    }

    // Bundles filtered by year
    final filteredBundles = bundleProvider.bundles
        .where((b) => b.academicYear == _selectedYear)
        .toList();

    // Subjects (Groups) for the selected bundle
    final subjectsEnrolled = groupProvider.groups
        .where((g) => g.bundleId == _selectedBundleId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(years, filteredBundles),
        const SizedBox(height: 24),
        if (_selectedBundleId == null)
          _buildEmptyState(
            "Seleccione un curso para gestionar las asignaciones.",
          )
        else
          Expanded(
            child: _buildAssignmentList(
              subjectsEnrolled,
              groupProvider.teachers,
              groupProvider,
            ),
          ),
      ],
    );
  }

  Widget _buildFilters(List<int> years, List<dynamic> bundles) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gestión Selector
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gestión Académica",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedYear = val;
                      _selectedBundleId =
                          null; // Reset bundle when year changes
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Curso Abierto Selector
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Curso Abierto",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBundleId,
                  hint: const Text("Seleccione un curso..."),
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: bundles
                      .map<DropdownMenuItem<String>>(
                        (b) => DropdownMenuItem<String>(
                          value: b.id as String,
                          child: Text(
                            b.name as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBundleId = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(
    List<Group> subjects,
    List<User> teachers,
    GroupProvider provider,
  ) {
    if (subjects.isEmpty) {
      return _buildEmptyState(
        "Este curso no tiene materias registradas. Agregue materias en la pestaña 'Cursos Abiertos'.",
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Materia",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Docente Asignado",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
          const Divider(height: 1),
          // List Items
          Expanded(
            child: ListView.separated(
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final group = subjects[index];
                final bundleList = context.read<CourseBundleProvider>().bundles;
                final bundle = bundleList.any((b) => b.id == _selectedBundleId)
                    ? bundleList.firstWhere((b) => b.id == _selectedBundleId)
                    : null;
                final bool isClosed = bundle != null ? !bundle.isActive : false;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.courseName ?? "Materia",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "ID: ${group.id.substring(0, 8)}",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? Colors.grey.shade100
                                  : Colors.blue.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isClosed
                                    ? Colors.grey.shade300
                                    : Colors.blue.shade100,
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: group.teacherId,
                              isExpanded: true,
                              disabledHint: Text(
                                group.teacherName ?? "Sin asignar",
                              ),
                              icon: Icon(
                                isClosed ? Icons.lock_outline : Icons.person,
                                size: 18,
                                color: isClosed ? Colors.grey : Colors.blue,
                              ),
                              items: isClosed
                                  ? null
                                  : [
                                      const DropdownMenuItem(
                                        value: 'unassigned',
                                        child: Text("Sin asignar"),
                                      ),
                                      ...teachers.map((t) {
                                        return DropdownMenuItem(
                                          value: t.id,
                                          child: Text(
                                            t.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                              onChanged: isClosed
                                  ? null
                                  : (newTeacherId) async {
                                      if (newTeacherId != null &&
                                          newTeacherId != group.teacherId) {
                                        _showConfirmAssignment(
                                          context,
                                          group,
                                          newTeacherId,
                                          provider,
                                        );
                                      }
                                    },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Indicator: Green check if assigned, Orange warning if pending
                      Icon(
                        group.teacherId == 'unassigned'
                            ? Icons.error_outline_rounded
                            : Icons.check_circle,
                        color: group.teacherId == 'unassigned'
                            ? Colors.orange
                            : Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmAssignment(
    BuildContext context,
    Group group,
    String newTeacherId,
    GroupProvider provider,
  ) {
    String message;
    if (newTeacherId == 'unassigned') {
      message =
          "¿Desea quitar la asignación docente de la materia ${group.courseName}?";
    } else {
      final teacher = provider.teachers.firstWhere((t) => t.id == newTeacherId);
      message =
          "¿Desea asignar a ${teacher.name} para la materia ${group.courseName} en este curso?";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newTeacherId == 'unassigned'
              ? "Quitar Asignación"
              : "Confirmar Cambio",
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateGroupTeacher(group.id, newTeacherId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newTeacherId == 'unassigned'
                          ? "✅ Docente desasignado correctamente"
                          : "✅ Docente asignado correctamente",
                    ),
                  ),
                );
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
