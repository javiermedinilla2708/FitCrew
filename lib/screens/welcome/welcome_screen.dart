import 'package:fitcrew/screens/auth/login_screen.dart';
import 'package:fitcrew/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------------------
    // 1. PALETA DE COLORES
    // ----------------------------------------------------------------------
    const colorVerdeFondo = Color(0xFFE8F3ED);
    const colorVerdeBurbuja = Color(0xFFD3E6DB);
    const colorVerdePrimario = Color(0xFF234D41);
    const colorTextoTitulo = Color(0xFF0F1D19);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ------------------------------------------------------------------
          // 2. CAPAS DECORATIVAS (Blobs Difuminados + Burbujas Definidas)
          // ------------------------------------------------------------------
          _buildBackgroundDecorations(colorVerdeFondo, colorVerdeBurbuja, colorVerdePrimario),

          // ------------------------------------------------------------------
          // 3. CONTENIDO PRINCIPAL CON ANIMACIÓN DE ENTRADA
          // ------------------------------------------------------------------
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
            child: _buildMainContent(context, colorTextoTitulo, colorVerdePrimario),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SEGMENTO: DECORACIÓN DE FONDO
  // ----------------------------------------------------------------------
  Widget _buildBackgroundDecorations(Color fondo, Color burbuja, Color primario) {
    return Stack(
      children: [
        // --- BLOBS DIFUMINADOS (Estilo foto) ---
        Positioned(top: -50, right: -30, child: _buildBlurCircle(fondo, 400)),
        Positioned(top: 280, left: -100, child: _buildBlurCircle(burbuja.withOpacity(0.4), 300)),
        Positioned(bottom: 220, left: 30, child: _buildBlurCircle(burbuja.withOpacity(0.6), 180)),
        Positioned(bottom: 80, right: -40, child: _buildBlurCircle(burbuja, 280)),

        // --- BURBUJAS FLOTANTES (Definidas) ---
        _buildFloatingBubble(top: 120, left: 40, size: 120, color: primario.withOpacity(0.1)),
        _buildFloatingBubble(top: 400, right: 30, size: 40, color: burbuja),
        _buildFloatingBubble(bottom: 300, right: 80, size: 60, color: primario.withOpacity(0.05)),
        _buildFloatingBubble(bottom: 150, left: 20, size: 120, color: burbuja.withOpacity(0.8)),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // SEGMENTO: CONTENIDO
  // ----------------------------------------------------------------------
  Widget _buildMainContent(BuildContext context, Color tituloC, Color primario) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(primario),
          const SizedBox(height: 20),
          _buildTextSection("Tu cuerpo,\ntu equipo.", tituloC, 48, FontWeight.w900),
          const Spacer(),
          _buildBottomSection(tituloC),
          const SizedBox(height: 50),
          _buildActionButtons(context, primario),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // COMPONENTES INDIVIDUALES
  // ----------------------------------------------------------------------
  Widget _buildLogo(Color primario) {
    return Text(
      "FITCREW",
      style: TextStyle(
        color: primario.withOpacity(0.5),
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        fontSize: 14,
      ),
    );
  }

  Widget _buildBottomSection(Color tituloC) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildTextSection("Alcanza tu máximo\npotencial", tituloC, 28, FontWeight.bold),
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

  Widget _buildActionButtons(BuildContext context, Color primario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              label: "Entrar",
              color: primario,
              textColor: Colors.white,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildButton(
              label: "Registrarse",
              color: Colors.transparent,
              textColor: primario,
              isOutlined: true,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // HELPERS DE DISEÑO
  // ----------------------------------------------------------------------
  Widget _buildTextSection(String text, Color color, double size, FontWeight weight) {
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

  Widget _buildButton({required String label, required Color color, required Color textColor, bool isOutlined = false, required VoidCallback onPressed}) {
    return SizedBox(
      height: 75,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                foregroundColor: textColor,
              ),
              child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildFloatingBubble({double? top, double? left, double? right, double? bottom, required double size, required Color color}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
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
            )
          ],
        ),
      ),
    );
  }
}