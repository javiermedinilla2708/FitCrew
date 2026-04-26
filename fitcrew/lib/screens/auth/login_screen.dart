// ============================================================
// lib/screens/auth/login_screen.dart
// Pantalla de inicio de sesion con validacion de campos,
// feedback visual y acceso a recuperacion de contraseña.
// Soporta login con email y contraseña y con Google.
// ============================================================

import 'package:fitcrew/screens/auth/forgot_password_screen.dart';
import 'package:fitcrew/screens/filters/filter_screen.dart';
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
  // VALIDACION DE EMAIL
  // ----------------------------------------------------------
  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  // ----------------------------------------------------------
  // LOGICA DE LOGIN CON EMAIL Y CONTRASENA
  // Valida los campos antes de llamar al ViewModel.
  // Navega a HomeScreen si el login es exitoso.
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
      _showSnackBar("Introduce un email valido");
      return;
    }

    final success = await authVM.login(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(authVM.errorMessage ?? "Error al iniciar sesion");
    }
  }

  // ----------------------------------------------------------
  // LOGICA DE LOGIN CON GOOGLE
  // Si el usuario es nuevo lo lleva a FilterScreen para
  // seleccionar deportes y pasar por el tutorial.
  // Si ya tiene cuenta lo lleva directamente a HomeScreen.
  // ----------------------------------------------------------
  Future<void> _handleGoogleLogin() async {
    final authVM = context.read<AuthViewModel>();
    final result = await authVM.loginWithGoogle();

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['isNewUser'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FilterScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      final error = authVM.errorMessage ?? "Error al iniciar sesion con Google";
      if (error != "Inicio de sesion cancelado") {
        _showSnackBar(error);
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                // Boton volver a la pantalla anterior
                _buildBackButton(context),

                const SizedBox(height: 30),

                // Cabecera con titulo y descripcion
                _buildHeader(),

                const SizedBox(height: 40),

                // Campo de email
                _buildInputLabel("Email"),
                _buildCustomTextField(
                  controller: _emailController,
                  hint: "ejemplo@fitcrew.com",
                  icon: Icons.alternate_email_rounded,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 25),

                // Campo de contrasena con toggle de visibilidad
                _buildInputLabel("Contrasena"),
                _buildCustomTextField(
                  controller: _passwordController,
                  hint: "................",
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

                // Enlace a recuperacion de contrasena
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                    child: const Text(
                      "¿Olvidaste tu contrasena?",
                      style: TextStyle(
                        color: _colorVerdeBosque,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Boton principal de login
                _buildLoginButton(isLoading),

                const SizedBox(height: 40),

                // Divisor visual entre login y opciones sociales
                _buildDivider(),

                const SizedBox(height: 30),

                // Boton de inicio de sesion con Google
                Center(child: _buildSocialButton()),

                const SizedBox(height: 40),

                // Enlace a la pantalla de registro
                _buildFooter(context, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CABECERA
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
          "Inicia sesion para continuar tu viaje y conectar con la comunidad.",
          style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BOTON VOLVER
  // ----------------------------------------------------------
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
  // SEGMENTO: LABEL DE CAMPO
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

  // ----------------------------------------------------------
  // SEGMENTO: CAMPO DE TEXTO PERSONALIZADO
  // Soporta texto normal, contrasena y teclado numerico.
  // El suffixIcon se usa para el toggle de visibilidad.
  // ----------------------------------------------------------
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
  // SEGMENTO: BOTON DE LOGIN
  // Muestra un indicador de carga mientras se procesa el login
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
                "Iniciar sesion",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DIVISOR VISUAL
  // Separa el login con email del login con Google
  // ----------------------------------------------------------
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "O CONTINUA CON",
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

  // ----------------------------------------------------------
  // SEGMENTO: BOTON DE GOOGLE
  // Muestra el logo de Google y el texto
  // de accion. Llama a _handleGoogleLogin al pulsarlo.
  // ----------------------------------------------------------
  Widget _buildSocialButton() {
    final isLoading = context.read<AuthViewModel>().isLoading;

    return GestureDetector(
      onTap: isLoading ? null : _handleGoogleLogin,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo oficial de Google como asset
              Image.asset(
                'assets/images/google_logo.png',
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 14),
              const Text(
                "Continuar con Google",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1D19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: FOOTER
  // Enlace a la pantalla de registro para nuevos usuarios
  // ----------------------------------------------------------
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
                text: "Registrate",
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
