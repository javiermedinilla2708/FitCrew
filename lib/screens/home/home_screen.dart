import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Explorar", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("Actividades", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _buildFilterMenu(context),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildActivityCard();
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF24FF8F),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  //Widget para el filtro
  Widget _buildFilterMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.tune, color: Colors.black, size: 24),
      ),
      onSelected: (String value) {
        print("Seleccionado: $value");
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Todos',
          child: Text('Todos los deportes'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'Padel',
          child: Text('Padel'),
        ),
        const PopupMenuItem<String>(
          value: 'Running',
          child: Text('Running'),
        ),
        const PopupMenuItem<String>(
          value: 'Yoga',
          child: Text('Yoga'),
        ),
      ],
    );
  }

  Widget _buildActivityCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF24FF8F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.sports_tennis, color: Colors.black),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Partido de Padel (Nivel Medio)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text("Polideportivo Municipal • 18:00h",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}