import 'package:fitcrew/screens/auth/login_screen.dart';
import 'package:fitcrew/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';

// ============================================================
// WelcomeScreen
// Pantalla de bienvenida con animación de entrada y acceso
// a login y registro
// ============================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeFondo = Color(0xFFE8F3ED);
  static const _colorVerdeBurbuja = Color(0xFFD3E6DB);
  static const _colorVerdePrimario = Color(0xFF234D41);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- FONDO: blobs y burbujas decorativas ---
          _buildBackgroundDecorations(),

          // --- CONTENIDO: animación de entrada ---
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DECORACIÓN DE FONDO
  // ----------------------------------------------------------
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // --- Blobs difuminados ---
        Positioned(
          top: -50,
          right: -30,
          child: _buildBlurCircle(_colorVerdeFondo, 400),
        ),
        Positioned(
          top: 280,
          left: -100,
          child: _buildBlurCircle(_colorVerdeBurbuja.withOpacity(0.4), 300),
        ),
        Positioned(
          bottom: 220,
          left: 30,
          child: _buildBlurCircle(_colorVerdeBurbuja.withOpacity(0.6), 180),
        ),
        Positioned(
          bottom: 80,
          right: -40,
          child: _buildBlurCircle(_colorVerdeBurbuja, 280),
        ),

        // --- Burbujas definidas ---
        _buildFloatingBubble(
          top: 120,
          left: 40,
          size: 120,
          color: _colorVerdePrimario.withOpacity(0.1),
        ),
        _buildFloatingBubble(
          top: 400,
          right: 30,
          size: 40,
          color: _colorVerdeBurbuja,
        ),
        _buildFloatingBubble(
          bottom: 300,
          right: 80,
          size: 60,
          color: _colorVerdePrimario.withOpacity(0.05),
        ),
        _buildFloatingBubble(
          bottom: 150,
          left: 20,
          size: 120,
          color: _colorVerdeBurbuja.withOpacity(0.8),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CONTENIDO PRINCIPAL
  // ----------------------------------------------------------
  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // --- Logo textual ---
          _buildLogo(),

          const SizedBox(height: 20),

          // --- Título principal ---
          _buildTextSection(
            "Tu cuerpo,\ntu equipo.",
            _colorTextoTitulo,
            48,
            FontWeight.w900,
          ),

          const Spacer(),

          // --- Subtítulo y descripción ---
          _buildBottomSection(),

          const SizedBox(height: 50),

          // --- Botones de acción ---
          _buildActionButtons(context),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: LOGO
  // ----------------------------------------------------------
  Widget _buildLogo() {
    return Text(
      "FITCREW",
      style: TextStyle(
        color: _colorVerdePrimario.withOpacity(0.5),
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        fontSize: 14,
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: SECCIÓN INFERIOR
  // ----------------------------------------------------------
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildTextSection(
            "Alcanza tu máximo\npotencial",
            _colorTextoTitulo,
            28,
            FontWeight.bold,
          ),
          const SizedBox(height: 15),
          Text(
            "Únete a la comunidad de entrenamiento más exclusiva y lleva un registro profesional de tus progresos.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 17,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BOTONES DE ACCIÓN
  // ----------------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          // --- Botón Entrar ---
          Expanded(
            child: _buildButton(
              label: "Entrar",
              color: _colorVerdePrimario,
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // --- Botón Registrarse ---
          Expanded(
            child: _buildButton(
              label: "Registrarse",
              color: Colors.transparent,
              textColor: _colorVerdePrimario,
              isOutlined: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPERS DE DISEÑO
  // ----------------------------------------------------------
  Widget _buildTextSection(
    String text,
    Color color,
    double size,
    FontWeight weight,
  ) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.1,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 75,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _colorVerdePrimario.withOpacity(0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                foregroundColor: textColor,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingBubble({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
    );
  }
}
