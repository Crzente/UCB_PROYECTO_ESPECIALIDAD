import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_page.dart';
import 'tabs/teacher_courses_tab.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TeacherCoursesTab(),
    const Center(child: Text("Próximamente: Carga Rápida")),
    const Center(child: Text("Próximamente: Reportes")),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Portal Docente',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFEA580C), // Orange for Teachers
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                user?.name ?? 'Docente',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
      drawer: MediaQuery.of(context).size.width <= 900 ? _buildDrawer() : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          color: Colors.white,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildMenuItem(0, Icons.class_, "Mis Asignaturas"),
              _buildMenuItem(1, Icons.edit_note, "Cargar Notas"),
              _buildMenuItem(2, Icons.analytics_outlined, "Reportes"),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _pages[_selectedIndex],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _pages[_selectedIndex];
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFEA580C)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 48),
                const SizedBox(height: 10),
                Text(
                  'Menú Docente',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          _buildMenuItem(0, Icons.class_, "Mis Asignaturas"),
          _buildMenuItem(1, Icons.edit_note, "Cargar Notas"),
          _buildMenuItem(2, Icons.analytics_outlined, "Reportes"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFEA580C) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFFEA580C) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.orange.withOpacity(0.1),
      onTap: () {
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
