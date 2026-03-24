import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/military_rank_utils.dart';
import '../../../../domain/entities/group.dart';
import '../../../../domain/entities/enrollment.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/evaluation_provider.dart';
import '../../../providers/grade_provider.dart';

class GradesTab extends StatefulWidget {
  final Group group;

  const GradesTab({super.key, required this.group});

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  bool _showAllStudents = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnrollmentProvider>().loadEnrollments(widget.group.id);
      context.read<GradeProvider>().loadGrades(widget.group.id);
      context.read<EvaluationProvider>().ensurePeriodsFromTemplates(
        widget.group.id,
        widget.group.courseId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final evaluationProvider = context.watch<EvaluationProvider>();
    final gradeProvider = context.watch<GradeProvider>();

    if (enrollmentProvider.isLoading ||
        evaluationProvider.isLoading ||
        gradeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (evaluationProvider.periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rule, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              "Configurando esquema de evaluación...",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Defina porcentajes en la materia base para ver esta sección.",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Filter enrollments based on status
    final allEnrollments = enrollmentProvider.enrollments;
    final enrollmentsToDisplay = _showAllStudents
        ? allEnrollments
        : allEnrollments.where((e) => e.status == 'En curso').toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return _buildMobileGradesList(
                  enrollmentsToDisplay,
                  evaluationProvider,
                  gradeProvider,
                );
              }
              return _buildDesktopGradesTable(
                enrollmentsToDisplay,
                evaluationProvider,
                gradeProvider,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("Mostrar todos:", style: TextStyle(fontSize: 12)),
          Switch(
            value: _showAllStudents,
            onChanged: (val) => setState(() => _showAllStudents = val),
            activeColor: Colors.blue,
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _showAllStudents
                ? "Mostrando todos (incluye suspendidos/retirados)"
                : "Mostrando solo activos",
            child: Icon(
              _showAllStudents ? Icons.filter_list_off : Icons.filter_list,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGradesList(
    List<Enrollment> enrollments,
    EvaluationProvider evaluationProvider,
    GradeProvider gradeProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        final bool isEditable = enrollment.status == 'En curso';

        double totalScore = 0;
        for (var p in evaluationProvider.periods) {
          final s = gradeProvider.getScore(enrollment.id, p.id);
          if (s != null) totalScore += s * (p.weight / 100);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(child: Text(enrollment.studentName ?? "Alumno")),
                if (!isEditable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      enrollment.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: enrollment.status == 'Suspendido'
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text("Total: ${totalScore.toStringAsFixed(1)}% / 100%"),
            children: evaluationProvider.periods.map((p) {
              return ListTile(
                title: Text("${p.name} (${p.weight}%)"),
                trailing: SizedBox(
                  width: 80,
                  child: _GradeInputCell(
                    enabled: isEditable,
                    initialValue: gradeProvider.getScore(enrollment.id, p.id),
                    onChanged: (val) =>
                        gradeProvider.updateGrade(enrollment.id, p.id, val),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDesktopGradesTable(
    List<Enrollment> enrollments,
    EvaluationProvider evaluationProvider,
    GradeProvider gradeProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            headingRowHeight: 60,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              const DataColumn(label: Text("Grado")),
              const DataColumn(label: Text("Compl.")),
              const DataColumn(label: Text("Alumno")),
              const DataColumn(label: Text("Estado")),
              ...evaluationProvider.periods.map(
                (p) => DataColumn(
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${p.weight}%",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const DataColumn(label: Text("Total (100%)")),
            ],
            rows: enrollments.map((enrollment) {
              final bool isEditable = enrollment.status == 'En curso';

              double totalScore = 0;
              final cells = evaluationProvider.periods.map((p) {
                final s = gradeProvider.getScore(enrollment.id, p.id);
                if (s != null) totalScore += s * (p.weight / 100);
                return DataCell(
                  _GradeInputCell(
                    enabled: isEditable,
                    initialValue: s,
                    onChanged: (val) =>
                        gradeProvider.updateGrade(enrollment.id, p.id, val),
                  ),
                );
              }).toList();

              return DataRow(
                color: isEditable
                    ? null
                    : WidgetStateProperty.all(Colors.grey.shade50),
                cells: [
                  DataCell(
                    Text(
                      enrollment.grade != null
                          ? MilitaryRankUtils.abreviarGrado(enrollment.grade!)
                          : "",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isEditable ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      enrollment.specialty ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isEditable ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      enrollment.studentName ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isEditable ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEditable
                            ? Colors.green.shade50
                            : (enrollment.status == 'Suspendido'
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        enrollment.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isEditable
                              ? Colors.green.shade700
                              : (enrollment.status == 'Suspendido'
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700),
                        ),
                      ),
                    ),
                  ),
                  ...cells,
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: totalScore >= 61
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        totalScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalScore >= 61
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _GradeInputCell extends StatefulWidget {
  final double? initialValue;
  final Function(double) onChanged;
  final bool enabled;

  const _GradeInputCell({
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<_GradeInputCell> createState() => _GradeInputCellState();
}

class _GradeInputCellState extends State<_GradeInputCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? "",
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _save();
    }
  }

  void _save() {
    final val = double.tryParse(_controller.text);
    if (val != null && val >= 0 && val <= 100 && val != widget.initialValue) {
      widget.onChanged(val);
    }
  }

  @override
  void didUpdateWidget(covariant _GradeInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes (only if not focused to avoid interrupting user)
    if (!_focusNode.hasFocus &&
        widget.initialValue?.toString() != _controller.text &&
        widget.initialValue?.toString() != oldWidget.initialValue?.toString()) {
      _controller.text = widget.initialValue?.toString() ?? "";
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        onFieldSubmitted: (_) => _save(),
      ),
    );
  }
}
