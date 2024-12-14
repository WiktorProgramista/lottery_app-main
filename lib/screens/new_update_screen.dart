import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class NewUpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String newVersion;

  const NewUpdateScreen(
      {super.key, required this.currentVersion, required this.newVersion});

  @override
  State<NewUpdateScreen> createState() => _NewUpdateScreenState();
}

class _NewUpdateScreenState extends State<NewUpdateScreen> {
  String updateLink = "";

  // Funkcja pobierająca dane z Firebase, czyli wersję i link do aktualizacji
  Future<void> _getAppUpdateLink() async {
    try {
      // Pobierz dane z Firebase
      final DataSnapshot snapshot =
          await FirebaseDatabase.instance.ref('app').get();
      if (snapshot.exists) {
        // Przypisz dane do zmiennych
        final data = snapshot.value as Map<dynamic, dynamic>;
        final link = data['updateLink'] as String;
        developer.log(link);

        // Zaktualizuj stan
        setState(() {
          updateLink = link;
        });
      } else {
        developer.log("Brak danych w bazie: app/updateLink");
      }
    } catch (e) {
      developer.log("Błąd podczas pobierania danych z Firebase: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getAppUpdateLink(); // Pobierz link do aktualizacji przy starcie ekranu
  }

  // Funkcja uruchamiająca link do aktualizacji
  void _launchUpdateLink() async {
    if (await canLaunchUrl(Uri.parse(updateLink))) {
      await launchUrl(Uri.parse(updateLink));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Dostępna jest nowa wersja aplikacji.',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              // Pokazanie przycisku tylko jeśli link do aktualizacji został załadowany i nie jest pusty
              if (updateLink.isNotEmpty)
                ElevatedButton(
                  onPressed: _launchUpdateLink,
                  child: Text(
                    'Pobierz nową wersję \n ${widget.newVersion}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              if (updateLink.isEmpty)
                const Text(
                  'Brak dostępnego linku do pobrania aktualizacji.',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              const Spacer(),
              Text(
                'Aktualna wersja ${widget.currentVersion}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
