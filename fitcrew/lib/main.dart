import 'package:fitcrew/screens/splash_screen.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart';
import 'package:fitcrew/viewmodels/stats_view_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // ViewModel de actividades (eventos deportivos)
        ChangeNotifierProvider(create: (_) => ActivityViewModel()), // 1. Añadir
        // ViewModel de la feed social (Posts)
        ChangeNotifierProvider(create: (_) => PostViewModel()),

        // Otros ViewModels
        ChangeNotifierProvider(create: (_) => FilterViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => StatsViewModel()),
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
