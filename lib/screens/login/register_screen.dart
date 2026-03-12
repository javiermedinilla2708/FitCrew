import 'package:fitcrew/screens/filters/sport_filter.dart';
import 'package:fitcrew/services/auth_services.dart';
import 'package:flutter/material.dart';

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
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, rellena todos los campos")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SportFilter()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al crear la cuenta. Inténtalo de nuevo.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
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
                      // Botón de retroceso 
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
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
      
                      //Campo nombre
                      const SizedBox(height: 40),
                      _buildInputLabel("Nombre Completo"),
                      _buildCustomTextField(
                        controller: _nameController,
                        hint: "Tu nombre",
                        icon: Icons.person_outline,
                      ),
      
                      //Campo Email
                      const SizedBox(height: 20),
                      _buildInputLabel("Email"),
                      _buildCustomTextField(
                        controller: _emailController,
                        hint: "hola@ejemplo.com",
                        icon: Icons.email_outlined,
                      ),
      
                      //Campo Contraseña
                      const SizedBox(height: 20),
                      _buildInputLabel("Contraseña"),
                      _buildCustomTextField(
                        controller: _passwordController,
                        hint: "Crea tu contraseña",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
      
                      //Campo Confirmacion de Contraseña
                      const SizedBox(height: 20),
                      _buildInputLabel("Confirmar contraseña"),
                      _buildCustomTextField(
                        controller: _confirmPasswordController,
                        hint: "Repetir contraseña",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Botón de continuar
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24FF8F),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
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

  // Métodos de ayuda 
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
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF24FF8F), width: 1.5),
        ),
      ),
    );
  }
}