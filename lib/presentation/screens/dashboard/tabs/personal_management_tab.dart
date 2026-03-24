import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/providers/user_management_provider.dart';
import '../../../../presentation/providers/student_provider.dart';
import '../../../../presentation/providers/teacher_provider.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/entities/student.dart';
import '../../../../domain/entities/teacher.dart';

class PersonalManagementTab extends StatefulWidget {
  const PersonalManagementTab({super.key});

  @override
  State<PersonalManagementTab> createState() => _PersonalManagementTabState();
}

class _PersonalManagementTabState extends State<PersonalManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _filterRole = 'all';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadUsers();
      context.read<StudentProvider>().loadStudents();
      context.read<TeacherProvider>().loadTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserManagementProvider>();
    List<User> users = userProvider.users;

    // Filtering Logic
    if (_filterRole != 'all') {
      users = users.where((u) => u.role == _filterRole).toList();
    }
    if (_filterStatus != 'all') {
      users = users.where((u) => u.status == _filterStatus).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      users = users.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildSearchAndFilters(),
        const SizedBox(height: 24),
        Expanded(child: _buildUserList(context, users, userProvider.isLoading)),
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
              "Gestión de Usuarios",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              "Administre cuentas, roles y acceso al sistema",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context),
          icon: const Icon(Icons.person_add, size: 20),
          label: Text(
            "Nueva Cuenta",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Buscar usuarios...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildDropdownFilter(
            label: "Rol",
            value: _filterRole,
            items: const [
              DropdownMenuItem(value: 'all', child: Text("Todos los Roles")),
              DropdownMenuItem(value: 'admin', child: Text("Administradores")),
              DropdownMenuItem(value: 'teacher', child: Text("Docentes")),
              DropdownMenuItem(value: 'student', child: Text("Alumnos")),
            ],
            onChanged: (val) => setState(() => _filterRole = val!),
          ),
          const SizedBox(width: 16),
          _buildDropdownFilter(
            label: "Estado",
            value: _filterStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text("Todos")),
              DropdownMenuItem(value: 'active', child: Text("Activos")),
              DropdownMenuItem(value: 'blocked', child: Text("Bloqueados")),
            ],
            onChanged: (val) => setState(() => _filterStatus = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<User> users,
    bool isLoading,
  ) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              "No se encontraron usuarios que coincidan",
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isActive = user.status == 'active';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                  backgroundImage:
                      (user.profileImage != null &&
                          user.profileImage!.isNotEmpty)
                      ? MemoryImage(base64Decode(user.profileImage!))
                      : null,
                  child:
                      (user.profileImage == null || user.profileImage!.isEmpty)
                      ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleBadge(user.role),
              ],
            ),
            subtitle: Text(
              user.email,
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => _handleAction(context, value, user),
              itemBuilder: (context) => [
                _buildPopupItem('view', Icons.visibility_outlined, "Ver"),
                _buildPopupItem('edit', Icons.edit_outlined, "Editar"),
                _buildPopupItem(
                  'password',
                  Icons.lock_reset,
                  "Resetear Contraseña",
                ),
                _buildPopupItem(
                  'toggle_status',
                  isActive ? Icons.block : Icons.check_circle_outline,
                  isActive ? "Desactivar" : "Activar",
                ),
                _buildPopupItem('delete', Icons.delete_outline, "Eliminar"),
              ],
            ),
          ),
        );
      },
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

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: _getRoleColor(role),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.indigo;
      case 'teacher':
        return Colors.orange.shade700;
      case 'student':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  void _handleAction(BuildContext context, String action, User user) {
    switch (action) {
      case 'view':
        _showUserDetails(context, user);
        break;
      case 'edit':
        _showEditUserDialog(context, user);
        break;
      case 'password':
        _showResetPasswordDialog(context, user);
        break;
      case 'toggle_status':
        _toggleUserStatus(context, user);
        break;
      case 'delete':
        _confirmDeleteUser(context, user);
        break;
    }
  }

  Future<void> _toggleUserStatus(BuildContext context, User user) async {
    // Safety check for last admin
    if (user.role == 'admin' && user.status == 'active') {
      final activeAdminCount = context
          .read<UserManagementProvider>()
          .users
          .where((u) => u.role == 'admin' && u.status == 'active')
          .length;

      if (activeAdminCount <= 1) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Acción Protegida"),
            content: const Text(
              "No se puede desactivar al único administrador activo del sistema.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
        return;
      }
    }

    final newStatus = user.status == 'active' ? 'blocked' : 'active';
    final updated = User(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      status: newStatus,
    );

    final userProvider = context.read<UserManagementProvider>();
    final studentProvider = context.read<StudentProvider>();
    final teacherProvider = context.read<TeacherProvider>();

    // 1. Update User
    await userProvider.updateUser(updated);

    // 2. Synchronize with Student/Teacher if necessary
    if (user.role == 'student') {
      final students = studentProvider.students;
      Student? student;
      for (final s in students) {
        if (s.userId == user.id) {
          student = s;
          break;
        }
      }

      if (student != null) {
        final updatedStudent = student.copyWith(status: newStatus);
        await studentProvider.updateStudent(updatedStudent);
      }
    } else if (user.role == 'teacher') {
      final teachers = teacherProvider.teachers;
      Teacher? teacher;
      for (final t in teachers) {
        if (t.userId == user.id) {
          teacher = t;
          break;
        }
      }

      if (teacher != null) {
        final updatedTeacher = teacher.copyWith(status: newStatus);
        await teacherProvider.updateTeacher(updatedTeacher);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Usuario ${newStatus == 'active' ? 'habilitado' : 'bloqueado'}",
          ),
        ),
      );
    }
  }

  void _confirmDeleteUser(BuildContext context, User user) {
    final isLinkedToStudent = context.read<StudentProvider>().students.any(
      (s) => s.userId == user.id,
    );
    final isLinkedToTeacher = context.read<TeacherProvider>().teachers.any(
      (t) => t.userId == user.id,
    );

    if (isLinkedToStudent || isLinkedToTeacher) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No se puede eliminar"),
          content: Text(
            "El usuario ${user.name} está vinculado como ${isLinkedToStudent ? 'Alumno' : 'Docente'}. Debe eliminarlo desde el módulo correspondiente para mantener la integridad del sistema.",
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

    // Safety rule for last admin
    if (user.role == 'admin') {
      final adminCount = context
          .read<UserManagementProvider>()
          .users
          .where((u) => u.role == 'admin')
          .length;
      if (adminCount <= 1) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Acción Protegida"),
            content: const Text(
              "No se puede eliminar al último administrador del sistema.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: Text(
          "¿Está seguro de eliminar permanentemente a ${user.name}? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<UserManagementProvider>().deleteUser(user.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Usuario eliminado")),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Detalles del Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow("Nombre", user.name),
            _detailRow("Email", user.email),
            _detailRow("Rol", user.role.toUpperCase()),
            _detailRow(
              "Estado",
              user.status == 'active' ? "ACTIVO" : "BLOQUEADO",
            ),
          ],
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  // --- REFINED DIALOGS ---

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Registrar Nueva Cuenta"),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nombre Completo",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: "Contraseña Inicial",
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: "Asignar Rol",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text("Administrador"),
                    ),
                    DropdownMenuItem(value: 'teacher', child: Text("Docente")),
                    DropdownMenuItem(value: 'student', child: Text("Alumno")),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty &&
                    emailCtrl.text.isNotEmpty &&
                    passCtrl.text.isNotEmpty) {
                  try {
                    await context.read<UserManagementProvider>().addUser(
                      nameCtrl.text,
                      emailCtrl.text,
                      passCtrl.text,
                      role,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cuenta creada exitosamente"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Crear Cuenta"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String role = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Modificar Información"),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: "Rol",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text("Administrador"),
                    ),
                    DropdownMenuItem(value: 'teacher', child: Text("Docente")),
                    DropdownMenuItem(value: 'student', child: Text("Alumno")),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = User(
                  id: user.id,
                  email: emailCtrl.text,
                  name: nameCtrl.text,
                  role: role,
                  status: user.status,
                );
                try {
                  await context.read<UserManagementProvider>().updateUser(
                    updated,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Información actualizada"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error al actualizar: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, User user) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Resetear Acceso"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Establecer nueva contraseña para:",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: "Nueva Contraseña",
                prefixIcon: Icon(Icons.lock_outline),
                hintText: "Min. 6 caracteres",
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text.isNotEmpty) {
                context.read<UserManagementProvider>().updateUser(
                  user,
                  password: passCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Credenciales actualizadas")),
                );
              }
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }
}
