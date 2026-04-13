import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/screens/home/home_screen.dart';

// ============================================================
// FilterScreen
// Pantalla de onboarding para seleccionar deportes favoritos
// Mínimo 3 deportes requeridos para continuar
// ============================================================

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FilterViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- FONDO: círculos decorativos ---
          _buildBackgroundDecorations(),

          // --- CONTENIDO PRINCIPAL ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // --- Cabecera de texto ---
                  _buildHeader(),

                  const SizedBox(height: 35),

                  // --- Lista de deportes con chips ---
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: vm.sports.map((sport) {
                          final isSelected = vm.selectedSports.contains(sport);
                          return _buildSportChip(sport, isSelected, vm);
                        }).toList(),
                      ),
                    ),
                  ),

                  // --- Botón finalizar ---
                  _buildBottomButton(context, vm),
                ],
              ),
            ),
          ),
        ],
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
          "Casi listo",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _colorTextoTitulo.withOpacity(0.7),
          ),
        ),
        const Text(
          "¿Qué te mueve?",
          style: TextStyle(
            fontSize: 40,
            color: _colorVerdeBosque,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
          style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CHIP DE DEPORTE
  // ----------------------------------------------------------
  Widget _buildSportChip(String sport, bool isSelected, FilterViewModel vm) {
    return FilterChip(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      avatar: Icon(
        vm.getSportIcon(sport),
        size: 20,
        color: isSelected ? _colorVerdeBosque : Colors.grey[400],
      ),
      label: Text(
        sport,
        style: TextStyle(
          color: isSelected ? _colorVerdeBosque : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => vm.toggleSport(sport),
      backgroundColor: Colors.grey[50],
      selectedColor: _colorVerdeMenta,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected
              ? _colorVerdeBosque.withOpacity(0.3)
              : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BOTÓN FINALIZAR
  // ----------------------------------------------------------
  Widget _buildBottomButton(BuildContext context, FilterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          onPressed: vm.canFinalize
              ? () async {
                  final success = await vm.saveUserSports();
                  if (success && context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorVerdeBosque,
            disabledBackgroundColor: Colors.grey[200],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: vm.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  "Finalizar (${vm.selectedSports.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DECORACIÓN DE FONDO
  // ----------------------------------------------------------
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // --- Círculo superior izquierdo ---
        Positioned(
          top: -100,
          left: -50,
          child: _buildBlurCircle(_colorVerdeMenta.withOpacity(0.4), 300),
        ),

        // --- Círculo inferior derecho ---
        Positioned(
          bottom: -50,
          right: -50,
          child: _buildBlurCircle(_colorVerdeMenta.withOpacity(0.3), 350),
        ),

        // --- Burbuja decorativa ---
        Positioned(
          top: 250,
          right: 30,
          child: _buildFloatingBubble(size: 15, color: _colorVerdeMenta),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // HELPERS DE DISEÑO
  // ----------------------------------------------------------
  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  Widget _buildFloatingBubble({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
