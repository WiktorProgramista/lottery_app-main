import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/firebase_service.dart';
import 'package:lottery_app/lottery_service.dart';
import 'package:lottery_app/objects/winning_bet.dart';
import 'package:lottery_app/widgets/bet_number_widget.dart';
import 'dart:developer' as developer;

class ResultsListScreen extends StatefulWidget {
  final List<dynamic> betGroup;

  const ResultsListScreen({super.key, required this.betGroup});

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
  final LotteryService lotteryService = LotteryService();
  final FirebaseService firebaseService = FirebaseService();
  List<WinningBet> winningBetList = [];
  User? user = FirebaseAuth.instance.currentUser;

  // Function to check if results are available
  Future<List<dynamic>> _checkIfResultsMatch() async {
    var bet = widget.betGroup[0];
    bool isDrawCompleted = await lotteryService.isDrawCompleted(
        bet['betData']['lotteryName'], bet['betData']['nextDrawId']);

    if (isDrawCompleted) {
      var results = await lotteryService.drawResultsById(
          bet['betData']['lotteryName'], bet['betData']['nextDrawId']);
      return results;
    } else {
      developer.log('Draw not completed');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    lotteryService.checkUserBets(user!.uid);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wyniki losowania"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _checkIfResultsMatch(), // Fetching the results
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator()); // Loading indicator
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Błąd: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Losowanie się nie odbyło.'));
                  } else {
                    var drawResults = snapshot.data!;
                    var basicNum = drawResults[0]['resultsJson'];
                    var additionalNum = drawResults[0]['specialResults'];

                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.grey.withOpacity(0.2)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        drawResults[0]['gameType'],
                                        style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        "Nr losowania:${drawResults[0]['drawSystemId']}"
                                            .toString(),
                                        style: const TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    BetNumberWidget(
                                        numbers: basicNum,
                                        officialNum: const []),
                                    if (additionalNum.isNotEmpty) ...[
                                      BetNumberWidget(
                                          numbers: additionalNum,
                                          isAdditional: true,
                                          officialNum: const []),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.betGroup.map((bet) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    BetNumberWidget(
                                        numbers: bet['betData']['basicNum'],
                                        bgColor: Colors.white,
                                        officialNum: basicNum),
                                    if (bet['betData']
                                            .containsKey('additionalNum') &&
                                        bet['betData']['additionalNum']
                                            .isNotEmpty) ...[
                                      BetNumberWidget(
                                          numbers: bet['betData']
                                              ['additionalNum'],
                                          isAdditional: true,
                                          bgColor: Colors.white,
                                          officialNum: additionalNum),
                                    ],
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
