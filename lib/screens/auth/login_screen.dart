import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/screens/auth/register_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';

// ============================================================
// LoginScreen
// Pantalla de inicio de sesión con validación y feedback visual
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // CONTROLLERS Y ESTADO
  // ----------------------------------------------------------
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // VALIDACIÓN
  // ----------------------------------------------------------
  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  // ----------------------------------------------------------
  // LÓGICA DE LOGIN
  // ----------------------------------------------------------
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

    if (!mounted) return;

    if (success) {
      // Navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(authVM.errorMessage ?? "Error al iniciar sesión");
    }
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _colorVerdeBosque,
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // --- Botón volver ---
                _buildBackButton(context),

                const SizedBox(height: 30),

                // --- Títulos ---
                _buildHeader(),

                const SizedBox(height: 40),

                // --- Campo email ---
                _buildInputLabel("Email"),
                _buildCustomTextField(
                  controller: _emailController,
                  hint: "ejemplo@fitcrew.com",
                  icon: Icons.alternate_email_rounded,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 25),

                // --- Campo contraseña ---
                _buildInputLabel("Contraseña"),
                _buildCustomTextField(
                  controller: _passwordController,
                  hint: "••••••••••••",
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_isPasswordVisible,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),

                // --- ¿Olvidaste contraseña? ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : () {},
                    child: Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(
                        color: _colorVerdeBosque,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Botón login ---
                _buildLoginButton(isLoading),

                const SizedBox(height: 40),

                // --- Divisor ---
                _buildDivider(),

                const SizedBox(height: 30),

                // --- Botón Google (deshabilitado hasta implementación) ---
                Center(child: _buildSocialButton(Icons.g_mobiledata)),

                const SizedBox(height: 40),

                // --- Footer: ir a registro ---
                _buildFooter(context, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // WIDGETS PRIVADOS — Cabecera
  // ----------------------------------------------------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bienvenido de nuevo a",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _colorTextoTitulo.withOpacity(0.7),
          ),
        ),
        const Text(
          "FitCrew",
          style: TextStyle(
            fontSize: 40,
            color: _colorVerdeBosque,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Inicia sesión para continuar tu viaje y conectar con la comunidad.",
          style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _colorVerdeMenta.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: _colorVerdeBosque,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // WIDGETS PRIVADOS — Formulario
  // ----------------------------------------------------------
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: _colorTextoTitulo,
        ),
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
        prefixIcon: Icon(
          icon,
          color: _colorVerdeBosque.withOpacity(0.4),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: _colorVerdeMenta.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: _colorVerdeBosque.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // WIDGETS PRIVADOS — Botones
  // ----------------------------------------------------------
  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorVerdeBosque,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "O CONTINÚA CON",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
      ],
    );
  }

  // Deshabilitado visualmente hasta implementar Google Sign-In
  Widget _buildSocialButton(IconData icon) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 35, color: _colorVerdeBosque),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Center(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
        child: RichText(
          text: TextSpan(
            text: "¿No tienes cuenta? ",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            children: const [
              TextSpan(
                text: "Regístrate",
                style: TextStyle(
                  color: _colorVerdeBosque,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
