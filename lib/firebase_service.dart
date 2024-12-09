import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/screens/home_screen.dart';
import 'package:lottery_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Funkcja do rejestracji użytkownika z e-mailem i hasłem
  Future<String?> registerUser(
      String email, String password, BuildContext context) async {
    try {
      // Rejestracja użytkownika
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Zapisanie stanu logowania w SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Zwrócenie UID użytkownika po udanej rejestracji
      if (context.mounted) {
        alert(context, 'Pomyślnie zarejestrowano konto.');
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      // Obsługa błędów, które mogą wystąpić przy rejestracji
      if (e.code == 'email-already-in-use') {
        if (context.mounted) {
          alert(context, 'Adres e-mail jest już używany.');
        }
      } else if (e.code == 'weak-password') {
        if (context.mounted) {
          alert(context, 'Hasło jest zbyt słabe.');
        }
      } else {
        if (context.mounted) {
          alert(context, 'Wystąpił błąd: ${e.message}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        alert(context, 'Nieoczekiwany błąd: ${e.toString()}');
      }
    }
    return null;
  }

  // Funkcja logowania użytkownika
  Future<String?> loginUser(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Zapisanie stanu logowania w SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (context.mounted) {
        // Upewnij się, że widget jest nadal w drzewie widgetów
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (e.code == 'user-not-found') {
          alert(context, 'Użytkownik nie znaleziony');
        } else if (e.code == 'wrong-password') {
          alert(context, 'Nieprawidłowe hasło');
        } else {
          alert(context, 'Wystąpił błąd: ${e.message}');
        }
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        alert(context, 'Nieoczekiwany błąd: ${e.toString()}');
      }
      return null;
    }
  }

  // Funkcja wylogowania
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await _auth.signOut();
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<String?> getCurrentUserName() async {
    final User? user = _auth.currentUser;
    return user?.displayName ??
        user?.email; // Preferowana nazwa użytkownika lub e-mail
  }

  Future<String?> getCurrentUserId() async {
    User? user = _auth.currentUser; // Pobieramy bieżącego użytkownika
    if (user != null) {
      return user.uid; // Zwracamy UID użytkownika
    } else {
      return null; // Zwracamy null, jeśli użytkownik nie jest zalogowany
    }
  }

  // Funkcja wyświetlająca AlertDialog
  void alert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
