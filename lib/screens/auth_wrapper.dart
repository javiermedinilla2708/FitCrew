import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/filters/filter_screen.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/screens/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

// ============================================================
// AuthWrapper
// Decide a qué pantalla navegar según el estado de autenticación
// y si el usuario ha completado el onboarding de deportes
// ============================================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorMentol = Color(0xFFDBF0DD);
  static const _colorPrimario = Color(0xFF235347);

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // --- ESTADO: esperando respuesta de Firebase ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          // --- ESTADO: usuario autenticado ---
          if (snapshot.hasData) {
            return _buildAuthenticatedRoute(snapshot.data!);
          }

          // --- ESTADO: usuario no autenticado ---
          return const WelcomeScreen();
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // RUTA AUTENTICADA — comprueba si completó el onboarding
  // ----------------------------------------------------------
  Widget _buildAuthenticatedRoute(User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // --- Esperando datos de Firestore ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        // --- Comprobamos si completó el setup de deportes ---
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final setupComplete = data?['setupComplete'] ?? false;

        if (setupComplete) {
          return const HomeScreen();
        } else {
          return const FilterScreen();
        }
      },
    );
  }

  // ----------------------------------------------------------
  // WIDGET: indicador de carga
  // ----------------------------------------------------------
  Widget _buildLoadingIndicator() {
    return Center(
      child: LinearProgressIndicator(
        color: _colorMentol,
        backgroundColor: _colorPrimario.withOpacity(0.1),
        minHeight: 6,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
