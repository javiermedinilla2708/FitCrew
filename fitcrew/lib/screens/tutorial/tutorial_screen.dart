// ============================================================
// lib/screens/tutorial/tutorial_screen.dart
// Pantalla de tutorial para nuevos usuarios.
// Se muestra una sola vez tras el onboarding de deportes,
// antes de llegar a HomeScreen.
// Cada paso explica una funcionalidad clave de la app.
// ============================================================

import 'package:flutter/material.dart';
import 'package:fitcrew/screens/home/home_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ----------------------------------------------------------
  // PASOS DEL TUTORIAL
  // ----------------------------------------------------------
  final List<_TutorialPage> _pages = const [
    _TutorialPage(
      icon: Icons.waving_hand_rounded,
      title: "Bienvenido a FitCrew",
      description:
          "Tu nueva comunidad deportiva. Conecta con personas que comparten tu pasion por el deporte, organiza actividades y comparte tus logros.",
      color: Color(0xFF234D41),
    ),
    _TutorialPage(
      icon: Icons.dynamic_feed_rounded,
      title: "Feed social",
      description:
          "Aqui veras los logros deportivos de la comunidad. Puedes dar like y dejar comentarios para motivar a otros usuarios. Pulsa el avatar de cualquier usuario para ver su perfil.",
      color: Color(0xFF2E6B5A),
    ),
    _TutorialPage(
      icon: Icons.add_circle_rounded,
      title: "Comparte tus logros",
      description:
          "Pulsa el boton central para publicar una foto de tu entrenamiento. Selecciona tu deporte, el nivel de intensidad y una descripcion para compartirlo con la comunidad.",
      color: Color(0xFF1A5C4A),
    ),
    _TutorialPage(
      icon: Icons.map_rounded,
      title: "Actividades en el mapa",
      description:
          "Descubre actividades deportivas cerca de ti en el mapa interactivo. Puedes unirte a las que te interesen o crear las tuyas propias con un formulario rapido.",
      color: Color(0xFF234D41),
    ),
    _TutorialPage(
      icon: Icons.people_rounded,
      title: "Encuentra companeros",
      description:
          "Busca usuarios con tus mismos deportes favoritos y sigueles para construir tu red deportiva. Acepta sus solicitudes desde la pestana de Solicitudes.",
      color: Color(0xFF2E6B5A),
    ),
    _TutorialPage(
      icon: Icons.person_rounded,
      title: "Tu perfil",
      description:
          "Consulta tus estadisticas, entrenos y logros publicados. Edita tu nombre, bio y foto de perfil. Configura tu privacidad y preferencias desde el menu de ajustes.",
      color: Color(0xFF1A5C4A),
    ),
  ];

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // NAVEGAR A LA SIGUIENTE PÁGINA
  // ----------------------------------------------------------
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToHome();
    }
  }

  // ----------------------------------------------------------
  // NAVEGAR A HOMESCREEN
  // ----------------------------------------------------------
  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      body: Stack(
        children: [
          // --------------------------------------------------
          // PAGEVIEW — una página por funcionalidad
          // --------------------------------------------------
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // --------------------------------------------------
          // BOTÓN OMITIR — esquina superior derecha
          // --------------------------------------------------
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: TextButton(
              onPressed: _goToHome,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "Omitir",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // --------------------------------------------------
          // CONTROLES INFERIORES — indicadores + botones
          // --------------------------------------------------
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Indicadores de página
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? _colorVerdeBosque
                            : _colorVerdeMenta,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Botón siguiente / empezar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorVerdeBosque,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1
                          ? "Siguiente"
                          : "Empezar FitCrew",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // CONSTRUIR PÁGINA INDIVIDUAL
  // ----------------------------------------------------------
  Widget _buildPage(_TutorialPage page) {
    return Column(
      children: [
        // Zona superior con fondo de color e icono
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: page.color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Círculo decorativo con icono
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(page.icon, size: 70, color: Colors.white),
                ),

                const SizedBox(height: 40),

                // Decoración de puntos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == 1 ? 12 : 8,
                      height: i == 1 ? 12 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(i == 1 ? 0.5 : 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Zona inferior con texto
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF234D41),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  page.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// MODELO DE PÁGINA DEL TUTORIAL
// ----------------------------------------------------------
class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
