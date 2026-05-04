// ============================================================
// lib/screens/profile/followers_screen.dart
// Pantalla que muestra seguidores o seguidos de un usuario.
// Permite buscar por nombre y seguir/dejar de seguir.
// ============================================================

import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/profile/user_profile_screen.dart';
import 'package:fitcrew/services/follow_services.dart';
import 'package:flutter/material.dart';

enum FollowersScreenMode { followers, following }

class FollowersScreen extends StatefulWidget {
  final String uid;
  final String userName;
  final FollowersScreenMode mode;

  const FollowersScreen({
    super.key,
    required this.uid,
    required this.userName,
    required this.mode,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final FollowService _followService = FollowService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, String> _followStatuses = {};
  bool _loading = true;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // CARGAR USUARIOS DESDE FIRESTORE
  // ----------------------------------------------------------
  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final collection = widget.mode == FollowersScreenMode.followers
          ? 'followers'
          : 'following';

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection(collection)
          .get();

      final List<Map<String, dynamic>> users = [];
      final Map<String, String> statuses = {};

      for (final doc in snap.docs) {
        final uid = doc.id;

        // Cargar datos del usuario desde la coleccion users
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (!userDoc.exists) continue;

        final data = userDoc.data()!;
        users.add({
          'uid': uid,
          'name': data['name'] ?? '',
          'profilePic': data['profilePic'],
          'favoriteSports': data['favoriteSports'] ?? [],
        });

        // Estado de seguimiento del usuario actual
        if (uid != _currentUid) {
          final status = await _followService.getFollowStatus(uid);
          statuses[uid] = status;
        }
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filtered = users;
          _followStatuses = statuses;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando usuarios: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------------------------------------------------
  // FILTRAR POR BUSQUEDA
  // ----------------------------------------------------------
  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _allUsers
          : _allUsers.where((u) {
              final name = (u['name'] as String).toLowerCase();
              return name.contains(query);
            }).toList();
    });
  }

  // ----------------------------------------------------------
  // ACCION DE SEGUIMIENTO
  // ----------------------------------------------------------
  Future<void> _handleFollowAction(String uid, String name) async {
    final currentStatus = _followStatuses[uid] ?? 'none';

    if (currentStatus == 'none') {
      final ok = await _followService.sendFollowRequest(uid, name);
      if (ok && mounted) {
        setState(() => _followStatuses[uid] = 'pending');
        _showFlushbar("Solicitud enviada a $name");
      }
    } else if (currentStatus == 'pending') {
      final ok = await _followService.cancelFollowRequest(uid);
      if (ok && mounted) {
        setState(() => _followStatuses[uid] = 'none');
        _showFlushbar("Solicitud cancelada");
      }
    } else if (currentStatus == 'following') {
      final ok = await _followService.unfollow(uid);
      if (ok && mounted) {
        setState(() => _followStatuses[uid] = 'none');
        _showFlushbar("Has dejado de seguir a $name");
      }
    }
  }

  // ----------------------------------------------------------
  // FLUSHBAR
  // ----------------------------------------------------------
  void _showFlushbar(String message) {
    Flushbar(
      messageText: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: _colorVerdeBosque,
      borderRadius: BorderRadius.circular(15),
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      flushbarPosition: FlushbarPosition.BOTTOM,
    ).show(context);
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final title = widget.mode == FollowersScreenMode.followers
        ? "Seguidores"
        : "Seguidos";

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
          title,
          style: const TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _colorVerdeBosque.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    color: _colorVerdeBosque,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Buscar por nombre...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Lista
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _colorVerdeBosque),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.mode == FollowersScreenMode.followers
                              ? Icons.people_outline_rounded
                              : Icons.person_search_rounded,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? "No se encontraron resultados"
                              : widget.mode == FollowersScreenMode.followers
                              ? "Aun no tienes seguidores"
                              : "Aun no sigues a nadie",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final user = _filtered[index];
                      final uid = user['uid'] as String;
                      final name = user['name'] as String;
                      final profilePic = user['profilePic'] as String?;
                      final isMe = uid == _currentUid;
                      final status = _followStatuses[uid] ?? 'none';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(uid: uid, name: name),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: _colorVerdeBosque.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _colorVerdeMenta,
                                backgroundImage:
                                    profilePic != null && profilePic.isNotEmpty
                                    ? MemoryImage(base64Decode(profilePic))
                                    : null,
                                child: profilePic == null || profilePic.isEmpty
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: _colorVerdeBosque,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 14),

                              // Nombre
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F1D19),
                                  ),
                                ),
                              ),

                              // Boton seguir/siguiendo/pendiente
                              // Solo si no soy yo mismo
                              if (!isMe)
                                GestureDetector(
                                  onTap: () => _handleFollowAction(uid, name),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == 'following'
                                          ? _colorVerdeMenta
                                          : status == 'pending'
                                          ? Colors.grey[200]
                                          : _colorVerdeBosque,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status == 'following'
                                          ? "Siguiendo"
                                          : status == 'pending'
                                          ? "Pendiente"
                                          : "Seguir",
                                      style: TextStyle(
                                        color: status == 'following'
                                            ? _colorVerdeBosque
                                            : status == 'pending'
                                            ? Colors.grey[700]
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
