import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/screens/welcome/welcome_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // --- NUEVA PALETA DE COLORES ---
  final Color colorVerdeBosque = const Color(0xFF234D41);
  final Color colorVerdeMenta = const Color(0xFFD3E6DB);
  final Color colorFondoFrio = const Color(0xFFFBFDFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondoFrio,
      appBar: AppBar(
        backgroundColor: colorFondoFrio,
        surfaceTintColor: colorFondoFrio,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Mi Perfil",
          style: TextStyle(
            color: colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: colorVerdeBosque, size: 28),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(colorVerdeBosque),
            const SizedBox(height: 30),
            _buildStatsGrid(),
            const SizedBox(height: 25),
            _buildPerformanceDashboard(colorVerdeBosque),
            const SizedBox(height: 35),
            _buildPostSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- MENÚ DE GESTIÓN (BOTTOM SHEET) ---
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage("https://picsum.photos/seed/profile/300"),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorVerdeBosque),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Color(0xFF234D41)),
                title: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context); // Cierra el BottomSheet
                  _showLogoutDialog(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFF234D41)),
                title: const Text("Eliminar Cuenta", style: TextStyle(color: Color(0xFF234D41), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context); // Cierra el BottomSheet
                  _handleDeleteAccount(context);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
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
          color: colorVerdeMenta.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorVerdeBosque, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorVerdeBosque)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // --- WIDGETS DE INTERFAZ ---

  Widget _buildHeader(Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorVerdeMenta, width: 2),
              ),
              child: const CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFF1F3F5),
                  backgroundImage: NetworkImage("https://picsum.photos/seed/profile/300"),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colorVerdeBosque, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            )
          ],
        ),
        const SizedBox(height: 20),
        Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: colorVerdeBosque)),
        const Text("Miembro Elite de FitCrew", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statItem("12", "Posts"),
          const SizedBox(width: 12),
          _statItem("248", "Seguidores"),
          const SizedBox(width: 12),
          _statItem("156", "Seguidos"),
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
          boxShadow: [BoxShadow(color: colorVerdeBosque.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorVerdeBosque)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDashboard(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _cardWrapper(
              child: Column(
                children: [
                  Text("Entrenos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorVerdeBosque)),
                  const SizedBox(height: 15),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 65, width: 65,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 7,
                          backgroundColor: colorVerdeMenta.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text("24", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorVerdeBosque)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Este mes", style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final List<dynamic> sportsData = data?['favoriteSports'] ?? [];
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mis Deportes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorVerdeBosque)),
                      const SizedBox(height: 12),
                      if (sportsData.isEmpty)
                        const Text("Sin deportes aún", style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        ...sportsData.take(3).map((sport) => _buildSportLevelBar(sport.toString(), color)),
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
        boxShadow: [BoxShadow(color: colorVerdeBosque.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildSportLevelBar(String sport, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sport, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorVerdeBosque)),
              const Text("Nvl. 4", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 5,
              backgroundColor: colorVerdeMenta.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSection() {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text("Mis Logros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorVerdeBosque)),
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
                      color: colorVerdeMenta.withOpacity(0.2),
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
            Icon(Icons.camera_alt_outlined, size: 50, color: colorVerdeMenta),
            const SizedBox(height: 10),
            const Text("Aún no has compartido ningún logro", 
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE AUTENTICACIÓN ---

  Future<void> _handleLogout(NavigatorState navigator, AuthViewModel authVM) async {
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
    // Obtenemos las referencias antes del showDialog
    final navigator = Navigator.of(context);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            "¿Cerrar sesión?",
            style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "¿Estás seguro de que quieres salir de tu cuenta de FitCrew?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Cierra el diálogo
                _handleLogout(navigator, authVM);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorVerdeBosque,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "Cerrar Sesión",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFF234D41), size: 28),
            const SizedBox(width: 10),
            Text(
              "¿Borrar cuenta?", 
              style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: const Text(
          "Esta acción es irreversible. Se borrarán tus posts y progreso en FitCrew. ¿Estás seguro?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorVerdeBosque,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await authVM.deleteAccount();

              if (success) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()), 
                  (route) => false
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(authVM.errorMessage ?? "Error al eliminar la cuenta"),
                    backgroundColor: colorVerdeBosque,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text(
              "ELIMINAR TODO", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}