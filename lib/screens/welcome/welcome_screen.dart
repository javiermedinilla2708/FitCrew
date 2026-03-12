// 1. IMPORTACIONES
import 'package:fitcrew/screens/login/login_screen.dart';
import 'package:fitcrew/screens/login/register_screen.dart';
import 'package:flutter/material.dart';

// 2. WIDGET DE PANTALLA DE BIENVENIDA 
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color fitCrewGreen = Color(0xFF24FF8F);

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          // 3. CAPAS DECORATIVAS DE FONDO 
          Positioned(
            top: -80,
            right: -120,
            child: _buildBlurCircle(fitCrewGreen.withOpacity(0.35), 450),
          ),

          Positioned(
            top: 130,
            right: 100,
            child: _buildFloatingCircle(const Color(0xFFF8F9FA), 120, 10),
          ),

          Positioned(
            top: 250,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fitCrewGreen.withOpacity(0.04),
              ),
            ),
          ),

          Positioned(
            bottom: -110,
            left: -90,
            child: _buildBlurCircle(fitCrewGreen.withOpacity(0.1), 380),
          ),

          Positioned(
            bottom: 250,
            left: 50,
            child: _buildFloatingCircle(const Color(0xFFF1F3F5), 85, 6),
          ),

          Positioned(
            bottom: 130,
            right: -30,
            child: _buildFloatingCircle(fitCrewGreen.withOpacity(0.6), 170, 18),
          ),

          Positioned(
            bottom: 60,
            right: 80,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE9ECEF),
              ),
            ),
          ),

          // 4. CONTENIDO PRINCIPAL ANIMADO 
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 2200), 
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
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 90),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "¡Bienvenido\nde Nuevo!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -1.2,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),

                  // 5. SECCIÓN INFERIOR: INFORMACIÓN Y ACCIONES
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Entrena con tu Crew",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Ingresa tus datos personales para acceder a tu cuenta y ver tus actividades.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          
                          const SizedBox(height: 200),

                          // 6. FILA DE BOTONES (ENTRAR Y REGISTRARSE)
                          Row(
                            children: [
                              // Botón de acceso
                              Expanded( 
                                child: SizedBox(
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context, 
                                        MaterialPageRoute(builder: (context) => const LoginScreen())
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Entrar",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 15),

                              // Botón de Registro 
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>const RegisterScreen()));
                                    }, 
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.black12, width: 2),
                                      shape: const StadiumBorder(),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text(
                                      "Registrarse",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES PARA WIDGETS DECORATIVOS ---

  // Constructor de círculos con degradado radial
  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.white.withOpacity(0)],
        ),
      ),
    );
  }

  // Constructor de esferas sólidas con sombra proyectada
  Widget _buildFloatingCircle(Color color, double size, double elevation) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
    );
  }
}