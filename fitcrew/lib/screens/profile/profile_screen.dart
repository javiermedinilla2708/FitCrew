import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/screens/welcome/welcome_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// ProfileScreen
// Pantalla de perfil con estadísticas, deportes favoritos
// y galería de logros del usuario
// ============================================================

class ProfileScreen extends StatelessWidget {
  final List<String> userSports;
  final String userEmail;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userSports,
    required this.userEmail,
    required this.userName,
  });

  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- Avatar y nombre ---
            _buildHeader(),

            const SizedBox(height: 30),

            // --- Estadísticas (posts reales de Firestore) ---
            _buildStatsGrid(),

            const SizedBox(height: 25),

            // --- Dashboard de rendimiento ---
            _buildPerformanceDashboard(),

            const SizedBox(height: 35),

            // --- Galería de posts ---
            _buildPostSection(),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: MENÚ DE CONFIGURACIÓN
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 25),

            // --- Info del usuario ---
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _colorVerdeMenta,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _colorVerdeBosque,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colorVerdeBosque,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            const Divider(),

            // --- Opciones de menú ---
            _buildMenuOption(
              icon: Icons.lock_person_outlined,
              title: "Privacidad",
              subtitle: "Perfil público, bloqueos y visibilidad",
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuOption(
              icon: Icons.shield_outlined,
              title: "Seguridad de la cuenta",
              subtitle: "Cambiar contraseña y verificación",
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuOption(
              icon: Icons.settings_suggest_outlined,
              title: "Preferencias",
              subtitle: "Unidades de medida y notificaciones",
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 10),
            const Divider(),

            // --- Cerrar sesión ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.logout_rounded,
                color: _colorVerdeBosque,
              ),
              title: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),

            // --- Eliminar cuenta ---
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
  // SEGMENTO: CABECERA DE PERFIL
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
              child: CircleAvatar(
                radius: 55,
                backgroundColor: _colorVerdeMenta,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _colorVerdeBosque,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
              ),
            ),

            // Botón editar foto
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _colorVerdeBosque,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: _colorVerdeBosque,
          ),
        ),
        const Text(
          "Miembro Elite de FitCrew",
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: ESTADÍSTICAS
  // ----------------------------------------------------------
  Widget _buildStatsGrid() {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _statItem(count.toString(), "Posts");
              },
            ),
          ),
          const SizedBox(width: 12),

          _statItem("—", "Seguidores"),
          const SizedBox(width: 12),
          _statItem("—", "Seguidos"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Container(
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
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: DASHBOARD DE RENDIMIENTO
  // ----------------------------------------------------------
  Widget _buildPerformanceDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Card de entrenos (datos pendientes de implementar) ---
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
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 7,
                          backgroundColor: _colorVerdeMenta.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _colorVerdeBosque,
                          ),
                        ),
                      ),
                      // ⚠️ Pendiente de conectar con datos reales
                      const Text(
                        "—",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colorVerdeBosque,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Este mes",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 6,
            child: _cardWrapper(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final List<dynamic> sportsData =
                      data?['favoriteSports'] ?? [];

                  return Column(
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
                      if (sportsData.isEmpty)
                        const Text(
                          "Sin deportes aún",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      else
                        ...sportsData
                            .take(3)
                            .map((sport) => _buildSportBar(sport.toString())),
                    ],
                  );
                },
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

  Widget _buildSportBar(String sport) {
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
              const Text(
                "—",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6,
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
  // SEGMENTO: GALERÍA DE POSTS
  // ----------------------------------------------------------
  Widget _buildPostSection() {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

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
              .where('userId', isEqualTo: uid)
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                  final String base64String = postData['imageUrl'] ?? "";

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _colorVerdeMenta.withOpacity(0.2),
                      image: base64String.isNotEmpty
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(base64String)),
                              fit: BoxFit.cover,
                            )
                          : null,
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
              "Aún no has compartido ningún logro",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: LÓGICA DE AUTENTICACIÓN
  // ----------------------------------------------------------
  Future<void> _handleLogout(
    NavigatorState navigator,
    AuthViewModel authVM,
  ) async {
    try {
      await authVM.logout();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
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
          "¿Cerrar sesión?",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "¿Estás seguro de que quieres salir de tu cuenta de FitCrew?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          // --- Cancelar ---
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

          // --- Confirmar logout ---
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
              "Cerrar Sesión",
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

  void _handleDeleteAccount(BuildContext context) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _colorVerdeBosque,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              "¿Borrar cuenta?",
              style: TextStyle(
                color: _colorVerdeBosque,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Esta acción es irreversible. Se borrarán tus posts y progreso en FitCrew. ¿Estás seguro?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          // --- Cancelar ---
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey[600])),
          ),

          // --- Confirmar borrado ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorVerdeBosque,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await authVM.deleteAccount();

              if (success) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      authVM.errorMessage ?? "Error al eliminar la cuenta",
                    ),
                    backgroundColor: _colorVerdeBosque,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
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
    );
  }
}
