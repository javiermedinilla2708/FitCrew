import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:fitcrew/services/auth_services.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State <HomeScreen> createState()=> _HomeScreen();

}

class _HomeScreen extends State<HomeScreen>{
  final AuthService _authService=AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  //Lista de deportes del usuario
  List<String>_userSports=[];
  bool _isLoading=true;

  @override
  void initState(){
    super.initState();
    _loadUserData();
  }

  //Lógica para cargar los datos desde la Firestore
  Future <void> _loadUserData()async{
    if(user==null){
      return;
    }

    try{
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

      if(userDoc.exists && userDoc.data() != null){
        setState(() {
          _userSports=List<String>.from(userDoc.get('selectedSports')??[]);
        });
      }
    }catch(e){
      print("Error cargando datos: $e");
    }finally{
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final activityVM = Provider.of<ActivityViewModel>(context);

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
              child: (activityVM.isLoading || _isLoading)
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF24FF8F)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      itemCount: activityVM.activities.length,
                      itemBuilder: (context, index) {
                        final activity = activityVM.activities[index];
                        return _buildActivityCard(activity, activityVM);
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí podrías abrir un diálogo para crear actividad
        },
        backgroundColor: const Color(0xFF24FF8F),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

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
        if (value == 'Logout') {
          _authService.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        }
        print("Seleccionado: $value");
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'Todos', child: Text('Todos los deportes')),
        const PopupMenuDivider(),
        ..._userSports.map((sport) => PopupMenuItem<String>(
              value: sport,
              child: Text(sport),
            )),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'Logout', 
          child: Row(
            children: [
              
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            ],
          )
        ),
      ],
    );
  }

  Widget _buildActivityCard(SportActivity activity, ActivityViewModel vm) {
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
            child: Icon(
              _getSportIcon(activity.sportType),
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text("${activity.location} • ${activity.level}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (String value) {
              if (value == 'delete') {
                vm.deleteActivity(activity.id);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text("Editar"),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  "Borrar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método auxiliar para obtener iconos dinámicos
  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'padel': return Icons.sports_tennis;
      case 'running': return Icons.directions_run;
      case 'yoga': return Icons.self_improvement;
      case 'ciclismo': return Icons.directions_bike;
      case 'fútbol': return Icons.sports_soccer;
      case 'baloncesto': return Icons.sports_basketball;
      case 'natación': return Icons.pool;
      default: return Icons.sports_gymnastics;
    }
  }
}