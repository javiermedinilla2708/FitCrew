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
    return Container(
      width: 140,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFFDBF0DD).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: LinearProgressIndicator(
        color: Color(0xFFDBF0DD),
        backgroundColor: Colors.white.withOpacity(0.05),
        minHeight: 3,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
