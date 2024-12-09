import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottery_app/firebase_service.dart';
import 'package:lottery_app/widgets/bet_item_widget.dart';
import 'dart:developer' as developer;

class BetListScreen extends StatefulWidget {
  const BetListScreen({super.key});

  @override
  State<BetListScreen> createState() => _BetListScreenState();
}

class _BetListScreenState extends State<BetListScreen> {
  final FirebaseService firebaseService = FirebaseService();
  String? uid;
  DatabaseReference? betsRef;

  @override
  void initState() {
    super.initState();

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        firebaseService.alert(
          context,
          "Użytkownik nie jest zalogowany.",
        );
      }
    } else {
      setState(() {
        uid = user.uid;
        betsRef = FirebaseDatabase.instance.ref('users/$uid/bets');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null || betsRef == null) {
      return const Scaffold(
        body:
            Center(child: Text('Proszę się zalogować, aby zobaczyć zakłady.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista zakładów'),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: betsRef!.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Wystąpił błąd: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData ||
                snapshot.data!.snapshot.value == null) {
              return const Center(child: Text('Brak danych do wyświetlenia.'));
            } else {
              final Map<dynamic, dynamic> bets = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);

              // Zmieniona funkcja grupowania, która także zawiera key (ID zakładu)
              final Map<dynamic, List<Map<String, dynamic>>> groupedBets =
                  groupBetsByTimestamp(bets);

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                itemCount: groupedBets.keys.length,
                itemBuilder: (context, index) {
                  final timestamp = groupedBets.keys.elementAt(index);
                  final List<Map<String, dynamic>> betGroup =
                      groupedBets[timestamp]!;

                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (val) {
                      // Usuwamy wszystkie zakłady z tej samej grupy
                      removeAllBetsFromFirebase(betGroup);
                    },
                    child: BetItemWidget(
                      timestamp: timestamp,
                      betGroup: betGroup,
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  // Funkcja usuwająca wszystkie zakłady z grupy
  void removeAllBetsFromFirebase(List<Map<String, dynamic>> betGroup) async {
    try {
      for (var bet in betGroup) {
        final betId = bet['betId'];
        final ref = FirebaseDatabase.instance.ref('users/$uid/bets/$betId');
        await ref.remove();
      }
    } catch (e) {
      developer.log('Błąd usuwania zakładów z grupy: $e');
    }
  }

  Map<dynamic, List<Map<String, dynamic>>> groupBetsByTimestamp(
      Map<dynamic, dynamic> bets) {
    final Map<dynamic, List<Map<String, dynamic>>> groupedBets = {};

    for (var entry in bets.entries) {
      final timestamp = entry.value['timestamp'];
      final betId = entry.key; // Klucz zakładu (ID)

      if (!groupedBets.containsKey(timestamp)) {
        groupedBets[timestamp] = [];
      }

      // Dodanie zakładu z ID (entry.key)
      groupedBets[timestamp]!.add({
        'betId': betId, // Klucz zakładu
        'betData': entry.value, // Dane zakładu
      });
    }

    // Sortowanie grup po timestamp (malejąco)
    final sortedGroupedBets = Map.fromEntries(
      groupedBets.entries.toList()
        ..sort((a, b) =>
            b.key.compareTo(a.key)), // Sortowanie po timestamp (malejąco)
    );

    // Sortowanie zakładów wewnątrz każdej grupy (malejąco)
    for (var timestamp in sortedGroupedBets.keys) {
      sortedGroupedBets[timestamp]!.sort((a, b) {
        final int timestampA = a['betData']['timestamp'];
        final int timestampB = b['betData']['timestamp'];
        return timestampB
            .compareTo(timestampA); // Sortowanie wewnątrz grupy malejąco
      });
    }

    return sortedGroupedBets;
  }
}
