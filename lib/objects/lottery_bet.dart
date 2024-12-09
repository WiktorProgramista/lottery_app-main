class LotteryBet {
  final String lotteryName;
  final List<int> basicNum;
  final List<int> additionalNum;
  int nextDrawId;

  LotteryBet({
    required this.lotteryName,
    required this.basicNum,
    required this.additionalNum,
    required this.nextDrawId,
  });
}
