import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/filters/sport_filter.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;

  // --- LÓGICA DE VALIDACIÓN ---
  bool _isEmailValid(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  // --- LÓGICA DE REGISTRO COORDINADA ---
  Future<void> _handleRegister() async {
    final authVM = context.read<AuthViewModel>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones locales rápidas
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showSnackBar("Por favor, rellena todos los campos");
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnackBar("Introduce un email válido");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Las contraseñas no coinciden");
      return;
    }

    // Ejecución en el ViewModel
    final success = await authVM.register(email, password, name);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SportFilter()),
        (route) => false,
      );
    } else if (mounted) {
      _showSnackBar(authVM.errorMessage ?? "Error al crear la cuenta");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Círculo decorativo
            Positioned(
              top: -50,
              right: -180,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF24FF8F).withOpacity(0.40),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      const Text("Únete a", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text("FitCrew", style: TextStyle(fontSize: 28, color: Color(0xFF24FF8F), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        "Crea tu cuenta para empezar tu nueva aventura con nosotros.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                      ),

                      const SizedBox(height: 40),
                      _buildInputLabel("Nombre Completo"),
                      _buildCustomTextField(
                        controller: _nameController,
                        hint: "Tu nombre",
                        icon: Icons.person_outline,
                        enabled: !isLoading,
                      ),

                      const SizedBox(height: 20),
                      _buildInputLabel("Email"),
                      _buildCustomTextField(
                        controller: _emailController,
                        hint: "hola@ejemplo.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                      ),

                      const SizedBox(height: 20),
                      _buildInputLabel("Contraseña"),
                      _buildCustomTextField(
                        controller: _passwordController,
                        hint: "Crea tu contraseña",
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildInputLabel("Confirmar contraseña"),
                      _buildCustomTextField(
                        controller: _confirmPasswordController,
                        hint: "Repetir contraseña",
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        action: TextInputAction.done,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24FF8F),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text("Continuar",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE UI ---
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: action,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF24FF8F), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}