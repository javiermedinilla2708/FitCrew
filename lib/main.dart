import 'package:fitcrew/screens/splash_screen.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart'; // 1. Importa el nuevo ViewModel

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        // Provider para las actividades (eventos)
        ChangeNotifierProvider(
          create: (_) => ActivityViewModel()..loadInitialData(),
        ),
        // 2. Añade el Provider para los Posts (Social Feed)
        ChangeNotifierProvider(
          create: (_) => PostViewModel(),
        ),

        ChangeNotifierProvider(
          create: (_) => FilterViewModel(),
        ),
        // En main.dart
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitCrew',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF24FF8F),
      ),
      home: const SplashScreen(),
    );
  }
}