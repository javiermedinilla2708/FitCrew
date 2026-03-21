import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/screens/home/home_screen.dart';

class SportFilter extends StatelessWidget {
  const SportFilter({super.key});

  @override
  Widget build(BuildContext context) {
    // Accedemos al ViewModel
    final vm = Provider.of<FilterViewModel>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildBackgroundDecorator(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildBackButton(context),
                  const SizedBox(height: 30),
                  const Text("Casi listo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text("¿Qué te mueve?", style: TextStyle(fontSize: 28, color: Color(0xFF24FF8F), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 30),
                  
                  // LISTA DE DEPORTES
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: vm.sports.map((sport) {
                          final isSelected = vm.selectedSports.contains(sport);
                          return FilterChip(
                            avatar: Icon(
                              vm.getSportIcon(sport),
                              size: 18,
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                            label: Text(sport),
                            selected: isSelected,
                            showCheckmark: false,
                            onSelected: (_) => vm.toggleSport(sport),
                            backgroundColor: Colors.grey.shade50,
                            selectedColor: const Color(0xFF24FF8F),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF24FF8F) : Colors.grey.shade200,
                              )
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // BOTÓN FINALIZAR
                  _buildBottomButton(context, vm),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, FilterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: vm.canFinalize ? () async {
            bool success = await vm.saveUserSports();
            if (success && context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false
              );
            } else if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al guardar tus preferencias"))
              );
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24FF8F),
            disabledBackgroundColor: Colors.grey[300],
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: vm.isLoading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Text(
                  "Finalizar (${vm.selectedSports.length})",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // Widgets auxiliares para limpiar el build principal
  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
    );
  }

  Widget _buildBackgroundDecorator() {
    return Positioned(
      top: -50, right: -180,
      child: Container(
        width: 400, height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF24FF8F).withOpacity(0.35),
              Colors.white.withOpacity(0)
            ]
          ),
        ),
      ),
    );
  }
}