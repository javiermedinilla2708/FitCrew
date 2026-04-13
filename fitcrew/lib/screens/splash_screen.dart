import 'dart:async';
import 'package:fitcrew/screens/auth_wrapper.dart';
import 'package:flutter/material.dart';

// ============================================================
// SplashScreen
// Pantalla de inicio animada que redirige al AuthWrapper
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------------
  // ANIMACIÓN
  // ----------------------------------------------------------
  late AnimationController _controller;
  late Animation<double> _animation;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // --- NAVEGACIÓN: redirige al AuthWrapper  ---
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // --- COLORES ---
    const colorMentol = Color(0xFFDBF0DD);
    const colorPrimario = Color(0xFF235347);
    const colorFondoOscuro = Color(0xFF051F20);
    const colorAcento = Color(0xFF8CB79B);

    return Scaffold(
      backgroundColor: colorPrimario,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colorPrimario.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colorAcento.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          // --- FONDO ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  colorPrimario.withOpacity(0.1),
                  Colors.transparent,
                  colorFondoOscuro.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // --- CONTENIDO CENTRAL ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ANIMADO ---
                ScaleTransition(
                  scale: _animation,
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: colorMentol.withOpacity(0.2),
                        size: 40,
                      ),
                      const SizedBox(height: 10),

                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Fit",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -2,
                              ),
                            ),
                            TextSpan(
                              text: "Crew",
                              style: TextStyle(
                                fontSize: 60,
                                color: colorMentol,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- BARRA DE CARGA ---
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: colorMentol.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: LinearProgressIndicator(
                    color: colorMentol,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
