import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottery_app/screens/results_list_screen.dart';
import 'bet_number_widget.dart';

class BetItemWidget extends StatelessWidget {
  final int timestamp;
  final List<dynamic> betGroup;

  const BetItemWidget({
    super.key,
    required this.timestamp,
    required this.betGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ResultsListScreen(betGroup: betGroup)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.5,
                spreadRadius: 0.1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/${betGroup[0]['betData']['lotteryName'].toString().toLowerCase()}.svg',
                width: 50.0,
                height: 50.0,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Zakłady z ${DateTime.fromMillisecondsSinceEpoch(timestamp)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              ...betGroup.map((bet) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BetNumberWidget(
                        numbers: bet['betData']['basicNum'],
                        officialNum: const []),
                    // Sprawdzamy, czy 'additionalNum' istnieje i nie jest pustą listą
                    if (bet['betData'].containsKey('additionalNum') &&
                        bet['betData']['additionalNum'].isNotEmpty) ...[
                      BetNumberWidget(
                        numbers: bet['betData']['additionalNum'],
                        isAdditional: true,
                        officialNum: const [],
                      ),
                    ],
                  ],
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}
