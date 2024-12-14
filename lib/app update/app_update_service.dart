import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/screens/new_update_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

class AppUpdateService {
  Future<void> checkAppVersion(BuildContext context) async {
    try {
      // Pobierz wersję lokalnej aplikacji
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Pobierz wersję z Firebase
      final snapshot = await FirebaseDatabase.instance.ref('app/version').get();
      if (snapshot.exists) {
        final firebaseVersion = snapshot.value as String;
        developer.log("current version=$currentVersion");
        developer.log("new version=$firebaseVersion");
        // Porównaj wersje
        if (isNewVersionAvailable(currentVersion, firebaseVersion) &&
            context.mounted) {
          // Przekieruj na ekran aktualizacji
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => NewUpdateScreen(
                    currentVersion: currentVersion,
                    newVersion: firebaseVersion)),
          );
        }
      }
    } catch (e) {
      developer.log("Błąd podczas sprawdzania wersji: $e");
    }
  }

  bool isNewVersionAvailable(String currentVersion, String firebaseVersion) {
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    List<int> firebaseParts =
        firebaseVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (i >= firebaseParts.length || currentParts[i] < firebaseParts[i]) {
        return true;
      } else if (currentParts[i] > firebaseParts[i]) {
        return false;
      }
    }
    return false;
  }
}
