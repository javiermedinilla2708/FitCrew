import 'package:fitcrew/screens/splash_screen.dart';
import 'package:fitcrew/services/push_notification_service.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:fitcrew/viewmodels/auth_viewmodel.dart';
import 'package:fitcrew/viewmodels/filter_viewmodel.dart';
import 'package:fitcrew/viewmodels/post_viewmodel.dart';
import 'package:fitcrew/viewmodels/stats_view_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// ----------------------------------------------------------
// CLAVE GLOBAL DEL NAVIGATOR RAIZ
// Permite navegar desde cualquier punto de la app sin
// depender del contexto local que puede estar destruido.
// Se usa principalmente en deleteAccount para navegar a
// WelcomeScreen tras eliminar la cuenta de Firebase Auth.
// ----------------------------------------------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PushNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityViewModel()),
        ChangeNotifierProvider(create: (_) => PostViewModel()),
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
      navigatorKey: navigatorKey,
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
