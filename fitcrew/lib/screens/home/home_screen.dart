import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/activities/activities_screen.dart';
import 'package:fitcrew/screens/notifications/notification_screen.dart';
import 'package:fitcrew/screens/post/create_post_screen.dart';
import 'package:fitcrew/screens/profile/profile_screen.dart';
import 'package:fitcrew/screens/profile/user_profile_screen.dart';
import 'package:fitcrew/screens/ranking/ranking_screen.dart';
import 'package:fitcrew/screens/search/search_user_screen.dart';
import 'package:fitcrew/services/api_service.dart';
import 'package:fitcrew/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart';

// ============================================================
// HomeScreen
// Pantalla principal con feed social, navegación inferior
// y acceso a actividades y perfil
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final User? _user = FirebaseAuth.instance.currentUser;

  List<String> _userSports = [];
  String _currentUserName = "Usuario";
  bool _isLoading = true;
  int _selectedIndex = 0;

  final GlobalKey<_StatsRowState> _statsKey = GlobalKey<_StatsRowState>();

  final GlobalKey<ProfileScreenState> _profileKey =
      GlobalKey<ProfileScreenState>();
  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ----------------------------------------------------------
  // CARGA DE DATOS DE USUARIO
  // ----------------------------------------------------------
  Future<void> _loadUserData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = data['name'] ?? _user.displayName ?? "Usuario";
          _userSports = List<String>.from(data['favoriteSports'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos de usuario: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadStats() async {
    await _statsKey.currentState?.reload();
  }

  // ----------------------------------------------------------
  // LÓGICA DE COMENTARIOS
  // ----------------------------------------------------------
  Future<void> _addComment(String postId, String commentText) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
            'userId': _user.uid,
            'userName': _currentUserName,
            'comment': commentText,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error al comentar: $e");
    }
  }

  // ----------------------------------------------------------
  // LÓGICA DE ELIMINACIÓN
  // ----------------------------------------------------------
  void _confirmDeletion(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: _colorVerdeBosque,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "¿Eliminar actividad?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _colorVerdeBosque,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Esta acción borrará permanentemente tu registro. ¿Estás seguro?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorVerdeBosque,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await context
                      .read<PostViewModel>()
                      .deletePost(postId);
                  if (success && mounted) {
                    _showSnackBar("Actividad eliminada con éxito");
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) _reloadStats();
                  }
                },
                child: const Text(
                  "Sí, eliminar ahora",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
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
                child: const Text(
                  "No, mantener post",
                  style: TextStyle(
                    color: _colorVerdeBosque,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _colorVerdeBosque,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: _colorFondoFrio,
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  color: _colorVerdeBosque,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : _selectedIndex == 0
          ? _buildHomeFeed()
          : _buildOtherScreens(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: FEED PRINCIPAL
  // ----------------------------------------------------------
  Widget _buildHomeFeed() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 160.0,
          backgroundColor: Colors.white.withOpacity(0.9),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 10),
                _StatsRow(key: _statsKey, uid: _user?.uid ?? ''),
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
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _colorVerdeBosque),
                ),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = posts[index].data() as Map<String, dynamic>;
                  return _buildSocialPost(
                    posts[index].id,
                    data['userName'] ?? "Usuario",
                    data['sportType'] ?? "Deporte",
                    data['level'] ?? "Medio",
                    data['imageUrl'],
                    data['description'] ?? "",
                    data['userId'] ?? "",
                    data['profilePic'],
                  );
                }, childCount: posts.length),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CABECERA SUPERIOR
  // ----------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 25, right: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Fit',
                  style: TextStyle(
                    color: _colorTextoTitulo,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: 'Crew',
                  style: TextStyle(
                    color: _colorVerdeBosque,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              // Botón buscar personas con badge
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('follow_requests')
                    .where('toUid', isEqualTo: _user?.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData
                      ? snapshot.data!.docs.length
                      : 0;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _colorVerdeMenta.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.people_outline_rounded,
                            color: _colorVerdeBosque,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchUsersScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? "9+" : "$count",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 8),

              // Botón notificaciones con badge
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _colorVerdeMenta.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: _colorVerdeBosque,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? "9+" : "$count",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: TARJETA DE POST SOCIAL
  // ----------------------------------------------------------
  Widget _buildSocialPost(
    String postId,
    String userName,
    String sport,
    String level,
    String? imageStr,
    String description,
    String postOwnerId,
    String? profilePic,
  ) {
    final bool isMyPost = _user?.uid == postOwnerId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _colorVerdeBosque.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            leading: GestureDetector(
              onTap: () {
                if (postOwnerId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(uid: postOwnerId, name: userName),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                key: ValueKey(profilePic ?? userName),
                backgroundColor: _colorVerdeMenta,
                backgroundImage: profilePic != null && profilePic.isNotEmpty
                    ? MemoryImage(base64Decode(profilePic))
                    : null,
                child: profilePic == null || profilePic.isEmpty
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _colorVerdeBosque,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "$sport • $level",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: isMyPost
                ? PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[400],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeletion(context, postId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: _colorVerdeBosque,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Eliminar post",
                              style: TextStyle(color: _colorVerdeBosque),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          if (imageStr != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: double.infinity,
                  color: _colorFondoFrio,
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
                    LikeButton(postId: postId, activeColor: _colorVerdeBosque),
                    const SizedBox(width: 15),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData
                            ? snapshot.data!.docs.length
                            : 0;
                        return GestureDetector(
                          onTap: () => _showComments(context, postId),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _colorVerdeMenta.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: _colorVerdeBosque,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  "$count",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _colorTextoTitulo,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: "$userName ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  // ----------------------------------------------------------
  // SEGMENTO: RENDERIZADO DE IMAGEN
  // ----------------------------------------------------------
  Widget _renderImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            Icons.fitness_center,
            size: 50,
            color: _colorVerdeBosque.withOpacity(0.2),
          ),
        ),
      );
    }

    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: Colors.grey[100],
            child: _buildImagePlaceholder(),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
      );
    }

    try {
      return Image.memory(
        base64Decode(imageStr),
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
      return Container(
        height: 200,
        color: Colors.grey[100],
        child: _buildErrorIcon(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _colorVerdeBosque,
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
          Text(
            "No se pudo cargar",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: NAVEGACIÓN INFERIOR
  // ----------------------------------------------------------
  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
        height: 70,
        decoration: BoxDecoration(
          color: _colorVerdeBosque,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 0),
            _buildNavItem(Icons.search_rounded, Icons.search_rounded, 1),
            _buildCentralAddButton(),
            _buildNavItem(Icons.map_outlined, Icons.map_rounded, 2),
            _buildNavItem(Icons.person_outline_rounded, Icons.person, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutlined, IconData iconFilled, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _colorFondoFrio.withOpacity(0.2)
              : Colors.transparent,
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          _reloadStats();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _colorVerdeMenta,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Color(0xFF0F1D19),
          size: 26,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: OTRAS PANTALLAS (IndexedStack)
  // ----------------------------------------------------------
  Widget _buildOtherScreens() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const SizedBox.shrink(),
        const RankingScreen(),
        ActivityScreen(
          userInterests: _userSports,
          onStatsChanged: () async {
            await Future.delayed(const Duration(seconds: 1));
            _reloadStats();
            _profileKey.currentState?.reload();
          },
        ),
        ProfileScreen(
          key: _profileKey,
          userSports: _userSports,
          userEmail: _user?.email ?? "",
          userName: _currentUserName,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: MODAL DE COMENTARIOS
  // ----------------------------------------------------------
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
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Comentarios",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _colorTextoTitulo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (total > 0)
                        Badge(
                          label: Text(total.toString()),
                          backgroundColor: _colorVerdeBosque,
                        ),
                    ],
                  ),

                  const Divider(),

                  Expanded(
                    child: !snapshot.hasData
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _colorVerdeBosque,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: total,
                            itemBuilder: (context, index) {
                              final data =
                                  snapshot.data!.docs[index].data()
                                      as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _colorVerdeMenta,
                                  child: const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: _colorVerdeBosque,
                                  ),
                                ),
                                title: Text(
                                  data['userName'] ?? 'Usuario',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(data['comment'] ?? ''),
                              );
                            },
                          ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: "Añadir comentario...",
                              filled: true,
                              fillColor: _colorFondoFrio,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: _colorVerdeBosque,
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () async {
                              if (commentController.text.isNotEmpty) {
                                final text = commentController.text;
                                commentController.clear();
                                await _addComment(postId, text);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET: _StatsRow
// Widget independiente con su propio estado para que al
// recargar las stats solo se reconstruya este widget y no
// toda la HomeScreen ni el feed de posts
// ============================================================
class _StatsRow extends StatefulWidget {
  final String uid;
  const _StatsRow({super.key, required this.uid});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);

  UserStats? _userStats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService().getUserStats(widget.uid);
      if (mounted) setState(() => _userStats = stats);
    } catch (e) {
      debugPrint("Error cargando stats: $e");
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  //Método público llamado desde HomeScreen via GlobalKey
  Future<void> reload() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _chip(
            Icons.photo_camera_outlined,
            "Posts",
            _loadingStats ? "..." : "${_userStats?.totalPosts ?? 0}",
          ),
          const SizedBox(width: 10),
          _chip(
            Icons.sports_outlined,
            "Actividades",
            _loadingStats ? "..." : "${_userStats?.totalActivitiesJoined ?? 0}",
          ),
          const SizedBox(width: 10),
          _chip(
            Icons.local_fire_department_outlined,
            "Racha",
            _loadingStats ? "..." : "${_userStats?.currentStreakDays ?? 0}d",
          ),
          const SizedBox(width: 10),
          _chip(
            Icons.emoji_events_outlined,
            "Organizado",
            _loadingStats
                ? "..."
                : "${_userStats?.totalActivitiesOrganized ?? 0}",
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: _colorVerdeMenta.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _colorVerdeBosque.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _colorVerdeBosque),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _colorVerdeBosque,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: _colorVerdeBosque.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET: LikeButton
// ============================================================
class LikeButton extends StatelessWidget {
  final String postId;
  final Color activeColor;

  const LikeButton({
    super.key,
    required this.postId,
    required this.activeColor,
  });

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
        if (!snapshot.hasData) {
          return const Icon(Icons.favorite_border_rounded);
        }

        final likes = snapshot.data!.docs;
        final isLiked = likes.any((doc) => doc.id == userId);

        return Row(
          children: [
            GestureDetector(
              onTap: () => _toggleLike(postId, userId, isLiked),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLiked
                      ? activeColor.withOpacity(0.1)
                      : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? activeColor : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${likes.length}",
              style: const TextStyle(fontWeight: FontWeight.bold),
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
      await docRef.delete();
    } else {
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});
    }
  }
}
