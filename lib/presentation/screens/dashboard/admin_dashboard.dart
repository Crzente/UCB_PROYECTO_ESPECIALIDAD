import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_page.dart';
import 'tabs/student_management_screen.dart';
import 'tabs/academic_screen.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_settings_tab.dart';
import 'tabs/personal_management_tab.dart';
import 'tabs/teacher_management_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/reports_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    // Pages defined here to access setState
    final List<Widget> pages = [
      AdminHomeTab(
        onRegisterStudent: () {
          setState(() {
            _selectedIndex = 2; // Navigate to Students tab
          });
        },
        onRegisterTeacher: () {
          setState(() {
            _selectedIndex = 3; // Navigate to Teachers tab
          });
        },
      ),
      const PersonalManagementTab(),
      const StudentManagementScreen(),
      const TeacherManagementTab(),
      const AcademicScreen(),
      const ReportsTab(),
      const HistoryTab(),
      const AdminSettingsTab(), // Mi Cuenta
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      appBar: AppBar(
        title: Text(
          'Panel Administrativo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                user?.name ?? 'Admin',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(pages);
          } else {
            return _buildMobileLayout(pages);
          }
        },
      ),
      drawer: MediaQuery.of(context).size.width <= 900 ? _buildDrawer() : null,
    );
  }

  Widget _buildDesktopLayout(List<Widget> pages) {
    return Row(
      children: [
        // Sidebar for Desktop
        Container(
          width: 250,
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildMenuItem(0, Icons.dashboard_rounded, "Inicio"),
              _buildMenuItem(
                1,
                Icons.people_alt_rounded,
                "Gestión de Usuarios",
              ),
              _buildMenuItem(2, Icons.school_rounded, "Alumnos"),
              _buildMenuItem(3, Icons.person_outline_rounded, "Docentes"),
              _buildMenuItem(4, Icons.library_books_rounded, "Académico"),
              _buildMenuItem(5, Icons.bar_chart_rounded, "Reportes"),
              _buildMenuItem(6, Icons.history, "Historial"),
              _buildMenuItem(7, Icons.account_circle_rounded, "Mi Cuenta"),
              _buildMenuItem(8, Icons.logout, "Cerrar Sesión"),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<Widget> pages) {
    return IndexedStack(index: _selectedIndex, children: pages);
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Menú Admin',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(0, Icons.dashboard_rounded, "Inicio"),
                _buildMenuItem(
                  1,
                  Icons.people_alt_rounded,
                  "Gestión de Usuarios",
                ),
                _buildMenuItem(2, Icons.school_rounded, "Alumnos"),
                _buildMenuItem(3, Icons.person_outline_rounded, "Docentes"),
                _buildMenuItem(4, Icons.library_books_rounded, "Académico"),
                _buildMenuItem(5, Icons.bar_chart_rounded, "Reportes"),
                _buildMenuItem(6, Icons.history, "Historial"),
                _buildMenuItem(7, Icons.account_circle_rounded, "Mi Cuenta"),
                _buildMenuItem(8, Icons.logout, "Cerrar Sesión"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFEFF6FF),
      onTap: () {
        // Caso especial: Cerrar Sesión
        if (index == 8) {
          context.read<AuthProvider>().logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }

        // Caso normal: cambiar de pestaña
        setState(() {
          _selectedIndex = index;
        });
        if (MediaQuery.of(context).size.width <= 900) {
          Navigator.pop(context);
        }
      },
    );
  }
}
