import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/firebase_service.dart';
import 'dart:developer' as developer;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FirebaseService firebaseService = FirebaseService();
  String? userName;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Ładuje nazwę użytkownika i UID
  Future<void> _loadUserName() async {
    final name = FirebaseAuth.instance.currentUser!.email.toString();
    final uid = await firebaseService.getCurrentUserId(); // Pobieramy UID
    setState(() {
      userName = name;
      userId = uid;
    });
  }

  // Funkcja usuwająca zakłady użytkownika
  Future<void> usunZaklady(String uid) async {
    if (uid.isEmpty) {
      developer.log('Brak UID użytkownika!');
      return;
    }
    final DatabaseReference betsRef =
        FirebaseDatabase.instance.ref('users/$uid/bets');

    try {
      // Usuwanie wszystkich zakładów użytkownika
      await betsRef.remove();
      developer.log('Zakłady zostały pomyślnie usunięte dla użytkownika $uid');
      setState(() {
        // Możesz tutaj zaktualizować UI, np. wyświetlić komunikat
      });
    } catch (e) {
      // Obsługa błędów
      developer.log('Nie udało się usunąć zakładów: $e');
    }
  }

  // Funkcja usuwająca wygrane użytkownika
  Future<void> usunWygrane(String uid) async {
    if (uid.isEmpty) {
      developer.log('Brak UID użytkownika!');
      return;
    }
    final DatabaseReference betsRef =
        FirebaseDatabase.instance.ref('users/$uid/wins');

    try {
      // Usuwanie wszystkich zakładów użytkownika
      await betsRef.remove();
      developer.log('Zakłady zostały pomyślnie usunięte dla użytkownika $uid');
      setState(() {
        // Możesz tutaj zaktualizować UI, np. wyświetlić komunikat
      });
    } catch (e) {
      // Obsługa błędów
      developer.log('Nie udało się usunąć zakładów: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            if (userName != null)
              Text(
                'Witaj, $userName!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 15.0),
            // Przekazujemy funkcję wylogowującą się z kontekstem
            _customButton('Wyloguj się', () => firebaseService.logout(context)),
            const SizedBox(height: 15.0),
            if (userId != null &&
                userId!.isNotEmpty) // Sprawdzamy, czy mamy userId
              _customButton('Usuń zakłady',() => usunZaklady(userId!)),
               const SizedBox(height: 15.0),
              _customButton('Usuń wygrane', ()=> usunWygrane(userId!)),
          ],
        ),
      ),
    );
  }

  Widget _customButton(String text, Function() function) {
    return ElevatedButton(
      onPressed: () async {
        await function(); // Wywołanie funkcji bez kontekstu
      },
     
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
