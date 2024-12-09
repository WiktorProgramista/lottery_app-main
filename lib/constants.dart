import 'package:lottery_app/objects/lottery.dart';

List<Lottery> lotterys = [
  Lottery(
      name: 'Lotto',
      basicNum: 6,
      basicNumRange: 49,
      additionalNum: 0,
      additionalNumRange: 0,
      imagePath: 'assets/lotto.svg'),
  Lottery(
      name: 'MiniLotto',
      basicNum: 5,
      basicNumRange: 42,
      additionalNum: 0,
      additionalNumRange: 0,
      imagePath: 'assets/minilotto.svg'),
  Lottery(
      name: 'EuroJackpot',
      basicNum: 5,
      basicNumRange: 50,
      additionalNum: 2,
      additionalNumRange: 12,
      imagePath: 'assets/eurojackpot.svg'),
  Lottery(
      name: 'Szybkie600',
      basicNum: 6,
      basicNumRange: 32,
      additionalNum: 0,
      additionalNumRange: 0,
      imagePath: 'assets/szybkie600.svg'),
  Lottery(
      name: 'EkstraPensja',
      basicNum: 5,
      basicNumRange: 35,
      additionalNum: 1,
      additionalNumRange: 4,
      imagePath: 'assets/ekstrapensja.svg'),
];
