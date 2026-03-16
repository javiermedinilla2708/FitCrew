// ==========================================
// 1. IMPORTACIONES
// ==========================================
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/post/create_post_screen.dart';
import 'package:flutter/material.dart';

// ==========================================
// 2. WIDGET PRINCIPAL (HOME SCREEN)
// ==========================================
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
  final Color fitCrewGreen = const Color(0xFF24FF8F);
  String _currentUserName = "Usuario";
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- Lógica de Firebase ---

  Future<void> _loadUserData() async {
  if (user == null) {
    print("DEBUG-FIT: No hay usuario autenticado.");
    if (mounted) setState(() => _isLoading = false);
    return;
  }

  print("DEBUG-FIT: Buscando UID: ${user!.uid}");

  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (!userDoc.exists) {
      print("DEBUG-FIT: ¡ERROR! El documento con ID ${user!.uid} NO EXISTE en la colección 'users'.");
    } else {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      print("DEBUG-FIT: Datos encontrados: $data");

      if (mounted) {
        setState(() {
          // Cambia 'username' por el nombre exacto que veas en el print de arriba
          _currentUserName = data['username'] ?? data['name'] ?? data['display_name'] ?? "Nombre no hallado";
          _userSports = List<String>.from(data['selectedSports'] ?? []);
        });
      }
    }
  } catch (e) {
    print("DEBUG-FIT: Excepción capturada: $e");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
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
      'userName': _currentUserName, // <--- Aquí ya usamos el nombre real
      'comment': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint("Error al comentar: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 100,
                child: LinearProgressIndicator(color: fitCrewGreen),
              ),
            )
          : _selectedIndex == 0
              ? _buildHomeFeed()
              : _buildOtherScreens(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: fitCrewGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================
  // 3. COMPONENTES DEL FEED
  // ==========================================

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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: fitCrewGreen)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text("No hay actividades aún")),
              );
            }

            final posts = snapshot.data!.docs;
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final data = posts[index].data() as Map<String, dynamic>;
                  return _buildSocialPost(
                    posts[index].id,
                    data['userName'] ?? "Usuario", // Solo el nombre
                    data['sportType'] ?? "Deporte",
                    data['level'] ?? "Medio",
                    data['imageUrl'],
                    data['description'] ?? "",
                  );
                },
                childCount: posts.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
            text: TextSpan(
              children: [
                const TextSpan(text: 'Fit', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                TextSpan(text: 'Crew', style: TextStyle(color: fitCrewGreen, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
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

  Widget _buildStoryItem(String sport) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF24FF8F), Colors.blueAccent])),
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

  // ==========================================
  // 4. WIDGETS DE POST SOCIAL
  // ==========================================

  Widget _buildSocialPost(String postId, String userName, String sport, String level, String? imageStr, String description) {
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
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF24FF8F),
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("$sport • $level", style: const TextStyle(fontSize: 12)),
            trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          ),
          Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _renderImage(imageStr),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                LikeButton(postId: postId),
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
                    }),
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
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty) {
      return const Icon(Icons.fitness_center, size: 50, color: Colors.grey);
    }
    if (imageStr.startsWith('http')) {
      return Image.network(imageStr, fit: BoxFit.cover);
    }
    try {
      return Image.memory(
        base64Decode(imageStr),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }

  // ==========================================
  // 5. NAVEGACIÓN Y OTROS
  // ==========================================

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? fitCrewGreen : Colors.grey, size: isSelected ? 30 : 26),
      onPressed: () => setState(() => _selectedIndex = index),
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
      case 'running': return Icons.directions_run;
      case 'basket': return Icons.sports_basketball;
      case 'fútbol': return Icons.sports_soccer;
      case 'ciclismo': return Icons.directions_bike;
      case 'crossfit': case 'gimnasio': return Icons.fitness_center;
      case 'yoga': return Icons.self_improvement;
      default: return Icons.bolt;
    }
  }

  // ==========================================
  // 6. MODAL DE COMENTARIOS
  // ==========================================

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
                      backgroundColor: fitCrewGreen,
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

// ==========================================
// 7. WIDGET LIKEBUTTON
// ==========================================
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
            Text("${likes.length}", style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }

  Future<void> _toggleLike(String postId, String? userId, bool isLiked) async {
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId).collection('likes').doc(userId);
    if (isLiked) {
      await docRef.delete();
    } else {
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
  }
}