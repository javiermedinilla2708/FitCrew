// ============================================================
// lib/screens/auth/forgot_password_screen.dart
// Pantalla de recuperacion de contraseña.
// Envia un correo de restablecimiento via Firebase Auth.
// El usuario recibe un enlace para crear una nueva contraseña.
// ============================================================

import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void dispose() {
    _emailController.dispose();
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
  // ENVIAR CORREO DE RECUPERACION
  // Llama a Firebase Auth para enviar el enlace al email.
  // Si tiene exito muestra la pantalla de confirmacion.
  // Si falla muestra un snackbar con el error.
  // ----------------------------------------------------------
  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Introduce tu email");
      return;
    }

    if (!_isEmailValid(email)) {
      _showSnackBar("Introduce un email valido");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'user-not-found':
          _showSnackBar("No existe ninguna cuenta con ese email");
          break;
        case 'invalid-email':
          _showSnackBar("El formato del email no es valido");
          break;
        case 'too-many-requests':
          _showSnackBar("Demasiados intentos. Espera unos minutos");
          break;
        default:
          _showSnackBar("Error al enviar el correo. Intentalo de nuevo");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  // FLUSHBAR
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ESTADO FORMULARIO
  // Muestra el campo de email y el boton de enviar
  // ----------------------------------------------------------
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Boton volver
        GestureDetector(
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
        ),

        const SizedBox(height: 30),

        // Icono principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _colorVerdeMenta,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 40,
            color: _colorVerdeBosque,
          ),
        ),

        const SizedBox(height: 30),

        // Cabecera
        Text(
          "Recupera tu",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _colorTextoTitulo.withOpacity(0.7),
          ),
        ),
        const Text(
          "contraseña",
          style: TextStyle(
            fontSize: 40,
            color: _colorVerdeBosque,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Introduce el email con el que te registraste y te enviaremos un enlace para crear una nueva contraseña.",
          style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
        ),

        const SizedBox(height: 40),

        // Label email
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _colorTextoTitulo,
            ),
          ),
        ),

        // Campo email
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: _colorVerdeBosque.withOpacity(0.4),
              size: 22,
            ),
            hintText: "ejemplo@fitcrew.com",
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
        ),

        const SizedBox(height: 40),

        // Boton enviar
        SizedBox(
          width: double.infinity,
          height: 70,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorVerdeBosque,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    "Enviar enlace",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // ESTADO EXITO
  // Se muestra tras enviar el correo correctamente.
  // Informa al usuario de que revise su bandeja de entrada.
  // ----------------------------------------------------------
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Icono de exito
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: _colorVerdeMenta,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 70,
            color: _colorVerdeBosque,
          ),
        ),

        const SizedBox(height: 40),

        // Titulo
        const Text(
          "Correo enviado",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _colorVerdeBosque,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 16),

        // Descripcion
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Hemos enviado un enlace de recuperacion a:\n\n${_emailController.text.trim()}\n\nRevisa tu bandeja de entrada y sigue las instrucciones para crear una nueva contraseña.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Aviso spam
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorVerdeMenta.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _colorVerdeBosque,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Si no ves el correo revisa la carpeta de spam o correo no deseado.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Boton volver al login
        SizedBox(
          width: double.infinity,
          height: 70,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorVerdeBosque,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Volver al inicio de sesion",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Reenviar correo
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            "Usar otro email",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
