import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/screens/auth/register_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // --- COLORES DE IDENTIDAD ---
  final colorVerdeBosque = const Color(0xFF234D41);
  final colorVerdeMenta = const Color(0xFFD3E6DB);
  final colorTextoTitulo = const Color(0xFF0F1D19);

  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final authVM = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Rellena todos los campos");
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnackBar("Introduce un email válido");
      return;
    }

    final success = await authVM.login(email, password);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      _showSnackBar(authVM.errorMessage ?? "Error al iniciar sesión");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorVerdeBosque,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildBackButton(context),
                    const SizedBox(height: 30),
                    
                    Text("Bienvenido de nuevo a",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: colorTextoTitulo.withOpacity(0.7))),
                    Text("FitCrew",
                        style: TextStyle(fontSize: 40, color: colorVerdeBosque, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    
                    const SizedBox(height: 12),
                    Text(
                      "Inicia sesión para continuar tu viaje y conectar con la comunidad.",
                      style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 40),

                    // Inputs
                    _buildInputLabel("Email"),
                    _buildCustomTextField(
                      controller: _emailController,
                      hint: "ejemplo@fitcrew.com",
                      icon: Icons.alternate_email_rounded,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 25),
                    _buildInputLabel("Contraseña"),
                    _buildCustomTextField(
                      controller: _passwordController,
                      hint: "••••••••••••",
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_isPasswordVisible,
                      enabled: !isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {},
                        child: Text("¿Olvidaste tu contraseña?",
                            style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    // Botón de Login (Estilo idéntico a Welcome)
                    _buildLoginButton(isLoading),

                    const SizedBox(height: 40),
                    _buildDivider(),
                    const SizedBox(height: 30),
                    Center(child: _socialButton(Icons.g_mobiledata)),

                    const SizedBox(height: 40),
                    _buildFooter(context, isLoading),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorVerdeMenta.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorVerdeBosque),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorVerdeBosque,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text("Iniciar sesión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: colorVerdeBosque.withOpacity(0.4), size: 22),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: colorVerdeMenta.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorVerdeBosque.withOpacity(0.2), width: 2),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorTextoTitulo)),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text("O CONTINÚA CON", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
      ],
    );
  }

  Widget _socialButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Icon(icon, size: 35, color: colorVerdeBosque),
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Center(
      child: GestureDetector(
        onTap: isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
        child: RichText(
          text: TextSpan(
            text: "¿No tienes cuenta? ",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            children: [
              TextSpan(text: "Regístrate", style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  
}