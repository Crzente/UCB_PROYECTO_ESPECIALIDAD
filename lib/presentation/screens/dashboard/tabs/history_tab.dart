import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/providers/academic_year_provider.dart';

import '../../../../domain/entities/final_grade_history.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _filtroEstado = 'Todos';
  String _busqueda = '';
  bool _isExporting = false;

  final List<String> _estados = [
    'Todos',
    'Aprobado',
    'Reprobado',
    'Incompleto',
  ];

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _darkColor = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicYearProvider>().loadYears();
      // Cargar historial completo al iniciar
      _cargarHistorialCompleto();
    });
  }

  Future<void> _cargarHistorialCompleto() async {
    // Cargamos el historial del año actual y anteriores
    final provider = context.read<AcademicYearProvider>();
    final currentYear = DateTime.now().year;
    // Cargamos los 5 años más recientes para tener datos
    for (int y = currentYear; y >= currentYear - 4; y--) {
      await provider.loadYearGradesHistory(y);
      if (provider.gradesHistory.isNotEmpty) break;
    }
    // Si no hay datos para los últimos 5 años, carga la gestión actual
    if (provider.gradesHistory.isEmpty) {
      await provider.loadYearGradesHistory(currentYear);
    }
  }

  String _statusToFilter(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'failed':
        return 'Reprobado';
      case 'incomplete':
        return 'Incompleto';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'incomplete':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade50;
      case 'failed':
        return Colors.red.shade50;
      case 'incomplete':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  List<FinalGradeHistory> get _registrosFiltrados {
    final provider = context.read<AcademicYearProvider>();
    final todos = provider.gradesHistory;

    return todos.where((r) {
      bool coincideEstado =
          _filtroEstado == 'Todos' ||
          _statusToFilter(r.status) == _filtroEstado;
      bool coincideBusqueda =
          _busqueda.isEmpty || _coincideBusquedaFlexible(r, _busqueda);
      return coincideEstado && coincideBusqueda;
    }).toList();
  }

  bool _coincideBusquedaFlexible(FinalGradeHistory r, String busqueda) {
    if (busqueda.isEmpty) return true;
    final b = busqueda.toLowerCase().trim();
    if (_coincidenciaFlexible(r.studentName.toLowerCase(), b)) return true;
    if (_coincidenciaFlexible(r.courseName.toLowerCase(), b)) return true;
    if (_coincidenciaFlexible(r.groupName.toLowerCase(), b)) return true;
    if (r.year.toString().contains(b)) return true;
    return false;
  }

  bool _coincidenciaFlexible(String texto, String busqueda) {
    if (texto.contains(busqueda)) return true;
    if (busqueda.contains(texto) && texto.length > 2) return true;
    final palabrasBusqueda = busqueda
        .split(' ')
        .where((p) => p.length > 1)
        .toList();
    final palabrasTexto = texto.split(' ').where((p) => p.length > 1).toList();
    for (var pb in palabrasBusqueda) {
      for (var pt in palabrasTexto) {
        if (pt.contains(pb) || pb.contains(pt)) return true;
      }
    }
    return false;
  }

  Map<int, List<FinalGradeHistory>> get _registrosAgrupados {
    final registros = _registrosFiltrados;
    final agrupados = <int, List<FinalGradeHistory>>{};
    for (var r in registros) {
      if (!agrupados.containsKey(r.year)) {
        agrupados[r.year] = [];
      }
      agrupados[r.year]!.add(r);
    }
    // Ordenar: años más recientes primero
    final sortedKeys = agrupados.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, agrupados[key]!)),
    );
  }

  void _mostrarOpciones(AcademicYearProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exportar Historial',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: Text(
                'Exportar a Excel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Archivo .xlsx organizado por año',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarExcel(provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                'Exportar a PDF',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Documento PDF con formato profesional',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarPDF(provider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarExcel(AcademicYearProvider provider) async {
    final agrupados = _registrosAgrupados;
    if (agrupados.isEmpty) {
      _mostrarSnackbar('No hay datos para exportar');
      return;
    }
    setState(() => _isExporting = true);
    try {
      // Exportar el primer año visible como referencia
      final year = agrupados.keys.first;
      final path = await provider.generateExcelReport(year);
      _mostrarSnackbar('Excel exportado: $path');
    } catch (e) {
      _mostrarSnackbar('Error al exportar Excel: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportarPDF(AcademicYearProvider provider) async {
    final agrupados = _registrosAgrupados;
    if (agrupados.isEmpty) {
      _mostrarSnackbar('No hay datos para exportar');
      return;
    }
    setState(() => _isExporting = true);
    try {
      final year = agrupados.keys.first;
      final path = await provider.generatePdfReport(year);
      _mostrarSnackbar('PDF exportado: $path');
    } catch (e) {
      _mostrarSnackbar('Error al exportar PDF: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _mostrarSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: _darkColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _verDetalleRegistro(FinalGradeHistory r) {
    showDialog(
      context: context,
      builder: (context) => _DetalleDialog(
        registro: r,
        statusColor: _statusColor(r.status),
        statusLabel: _statusToFilter(r.status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<AcademicYearProvider>();
    final registrosFiltrados = _registrosFiltrados;
    final agrupados = _registrosAgrupados;
    final total = registrosFiltrados.length;
    final aprobados = registrosFiltrados
        .where((r) => r.status == 'approved')
        .length;
    final reprobados = registrosFiltrados
        .where((r) => r.status == 'failed')
        .length;
    final incompletos = registrosFiltrados
        .where((r) => r.status == 'incomplete')
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: historyProvider.isLoading && historyProvider.gradesHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Encabezado ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historial Académico',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _darkColor,
                        ),
                      ),
                      Row(
                        children: [
                          if (_isExporting)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else ...[
                            _BotonIcono(
                              icon: Icons.file_download_outlined,
                              tooltip: 'Exportar Excel',
                              color: Colors.green.shade700,
                              onTap: () => _exportarExcel(historyProvider),
                            ),
                            const SizedBox(width: 6),
                            _BotonIcono(
                              icon: Icons.picture_as_pdf_outlined,
                              tooltip: 'Exportar PDF',
                              color: Colors.red.shade700,
                              onTap: () => _exportarPDF(historyProvider),
                            ),
                            const SizedBox(width: 6),
                            _BotonIcono(
                              icon: Icons.more_vert,
                              tooltip: 'Opciones',
                              color: _darkColor,
                              onTap: () => _mostrarOpciones(historyProvider),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listado histórico de notas finales por gestión',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Filtros ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por alumno, materia, grupo...',
                              hintStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => _busqueda = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroEstado,
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            items: _estados
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _filtroEstado = val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Estadísticas ──
                  Row(
                    children: [
                      _TarjetaEstadistica(
                        icon: Icons.history_edu_rounded,
                        label: 'Total',
                        valor: total,
                        color: Colors.deepPurple.shade400,
                        bgColor: Colors.deepPurple.shade50,
                        visible: true,
                      ),
                      const SizedBox(width: 10),
                      _TarjetaEstadistica(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Aprobados',
                        valor: aprobados,
                        color: Colors.green.shade600,
                        bgColor: Colors.green.shade50,
                        visible:
                            _filtroEstado == 'Todos' ||
                            _filtroEstado == 'Aprobado',
                      ),
                      const SizedBox(width: 10),
                      _TarjetaEstadistica(
                        icon: Icons.cancel_outlined,
                        label: 'Reprobados',
                        valor: reprobados,
                        color: Colors.red.shade600,
                        bgColor: Colors.red.shade50,
                        visible:
                            _filtroEstado == 'Todos' ||
                            _filtroEstado == 'Reprobado',
                      ),
                      const SizedBox(width: 10),
                      _TarjetaEstadistica(
                        icon: Icons.pending_outlined,
                        label: 'Incompletos',
                        valor: incompletos,
                        color: Colors.orange.shade600,
                        bgColor: Colors.orange.shade50,
                        visible:
                            _filtroEstado == 'Todos' ||
                            _filtroEstado == 'Incompleto',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Chip de búsqueda activa ──
                  if (_busqueda.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Chip(
                        avatar: const Icon(
                          Icons.search,
                          size: 16,
                          color: _primaryColor,
                        ),
                        label: Text(
                          '$_busqueda  ($total resultados)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _primaryColor,
                          ),
                        ),
                        backgroundColor: _primaryColor.withValues(alpha: 0.08),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _busqueda = ''),
                      ),
                    ),

                  // ── Lista agrupada por gestión ──
                  Expanded(
                    child: agrupados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _busqueda.isNotEmpty
                                      ? 'Sin resultados para "$_busqueda"'
                                      : 'No hay registros en el historial',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: agrupados.length,
                            itemBuilder: (context, index) {
                              final year = agrupados.keys.elementAt(index);
                              final registros = agrupados[year]!;
                              return _GrupoGestion(
                                year: year,
                                registros: registros,
                                autoExpand: _busqueda.isNotEmpty,
                                onVerDetalle: _verDetalleRegistro,
                                statusColor: _statusColor,
                                statusBgColor: _statusBgColor,
                                statusLabel: _statusToFilter,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _BotonIcono extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _BotonIcono({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  final IconData icon;
  final String label;
  final int valor;
  final Color color;
  final Color bgColor;
  final bool visible;

  const _TarjetaEstadistica({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
    required this.bgColor,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valor.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grupo por gestión (expandible)
// ─────────────────────────────────────────────────────────────────────────────

class _GrupoGestion extends StatefulWidget {
  final int year;
  final List<FinalGradeHistory> registros;
  final bool autoExpand;
  final Function(FinalGradeHistory) onVerDetalle;
  final Color Function(String) statusColor;
  final Color Function(String) statusBgColor;
  final String Function(String) statusLabel;

  const _GrupoGestion({
    required this.year,
    required this.registros,
    required this.autoExpand,
    required this.onVerDetalle,
    required this.statusColor,
    required this.statusBgColor,
    required this.statusLabel,
  });

  @override
  State<_GrupoGestion> createState() => _GrupoGestionState();
}

class _GrupoGestionState extends State<_GrupoGestion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.autoExpand;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(_GrupoGestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoExpand && !_isExpanded) {
      _isExpanded = true;
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aprobados = widget.registros
        .where((r) => r.status == 'approved')
        .length;
    final reprobados = widget.registros
        .where((r) => r.status == 'failed')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabecera del grupo
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gestión ${widget.year}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.registros.length} registro${widget.registros.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Mini stats
                  _MiniChip(
                    label: '$aprobados ✓',
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  _MiniChip(label: '$reprobados ✗', color: Colors.red.shade600),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de registros
          FadeTransition(
            opacity: _fadeAnimation,
            child: SizeTransition(
              sizeFactor: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: widget.registros.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final r = widget.registros[index];
                    return _RegistroCard(
                      registro: r,
                      statusColor: widget.statusColor(r.status),
                      statusBgColor: widget.statusBgColor(r.status),
                      statusLabel: widget.statusLabel(r.status),
                      onTap: () => widget.onVerDetalle(r),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: color, fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de registro individual
// ─────────────────────────────────────────────────────────────────────────────

class _RegistroCard extends StatelessWidget {
  final FinalGradeHistory registro;
  final Color statusColor;
  final Color statusBgColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _RegistroCard({
    required this.registro,
    required this.statusColor,
    required this.statusBgColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Text(
                registro.studentName.isNotEmpty
                    ? registro.studentName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registro.studentName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${registro.courseName} · ${registro.groupName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nota y estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  registro.finalScore.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de detalle
// ─────────────────────────────────────────────────────────────────────────────

class _DetalleDialog extends StatelessWidget {
  final FinalGradeHistory registro;
  final Color statusColor;
  final String statusLabel;

  const _DetalleDialog({
    required this.registro,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(
                    0xFF2563EB,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    registro.studentName.isNotEmpty
                        ? registro.studentName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registro.studentName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Gestión ${registro.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Datos
            _FilaDato(label: 'Materia / Curso', value: registro.courseName),
            _FilaDato(label: 'Grupo', value: registro.groupName),
            _FilaDato(label: 'Gestión', value: registro.year.toString()),
            _FilaDato(
              label: 'Nota Final',
              value: registro.finalScore.toStringAsFixed(2),
              valueColor: statusColor,
              valueBold: true,
            ),
            _FilaDato(
              label: 'Fecha de registro',
              value:
                  '${registro.createdAt.day.toString().padLeft(2, '0')}/${registro.createdAt.month.toString().padLeft(2, '0')}/${registro.createdAt.year}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF0F172A,
                  ).withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _FilaDato({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: valueColor ?? const Color(0xFF0F172A),
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
