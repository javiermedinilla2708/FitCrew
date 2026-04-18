import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/filters/filter_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';

// ============================================================
// RegisterScreen
// Pantalla de registro con validación de campos y navegación
// al selector de deportes favoritos
// ============================================================

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
  // VALIDACIÓN
  // ----------------------------------------------------------
  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  // ----------------------------------------------------------
  // LÓGICA DE REGISTRO
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

    final success = await authVM.register(email, password, name);

    if (!mounted) return;

    if (success) {
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

                // --- Campo nombre ---
                _buildInputLabel("Nombre de usuario"),
                _buildCustomTextField(
                  controller: _nameController,
                  hint: "Tu nombre",
                  icon: Icons.person_outline_rounded,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 20),

                // --- Campo email ---
                _buildInputLabel("Email"),
                _buildCustomTextField(
                  controller: _emailController,
                  hint: "hola@fitcrew.com",
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),

                const SizedBox(height: 20),

                // --- Campo contraseña ---
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

                // --- Campo confirmar contraseña ---
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

                // --- Botón continuar ---
                _buildRegisterButton(isLoading),

                const SizedBox(height: 30),
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
          "Únete a",
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
  // WIDGETS PRIVADOS — Botón de registro
  // ----------------------------------------------------------
  Widget _buildRegisterButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegister,
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
                "Continuar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
