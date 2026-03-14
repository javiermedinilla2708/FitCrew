// 1. IMPORTACIONES
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:flutter/material.dart';

// 2. WIDGET CON ESTADO 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

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

  Future<void> _addCommentToFirebase(String postId, String commentText) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': user!.uid,
        'userName': user!.displayName ?? "Usuario Fit",
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al comentar: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    const Color fitCrewGreen = Color(0xFF24FF8F);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white, 
      
      body: _isLoading
          ? const Center(child: LinearProgressIndicator(color: fitCrewGreen))
          : _selectedIndex == 0 
              ? _buildHomeFeed() 
              : _buildOtherScreens(),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: fitCrewGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomAppBar(
            height: 65,
            color: Colors.white,
            elevation: 10,
            notchMargin: 8,
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, 0),
                _buildNavItem(Icons.search, 1),
                const SizedBox(width: 40),
                _buildNavItem(Icons.calendar_today_rounded, 3),
                _buildNavItem(Icons.person_outline, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Tus importaciones y modelos se mantienen igual arriba)

Widget _buildHomeFeed() {
  return CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverAppBar(
        floating: true,
        pinned: true,
        expandedHeight: 170.0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Column(
            children: [
              const SizedBox(height: 50),
              _buildTopHeader(),
              _buildStoriesRow(),
            ],
          ),
        ),
      ),
      // --- CARGA DE POSTS REALES DESDE FIREBASE ---
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts') // O 'activities', como prefieras llamarlo
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF24FF8F))),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SliverFillRemaining(
              child: Center(child: Text("No hay actividades próximas. ¡Crea una!")),
            );
          }

          final posts = snapshot.data!.docs;

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Convertimos el documento de Firebase a nuestro modelo SportActivity
                final data = posts[index].data() as Map<String, dynamic>;
                final activity = SportActivity.fromMap(data, posts[index].id);

                return _buildSocialPost(
                  activity.id,
                  "Usuario Fit", // Aquí podrías hacer un fetch del nombre del organizador
                  activity.sportType,
                  activity.location,
                  data['imageUrl'] ?? "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=500",
                );
              },
              childCount: posts.length,
            ),
          );
        },
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: 120), // Espacio extra para el scroll
      ),
    ],
  );
}

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Fit', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                TextSpan(text: 'Crew', style: TextStyle(color: Color(0xFF24FF8F), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.send_rounded), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _userSports.length,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) => _buildStoryItem(_userSports[index]),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? const Color(0xFF24FF8F) : Colors.grey, size: isSelected ? 30 : 26),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildSocialPost(String postId, String userName, String sport, String location, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(location, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          ),
          Container(
            height: 280,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                LikeButton(postId: postId), // Pasamos el postId al botón
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87),
                  onPressed: () => _showComments(context, postId),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text("$count", style: const TextStyle(fontWeight: FontWeight.w600));
                  }
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(text: "$userName ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "¡Entrenamiento de $sport a tope! 🚀"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showCreatePostSheet(BuildContext context) {
  final TextEditingController descriptionController = TextEditingController();
  String selectedSport = _userSports.isNotEmpty ? _userSports[0] : "Running";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder( // Usamos StatefulBuilder para que el dropdown funcione dentro del modal
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 10,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                height: 5, width: 40,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text("¿Qué has entrenado hoy?", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Selector de Deporte (basado en los deportes del usuario)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSport,
                  isExpanded: true,
                  items: (_userSports.isNotEmpty ? _userSports : ["Running", "Padel", "Gym"])
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedSport = val!),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Input de descripción
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: ¡6km de carrera suave por el parque! Me he sentido genial...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botón de Publicar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Aquí llamarías a tu ViewModel para guardar en Firebase
                  // viewModel.createSocialPost(sport: selectedSport, description: descriptionController.text...)
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24FF8F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text("COMPARTIR LOGRO", 
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildStoryItem(String sport) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle, 
              gradient: LinearGradient(colors: [Color(0xFF24FF8F), Colors.blueAccent])
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(_getSportIcon(sport), color: Colors.black, size: 24),
            ),
          ),
          Text(sport, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOtherScreens() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        SizedBox(), 
        Center(child: Text("Búsqueda")),
        SizedBox(),
        Center(child: Text("Actividades")),
        Center(child: Text("Perfil")),
      ],
    );
  }

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

  void _showComments(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 5, width: 40,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const Text("Comentarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
                          title: Text(data['userName'] ?? 'Usuario', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(data['comment'] ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 15,
                  left: 15, right: 15, top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Escribe un comentario...",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF24FF8F),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black, size: 20),
                        onPressed: () async {
                          if (commentController.text.isNotEmpty) {
                            await _addCommentToFirebase(postId, commentController.text);
                            commentController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. WIDGET LIKEBUTTON ACTUALIZADO PARA FIREBASE
class LikeButton extends StatelessWidget {
  final String postId;
  const LikeButton({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Icon(Icons.favorite_border_rounded);

        final likes = snapshot.data!.docs;
        // Comprobar si el usuario actual ya dio like
        final bool isLiked = likes.any((doc) => doc.id == userId);

        return Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.red : Colors.black,
              ),
              onPressed: () => _toggleLike(postId, userId, isLiked),
            ),
            Text(
              "${likes.length}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleLike(String postId, String? userId, bool isLiked) async {
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId);

    if (isLiked) {
      await docRef.delete(); // Quitar like
    } else {
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
      }); // Añadir like
    }
  }
}