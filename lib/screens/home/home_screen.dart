import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/post/create_post_screen.dart';
import 'package:fitcrew/screens/profile/profile_screen.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart'; // Asegúrate de que la ruta sea correcta
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final PostViewModel _postVM = PostViewModel(); // Instancia del ViewModel
  
  List<String> _userSports = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  // --- PALETA DE COLORES FITCREW ---
  final Color colorVerdeBosque = const Color(0xFF234D41);
  final Color colorVerdeMenta = const Color(0xFFD3E6DB);
  final Color colorFondoFrio = const Color(0xFFFBFDFA);
  final Color colorTextoTitulo = const Color(0xFF0F1D19);

  String _currentUserName = "Usuario";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && mounted) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['name'] ?? user?.displayName ?? "Usuario";
          _userSports = List<String>.from(data['favoriteSports'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos de usuario: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE ELIMINACIÓN ---

  void _confirmDeletion(BuildContext context, String postId) {
  ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de advertencia estilizado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 40),
          ),
          const SizedBox(height: 20),
          
          // Título y cuerpo
          Text(
            "¿Eliminar actividad?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorVerdeBosque,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Esta acción borrará permanentemente tu registro del entrenamiento. ¿Estás seguro?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Botones en columna para mejor UX
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                bool success = await _postVM.deletePost(postId);
                if (success && mounted) {
                  _showSnackBar("Actividad eliminada con éxito");
                }
              },
              child: const Text("Sí, eliminar ahora", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "No, mantener post",
                style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorVerdeBosque, // O Colors.red si quieres que sea diferente
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );
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
        'userName': _currentUserName,
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
      backgroundColor: colorFondoFrio,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorVerdeBosque))
          : _selectedIndex == 0
              ? _buildHomeFeed()
              : _buildOtherScreens(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeFeed() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 140.0,
          backgroundColor: Colors.white.withOpacity(0.9),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 10),
                _buildStoriesRow(),
                const SizedBox(height: 15),
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
                child: Center(child: CircularProgressIndicator(color: colorVerdeBosque)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text("No hay actividades aún")),
              );
            }

            final posts = snapshot.data!.docs;
            return SliverPadding(
              padding: const EdgeInsets.only(top: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = posts[index].data() as Map<String, dynamic>;
                    return _buildSocialPost(
                      posts[index].id,
                      data['userName'] ?? "Usuario",
                      data['sportType'] ?? "Deporte",
                      data['level'] ?? "Medio",
                      data['imageUrl'],
                      data['description'] ?? "",
                      data['userId'] ?? "", // Pasamos el ID del creador
                    );
                  },
                  childCount: posts.length,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Fit', style: TextStyle(color: colorTextoTitulo, fontSize: 26, fontWeight: FontWeight.w900)),
                TextSpan(text: 'Crew', style: TextStyle(color: colorVerdeBosque, fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: colorVerdeMenta.withOpacity(0.3), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: colorVerdeBosque),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _userSports.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final sport = _userSports[index];
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorVerdeMenta.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorVerdeBosque.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(_getSportIcon(sport), size: 16, color: colorVerdeBosque),
                const SizedBox(width: 8),
                Text(sport, style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialPost(String postId, String userName, String sport, String level, String? imageStr, String description, String postOwnerId) {
    // Validamos si el usuario actual es el dueño del post
    final bool isMyPost = user?.uid == postOwnerId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: colorVerdeBosque.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: colorVerdeMenta,
              child: Text(userName[0].toUpperCase(), style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold)),
            ),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("$sport • $level", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: isMyPost 
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) {
                      if (value == 'delete') _confirmDeletion(context, postId);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text("Eliminar post", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          
          // Busca esta parte dentro de tu _buildSocialPost:
          if (imageStr != null)
            Padding(
              // Añadimos un pequeño margen horizontal para que no pegue al borde del post
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  // Eliminamos height: 350. Ahora la altura es automática.
                  width: double.infinity,
                  color: colorFondoFrio, // Un fondo muy sutil mientras carga
                  child: _renderImage(imageStr),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LikeButton(postId: postId, activeColor: colorVerdeBosque),
                    const SizedBox(width: 15),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots(),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return GestureDetector(
                          onTap: () => _showComments(context, postId),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: colorVerdeMenta.withOpacity(0.3), shape: BoxShape.circle),
                                child: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: colorVerdeBosque),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 8),
                                Text("$count", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ]
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: colorTextoTitulo, fontSize: 14, height: 1.3),
                    children: [
                      TextSpan(text: "$userName ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: description),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(String? imageStr) {
  if (imageStr == null || imageStr.isEmpty) {
    return Container(
      height: 200, // Altura por defecto solo si no hay imagen
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.fitness_center, size: 50, color: colorVerdeBosque.withOpacity(0.2)),
      ),
    );
  }

  // 2. Renderizado para URL (Network)
  if (imageStr.startsWith('http')) {
    return Image.network(
      imageStr,
      // CAMBIADO: Usamos BoxFit.fitWidth para que ocupe todo el ancho 
      // y la altura se ajuste sola para mostrarla ENTERA.
      fit: BoxFit.fitWidth, 
      width: double.infinity,
      gaplessPlayback: true, 
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // Placeholder con altura estimada para evitar saltos visuales
        return Container(height: 250, color: Colors.grey[100], child: _buildPlaceholder());
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
    );
  }

  // 3. Renderizado para Base64 (Memoria)
  try {
    return Image.memory(
      base64Decode(imageStr),
      // CAMBIADO: Usamos BoxFit.fitWidth aquí también.
      fit: BoxFit.fitWidth, 
      width: double.infinity,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
    );
  } catch (e) {
    debugPrint("Error decodificando Base64: $e");
    return Container(height: 200, color: Colors.grey[100], child: _buildErrorIcon());
  }
}

// --- Widgets auxiliares para mantener el código limpio ---

Widget _buildPlaceholder() {
  return Container(
    color: Colors.grey[100],
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: colorVerdeBosque.withOpacity(0.3),
      ),
    ),
  );
}

Widget _buildErrorIcon() {
  return Container(
    color: Colors.grey[100],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_outlined, color: Colors.red[200], size: 40),
        const SizedBox(height: 8),
        Text("No se pudo cargar", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    ),
  );
}

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
        height: 70,
        decoration: BoxDecoration(
          color: colorVerdeBosque,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 0),
            _buildNavItem(Icons.search_rounded, Icons.search_rounded, 1),
            _buildCentralAddButton(),
            _buildNavItem(Icons.fitness_center_outlined, Icons.fitness_center_rounded, 2), 
            _buildNavItem(Icons.person_outline_rounded, Icons.person, 3), 
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutlined, IconData iconFilled, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorFondoFrio.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? iconFilled : iconOutlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCentralAddButton() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colorVerdeMenta, borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add_rounded, color: Color(0xFF0F1D19), size: 26),
      ),
    );
  }

  Widget _buildOtherScreens() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const SizedBox.shrink(), 
        const Center(child: Text("Búsqueda")),
        const Center(child: Text("Actividades")),
        ProfileScreen(
          userSports: _userSports,
          userEmail: user?.email ?? "",
          userName: _currentUserName,
        ),
      ],
    );
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    height: 5, width: 40,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Comentarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorTextoTitulo)),
                      const SizedBox(width: 8),
                      if (total > 0)
                        Badge(label: Text(total.toString()), backgroundColor: colorVerdeBosque),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: !snapshot.hasData 
                      ? Center(child: CircularProgressIndicator(color: colorVerdeBosque))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: total,
                          itemBuilder: (context, index) {
                            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(backgroundColor: colorVerdeMenta, child: Icon(Icons.person, size: 20, color: colorVerdeBosque)),
                              title: Text(data['userName'] ?? 'Usuario', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(data['comment'] ?? ''),
                            );
                          },
                        ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: "Añadir comentario...",
                              filled: true,
                              fillColor: colorFondoFrio,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: colorVerdeBosque,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: () async {
                              if (commentController.text.isNotEmpty) {
                                String text = commentController.text;
                                commentController.clear();
                                await _addCommentToFirebase(postId, text);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
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
}

// ==========================================
// WIDGET LIKEBUTTON (REDISEÑADO)
// ==========================================
class LikeButton extends StatelessWidget {
  final String postId;
  final Color activeColor;
  const LikeButton({super.key, required this.postId, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('likes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Icon(Icons.favorite_border_rounded);
        final likes = snapshot.data!.docs;
        final bool isLiked = likes.any((doc) => doc.id == userId);

        return Row(
          children: [
            GestureDetector(
              onTap: () => _toggleLike(postId, userId, isLiked),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLiked ? activeColor.withOpacity(0.1) : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? activeColor : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("${likes.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
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