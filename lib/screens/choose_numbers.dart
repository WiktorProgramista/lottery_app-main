import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottery_app/firebase_service.dart';
import 'package:lottery_app/lottery_service.dart';
import 'package:lottery_app/objects/lottery.dart';
import 'package:lottery_app/objects/lottery_bet.dart';
import 'package:lottery_app/screens/bet_list_screen.dart';
import 'dart:developer' as developer;

class ChooseNumbers extends StatefulWidget {
  final Lottery lottery;
  const ChooseNumbers({super.key, required this.lottery});

  @override
  State<ChooseNumbers> createState() => _ChooseNumbersState();
}

class _ChooseNumbersState extends State<ChooseNumbers> {
  final ValueNotifier<List<int>> _selectedBasicNum =
      ValueNotifier<List<int>>([]);
  final ValueNotifier<List<int>> _selectedAdditionalNum =
      ValueNotifier<List<int>>([]);
  final List<LotteryBet> _savedBets = [];
  bool _isBetEditing = false;
  User? user = FirebaseAuth.instance.currentUser;
  LotteryService lotteryService = LotteryService();
  FirebaseService firebaseService = FirebaseService();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          child: Column(
            children: [
              _listOfBets(context),
              _randomSwitch(),
              _customButton(
                  'Dodaj zakład', () => _showBottomSheet(widget.lottery)),
              const SizedBox(height: 10.0),
              _customButton('Potwierdzam i dodaje', () => _uploadListToDb())
            ],
          ),
        ),
      ),
    );
  }

  Widget _listOfBets(context) {
    return Expanded(
      child: ListView.builder(
        itemCount: _savedBets.length,
        itemBuilder: (context, index) {
          LotteryBet lotteryBet = _savedBets[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.5,
                          spreadRadius: 0.1,
                          offset: const Offset(0, 3)),
                    ]),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: lotteryBet.basicNum.map((lotteryBet) {
                        return Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.deepPurple,
                                    Colors.deepPurple.shade300
                                  ])),
                          child: Center(
                            child: Text(
                              lotteryBet.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: lotteryBet.additionalNum.map((lotteryBet) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.deepPurple,
                                      Colors.deepPurple.shade300
                                    ])),
                            child: Center(
                              child: Text(
                                lotteryBet.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _iconButton(Icons.edit, () {
                          setState(() {
                            _isBetEditing = true;
                            _selectedBasicNum.value = lotteryBet.basicNum;
                            _selectedAdditionalNum.value =
                                lotteryBet.additionalNum;
                          });
                          _showBottomSheet(widget.lottery);
                        }),
                        _iconButton(Icons.refresh, () {
                          setState(() {
                            _savedBets.removeAt(index);
                            _addRandomNumbers(index);
                          });
                        }),
                        _iconButton(Icons.delete, () {
                          setState(() {
                            _savedBets.removeAt(index);
                          });
                        }),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _basicNumWidgetList(Lottery lottery, context) {
    return List<Widget>.generate(lottery.basicNumRange, (index) {
      return ValueListenableBuilder<List<int>>(
        valueListenable: _selectedBasicNum,
        builder: (context, selectedNumbers, _) {
          return ElevatedButton(
            onPressed: () {
              if (_selectedBasicNum.value.contains(index + 1) ||
                  _selectedBasicNum.value.length >= lottery.basicNum) {
                _selectedBasicNum.value =
                    selectedNumbers.where((item) => item != index + 1).toList();
              } else if (selectedNumbers.length < lottery.basicNumRange) {
                _selectedBasicNum.value = List.from(selectedNumbers)
                  ..add(index + 1);
                _selectedBasicNum.value =
                    _selectedBasicNum.value.toSet().toList();
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(
                  width: 1.0,
                  color: _selectedBasicNum.value.contains(index + 1)
                      ? Colors.blue
                      : Colors.black.withOpacity(0.1)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _additionalNumWidgetList(Lottery lottery, context) {
    return List<Widget>.generate(lottery.additionalNumRange, (index) {
      return ValueListenableBuilder<List<int>>(
        valueListenable: _selectedAdditionalNum,
        builder: (context, selectedNumbers, _) {
          return ElevatedButton(
            onPressed: () {
              // Sprawdzenie, czy liczba jest już wybrana lub liczba dodatkowych liczb jest już pełna
              if (_selectedAdditionalNum.value.contains(index + 1)) {
                _selectedAdditionalNum.value =
                    selectedNumbers.where((item) => item != index + 1).toList();
              } else if (_selectedAdditionalNum.value.length < 2) {
                // Umożliwiamy wybór tylko 2 liczb
                _selectedAdditionalNum.value = List.from(selectedNumbers)
                  ..add(index + 1);
                _selectedAdditionalNum.value =
                    _selectedAdditionalNum.value.toSet().toList();
              } else {
                // Dodaj komunikat lub zablokuj wybór, jeśli wybrano już 2 liczby
                if (context.mounted) {
                  firebaseService.alert(
                      context, "Możesz wybrać tylko dwie liczby dodatkowe.");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(
                  width: 1.0,
                  color: _selectedAdditionalNum.value.contains(index + 1)
                      ? Colors.blue
                      : Colors.black.withOpacity(0.1)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          );
        },
      );
    }).toList();
  }

  void _showBottomSheet(Lottery lottery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Wybierz ${lottery.basicNum} liczb z ${lottery.basicNumRange}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.center,
              runSpacing: 3.0,
              children: _basicNumWidgetList(lottery, context),
            ),
            if (lottery.additionalNum != 0) ...[
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Wybierz ${lottery.additionalNum} liczb z ${lottery.additionalNumRange}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              ...[
                if (lottery.additionalNum != 0) ...[
                  const SizedBox(height: 10.0),
                  Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.center,
                    runSpacing: 3.0,
                    children: _additionalNumWidgetList(lottery, context),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 10.0),
            _customButton(
                'Zapisz',
                () => _saveBetsToList(
                    _selectedBasicNum, _selectedAdditionalNum, lottery))
          ],
        );
      },
    );
  }

  void _saveBetsToList(
    ValueNotifier<List<int>> selectedBasicNum,
    ValueNotifier<List<int>> selectedAdditionalNum,
    Lottery lottery,
  ) async {
    setState(() {
      if (selectedBasicNum.value.length == lottery.basicNum &&
          (lottery.additionalNum == 0 ||
              selectedAdditionalNum.value.length == lottery.additionalNum)) {
        // Zapisujemy zakład tylko wtedy, gdy liczba liczb podstawowych i dodatkowych (jeśli wymagane) jest poprawna
        if (_isBetEditing) {
          var existingBetIndex =
              _savedBets.indexWhere((bet) => bet.lotteryName == lottery.name);
          if (existingBetIndex != -1) {
            _savedBets[existingBetIndex] = LotteryBet(
                lotteryName: lottery.name,
                basicNum: selectedBasicNum.value.toList(),
                additionalNum: selectedAdditionalNum.value.toList(),
                nextDrawId: 1);
          }
        } else {
          _savedBets.add(LotteryBet(
              lotteryName: lottery.name,
              basicNum: selectedBasicNum.value.toList(),
              additionalNum: selectedAdditionalNum.value.toList(),
              nextDrawId: 1));
        }
        _selectedBasicNum.value.clear();
        _selectedAdditionalNum.value.clear();
        _isBetEditing = false;
        Navigator.pop(context);
      } else {
        if (context.mounted) {
          firebaseService.alert(
              context, "Musisz wybrać poprawną liczbę liczb.");
        }
      }
    });
  }

  Future<void> _updateNextDrawId() async {
    try {
      var nextDrawId =
          await lotteryService.lastDrawResults(widget.lottery.name);

      for (LotteryBet bet in _savedBets) {
        bet.nextDrawId = nextDrawId[0]['drawSystemId'] + 1;
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }

  void _uploadListToDb() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Używaj alertu, jeśli użytkownik nie jest zalogowany
        if (mounted) {
          if (context.mounted) {
            firebaseService.alert(context, "Użytkownik nie jest zalogowany.");
          }
        }
        return;
      }

      // Ensure we update nextDrawId before uploading
      await _updateNextDrawId();

      final String uid = user.uid;
      final DatabaseReference betsRef =
          FirebaseDatabase.instance.ref('users/$uid/bets');

      // Przygotowanie mapy z danymi do zapisania
      Map<String, dynamic> betsMap = {};

      for (var i = 0; i < _savedBets.length; i++) {
        String betId = betsRef.push().key ??
            i.toString(); // Unikalny identyfikator zakładu
        betsMap[betId] = {
          'lotteryName': _savedBets[i].lotteryName,
          'basicNum': _savedBets[i].basicNum,
          'additionalNum': _savedBets[i].additionalNum,
          'nextDrawId': _savedBets[i].nextDrawId,
          'timestamp': ServerValue.timestamp,
        };
      }

      // Wysyłanie wszystkich zakładów w jednym zapytaniu
      await betsRef.update(betsMap);

      // Powiadomienie o sukcesie
      if (mounted) {
        firebaseService.alert(context, "Zakłady zostały zapisane.");
      }

      // Zamknij aktualny ekran, jeśli operacja się powiedzie
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      // Obsługa błędów w przypadku problemów z bazą danych
      if (mounted) {
        firebaseService.alert(
            context, "Błąd podczas zapisywania zakładów: $error");
      }
    }
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const BetListScreen()));
    }
  }

  void _addRandomNumbers(int index) {
    final name = widget.lottery.name;
    final basic = widget
        .lottery.basicNum; // Liczba podstawowych liczb (np. 6 w Lotto 6 z 49)
    final additional = widget.lottery
        .additionalNum; // Liczba dodatkowych liczb (np. 1 w Lotto 6 z 49)
    final basicNumberRange = widget.lottery
        .basicNumRange; // Zakres liczb podstawowych (np. 49 w Lotto 6 z 49)
    final additionalNumberRange = widget.lottery
        .additionalNumRange; // Zakres liczb dodatkowych (np. 10 w Lotto 6 z 49)

    setState(() {
      List<int> basicNumbers = _generateRandomNumbers(basic, basicNumberRange);

      // Generowanie dodatkowych liczb
      List<int> additionalNumbers =
          _generateRandomNumbers(additional, additionalNumberRange);

      // Tworzymy nowy obiekt LotteryBet z losowymi liczbami
      _savedBets.insert(
          index,
          LotteryBet(
            lotteryName: name,
            basicNum: basicNumbers,
            additionalNum: additionalNumbers,
            nextDrawId:
                1, // Możesz dostosować ten identyfikator w zależności od potrzeby
          ));
    });
  }

// Funkcja pomocnicza do generowania losowych liczb
  List<int> _generateRandomNumbers(int count, int range) {
    List<int> numbers = [];
    Random rand = Random();

    while (numbers.length < count) {
      int randomNumber =
          rand.nextInt(range) + 1; // Generowanie liczby w zakresie 1 - range
      if (!numbers.contains(randomNumber)) {
        // Sprawdzamy, czy liczba już została wybrana
        numbers.add(randomNumber);
      }
    }

    return numbers;
  }

  Widget _randomSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chybił trafił',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
        ),
        CupertinoSwitch(
          value: isChecked,
          onChanged: (bool newValue) {
            setState(() {
              isChecked = newValue;
              if (isChecked) {
                _addRandomNumbers(_savedBets.length);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _customButton(String text, VoidCallback function) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: function,
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          )),
    );
  }

  Widget _iconButton(IconData icon, Function function) {
    return InkWell(
      onTap: () => function(),
      child: SizedBox(
          child: Icon(
        icon,
        color: Colors.black,
        size: 28.0,
      )),
    );
  }
}
