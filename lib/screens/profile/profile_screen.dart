import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    const Color fitCrewGreen = Color(0xFF24FF8F);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Mi Perfil",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -1,
          ),
        ),
        actions: [
          // Botón de 3 puntos que activa el menú superpuesto
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.black, size: 28),
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(fitCrewGreen),
            const SizedBox(height: 30),
            _buildStatsGrid(),
            const SizedBox(height: 25),
            _buildPerformanceDashboard(fitCrewGreen),
            const SizedBox(height: 35),
            _buildPostSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- NUEVO: MENÚ DE GESTIÓN (BOTTOM SHEET) ---
  // Este menú se superpone a todo, incluyendo el BottomNav
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Permite ver el redondeo del contenedor
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
              // Indicador de arrastre
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              
              // SECCIÓN 1: DATOS DEL USUARIO
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

              // SECCIÓN 2: GESTIÓN Y PRIVACIDAD
              _buildMenuOption(
                icon: Icons.lock_person_outlined,
                title: "Privacidad",
                subtitle: "Perfil público, bloqueos y visibilidad",
                onTap: () {
                  // Lógica para gestionar privacidad
                  Navigator.pop(context);
                },
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
              
              // SECCIÓN 3: ACCIONES CRÍTICAS
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                title: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _handleLogout(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text("Eliminar Cuenta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () => _handleDeleteAccount(context),
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
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // --- MÉTODOS DE LA INTERFAZ ORIGINAL ---

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Colors.blueAccent],
                ),
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
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            )
          ],
        ),
        const SizedBox(height: 20),
        Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  const Text("Entrenos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 15),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 65, width: 65,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 7,
                          backgroundColor: color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const Text("24", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mis Deportes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (userSports.isEmpty)
                    const Text("Sin deportes aún", style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...userSports.take(3).map((sport) => _buildSportLevelBar(sport, color)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
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
              Text(sport, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const Text("Nvl. 4", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text("Publicaciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage("https://picsum.photos/seed/${index + 10}/200"),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- LÓGICA DE FIREBASE ---

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Borrar cuenta?"),
        content: const Text("Perderás todo tu progreso. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              String? uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                await FirebaseAuth.instance.currentUser!.delete();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                }
              }
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}