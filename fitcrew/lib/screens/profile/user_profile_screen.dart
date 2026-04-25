// ============================================================
// lib/screens/profile/user_profile_screen.dart
// Pantalla de perfil ajeno. Si el perfil es privado y el
// usuario no sigue al dueño, solo muestra estadísticas básicas.
// Si el perfil es público o ya le sigue, muestra todo.
// ============================================================

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/follow_services.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;
  final String name;

  const UserProfileScreen({super.key, required this.uid, required this.name});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  final FollowService _followService = FollowService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Datos del perfil ajeno
  String _name = '';
  String _bio = '';
  String? _picB64;
  List<String> _sports = [];
  bool _isPrivate = false;
  bool _loading = true;

  // Estado de seguimiento
  String _followStatus = 'none'; // none, pending, following

  // Estadísticas básicas (siempre visibles)
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ----------------------------------------------------------
  // CARGAR PERFIL COMPLETO
  // ----------------------------------------------------------
  Future<void> _loadProfile() async {
    try {
      // Datos del usuario
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;

      // Stats básicas — siempre visibles
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.uid)
          .get();

      final followersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('followers')
          .get();

      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('following')
          .get();

      // Estado de seguimiento actual
      final status = await _followService.getFollowStatus(widget.uid);

      if (mounted) {
        setState(() {
          _name = data['name'] ?? widget.name;
          _bio = data['bio'] ?? '';
          _picB64 = data['profilePic'];
          _sports = List<String>.from(data['favoriteSports'] ?? []);
          _isPrivate = data['isPrivate'] ?? false;
          _postsCount = postsSnap.docs.length;
          _followersCount = followersSnap.docs.length;
          _followingCount = followingSnap.docs.length;
          _followStatus = status;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando perfil ajeno: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------------------------------------------------
  // ACCION DE SEGUIMIENTO
  // ----------------------------------------------------------
  Future<void> _handleFollowAction() async {
    if (_followStatus == 'none') {
      final ok = await _followService.sendFollowRequest(widget.uid, _name);
      if (ok && mounted) {
        setState(() => _followStatus = 'pending');
        _showSnackBar("Solicitud enviada a $_name");
      }
    } else if (_followStatus == 'pending') {
      final ok = await _followService.cancelFollowRequest(widget.uid);
      if (ok && mounted) {
        setState(() => _followStatus = 'none');
        _showSnackBar("Solicitud cancelada");
      }
    } else if (_followStatus == 'following') {
      final ok = await _followService.unfollow(widget.uid);
      if (ok && mounted) {
        setState(() {
          _followStatus = 'none';
          _followersCount = (_followersCount - 1).clamp(0, 9999);
        });
        _showSnackBar("Has dejado de seguir a $_name");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _colorVerdeBosque,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ----------------------------------------------------------
  // El usuario puede ver el contenido completo si:
  // - El perfil es público
  // - O ya le sigue
  // ----------------------------------------------------------
  bool get _canSeeFullProfile => !_isPrivate || _followStatus == 'following';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        backgroundColor: _colorFondoFrio,
        surfaceTintColor: _colorFondoFrio,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _colorVerdeBosque,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _name.isNotEmpty ? _name : widget.name,
          style: const TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _colorVerdeBosque),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // CABECERA — siempre visible
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // STATS — siempre visibles
                  _buildStatsRow(),

                  const SizedBox(height: 24),

                  // CONTENIDO — solo si puede ver el perfil completo
                  if (_canSeeFullProfile) ...[
                    _buildSportsSection(),
                    const SizedBox(height: 24),
                    _buildPostsGrid(),
                  ] else ...[
                    _buildPrivateProfilePlaceholder(),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------------
  // CABECERA — avatar, nombre, bio y boton de seguir
  // ----------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _colorVerdeMenta, width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: _colorVerdeMenta,
              backgroundImage: _picB64 != null
                  ? MemoryImage(base64Decode(_picB64!))
                  : null,
              child: _picB64 == null
                  ? Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: _colorVerdeBosque,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Nombre
          Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: _colorVerdeBosque,
            ),
          ),

          // Bio si existe y puede verla
          if (_bio.isNotEmpty && _canSeeFullProfile) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Icono privado si aplica
          if (_isPrivate && !_canSeeFullProfile) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  "Perfil privado",
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Boton de seguimiento
          if (widget.uid != _currentUid) _buildFollowButton(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BOTON DE SEGUIMIENTO
  // ----------------------------------------------------------
  Widget _buildFollowButton() {
    String label;
    Color bgColor;
    Color textColor;

    switch (_followStatus) {
      case 'following':
        label = "Siguiendo";
        bgColor = _colorVerdeMenta;
        textColor = _colorVerdeBosque;
        break;
      case 'pending':
        label = "Solicitud enviada";
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
      default:
        label = "Seguir";
        bgColor = _colorVerdeBosque;
        textColor = Colors.white;
    }

    return GestureDetector(
      onTap: _handleFollowAction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // FILA DE ESTADÍSTICAS — siempre visible
  // ----------------------------------------------------------
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _statItem(_postsCount.toString(), "Posts")),
          const SizedBox(width: 12),
          Expanded(child: _statItem(_followersCount.toString(), "Seguidores")),
          const SizedBox(width: 12),
          Expanded(child: _statItem(_followingCount.toString(), "Seguidos")),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
  // DEPORTES FAVORITOS — solo si puede ver el perfil completo
  // ----------------------------------------------------------
  Widget _buildSportsSection() {
    if (_sports.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Deportes favoritos",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sports.map((sport) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _colorVerdeMenta.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_rounded,
                      size: 14,
                      color: _colorVerdeBosque,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _colorVerdeBosque,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // GRID DE POSTS — solo si puede ver el perfil completo
  // ----------------------------------------------------------
  Widget _buildPostsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Logros",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: widget.uid)
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _colorVerdeBosque),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    "Aun no hay logros publicados",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ),
              );
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
                  final data = posts[index].data() as Map<String, dynamic>;
                  final String b64 = data['imageUrl'] ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _colorVerdeMenta.withOpacity(0.2),
                      image: b64.isNotEmpty
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(b64)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: b64.isEmpty
                        ? Icon(
                            Icons.fitness_center_rounded,
                            color: _colorVerdeBosque.withOpacity(0.3),
                            size: 28,
                          )
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // PLACEHOLDER PERFIL PRIVADO
  // Se muestra cuando el perfil es privado y no le sigue
  // ----------------------------------------------------------
  Widget _buildPrivateProfilePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _colorVerdeMenta.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: _colorVerdeBosque,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Este perfil es privado",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Sigue a ${widget.name} para ver sus publicaciones, deportes favoritos y logros.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          if (_followStatus == 'pending') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Solicitud pendiente de aceptacion",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
