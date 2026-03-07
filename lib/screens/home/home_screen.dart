import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //1.Header superior
            Padding(
              padding: EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Explorar", style: TextStyle(fontSize: 16,color: Colors.grey)),
                      Text("Actividades",style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),)
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Color(0xFF24FF8F).withOpacity(0.2),
                    child: Icon(Icons.person,color: Colors.black)
                  ),
                ],
              ),
            ),

            //Filtro para buscar el deporte de interes
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 25),
                children: [
                  
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}