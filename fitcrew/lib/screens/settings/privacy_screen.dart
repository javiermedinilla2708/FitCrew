// ============================================================
// lib/screens/settings/privacy_screen.dart
// Permite al usuario configurar si su perfil es público
// o privado. Si es privado, los usuarios que no le siguen
// solo ven sus estadísticas básicas.
// ============================================================

import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart';
import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  final UserService _userService = UserService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isPrivate = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  // ----------------------------------------------------------
  // CARGAR PREFERENCIA ACTUAL DESDE FIRESTORE
  // ----------------------------------------------------------
  Future<void> _loadPrivacy() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _isPrivate = doc.data()?['isPrivate'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando privacidad: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------------------------------------------------
  // GUARDAR PREFERENCIA EN FIRESTORE
  // ----------------------------------------------------------
  Future<void> _togglePrivacy(bool value) async {
    setState(() => _isPrivate = value);
    try {
      await _userService.updatePrivacy(_uid, value);
      if (mounted) {
        Flushbar(
          messageText: Text(
            value ? "Perfil cambiado a privado" : "Perfil cambiado a publico",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          icon: Icon(
            value ? Icons.lock_rounded : Icons.lock_open_rounded,
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
    } catch (e) {
      // Revertir si falla
      setState(() => _isPrivate = !value);
    }
  }

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
        title: const Text(
          "Privacidad",
          style: TextStyle(
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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Descripción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _colorVerdeMenta.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _colorVerdeBosque,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Si tu perfil es privado, los usuarios que no te siguen solo podran ver tus estadisticas basicas. Tendran que enviarte una solicitud para ver tu contenido completo.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle perfil privado
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Perfil privado",
                  subtitle: _isPrivate
                      ? "Solo tus seguidores pueden ver tu perfil completo"
                      : "Cualquier usuario puede ver tu perfil completo",
                  trailing: Switch(
                    value: _isPrivate,
                    onChanged: _togglePrivacy,
                    activeColor: _colorVerdeBosque,
                    activeTrackColor: _colorVerdeMenta,
                  ),
                ),

                const SizedBox(height: 12),

                // Info adicional según estado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isPrivate ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPrivate
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: _isPrivate
                            ? Colors.orange[700]
                            : Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isPrivate
                              ? "Tu perfil es privado. Los usuarios que no te siguen solo veran tu numero de posts, seguidores y seguidos."
                              : "Tu perfil es publico. Cualquier usuario puede ver tu contenido completo.",
                          style: TextStyle(
                            fontSize: 13,
                            color: _isPrivate
                                ? Colors.orange[700]
                                : Colors.green[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _colorVerdeMenta.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _colorVerdeBosque, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F1D19),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
