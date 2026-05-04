// ============================================================
// lib/screens/profile/profile_screen.dart
// Pantalla de perfil con estadísticas, deportes favoritos
// y galería de logros del usuario.
// Permite editar nombre, bio, foto de perfil y deportes.
// Circulo de entrenos y barras de deportes con datos reales.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/main.dart';
import 'package:fitcrew/screens/settings/preferences_screen.dart';
import 'package:fitcrew/screens/settings/privacy_screen.dart';
import 'package:fitcrew/screens/settings/security_screen.dart';
import 'package:fitcrew/screens/welcome/welcome_screen.dart';
import 'package:fitcrew/services/api_service.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ============================================================
// StatefulWidget — necesario para gestionar el estado local
// del perfil (nombre, bio, foto, deportes y stats de la API)
// ============================================================
class ProfileScreen extends StatefulWidget {
  final List<String> userSports;
  final String userEmail;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userSports,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  // ----------------------------------------------------------
  // ESTADO LOCAL DEL PERFIL
  // ----------------------------------------------------------
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Datos del perfil cargados desde Firestore
  String _currentName = '';
  String _currentBio = '';
  String? _currentPicB64;
  List<String> _currentSports = [];

  // Stats desde la API (circulo de entrenos)
  UserStats? _userStats;
  bool _loadingStats = false;

  // Actividades por deporte para las barras de progreso reales
  Map<String, int> _activitiesBySport = {};

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadStats();
  }

  // ----------------------------------------------------------
  // CARGAR DATOS DEL PERFIL DESDE FIRESTORE
  // ----------------------------------------------------------
  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _currentName = data['name'] ?? widget.userName;
          _currentBio = data['bio'] ?? '';
          _currentPicB64 = data['profilePic'];
          _currentSports = List<String>.from(data['favoriteSports'] ?? []);
        });
        await _loadActivitiesBySport();
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    }
  }

  // ----------------------------------------------------------
  // CARGAR STATS DESDE LA API
  // totalActivitiesJoined alimenta el circulo de Entrenos
  // ----------------------------------------------------------
  Future<void> _loadStats() async {
    if (_uid.isEmpty) return;
    setState(() => _loadingStats = true);
    try {
      final stats = await ApiService().getUserStats(_uid);
      if (mounted) setState(() => _userStats = stats);
    } catch (e) {
      debugPrint("Error cargando stats: $e");
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ----------------------------------------------------------
  // CALCULAR ACTIVIDADES POR DEPORTE
  // Cuenta las actividades del usuario agrupadas por sportType
  // para alimentar las barras de progreso con datos reales
  // ----------------------------------------------------------
  Future<void> _loadActivitiesBySport() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('activities')
          .where('participants', arrayContains: _uid)
          .get();

      final Map<String, int> counts = {};
      for (final doc in query.docs) {
        final sport = doc.data()['sportType'] as String? ?? 'Otros';
        counts[sport] = (counts[sport] ?? 0) + 1;
      }

      if (mounted) setState(() => _activitiesBySport = counts);
    } catch (e) {
      debugPrint("Error cargando actividades por deporte: $e");
    }
  }

  // ----------------------------------------------------------
  // RECARGA PUBLICA
  // Llamado desde HomeScreen via GlobalKey cuando el usuario
  // crea una actividad o se apunta/desapunta desde el mapa
  // ----------------------------------------------------------
  Future<void> reload() async {
    await _loadStats();
    await _loadActivitiesBySport();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        backgroundColor: _colorFondoFrio,
        surfaceTintColor: _colorFondoFrio,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Mi Perfil",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: _colorVerdeBosque,
              size: 28,
            ),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 25),
              _buildPerformanceDashboard(),
              const SizedBox(height: 35),
              _buildPostSection(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CABECERA DE PERFIL
  // Avatar con foto real en Base64, nombre y bio.
  // El boton de editar abre el modal de edicion de perfil.
  // ----------------------------------------------------------
  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _colorVerdeMenta, width: 2),
              ),
              child: GestureDetector(
                onTap: () {
                  if (_currentPicB64 != null && _currentPicB64!.isNotEmpty) {
                    _showFullScreenImage(context, _currentPicB64!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _colorVerdeMenta, width: 2),
                  ),

                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: _colorVerdeMenta,
                    // Muestra la foto en Base64 si existe, letra inicial si no
                    backgroundImage: _currentPicB64 != null
                        ? MemoryImage(base64Decode(_currentPicB64!))
                        : null,
                    child: _currentPicB64 == null
                        ? Text(
                            _currentName.isNotEmpty
                                ? _currentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _colorVerdeBosque,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Boton editar — abre el modal de edicion
            GestureDetector(
              onTap: () => _showEditProfileSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _colorVerdeBosque,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          _currentName.isNotEmpty ? _currentName : widget.userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: _colorVerdeBosque,
          ),
        ),

        // Bio — visible solo si el usuario la ha rellenado
        if (_currentBio.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _currentBio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: ESTADISTICAS PRINCIPALES
  // Posts, Seguidores y Seguidos en tiempo real desde Firestore
  // ----------------------------------------------------------
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Posts en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _statItem(count.toString(), "Posts");
              },
            ),
          ),

          const SizedBox(width: 12),

          // Seguidores en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .collection('followers')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _statItem(count.toString(), "Seguidores");
              },
            ),
          ),

          const SizedBox(width: 12),

          // Seguidos en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .collection('following')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _statItem(count.toString(), "Seguidos");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colorVerdeBosque.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DASHBOARD DE RENDIMIENTO
  // Circulo de Entrenos: totalActivitiesJoined de la API
  //   maximo = 30 actividades (referencia mensual)
  // Barras de deportes: actividades reales por deporte
  //   la barra mas larga es el deporte con mas actividades
  // ----------------------------------------------------------
  Widget _buildPerformanceDashboard() {
    const int maxActivities = 30;
    final int joined = _userStats?.totalActivitiesJoined ?? 0;
    final double progress = (joined / maxActivities).clamp(0.0, 1.0);

    _currentSports.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circulo de Entrenos con datos reales de la API
          Expanded(
            flex: 4,
            child: _cardWrapper(
              child: Column(
                children: [
                  const Text(
                    "Entrenos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _colorVerdeBosque,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 65,
                        width: 65,
                        child: _loadingStats
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _colorVerdeBosque,
                              )
                            : CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 7,
                                backgroundColor: _colorVerdeMenta.withOpacity(
                                  0.3,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _colorVerdeBosque,
                                ),
                              ),
                      ),
                      if (!_loadingStats)
                        Text(
                          "$joined",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _colorVerdeBosque,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "de $maxActivities este mes",
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Barras de deportes con actividades reales
          Expanded(
            flex: 6,
            child: _cardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mis Deportes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _colorVerdeBosque,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentSports.isEmpty)
                    Text(
                      "Sin deportes aun",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    )
                  else
                    ...() {
                      final maxCount = _activitiesBySport.values.isEmpty
                          ? 1
                          : _activitiesBySport.values.reduce(
                              (a, b) => a > b ? a : b,
                            );
                      return _currentSports.map((sport) {
                        final count = _activitiesBySport[sport] ?? 0;
                        final barValue = maxCount > 0 ? count / maxCount : 0.0;
                        return _buildSportBar(sport, barValue, count);
                      }).toList();
                    }(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _colorVerdeBosque.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // Barra de progreso de deporte con contador real de actividades
  Widget _buildSportBar(String sport, double value, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sport,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _colorVerdeBosque,
                ),
              ),
              Text(
                count > 0 ? "$count activ." : "—",
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: _colorVerdeMenta.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _colorVerdeBosque,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: GALERIA DE POSTS (MIS LOGROS)
  // Grid con los posts del usuario. Cada celda muestra la
  // imagen y un boton de eliminar en la esquina superior.
  // ----------------------------------------------------------
  Widget _buildPostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text(
            "Mis Logros",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
        ),

        const SizedBox(height: 15),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _uid)
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _colorVerdeBosque),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyPostsState();
            }

            final posts = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final postData = posts[index].data() as Map<String, dynamic>;
                  final postId = posts[index].id;
                  final String base64String = postData['imageUrl'] ?? "";

                  return GestureDetector(
                    onTap: () {
                      if (base64String.isNotEmpty) {
                        _showFullScreenImage(context, base64String);
                      }
                    },
                    onLongPress: () => _confirmDeletePost(context, postId),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _colorVerdeMenta.withOpacity(0.2),
                            image: base64String.isNotEmpty
                                ? DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(base64String),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: base64String.isEmpty
                              ? Icon(
                                  Icons.fitness_center_rounded,
                                  color: _colorVerdeBosque.withOpacity(0.3),
                                  size: 28,
                                )
                              : null,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _confirmDeletePost(context, postId),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyPostsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 50,
              color: _colorVerdeMenta,
            ),
            const SizedBox(height: 10),
            const Text(
              "Aun no has compartido ningun logro",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // DIALOGO DE CONFIRMACION DE BORRADO DE POST
  // Se activa al pulsar el boton de eliminar o al mantener
  // pulsada la celda del grid
  // ----------------------------------------------------------
  void _confirmDeletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  212,
                  210,
                  210,
                ).withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: _colorVerdeBosque,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Eliminar logro",
              style: TextStyle(
                color: _colorVerdeBosque,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Esta accion eliminara el post permanentemente.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorVerdeBosque,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<PostViewModel>().deletePost(postId);
                },
                child: const Text(
                  "Eliminar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancelar",
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
  // SEGMENTO: MENU DE CONFIGURACION
  // Igual que antes pero muestra la foto de perfil real
  // y el nombre actualizado desde el estado local
  // ----------------------------------------------------------
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 25),

              // Info del usuario con foto real
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _colorVerdeMenta,
                    backgroundImage: _currentPicB64 != null
                        ? MemoryImage(base64Decode(_currentPicB64!))
                        : null,
                    child: _currentPicB64 == null
                        ? Text(
                            _currentName.isNotEmpty
                                ? _currentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _colorVerdeBosque,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _colorVerdeBosque,
                          ),
                        ),
                        Text(
                          widget.userEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const Divider(),

              _buildMenuOption(
                icon: Icons.lock_person_outlined,
                title: "Privacidad",
                subtitle: "Perfil publico, bloqueos y visibilidad",
                onTap: () {
                  final navigator = Navigator.of(context);
                  Navigator.pop(context);
                  Future.delayed(
                    const Duration(milliseconds: 200),
                    () => navigator.push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  );
                },
              ),
              _buildMenuOption(
                icon: Icons.shield_outlined,
                title: "Seguridad de la cuenta",
                subtitle: "Cambiar contrasena y verificacion",
                onTap: () {
                  final navigator = Navigator.of(context);
                  Navigator.pop(context);
                  Future.delayed(
                    const Duration(milliseconds: 200),
                    () => navigator.push(
                      MaterialPageRoute(builder: (_) => const SecurityScreen()),
                    ),
                  );
                },
              ),
              _buildMenuOption(
                icon: Icons.settings_suggest_outlined,
                title: "Preferencias",
                subtitle: "Unidades de medida y notificaciones",
                onTap: () {
                  final navigator = Navigator.of(context);
                  Navigator.pop(context);
                  Future.delayed(
                    const Duration(milliseconds: 200),
                    () => navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const PreferencesScreen(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: _colorVerdeBosque,
                ),
                title: const Text(
                  "Cerrar Sesion",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: _colorVerdeBosque,
                ),
                title: const Text(
                  "Eliminar Cuenta",
                  style: TextStyle(
                    color: _colorVerdeBosque,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteAccount(context);
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _colorVerdeMenta.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _colorVerdeBosque, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: _colorVerdeBosque,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // ----------------------------------------------------------
  // BOTTOM SHEET: EDITAR PERFIL
  // Permite editar nombre, bio, foto (Base64) y deportes.
  // Guarda todos los cambios en Firestore y actualiza el
  // estado local sin necesidad de recargar la pantalla.
  // ----------------------------------------------------------
  void _showEditProfileSheet(BuildContext context) {
    final nameController = TextEditingController(text: _currentName);
    final bioController = TextEditingController(text: _currentBio);
    String? previewPicB64 = _currentPicB64;
    List<String> selectedSports = List.from(_currentSports);

    final allSports = FilterViewModel().sports;
    ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 5,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Titulo del modal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _colorVerdeMenta,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: _colorVerdeBosque,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Editar perfil",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _colorVerdeBosque,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar con boton para cambiar foto
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: _colorVerdeMenta,
                                  backgroundImage: previewPicB64 != null
                                      ? MemoryImage(
                                          base64Decode(previewPicB64!),
                                        )
                                      : null,
                                  child: previewPicB64 == null
                                      ? Text(
                                          nameController.text.isNotEmpty
                                              ? nameController.text[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: _colorVerdeBosque,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 30,
                                          ),
                                        )
                                      : null,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 400,
                                      imageQuality: 60,
                                    );
                                    if (picked != null) {
                                      final bytes = await File(
                                        picked.path,
                                      ).readAsBytes();
                                      setModalState(() {
                                        previewPicB64 = base64Encode(bytes);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: _colorVerdeBosque,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Campo nombre
                          _buildEditField(
                            controller: nameController,
                            label: "Nombre",
                            hint: "Tu nombre en FitCrew",
                            icon: Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 14),

                          // Campo bio con contador de caracteres
                          TextField(
                            controller: bioController,
                            maxLines: 3,
                            maxLength: 120,
                            decoration: InputDecoration(
                              labelText: "Bio",
                              hintText: "Cuentanos algo sobre ti...",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 44),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: _colorVerdeBosque,
                                  size: 20,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _colorVerdeBosque,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              counterStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Selector de deportes favoritos
                          Row(
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                color: _colorVerdeBosque,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Deportes favoritos",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _colorVerdeBosque,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "(min. 3)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Chips de deportes con icono del FilterViewModel
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allSports.map((sport) {
                              final isSelected = selectedSports.contains(sport);
                              final vm = FilterViewModel();
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedSports.remove(sport);
                                    } else {
                                      selectedSports.add(sport);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _colorVerdeBosque
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? _colorVerdeBosque
                                          : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        vm.getSportIcon(sport),
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : _colorVerdeBosque,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        sport,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Boton guardar cambios
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          if (selectedSports.length < 3) {
                            Flushbar(
                              messageText: const Text(
                                "Selecciona al menos 3 deportes",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.sports_soccer,
                                color: Colors.white,
                                size: 22,
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: _colorVerdeBosque,
                              borderRadius: BorderRadius.circular(15),
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 80,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              flushbarPosition: FlushbarPosition.BOTTOM,
                            ).show(context);

                            return;
                          }

                          try {
                            // Guardar perfil en Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .update({
                                  'name': nameController.text.trim(),
                                  'bio': bioController.text.trim(),
                                  'profilePic': previewPicB64,
                                  'favoriteSports': selectedSports,
                                });

                            if (previewPicB64 != _currentPicB64) {
                              final posts = await FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('userId', isEqualTo: _uid)
                                  .get();

                              if (posts.docs.isNotEmpty) {
                                final batch = FirebaseFirestore.instance
                                    .batch();
                                for (final doc in posts.docs) {
                                  batch.update(doc.reference, {
                                    'profilePic': previewPicB64,
                                  });
                                }
                                await batch.commit();
                              }
                            }

                            await FirebaseAuth.instance.currentUser
                                ?.updateDisplayName(nameController.text.trim());

                            if (mounted) {
                              setState(() {
                                _currentName = nameController.text.trim();
                                _currentBio = bioController.text.trim();
                                _currentPicB64 = previewPicB64;
                                _currentSports = selectedSports;
                              });
                            }

                            if (ctx.mounted) Navigator.pop(ctx);

                            Flushbar(
                              messageText: const Text(
                                "Perfil actualizado",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 22,
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: _colorVerdeBosque,
                              borderRadius: BorderRadius.circular(15),
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 100,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              flushbarPosition: FlushbarPosition.BOTTOM,
                            ).show(context);
                          } catch (e) {
                            Flushbar(
                              messageText: const Text(
                                "Error al guardar",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 22,
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: _colorVerdeBosque,
                              borderRadius: BorderRadius.circular(15),
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 100,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              flushbarPosition: FlushbarPosition.BOTTOM,
                            ).show(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorVerdeBosque,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Guardar cambios",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPER: CAMPO DE TEXTO DEL FORMULARIO DE EDICION
  // ----------------------------------------------------------
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: _colorVerdeBosque, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _colorVerdeBosque, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CERRAR SESION
  // ----------------------------------------------------------
  Future<void> _handleLogout(
    NavigatorState navigator,
    AuthViewModel authVM,
  ) async {
    try {
      await authVM.logout();
      await Future.delayed(const Duration(milliseconds: 300));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error al cerrar sesion: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final navigator = Navigator.of(context);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          "Cerrar sesion?",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Estas seguro de que quieres salir de tu cuenta de FitCrew?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancelar",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout(navigator, authVM);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorVerdeBosque,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Cerrar Sesion",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // ELIMINAR CUENTA
  // ----------------------------------------------------------
  void _handleDeleteAccount(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          scrollable: true,
          insetPadding: EdgeInsets.only(left: 24, right: 24, top: 24),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _colorVerdeBosque,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Borrar cuenta?",
                style: TextStyle(
                  color: _colorVerdeBosque,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Esta accion es irreversible. Se borraran tus posts y progreso en FitCrew.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                "Por seguridad confirma tu contrasena:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _colorVerdeBosque,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: "Tu contrasena",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _colorVerdeBosque,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () => setDialogState(
                      () => obscurePassword = !obscurePassword,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorVerdeBosque,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) return;

                Navigator.pop(ctx);

                final reauth = await authVM.reauthenticate(password);

                if (!reauth) {
                  if (context.mounted) {
                    Flushbar(
                      messageText: const Text(
                        "Contrasena incorrecta",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(15),
                      margin: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      flushbarPosition: FlushbarPosition.BOTTOM,
                    ).show(context);
                  }
                  return;
                }

                final success = await authVM.deleteAccount();

                if (success) {
                  await Future.delayed(const Duration(milliseconds: 300));
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                } else {
                  if (context.mounted) {
                    Flushbar(
                      messageText: const Text(
                        "Error al eliminar la cuenta",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(15),
                      margin: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      flushbarPosition: FlushbarPosition.BOTTOM,
                    ).show(context);
                  }
                }
              },
              child: const Text(
                "ELIMINAR TODO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // VISOR DE IMAGEN A PANTALLA COMPLETA
  // ----------------------------------------------------------
  void _showFullScreenImage(BuildContext context, String b64) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(base64Decode(b64), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
