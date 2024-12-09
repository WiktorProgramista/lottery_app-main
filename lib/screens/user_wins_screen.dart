import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserWinsScreen extends StatefulWidget {
  const UserWinsScreen({super.key});

  @override
  State<UserWinsScreen> createState() => _UserWinsScreenState();
}

class _UserWinsScreenState extends State<UserWinsScreen> {
  DatabaseReference? betsRef;

  @override
  void initState() {
    super.initState();
    String uid = FirebaseAuth.instance.currentUser!.uid;
    betsRef = FirebaseDatabase.instance.ref('users/$uid/wins');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Twoje Wygrane'),
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
              return const Center(child: Text('Brak wygranych.'));
            } else {
              final Map<dynamic, dynamic> wins =
                  Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

              return ListView.builder(
                itemCount: wins.length,
                itemBuilder: (context, index) {
                  String winKey = wins.keys.elementAt(index);
                  dynamic winObj = wins[winKey];

                  return winCard(
                    winKey,
                    winObj['lotteryName'],
                    winObj['priceValue'],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget winCard(String key, String? lotteryName, dynamic priceValue) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (lotteryName != null)
                SvgPicture.asset(
                  'assets/${lotteryName.toLowerCase()}.svg',
                  width: 50.0,
                  height: 50.0,
                  placeholderBuilder: (context) => const Icon(
                    Icons.image_not_supported,
                    size: 50.0,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  lotteryName ?? 'Nieznana loteria',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 30.0,
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          winInfo(
            label: 'Wygrana:',
            value: '${priceValue.toString()} zł',
          ),
          winInfo(
            label: 'Klucz:',
            value: key,
          ),
        ],
      ),
    );
  }

  Widget winInfo({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
