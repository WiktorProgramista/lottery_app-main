import 'package:flutter/material.dart';

class BetNumberWidget extends StatelessWidget {
  final List<dynamic> numbers;
  final List<dynamic> officialNum;
  final bool isAdditional;
  final Color bgColor;

  const BetNumberWidget(
      {super.key,
      required this.numbers,
      required this.officialNum,
      this.isAdditional = false,
      this.bgColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map<Widget>((number) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3.0),
          child: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1.3,
                      blurRadius: 5.0,
                      offset: const Offset(0, 3))
                ],
                shape: BoxShape.circle,
                color: officialNum.contains((number))
                    ? Colors.green
                    : isAdditional
                        ? const Color(0xFFFFCC00)
                        : Colors.white),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
