// ============================================================
// lib/screens/search/search_users_screen.dart
// Pantalla de búsqueda de usuarios con dos pestañas:
//   - Buscar: buscador por nombre + sugerencias por deportes
//   - Solicitudes: gestión de solicitudes de seguimiento recibidas
// Incluye historial de búsquedas recientes con SQLite (sqflite)
// ============================================================

import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/core/utils/app_constants.dart';
import 'package:fitcrew/screens/profile/user_profile_screen.dart';
import 'package:fitcrew/services/follow_services.dart';
import 'package:fitcrew/services/search_history_service.dart';
import 'package:flutter/material.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen>
    with SingleTickerProviderStateMixin {
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
  final FollowService _followService = FollowService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // SQLite — historial de búsquedas recientes
  final SearchHistoryService _historyService = SearchHistoryService();
  List<SearchHistoryEntry> _searchHistory = [];

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _loadingSuggestions = false;
  String _lastQuery = '';

  final Map<String, String> _followStatusCache = {};
  final Map<String, Map<String, String>> _knownRequests = {};

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestions();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // CARGAR HISTORIAL DESDE SQLITE
  // Se llama al iniciar la pantalla y tras cada búsqueda
  // ----------------------------------------------------------
  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) setState(() => _searchHistory = history);
  }

  // ----------------------------------------------------------
  // GUARDAR BÚSQUEDA EN SQLITE Y RECARGAR HISTORIAL
  // Se llama cuando el usuario pulsa una tarjeta de resultado
  // ----------------------------------------------------------
  Future<void> _onUserTapped(
    String uid,
    String name, {
    String? profilePic,
  }) async {
    await _historyService.saveSearch(uid, name, profilePic: profilePic);
    await _loadHistory();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(uid: uid, name: name),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // CARGAR SUGERENCIAS DESDE FIRESTORE
  // ----------------------------------------------------------
  Future<void> _loadSuggestions() async {
    if (_loadingSuggestions) return;
    setState(() => _loadingSuggestions = true);

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();

      final mySports = List<String>.from(
        userDoc.data()?['favoriteSports'] ?? [],
      );

      if (mySports.isEmpty) return;

      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .limit(50)
          .get();

      final suggestions = <Map<String, dynamic>>[];

      for (final doc in allUsers.docs) {
        if (doc.id == currentUid) continue;

        final data = doc.data();
        final theirSports = List<String>.from(data['favoriteSports'] ?? []);
        final commonSports = mySports
            .where((s) => theirSports.contains(s))
            .toList();

        if (commonSports.isNotEmpty) {
          if (!_followStatusCache.containsKey(doc.id)) {
            _followStatusCache[doc.id] = await _followService.getFollowStatus(
              doc.id,
            );
          }
          suggestions.add({
            'uid': doc.id,
            'name': data['name'] ?? 'Usuario',
            'favoriteSports': theirSports,
            'commonSports': commonSports,
            'profilePic': data['profilePic'],
          });
        }
      }

      if (mounted) setState(() => _suggestions = suggestions);
    } catch (e) {
      debugPrint("Error cargando sugerencias: $e");
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  // ----------------------------------------------------------
  // BÚSQUEDA DE USUARIOS POR NOMBRE
  // ----------------------------------------------------------
  Future<void> _search(String query) async {
    if (query.trim() == _lastQuery) return;
    _lastQuery = query.trim();

    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _followService.searchUsers(query.trim());

      for (final user in results) {
        final uid = user['uid'] as String;
        if (!_followStatusCache.containsKey(uid)) {
          _followStatusCache[uid] = await _followService.getFollowStatus(uid);
        }
      }

      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ----------------------------------------------------------
  // ACCIÓN DE SEGUIMIENTO
  // ----------------------------------------------------------
  Future<void> _handleFollowAction(String uid, String name) async {
    final status = _followStatusCache[uid] ?? 'none';

    if (status == 'none') {
      final ok = await _followService.sendFollowRequest(uid, name);
      if (ok && mounted) {
        setState(() => _followStatusCache[uid] = 'pending');
        _showSnackBar("Solicitud enviada a $name");
      }
    } else if (status == 'pending') {
      final ok = await _followService.cancelFollowRequest(uid);
      if (ok && mounted) {
        setState(() => _followStatusCache[uid] = 'none');
        _showSnackBar("Solicitud cancelada");
      }
    } else if (status == 'following') {
      final ok = await _followService.unfollow(uid);
      if (ok && mounted) {
        setState(() => _followStatusCache[uid] = 'none');
        _showSnackBar("Has dejado de seguir a $name");
      }
    }
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  // FLUSHBAR
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
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
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        backgroundColor: _colorFondoFrio,
        surfaceTintColor: _colorFondoFrio,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _colorVerdeBosque,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personas",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<QuerySnapshot>(
            stream: _followService.getPendingRequestsStream(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;

              return TabBar(
                controller: _tabController,
                indicatorColor: _colorVerdeBosque,
                indicatorWeight: 3,
                labelColor: _colorVerdeBosque,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  const Tab(text: "Buscar"),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Solicitudes"),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "$pendingCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [_buildSearchTab(), _buildRequestsTab()],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PESTAÑA 1: BUSCAR
  // ----------------------------------------------------------
  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: _colorVerdeBosque),
                )
              : _lastQuery.isNotEmpty
              ? _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList()
              : _buildInitialState(),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // PESTAÑA 2: SOLICITUDES RECIBIDAS
  // ----------------------------------------------------------
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _followService.getPendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _knownRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _colorVerdeBosque),
          );
        }

        final pendingDocs = snapshot.data?.docs ?? [];
        for (final doc in pendingDocs) {
          if (!_knownRequests.containsKey(doc.id)) {
            final data = doc.data() as Map<String, dynamic>;
            _knownRequests[doc.id] = {
              'fromUid': data['fromUid'] as String,
              'fromName': data['fromName'] as String? ?? 'Usuario',
            };
          }
        }

        if (_knownRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: _colorVerdeMenta,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sin solicitudes pendientes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorVerdeBosque,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cuando alguien quiera seguirte\naparecerá aquí",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: _knownRequests.length,
          itemBuilder: (context, index) {
            final requestId = _knownRequests.keys.elementAt(index);
            final data = _knownRequests[requestId]!;
            final fromUid = data['fromUid'] as String;
            final fromName = data['fromName'] as String;

            // Carga la foto del solicitante
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUid)
                  .get(),
              builder: (context, userSnap) {
                String? profilePic;
                if (userSnap.hasData && userSnap.data!.exists) {
                  profilePic =
                      (userSnap.data!.data()
                              as Map<String, dynamic>)['profilePic']
                          as String?;
                }

                return _RequestCard(
                  key: ValueKey(requestId),
                  requestId: requestId,
                  fromUid: fromUid,
                  fromName: fromName,
                  profilePic: profilePic,
                  followService: _followService,
                  onSnackBar: _showSnackBar,
                  followStatusCache: _followStatusCache,
                  onDismiss: () =>
                      setState(() => _knownRequests.remove(requestId)),
                );
              },
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BARRA DE BÚSQUEDA
  // ----------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Icons.search_rounded,
              color: _colorVerdeBosque,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Buscar por nombre...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _results = [];
                    _lastQuery = '';
                  });
                },
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
    );
  }

  // ----------------------------------------------------------
  // ESTADO INICIAL
  // Muestra historial de búsquedas recientes (SQLite)
  // y sugerencias por deportes en común (Firestore)
  // ----------------------------------------------------------
  Widget _buildInitialState() {
    if (_loadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(color: _colorVerdeBosque),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // HISTORIAL DE BUSQUEDAS RECIENTES (SQLite)
        if (_searchHistory.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: _colorVerdeBosque,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Busquedas recientes",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _colorVerdeBosque,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await _historyService.clearHistory();
                  _loadHistory();
                },
                child: Text(
                  "Borrar todo",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._searchHistory.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _colorVerdeBosque.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: _colorVerdeMenta,
                  backgroundImage:
                      entry.profilePic != null && entry.profilePic!.isNotEmpty
                      ? MemoryImage(base64Decode(entry.profilePic!))
                      : null,
                  child: entry.profilePic == null || entry.profilePic!.isEmpty
                      ? Text(
                          entry.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: _colorVerdeBosque,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _colorTextoTitulo,
                  ),
                ),
                subtitle: Text(
                  "Busqueda reciente",
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                //Boton eliminar entrada individual del historial
                trailing: GestureDetector(
                  onTap: () async {
                    await _historyService.deleteEntry(entry.uid);
                    _loadHistory();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
                // Al pulsar rellena el buscador y lanza la búsqueda
                onTap: () {
                  _searchController.text = entry.name;
                  _search(entry.name);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
        ],

        // SUGERENCIAS POR DEPORTES EN COMUN (Firestore)
        if (_suggestions.isEmpty && _searchHistory.isEmpty) ...[
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: _colorVerdeMenta,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Busca companeros de entrenamiento",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorVerdeBosque,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Escribe un nombre para encontrar\na otros usuarios de FitCrew",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],

        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.recommend_rounded, color: _colorVerdeBosque, size: 18),
              SizedBox(width: 8),
              Text(
                "Sugerencias segun tus gustos",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _colorVerdeBosque,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._suggestions.map((user) {
            final uid = user['uid'] as String;
            final name = user['name'] as String;
            final sports = List<String>.from(user['favoriteSports'] ?? []);
            final commonSports = List<String>.from(user['commonSports'] ?? []);
            final status = _followStatusCache[uid] ?? 'none';
            final profilePic = user['profilePic'] as String?;

            return _buildSuggestionCard(
              uid,
              name,
              sports,
              commonSports,
              status,
              profilePic,
            );
          }),
        ],
      ],
    );
  }

  // ----------------------------------------------------------
  // LISTA DE RESULTADOS DE BÚSQUEDA
  // Cada tarjeta guarda la búsqueda en SQLite al pulsarla
  // ----------------------------------------------------------
  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        final uid = user['uid'] as String;
        final name = user['name'] as String? ?? 'Usuario';
        final sports = List<String>.from(user['favoriteSports'] ?? []);
        final status = _followStatusCache[uid] ?? 'none';
        final profilePic = user['profilePic'] as String?;

        return _buildUserCard(uid, name, sports, status, profilePic);
      },
    );
  }

  // ----------------------------------------------------------
  // TARJETA DE USUARIO — resultados de búsqueda
  // Al pulsar guarda en SQLite via _onUserTapped
  // ----------------------------------------------------------
  Widget _buildUserCard(
    String uid,
    String name,
    List<String> sports,
    String status,
    String? profilePic,
  ) {
    final config = _buttonConfig(status);

    return GestureDetector(
      onTap: () => _onUserTapped(uid, name, profilePic: profilePic),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _colorVerdeMenta,
              backgroundImage: profilePic != null && profilePic.isNotEmpty
                  ? MemoryImage(base64Decode(profilePic))
                  : null,
              child: profilePic == null || profilePic.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: _colorVerdeBosque,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _colorTextoTitulo,
                    ),
                  ),
                  if (sports.isNotEmpty)
                    Text(
                      sports.take(3).join(" · "),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _buildFollowButton(uid, name, config),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TARJETA DE SUGERENCIA — con chips de deportes en común
  // Al pulsar guarda en SQLite via _onUserTapped
  // ----------------------------------------------------------
  Widget _buildSuggestionCard(
    String uid,
    String name,
    List<String> sports,
    List<String> commonSports,
    String status,
    String? profilePic,
  ) {
    final config = _buttonConfig(status);

    return GestureDetector(
      onTap: () => _onUserTapped(uid, name, profilePic: profilePic),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _colorVerdeMenta,
                  backgroundImage: profilePic != null && profilePic.isNotEmpty
                      ? MemoryImage(base64Decode(profilePic))
                      : null,
                  child: profilePic == null || profilePic.isEmpty
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: _colorVerdeBosque,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _colorTextoTitulo,
                        ),
                      ),
                      if (sports.isNotEmpty)
                        Text(
                          sports.take(3).join(" · "),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _buildFollowButton(uid, name, config),
              ],
            ),
            if (commonSports.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: commonSports.map((sport) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _colorVerdeMenta.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppConstants.getSportIcon(sport),
                          size: 11,
                          color: _colorVerdeBosque,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sport,
                          style: const TextStyle(
                            fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPER: Botón de seguimiento animado
  // ----------------------------------------------------------
  Widget _buildFollowButton(
    String uid,
    String name,
    Map<String, dynamic> config,
  ) {
    return GestureDetector(
      onTap: () async {
        await _handleFollowAction(uid, name);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: config['color'] as Color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config['icon'] as IconData,
              size: 14,
              color: config['textColor'] as Color,
            ),
            const SizedBox(width: 6),
            Text(
              config['label'] as String,
              style: TextStyle(
                color: config['textColor'] as Color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HELPER: Configuración del botón según estado
  // ----------------------------------------------------------
  Map<String, dynamic> _buttonConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'label': 'Pendiente',
          'color': Colors.grey[200],
          'textColor': Colors.grey[700],
          'icon': Icons.hourglass_empty_rounded,
        };
      case 'following':
        return {
          'label': 'Siguiendo',
          'color': _colorVerdeMenta,
          'textColor': _colorVerdeBosque,
          'icon': Icons.check_rounded,
        };
      default:
        return {
          'label': 'Seguir',
          'color': _colorVerdeBosque,
          'textColor': Colors.white,
          'icon': Icons.person_add_outlined,
        };
    }
  }

  // ----------------------------------------------------------
  // ESTADO VACÍO — sin resultados de búsqueda
  // ----------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: _colorVerdeMenta),
          const SizedBox(height: 16),
          Text(
            "No se encontro \"$_lastQuery\"",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Prueba con otro nombre",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET: _RequestCard
// ============================================================
class _RequestCard extends StatefulWidget {
  final String requestId;
  final String fromUid;
  final String fromName;
  final String? profilePic;
  final FollowService followService;
  final void Function(String) onSnackBar;
  final Map<String, String> followStatusCache;
  final VoidCallback onDismiss;

  const _RequestCard({
    super.key,
    required this.requestId,
    required this.fromUid,
    required this.fromName,
    this.profilePic,
    required this.followService,
    required this.onSnackBar,
    required this.followStatusCache,
    required this.onDismiss,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  bool _accepted = false;
  bool _loadingAccept = false;
  bool _loadingFollow = false;
  bool _alreadyFollowing = false;

  Future<void> _accept() async {
    setState(() => _loadingAccept = true);
    try {
      final ok = await widget.followService.acceptFollowRequest(
        widget.requestId,
        widget.fromUid,
      );
      if (ok && mounted) {
        final status =
            widget.followStatusCache[widget.fromUid] ??
            await widget.followService.getFollowStatus(widget.fromUid);
        setState(() {
          _accepted = true;
          _alreadyFollowing = status == 'following';
        });
        widget.onSnackBar("Has aceptado a ${widget.fromName}");
      }
    } finally {
      if (mounted) setState(() => _loadingAccept = false);
    }
  }

  Future<void> _followBack() async {
    setState(() => _loadingFollow = true);
    try {
      final sent = await widget.followService.sendFollowRequest(
        widget.fromUid,
        widget.fromName,
      );
      if (sent && mounted) {
        widget.followStatusCache[widget.fromUid] = 'pending';
        widget.onSnackBar("Solicitud enviada a ${widget.fromName}");
        setState(() => _alreadyFollowing = true);
      }
    } finally {
      if (mounted) setState(() => _loadingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _colorVerdeMenta,
                backgroundImage:
                    widget.profilePic != null && widget.profilePic!.isNotEmpty
                    ? MemoryImage(base64Decode(widget.profilePic!))
                    : null,
                child: widget.profilePic == null || widget.profilePic!.isEmpty
                    ? Text(
                        widget.fromName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _colorVerdeBosque,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fromName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _colorTextoTitulo,
                      ),
                    ),
                    Text(
                      _accepted ? "Solicitud aceptada" : "Quiere seguirte",
                      style: TextStyle(
                        fontSize: 12,
                        color: _accepted ? _colorVerdeBosque : Colors.grey[500],
                        fontWeight: _accepted
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_accepted) ...[
                GestureDetector(
                  onTap: _loadingAccept ? null : _accept,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _colorVerdeBosque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _loadingAccept
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Aceptar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final ok = await widget.followService.rejectFollowRequest(
                      widget.requestId,
                    );
                    if (ok && mounted) {
                      widget.onSnackBar("Solicitud rechazada");
                      widget.onDismiss();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Rechazar",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _colorVerdeMenta,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _colorVerdeBosque,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),

          if (_accepted && !_alreadyFollowing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _loadingFollow ? null : _followBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _colorVerdeMenta.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _colorVerdeBosque.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loadingFollow)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: _colorVerdeBosque,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        const Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: _colorVerdeBosque,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Seguir también",
                          style: TextStyle(
                            color: _colorVerdeBosque,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (_accepted && _alreadyFollowing) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  "Ya os seguis mutuamente",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
