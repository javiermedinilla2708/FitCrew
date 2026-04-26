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
  // 7 pasos — uno por funcionalidad principal de la app:
  //   0 - Bienvenida
  //   1 - Feed social
  //   2 - Crear post
  //   3 - Ranking
  //   4 - Mapa de actividades
  //   5 - Buscar companeros
  //   6 - Perfil propio
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
          "Aqui veras los logros deportivos de la comunidad. Puedes dar like y dejar comentarios para motivar a otros usuarios.",
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
      icon: Icons.emoji_events_rounded,
      title: "Ranking de la comunidad",
      description:
          "Consulta el ranking global de usuarios mas activos y filtra por deporte para ver quien lidera en tu disciplina favorita. Compite y escala posiciones entrenando.",
      color: Color(0xFF234D41),
    ),
    _TutorialPage(
      icon: Icons.map_rounded,
      title: "Actividades en el mapa",
      description:
          "Descubre actividades deportivas cerca de ti en el mapa interactivo. Puedes unirte a las que te interesen o crear las tuyas propias con un formulario rapido.",
      color: Color(0xFF2E6B5A),
    ),
    _TutorialPage(
      icon: Icons.people_rounded,
      title: "Encuentra companeros",
      description:
          "Busca usuarios con tus mismos deportes favoritos y sigueles para construir tu red deportiva. Acepta sus solicitudes desde la pestana de Solicitudes.",
      color: Color(0xFF1A5C4A),
    ),
    _TutorialPage(
      icon: Icons.person_rounded,
      title: "Tu perfil",
      description:
          "Consulta tus estadisticas, entrenos y logros publicados. Edita tu nombre, bio y foto de perfil. Configura tu privacidad y preferencias desde el menu de ajustes.",
      color: Color(0xFF234D41),
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
  // NAVEGAR A LA SIGUIENTE PAGINA
  // Si es la ultima pagina navega directamente a HomeScreen
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
  // Elimina todas las rutas anteriores del stack para que
  // el usuario no pueda volver al tutorial con el boton atras
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
          // PAGEVIEW — una pagina por funcionalidad
          // Swipe horizontal para navegar entre pasos
          // --------------------------------------------------
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // --------------------------------------------------
          // BOTON OMITIR — esquina superior derecha
          // Color verde oscuro sobre fondo claro de la zona
          // superior coloreada para garantizar legibilidad
          // --------------------------------------------------
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: TextButton(
              onPressed: _goToHome,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25),
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
          // CONTROLES INFERIORES — indicadores de pagina
          // y boton de siguiente o empezar en el ultimo paso
          // --------------------------------------------------
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Indicadores de pagina animados
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

                // Boton siguiente o empezar en el ultimo paso
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
  // CONSTRUIR PAGINA INDIVIDUAL
  // Zona superior con fondo de color e icono centrado.
  // Zona inferior con titulo y descripcion de la funcionalidad.
  // ----------------------------------------------------------
  Widget _buildPage(_TutorialPage page) {
    return Column(
      children: [
        // Zona superior coloreada con icono
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

                // Circulo decorativo con icono de la funcionalidad
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

                // Decoracion de puntos inferior
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

        // Zona inferior con titulo y descripcion
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
                    color: _colorVerdeBosque,
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
// MODELO DE PAGINA DEL TUTORIAL
// Contiene los datos de cada paso: icono, titulo,
// descripcion y color de fondo de la zona superior
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
