import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/screens/login/login_screen.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ActivityViewModel()..loadInitialData(),
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
      home: const LoginScreen(),
    );
  }
}