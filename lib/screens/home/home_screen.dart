// 1. IMPORTACIONES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 2. WIDGET CON ESTADO 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// 3. CLASE DE ESTADO Y LÓGICA DE NEGOCIO
class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<String> _userSports = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carga de datos del usuario desde Firestore
  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _userSports = List<String>.from(userDoc.get('selectedSports') ?? []);
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. CONSTRUCCIÓN DE LA INTERFAZ PRINCIPAL 
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), 
        appBar: _buildCustomAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF24FF8F)))
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildSocialFeedPage(),
                  const Center(child: Text("Pantalla de Chats")),
                  const Center(child: Text("Pantalla de Perfil")),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.black, 
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Inicio"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explorar"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF24FF8F),
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
    );
  }

  // 5. COMPONENTES DE LA INTERFAZ 

  // Barra de navegación superior 
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: false,
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(text: 'Fit', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            TextSpan(text: 'Crew', style: TextStyle(color: Color(0xFF24FF8F), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}),
        IconButton(icon: const Icon(Icons.send_rounded, color: Colors.black), onPressed: () {}),
        const SizedBox(width: 5),
      ],
    );
  }

  // Contenido principal del muro social
  Widget _buildSocialFeedPage() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          height: 115,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _userSports.length,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            itemBuilder: (context, index) {
              return _buildStoryItem(_userSports[index]);
            },
          ),
        ),
        
        const SizedBox(height: 10), 

        // Listado de actividades publicadas
        _buildPostCard("Juan García", "Padel 2vs2", "Centro Deportivo Ronda", "18:00h", "3/4", "padel"),
        _buildPostCard("Marta Ruiz", "Running Grupal", "Parque de la Alameda", "08:30h", "7/20", "running"),
        _buildPostCard("FitClub Ronda", "Clase Yoga", "Gimnasio FitCrew", "20:00h", "12/15", "yoga"),
        
        const SizedBox(height: 80), 
      ],
    );
  }

  // Elemento individual para el selector de deportes 
  Widget _buildStoryItem(String sport) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF24FF8F), Colors.blueAccent]
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(_getSportIcon(sport), color: Colors.black, size: 25),
            ),
          ),
          const SizedBox(height: 6),
          Text(sport, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Tarjeta de actividad 
  Widget _buildPostCard(String user, String title, String location, String time, String spots, String sport) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del post con datos del autor
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF24FF8F).withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.black),
            ),
            title: Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(location, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.more_horiz, color: Colors.grey),
          ),
          
          // Información detallada de la actividad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getSportIcon(sport), size: 32, color: const Color(0xFF24FF8F)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text("Hoy a las $time", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(spots, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  )
                ],
              ),
            ),
          ),

          // Sección de interacción 
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.favorite_border, size: 26), onPressed: () {}),
                IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 24), onPressed: () {}),
                IconButton(icon: const Icon(Icons.share_outlined, size: 24), onPressed: () {}),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24FF8F),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Apuntarse", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN PARA ASIGNAR ICONOS DINÁMICOS SEGÚN EL DEPORTE
IconData _getSportIcon(String sportType) {
  switch (sportType.toLowerCase()) {
    // Deportes de Raqueta
    case 'padel':
    case 'tenis':
      return Icons.sports_tennis;
    case 'bádminton':
      return Icons.wb_iridescent_rounded;
    case 'ping pong':
      return Icons.table_restaurant_rounded;

    // Deportes de Equipo
    case 'fútbol':
    case 'balonmano':
      return Icons.sports_soccer;
    case 'basket':
      return Icons.sports_basketball;
    case 'voleibol':
      return Icons.sports_volleyball;
    case 'rugby':
      return Icons.sports_rugby;

    // Resistencia y Cardio
    case 'running':
      return Icons.directions_run;
    case 'ciclismo':
      return Icons.directions_bike;
    case 'natación':
      return Icons.pool;
    case 'triatlón':
      return Icons.directions_run_rounded;
    case 'patinaje':
      return Icons.ice_skating;

    // Entrenamiento y Fuerza
    case 'yoga':
    case 'pilates':
      return Icons.self_improvement;
    case 'crossfit':
    case 'gimnasio':
    case 'calistenia':
      return Icons.fitness_center;

    // Deportes de Combate
    case 'boxeo':
    case 'mma':
      return Icons.sports_mma;
    case 'judo':
    case 'karate':
      return Icons.front_hand;

    // Aire Libre y Otros
    case 'senderismo':
      return Icons.terrain;
    case 'escalada':
      return Icons.landscape;
    case 'surf':
      return Icons.surfing;
    case 'golf':
      return Icons.sports_golf;

    default:
      return Icons.bolt;
  }
}
}