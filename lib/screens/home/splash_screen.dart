// 1. IMPORTACIONES
import 'dart:async';
import 'package:fitcrew/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

// 2. DEFINICIÓN DEL WIDGET
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplasScreen();
}

// 3. LÓGICA DEL ESTADO Y ANIMACIONES
class _SplasScreen extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configuración del controlador de la animación
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), 
      vsync: this,
    );

    // Definición de la curva de animación 
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    );

    // Iniciar el movimiento de la animación
    _controller.forward();

    // Temporizador para cambiar de pantalla automáticamente tras 3.5 segundos
    Timer(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 4. CONSTRUCCIÓN DE LA INTERFAZ VISUAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.0, 0.4],
            colors: [
              const Color(0xFF24FF8F).withOpacity(0.3), 
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Fit",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: "Crew",
                        style: TextStyle(
                          fontSize: 45,
                          color: Color(0xFF24FF8F),
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
        
              // Indicador de carga
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  color: const Color(0xFF24FF8F),
                  backgroundColor: const Color(0xFF24FF8F).withOpacity(0.1),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10), 
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}