// ============================================================
// lib/screens/auth/register_screen.dart
// Pantalla de registro con validacion de campos y navegacion
// al selector de deportes favoritos tras el registro.
// Soporta registro con email y contrasena y con Google.
// ============================================================

import 'package:another_flushbar/flushbar.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/filters/filter_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // CONTROLLERS Y ESTADO
  // ----------------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
  // LOGICA DE REGISTRO CON EMAIL Y CONTRASENA
  // Valida todos los campos antes de llamar al ViewModel.
  // Navega a FilterScreen para el onboarding de deportes.
  // ----------------------------------------------------------
  Future<void> _handleRegister() async {
    final authVM = context.read<AuthViewModel>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Por favor, rellena todos los campos");
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnackBar("Introduce un email valido");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("La contrasena debe tener al menos 6 caracteres");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Las contrasenas no coinciden");
      return;
    }

    final success = await authVM.register(email, password, name);

    if (!mounted) return;

    if (success) {
      if (context.mounted) {
        context.read<FilterViewModel>().reset();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const FilterScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(authVM.errorMessage ?? "Error al crear la cuenta");
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
        if (context.mounted) {
          context.read<FilterViewModel>().reset();
        }
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
  // FLUSHBAR
  // Muestra un mensaje de error personalizado en la parte inferior
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
    Flushbar(
      messageText: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: _colorVerdeBosque,
      borderRadius: BorderRadius.circular(15),
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      flushbarPosition: FlushbarPosition.BOTTOM,
    ).show(context);
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

                // Campo de nombre de usuario
                _buildInputLabel("Nombre de usuario"),
                _buildCustomTextField(
                  controller: _nameController,
                  hint: "Tu nombre",
                  icon: Icons.person_outline_rounded,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 20),

                // Campo de email
                _buildInputLabel("Email"),
                _buildCustomTextField(
                  controller: _emailController,
                  hint: "hola@fitcrew.com",
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 20),

                // Campo de contrasena con toggle de visibilidad
                _buildInputLabel("Contraseña"),
                _buildCustomTextField(
                  controller: _passwordController,
                  hint: "Crea tu contraseña",
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

                const SizedBox(height: 20),

                // Campo de confirmacion de contrasena
                _buildInputLabel("Confirmar contraseña"),
                _buildCustomTextField(
                  controller: _confirmPasswordController,
                  hint: "Repetir contraseña",
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_isConfirmPasswordVisible,
                  action: TextInputAction.done,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Boton principal de registro
                _buildRegisterButton(isLoading),

                const SizedBox(height: 30),

                // Divisor visual entre registro y opciones sociales
                _buildDivider(),

                const SizedBox(height: 30),

                // Boton de registro con Google
                Center(child: _buildSocialButton()),

                const SizedBox(height: 30),
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
          "Unete a",
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
          "Crea tu cuenta para empezar tu nueva aventura con nosotros.",
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
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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
  // Soporta texto normal, contrasena, teclado numerico y
  // accion de teclado configurable para el flujo del formulario
  // ----------------------------------------------------------
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
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
  // SEGMENTO: BOTON DE REGISTRO
  // Muestra un indicador de carga mientras se procesa el registro
  // ----------------------------------------------------------
  Widget _buildRegisterButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorVerdeBosque,
          disabledBackgroundColor: Colors.grey[200],
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
                "Continuar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DIVISOR VISUAL
  // Separa el registro con email del registro con Google
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
  // Muestra el logo de Googles y el texto
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
}
