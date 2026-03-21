import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/screens/auth/register_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // --- LÓGICA DE VALIDACIÓN ---
  bool _isEmailValid(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  // --- LÓGICA DE AUTENTICACIÓN COORDINADA CON VIEWMODEL ---
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

    // Ejecutamos la acción en el ViewModel
    final success = await authVM.login(email, password);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      // Usamos el mensaje de error procesado por el ViewModel
      _showSnackBar(authVM.errorMessage ?? "Error al iniciar sesión");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    // Escuchamos el estado de carga del ViewModel
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Círculo decorativo de fondo
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
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
                      const SizedBox(height: 30),
                      const Text("Bienvenido de nuevo a ",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text("FitCrew",
                          style: TextStyle(
                              fontSize: 28,
                              color: Color(0xFF24FF8F),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        "Inicia sesión en tu cuenta para continuar tu viaje del fitness y conectarte con la comunidad.",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 40),

                      _buildInputLabel("Email"),
                      _buildCustomTextField(
                        controller: _emailController,
                        hint: "hola@ejemplo.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                        enabled: !isLoading,
                      ),

                      const SizedBox(height: 20),
                      _buildInputLabel("Contraseña"),
                      _buildCustomTextField(
                        controller: _passwordController,
                        hint: "Introduce tu contraseña",
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        action: TextInputAction.done,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          child: const Text("¿Has olvidado la contraseña?",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24FF8F),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2),
                                )
                              : const Text("Iniciar sesión",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("O CONTINUA CON",
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),

                      const SizedBox(height: 30),
                      Center(child: _socialButton(Icons.g_mobiledata)),

                      const SizedBox(height: 40),
                      Center(
                        child: GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: "¿No tienes cuenta? ",
                              style: TextStyle(color: Colors.grey[600]),
                              children: const [
                                TextSpan(
                                    text: "Regístrate",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
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

  // --- COMPONENTES DE UI ---
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _socialButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 30, color: Colors.black),
    );
  }
}