import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/screens/home/home_screen.dart';

class SportFilter extends StatelessWidget {
  const SportFilter({super.key});

  // --- COLORES DE IDENTIDAD ---
  final colorVerdeBosque = const Color(0xFF234D41);
  final colorVerdeMenta = const Color(0xFFD3E6DB);
  final colorTextoTitulo = const Color(0xFF0F1D19);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FilterViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ------------------------------------------------------------------
          // DECORACIÓN DE FONDO
          // ------------------------------------------------------------------
          _buildBackgroundDecorations(),

          // ------------------------------------------------------------------
          // CONTENIDO
          // ------------------------------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildBackButton(context),
                  const SizedBox(height: 30),
                  
                  Text("Casi listo",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: colorTextoTitulo.withOpacity(0.7))),
                  Text("¿Qué te mueve?",
                      style: TextStyle(fontSize: 40, color: colorVerdeBosque, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  
                  const SizedBox(height: 12),
                  const Text(
                    "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
                    style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 35),
                  
                  // LISTA DE DEPORTES CON CHIPS MEJORADOS
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

                  // BOTÓN FINALIZAR
                  _buildBottomButton(context, vm),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildSportChip(String sport, bool isSelected, FilterViewModel vm) {
    return FilterChip(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      avatar: Icon(
        vm.getSportIcon(sport),
        size: 20,
        color: isSelected ? colorVerdeBosque : Colors.grey[400],
      ),
      label: Text(
        sport,
        style: TextStyle(
          color: isSelected ? colorVerdeBosque : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => vm.toggleSport(sport),
      backgroundColor: Colors.grey[50],
      selectedColor: colorVerdeMenta,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected ? colorVerdeBosque.withOpacity(0.3) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, FilterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          onPressed: vm.canFinalize ? () async {
            bool success = await vm.saveUserSports();
            if (success && context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false
              );
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorVerdeBosque,
            disabledBackgroundColor: Colors.grey[200],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: vm.isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(
                  "Finalizar (${vm.selectedSports.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorVerdeMenta.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorVerdeBosque),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(top: -100, left: -50, child: _buildBlurCircle(colorVerdeMenta.withOpacity(0.4), 300)),
        Positioned(bottom: -50, right: -50, child: _buildBlurCircle(colorVerdeMenta.withOpacity(0.3), 350)),
        Positioned(top: 250, right: 30, child: _buildFloatingBubble(size: 15, color: colorVerdeMenta)),
      ],
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
    );
  }

  Widget _buildFloatingBubble({required double size, required Color color}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}