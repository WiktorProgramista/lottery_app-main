import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/screens/home_screen.dart';
import 'package:lottery_app/screens/login_screen.dart';
import 'package:lottery_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyBAwWnn0de8OEzrBLwP327oEXlrOPONWAw',
          appId: 'lottery-81801',
          messagingSenderId: '1:1066247745744:android:8ec8a2cebc5cdadb91eed5',
          projectId: 'lottery-81801'));

  // Sprawdzenie stanu logowania
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({super.key, required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lottery App',
      debugShowCheckedModeBanner: false,
      theme: appTheme(context),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
