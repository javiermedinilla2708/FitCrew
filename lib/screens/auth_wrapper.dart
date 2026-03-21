import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/screens/home/home_screen.dart';
import 'package:fitcrew/screens/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends  StatelessWidget{
  const AuthWrapper ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(
              child: LinearProgressIndicator(
                color: const Color(0xFF24FF8F),
                backgroundColor: const Color(0xFF24FF8F).withOpacity(0.1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10), 
              ),
            );
          }

          if(snapshot.hasData){
            return HomeScreen();
          }else{
            return WelcomeScreen();
          }
        }
      ),
    );
  }
}