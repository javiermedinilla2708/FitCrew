// 1. IMPORTACIONES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

// 2. WIDGET CON ESTADO PARA SELECCIÓN DE DEPORTES
class SportFilter extends StatefulWidget{
  const SportFilter ({super.key});

  @override
  State<SportFilter> createState()=> _SportFilter();
}

// 3. LÓGICA Y GESTIÓN DE ESTADO
class _SportFilter extends State<SportFilter>{
  
  // Listado completo de deportes (Sincronizado con AppConstants)
  final List<String> _sports = [
    "Padel", "Tenis", "Bádminton", "Ping Pong",
    "Fútbol", "Basket", "Voleibol", "Balonmano", "Rugby",
    "Running", "Ciclismo", "Natación", "Triatlón", "Patinaje",
    "Yoga", "Crossfit", "Gimnasio", "Calistenia", "Pilates",
    "Boxeo", "Judo", "Karate", "MMA",
    "Senderismo", "Escalada", "Surf", "Golf"
  ];

  // Variables de control para selección y carga
  final List <String> _selectedSports=[];
  bool _isLoading = false;

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
                      Color(0xFF24FF8F).withOpacity(0.35),
                      Colors.white.withOpacity(0)
                    ]
                  ),
                ),
              )
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20,),
                
                    // Botón de retroceso estilizado
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: IconButton(
                        onPressed: ()=>Navigator.pop(context), 
                        icon: Icon(Icons.arrow_back,size: 20,),
                      ),
                    ),
                    SizedBox(height: 30,),
                
                    // Cabecera: Títulos principales
                    Text("Casi listo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
                    Text("¿Qué te mueve?", style: TextStyle(fontSize: 28, color: Color(0xFF24FF8F), fontWeight: FontWeight.bold),),
                    SizedBox(height: 12,),
                
                    Text(
                      "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                
                    SizedBox(height: 30,),
      
                    // Cuerpo: Cuadrícula de chips autoadaptable (Wrap)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _sports.map((sport){
                            final isSelected=_selectedSports.contains(sport);
                            return FilterChip(
                              label: Text(sport), 
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              selected: isSelected,
                              onSelected: (bool selected){
                                setState(() {
                                  if(selected){
                                    _selectedSports.add(sport);
                                  } else {
                                    _selectedSports.remove(sport);
                                  }
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: Color(0xFF24FF8F),
                              checkmarkColor: Colors.black,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected ? Color(0xFF24FF8F) : Colors.grey.shade200,
                                )
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ),
      
                    // Pie: Botón de finalización y guardado en Firebase
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: (_selectedSports.length >= 3 && !_isLoading) ? () async {
                            setState(() => _isLoading = true);
                            
                            try {
                              // Persistencia de datos en Firestore
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
      
                              // Navegación a la pantalla principal
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
                            backgroundColor: Color(0xFF24FF8F),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: StadiumBorder(),
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
            )
          ],
        ),
      ),
    );
  }
}