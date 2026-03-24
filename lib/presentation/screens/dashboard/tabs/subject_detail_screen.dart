import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/course.dart';
import '../../../../domain/entities/evaluation_template.dart';
import '../../../../presentation/providers/course_provider.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Course course;

  const SubjectDetailScreen({super.key, required this.course});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadTemplates(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final templates = courseProvider.currentTemplates;
    final totalWeight = templates.fold(0.0, (sum, t) => sum + t.weight);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.course.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Evaluation Templates Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Esquema Base de Evaluación",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Estos porcentajes se aplicarán automáticamente a los nuevos cursos.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTemplateDialog(context, totalWeight),
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar Componente"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Weight Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: totalWeight > 100
                    ? Colors.red[50]
                    : (totalWeight == 100
                          ? Colors.green[50]
                          : Colors.orange[50]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: totalWeight > 100
                      ? Colors.red
                      : (totalWeight == 100 ? Colors.green : Colors.orange),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    totalWeight == 100
                        ? Icons.check_circle
                        : (totalWeight > 100 ? Icons.error : Icons.warning),
                    color: totalWeight > 100
                        ? Colors.red
                        : (totalWeight == 100 ? Colors.green : Colors.orange),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Total Configurado: ${totalWeight.toStringAsFixed(1)}%",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: totalWeight > 100
                          ? Colors.red
                          : (totalWeight == 100
                                ? Colors.green
                                : Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List of Templates
            Expanded(
              child: courseProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rule, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No hay componentes definidos",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: templates.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              template.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "Peso: ${template.weight}%",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditTemplateDialog(
                                    context,
                                    template,
                                    totalWeight,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _showDeleteConfirmation(
                                    context,
                                    template,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context, double currentTotal) {
    final nameController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nuevo Componente Base',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre (Ej: Exámenes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso % (Ej: 60)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0.0;
              if (nameController.text.isNotEmpty && weight > 0) {
                if (currentTotal + weight > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error: El total no puede exceder 100%"),
                    ),
                  );
                  return;
                }
                context.read<CourseProvider>().addTemplate(
                  widget.course.id,
                  nameController.text,
                  weight,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showEditTemplateDialog(
    BuildContext context,
    EvaluationTemplate template,
    double currentTotal,
  ) {
    final nameController = TextEditingController(text: template.name);
    final weightController = TextEditingController(
      text: template.weight.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Componente',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso %',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0.0;
              if (nameController.text.isNotEmpty && weight > 0) {
                final otherTotal = currentTotal - template.weight;
                if (otherTotal + weight > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error: El total no puede exceder 100%"),
                    ),
                  );
                  return;
                }
                context.read<CourseProvider>().updateTemplate(
                  template.id,
                  widget.course.id,
                  nameController.text,
                  weight,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    EvaluationTemplate template,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Eliminar "${template.name}" del esquema base?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CourseProvider>().deleteTemplate(
                template.id,
                widget.course.id,
              );
              Navigator.pop(context);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
