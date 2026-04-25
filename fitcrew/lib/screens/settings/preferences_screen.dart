// ============================================================
// lib/screens/settings/preferences_screen.dart
// Permite al usuario configurar notificaciones e idioma.
// Los cambios se guardan en Firestore via UserService.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart';
import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  final UserService _userService = UserService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _notificationsOn = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ----------------------------------------------------------
  // CARGAR PREFERENCIAS DESDE FIRESTORE
  // ----------------------------------------------------------
  Future<void> _loadPreferences() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _notificationsOn = data['notificationsOn'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Error cargando preferencias: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ----------------------------------------------------------
  // TOGGLE NOTIFICACIONES
  // ----------------------------------------------------------
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsOn = value);
    try {
      await _userService.updateNotificationsEnabled(_uid, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? "Notificaciones activadas"
                  : "Notificaciones desactivadas",
            ),
            backgroundColor: _colorVerdeBosque,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _notificationsOn = !value);
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
          "Preferencias",
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
                // SECCION NOTIFICACIONES
                _buildSectionHeader("Notificaciones"),
                const SizedBox(height: 12),

                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: "Notificaciones push",
                  subtitle: _notificationsOn
                      ? "Recibes notificaciones de FitCrew"
                      : "Las notificaciones estan desactivadas",
                  trailing: Switch(
                    value: _notificationsOn,
                    onChanged: _toggleNotifications,
                    activeColor: _colorVerdeBosque,
                    activeTrackColor: _colorVerdeMenta,
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 12),

                // Aviso idioma
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _colorVerdeMenta.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _colorVerdeBosque,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "El cambio de idioma se aplicara la proxima vez que inicies sesion.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
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
