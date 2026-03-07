import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

class SportFilter extends StatefulWidget{
  const SportFilter ({super.key});

  @override
  State<SportFilter> createState()=> _SportFilter();

}

class _SportFilter extends State<SportFilter>{
  
  //Lista de deportes
  final List<String> _sports = [
    "Crossfit", "Running", "Yoga", "Padel", 
    "Ciclismo", "Fútbol", "Baloncesto", "Tenis", 
    "Natación", "Boxeo", "Gym", "Calistenia"
  ];

  //Lista para guardar los deportes seleccionados
  final List <String> _selectedSports=[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
              
                  //Botón de retroceso
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
              
                  //Título
                  Text("Casi listo",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
                  Text("¿Qué te mueve?", style: TextStyle(fontSize: 28,color: Color(0xFF24FF8F),fontWeight: FontWeight.bold),),
                  SizedBox(height: 12,),
              
                  Text(
                    "Selecciona al menos 3 deportes para encontrar a tu Crew ideal.",
                    style: TextStyle(color: Colors.grey,fontSize: 15),
                  ),
              
                  SizedBox(height: 30,),

                  //Contenedor para las chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _sports.map((sport){
                          final isSelected=_selectedSports.contains(sport);
                          return FilterChip(
                            label: Text(sport), 
                            labelStyle: TextStyle(
                              color: isSelected?Colors.black:Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold:FontWeight.normal,
                            ),
                            selected: isSelected,
                            onSelected: (bool selected){
                              setState(() {
                                if(selected){
                                  _selectedSports.add(sport);
                                }else{
                                  _selectedSports.remove(sport);
                                }
                              });
                            } ,
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

                  //Botón Finalizar
                  Padding(
                    padding:EdgeInsets.symmetric(vertical: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _selectedSports.length >=3 ? (){
                          //Logica para guardar en Firebase y entrar en la app

                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>HomeScreen()),
                          (route)=>false);
                        }:null,//Desactivado si no hay 3 seleccionados
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF24FF8F),
                          disabledBackgroundColor: Colors.grey,
                          shape: StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          "Finalizar (${_selectedSports.length})",
                          style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
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
    );
  }
}