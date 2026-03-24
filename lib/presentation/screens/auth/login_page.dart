import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/student_dashboard.dart';
import '../dashboard/teacher_dashboard.dart';
import '../dashboard/admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final authProvider = context.read<AuthProvider>();

    // Quick validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese usuario y contraseña')),
      );
      return;
    }

    // Call Login via Provider
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final role = authProvider.currentUser?.role;
      Widget nextScreen;

      switch (role) {
        case 'admin':
          nextScreen = const AdminDashboard();
          break;
        case 'teacher':
          nextScreen = const TeacherDashboard();
          break;
        case 'student':
        default:
          nextScreen = const StudentDashboard();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Monitor loading state state from provider
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(isLoading);
          } else {
            return _buildMobileLayout(isLoading);
          }
        },
      ),
    );
  }

  // -----------------------
  // Desktop Layout (Split)
  // -----------------------
  Widget _buildDesktopLayout(bool isLoading) {
    return Row(
      children: [
        // Left Side - Branding (60%)
        Expanded(
          flex: 6,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        child: const Icon(
                          Icons.school_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeInUp(
                        child: Text(
                          "Sistema de Gestión Académica",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side - Form (40%)
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: _buildLoginForm(isDark: false, isLoading: isLoading),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------
  // Mobile Layout (Single Column)
  // -----------------------
  Widget _buildMobileLayout(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: const Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  "Gestión Académica",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              _buildLoginForm(isDark: true, isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------
  // Shared Form Widget
  // -----------------------
  Widget _buildLoginForm({required bool isDark, required bool isLoading}) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor = isDark
        ? Colors.white60
        : const Color(0xFF64748B);
    final Color inputFillColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final Color iconColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Bienvenido de nuevo",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Ingrese sus credenciales.",
          style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
        ),
        const SizedBox(height: 30),

        // Username Field
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _usernameController,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.person_outline_rounded, color: iconColor),
              hintText: 'Usuario',
              hintStyle: GoogleFonts.poppins(color: subTextColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Password Field
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: GoogleFonts.poppins(color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock_outline_rounded, color: iconColor),
              hintText: 'Contraseña',
              hintStyle: GoogleFonts.poppins(color: subTextColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    "Iniciar Sesión",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
