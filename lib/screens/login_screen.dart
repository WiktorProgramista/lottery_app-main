import 'package:flutter/material.dart';
import 'package:lottery_app/firebase_service.dart';
import 'package:lottery_app/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text(
              'Zaloguj się',
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15.0),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                  
                  hintText: 'Wpisz email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  )),
            ),
            const SizedBox(height: 15.0),
            TextField(
              obscureText: true,
              controller: _password,
              decoration: InputDecoration(
                  
                  hintText: 'Wpisz hasło',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  )),
            ),
            const SizedBox(height: 15.0),
            _customButton('Zaloguj się', () {
              if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
                _firebaseService.loginUser(
                    _email.text, _password.text, context);
              } else {
                if (context.mounted) {
                  _firebaseService.alert(
                      context, 'Login i hasło nie mogą być puste');
                }
              }
            }),
            TextButton(
                child: const Text('Zarejestruj się'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()));
                })
          ],
        ),
      ),
    );
  }

  Widget _customButton(String text, VoidCallback function) {
    return ElevatedButton(
        onPressed: function,
  
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ));
  }
}
