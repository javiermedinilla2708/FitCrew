// 1. IMPORTACIONES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

// 2. WIDGET CON ESTADO PARA SELECCIÓN DE DEPORTES
class SportFilter extends StatefulWidget {
  const SportFilter({super.key});

  @override
  State<SportFilter> createState() => _SportFilterState();
}

// 3. LÓGICA Y GESTIÓN DE ESTADO
class _SportFilterState extends State<SportFilter> {
  // Listado completo de deportes
  final List<String> _sports = [
    "Padel", "Tenis", "Bádminton", "Ping Pong",
    "Fútbol", "Basket", "Voleibol", "Balonmano", "Rugby",
    "Running", "Ciclismo", "Natación", "Triatlón", "Patinaje",
    "Yoga", "Crossfit", "Gimnasio", "Calistenia", "Pilates",
    "Boxeo", "Judo", "Karate", "MMA",
    "Senderismo", "Escalada", "Surf", "Golf"
  ];

  // Variables de control
  final List<String> _selectedSports = [];
  bool _isLoading = false;

  // Función para obtener el icono según el deporte
  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'padel': case 'tenis': return Icons.sports_tennis;
      case 'bádminton': return Icons.wb_iridescent_rounded;
      case 'ping pong': return Icons.table_restaurant_rounded;
      case 'fútbol': case 'balonmano': return Icons.sports_soccer;
      case 'basket': return Icons.sports_basketball;
      case 'voleibol': return Icons.sports_volleyball;
      case 'rugby': return Icons.sports_rugby;
      case 'running': return Icons.directions_run;
      case 'ciclismo': return Icons.directions_bike;
      case 'natación': return Icons.pool;
      case 'triatlón': return Icons.directions_run_rounded;
      case 'patinaje': return Icons.ice_skating;
      case 'yoga': case 'pilates': return Icons.self_improvement;
      case 'crossfit': case 'gimnasio': case 'calistenia': return Icons.fitness_center;
      case 'boxeo': case 'mma': return Icons.sports_mma;
      case 'judo': case 'karate': return Icons.front_hand;
      case 'senderismo': return Icons.terrain;
      case 'escalada': return Icons.landscape;
      case 'surf': return Icons.surfing;
      case 'golf': return Icons.sports_golf;
      default: return Icons.bolt;
    }
  }

  // 4. CONSTRUCCIÓN DE LA INTERFAZ (BUILD)
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Elemento decorativo: Círculo de fondo con gradiente
            Positioned(
              top: -50,
              right: -180,
              child: Container(
                width: 400,
                height: 400,
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
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
              
                  // Botón de retroceso estilizado
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context), 
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(height: 30),
              
                  // Cabecera: Títulos principales
                  const Text("Casi listo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text("¿Qué te mueve?", style: TextStyle(fontSize: 28, color: Color(0xFF24FF8F), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
              
                  const Text(
                    "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
              
                  const SizedBox(height: 30),
    
                  // Cuerpo: Cuadrícula de chips autoadaptable (Wrap)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _sports.map((sport) {
                          final isSelected = _selectedSports.contains(sport);
                          return FilterChip(
                            // Icono dinámico según el deporte
                            avatar: Icon(
                              _getSportIcon(sport),
                              size: 18,
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                            label: Text(sport), 
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selected: isSelected,
                            showCheckmark: false, // Ocultamos el check para que luzca mejor con el icono
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSports.add(sport);
                                } else {
                                  _selectedSports.remove(sport);
                                }
                              });
                            },
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
    
                  // Pie: Botón de finalización
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_selectedSports.length >= 3 && !_isLoading) ? () async {
                          setState(() => _isLoading = true);
                          
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set({
                                'selectedSports': _selectedSports,
                                'setupComplete': true,
                              }, SetOptions(merge: true));
                            }
    
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context, 
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (route) => false
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error al guardar: $e"))
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        } : null, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24FF8F),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                            )
                          : Text(
                              "Finalizar (${_selectedSports.length})",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            )
                      ),
                    ), 
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}