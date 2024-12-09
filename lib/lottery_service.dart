import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class LotteryService {
  
  Future<Map<String, dynamic>> fetchUserBets(String uid) async {
    final DatabaseReference betsRef =
        FirebaseDatabase.instance.ref('users/$uid/bets');
    try {
      final userBetsSnapshot = await betsRef.get();

      if (!userBetsSnapshot.exists) {
        developer.log("No bets found for user $uid");
        return {};
      }

      return Map<String, dynamic>.from(userBetsSnapshot.value as Map);
    } catch (e) {
      developer.log("Error fetching user bets: $e");
      return {};
    }
  }

  Map<String, Map<int, List<dynamic>>> groupBetsByLotteryAndDraw(
    Map<String, dynamic> bets) {
  final groupedBets = <String, Map<int, List<dynamic>>>{};
  
  // Iterowanie przez wszystkie zakłady w mapie
  bets.forEach((betKey, betData) {
    final lotteryName = betData['lotteryName'];  // Nazwa loterii
    final nextDrawId = betData['nextDrawId'];    // ID następnego losowania

    // Jeżeli nie ma jeszcze grupy dla tej loterii, tworzę nową
    if (!groupedBets.containsKey(lotteryName)) {
      groupedBets[lotteryName] = {};
    }
    
    // Jeżeli nie ma jeszcze grupy dla tego ID losowania w danej loterii, tworzę nową listę
    if (!groupedBets[lotteryName]!.containsKey(nextDrawId)) {
      groupedBets[lotteryName]![nextDrawId] = [];
    }

    // Dodajemy zakład do odpowiedniej grupy w danej loterii i losowaniu
    groupedBets[lotteryName]![nextDrawId]!.add({
      'betKey': betKey, // dodajemy betKey do danych
      'betData': betData  // dodajemy dane zakładu
    });
  });

  return groupedBets;
}


  Future<double> getJackpotAmount(String lotteryName) async {

    String url =
        'https://developers.lotto.pl/api/open/v1/lotteries/info/game-jackpot';
    
    final headers = {
      "accept": "application/json",
      "secret": "ZaQdWY58zmZa8o83FdURxiaIdUQcug7/ZrJwDFzHJbA=",
    };

    try {
      final response = await http.get(Uri.parse(url).replace(queryParameters: {
        "gameType": lotteryName
      }), headers: headers);

      if (response.statusCode == 200) {
        Map<dynamic, dynamic> data = jsonDecode(response.body);
        developer.log(data.toString());
        double amount = data['jackpotValue'];
        return amount;

      } else {
        developer.log("Błąd: ${response.statusCode}");
        return 0.0;
      }
    } catch (e) {
      developer.log("Błąd: $e");
      return 0.0;
    }
  }

  Future<double> checkPrizesForGroup(String lotteryName, int drawId, String prizeNum) async {
    await Future.delayed(const Duration(seconds: 3)); // Dodanie opóźnienia

    final headers = {
      "accept": "application/json",
      "secret": "ZaQdWY58zmZa8o83FdURxiaIdUQcug7/ZrJwDFzHJbA=",
    };
    final url =
        'https://developers.lotto.pl/api/open/v1/lotteries/draw-prizes/$lotteryName/$drawId';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        var prizeVal  = data[0]['prizes'][prizeNum]['prizeValue'];
        return prizeVal;

      } else {
        developer.log("Błąd: ${response.statusCode}");
        return 0.0;
      }
    } catch (e) {
      developer.log("Błąd: $e");
      return 0.0;
    }
  }


  Future<void> addWinToDatabase({
    required String uid,
    required String lotteryName,
    required int nextDrawId,
    required double priceValue,
    required String betId
  }) async {
    try {
      // Referencja do lokalizacji w Firebase Database
      final DatabaseReference winsRef =
          FirebaseDatabase.instance.ref('users/$uid/wins');

      Map<String, dynamic> winsMap = {};

      // Tworzenie obiektu do zapisania
      winsMap[betId] = {
        'lotteryName': lotteryName,
        'nextDrawId': nextDrawId,
        'priceValue': priceValue,
      };
      
      // Dodanie obiektu do bazy danych
      await winsRef.update(winsMap);

      // Logowanie powodzenia
      developer.log("Win added to database: $winsMap");
    } catch (e) {
      // Logowanie błędu
      developer.log("Error adding win to database: $e");
    }
  }


  Future<void> checkUserBets(String uid) async {
  try {
    // 1. Pobranie zakładów użytkownika
    final bets = await fetchUserBets(uid);
    if (bets.isEmpty) return;

    // 2. Grupowanie zakładów według gry i losowania
    final groupedBets = groupBetsByLotteryAndDraw(bets);

    // 3. Sprawdzanie wyników dla każdej grupy
    for (final lotteryName in groupedBets.keys) {
      await getJackpotAmount(lotteryName);
      
      for (final drawId in groupedBets[lotteryName]!.keys) {
        var winningNumbers = await drawResultsById(lotteryName, drawId);
        
        // Iterowanie po wszystkich zakładach w danej grupie (loteria, losowanie)
        for (var i = 0; i < groupedBets[lotteryName]![drawId]!.length; i++) {
          var bet = groupedBets[lotteryName]![drawId]![i];
          
          // Zakładając, że 'bet' zawiera zarówno 'betKey', jak i 'betData'
          var betKey = bet['betKey'];  // betKey
          var betData = bet['betData']; // betData (dane zakładu)

          // Zakładając, że 'betData' ma właściwości 'basicNum' i 'additionalNum'
          var basicNum = betData['basicNum'];
          var additionalNum = betData.containsKey('additionalNum') ? betData['additionalNum'] : [];
          
          // Obliczanie trafionych numerów
          var basicHits = countHits(basicNum, winningNumbers[0]['resultsJson']);
          var addHits = countHits(additionalNum, winningNumbers[0]['specialResults']);
          
          // Obliczanie numeru nagrody
          var prizeNumber = calculateLotteryPrizeNumber(lotteryName, drawId, basicHits, addHits);

          // Sprawdzanie, czy jest nagroda
          if (prizeNumber != 'Brak nagrody') {
            var priceVal = await checkPrizesForGroup(lotteryName, drawId, prizeNumber);
            if (priceVal != 0) {
              await addWinToDatabase(uid: uid, lotteryName: lotteryName, nextDrawId: drawId, priceValue: priceVal, betId: betKey);
            } else {
              var newValue = await getJackpotAmount(lotteryName);
              await addWinToDatabase(uid: uid, lotteryName: lotteryName, nextDrawId: drawId, priceValue: newValue, betId: betKey);
            }
          } else {
            developer.log('Brak nagrody');
          }
        }
      }
    }
  } catch (e) {
    developer.log("Error: $e");
  }
}


  int countHits(List<dynamic> userNumbers, List<dynamic> winningNumbers) {
    int hits = 0;
    for (var num in userNumbers) {
      if (winningNumbers.contains(num)) {
        hits++;
      }
    }
    return hits;
  }

  Future<List<dynamic>> lastDrawResults(String lotteryName) async {
    String url =
        "https://www.lotto.pl/api/lotteries/draw-results/last-results-per-game?gameType=$lotteryName";

    try {
      final response = await http.get(Uri.parse(url));

      // Sprawdź, czy odpowiedź jest poprawna
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data;
      } else {
        developer.log("Błąd: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      developer.log("Błąd: $e");
      return [];
    }
  }

  Future<List<Map>> drawResultsById(String lotteryName, int drawId) async {
    String url =
        "https://www.lotto.pl/api/lotteries/draw-results/by-number-per-game?gameType=$lotteryName&drawSystemId=$drawId&index=1&size=10&sort=drawSystemId&order=DESC";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['items'].isNotEmpty) {
          final lastDraw = data['items'][0]['results'];

          List<Map> resultsList = List<Map>.from(lastDraw);
          return resultsList;
        } else {
          // Jeśli brak wyników, zwróć pustą listę
          return [];
        }
      } else {
        throw Exception('Błąd pobierania wyników: ${response.statusCode}');
      }
    } catch (e) {
      // Obsługuje błąd, np. brak połączenia z internetem
      throw Exception('Błąd: $e');
    }
  }


  Future<bool> isDrawCompleted(String lotteryName, int drawId) async {
    String url =
        "https://www.lotto.pl/api/lotteries/draw-results/by-number-per-game?gameType=$lotteryName&drawSystemId=$drawId&index=1&size=10&sort=drawSystemId&order=DESC";
    try {
      final response = await http.get(Uri.parse(url));

      // Sprawdź, czy odpowiedź jest poprawna
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Sprawdzenie, czy są jakiekolwiek wyniki
        if (data['items'].isNotEmpty) {
          // Ostatni wynik (pierwszy w liście, posortowane malejąco po drawSystemId)
          final lastDraw = data['items'][0];

          // Wyciągamy ostatni 'drawSystemId' oraz datę losowania
          int lastDrawId = lastDraw['drawSystemId'];

          // Sprawdzamy, czy podany 'drawId' jest równy ostatniemu
          if (lastDrawId == drawId) {
            return true; // Losowanie zostało zakończone
          } else {
            return false; // Losowanie nie zostało zakończone
          }
        } else {
          developer.log("Brak wyników.");
          return false;
        }
      } else {
        developer.log("Błąd: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("Błąd: $e");
      return false;
    }
  }

  
  String calculateLotteryPrizeNumber(
      String lotteryName, int drawId, int basicHits, int addHits) {
    if (lotteryName == "Lotto") {
      switch (basicHits) {
        case 6:
          return "1"; // Pierwsza nagroda za 6 trafień
        case 5:
          return "2"; // Druga nagroda za 5 trafień
        case 4:
          return "3"; // Trzecia nagroda za 4 trafienia
        case 3:
          return "4"; // Czwarta nagroda za 3 trafienia
        default:
          return "Brak nagrody";
      }
    } else if (lotteryName == "MiniLotto") {
      switch (basicHits) {
        case 5:
          return "1"; // Pierwsza nagroda za 5 trafień
        case 4:
          return "2"; // Druga nagroda za 4 trafienia
        case 3:
          return "3"; // Trzecia nagroda za 3 trafienia
        default:
          return "Brak nagrody";
      }
    } else if (lotteryName == "Szybkie600") {
      switch (basicHits) {
        case 6:
          return "1"; // Pierwsza nagroda za 6 trafień
        case 5:
          return "2"; // Druga nagroda za 5 trafień
        case 4:
          return "3"; // Trzecia nagroda za 4 trafienia
        case 3:
          return "4"; // Czwarta nagroda za 3 trafienia
        case 2:
          return "5"; // Piąta nagroda za 2 trafienia
        default:
          return "Brak nagrody";
      }
    } else if (lotteryName == "EuroJackpot") {
      // EuroJackpot uwzględnia dodatkowe liczby i 12 kategorii nagród
      if (basicHits == 5 && addHits == 2) {
        return "1"; // 5+2 - Pierwsza nagroda
      } else if (basicHits == 5 && addHits == 1) {
        return "2"; // 5+1 - Druga nagroda
      } else if (basicHits == 5 && addHits == 0) {
        return "3"; // 5+0 - Trzecia nagroda
      } else if (basicHits == 4 && addHits == 2) {
        return "4"; // 4+2 - Czwarta nagroda
      } else if (basicHits == 4 && addHits == 1) {
        return "5"; // 4+1 - Piąta nagroda
      } else if (basicHits == 4 && addHits == 0) {
        return "6"; // 4+0 - Szósta nagroda
      } else if (basicHits == 3 && addHits == 2) {
        return "7"; // 3+2 - Siódma nagroda
      } else if (basicHits == 2 && addHits == 2) {
        return "8"; // 2+2 - Ósma nagroda
      } else if (basicHits == 3 && addHits == 1) {
        return "9"; // 3+1 - Dziewiąta nagroda
      } else if (basicHits == 3 && addHits == 0) {
        return "10"; // 3+0 - Dziesiąta nagroda
      } else if (basicHits == 1 && addHits == 2) {
        return "11"; // 1+2 - Jedenasta nagroda
      } else if (basicHits == 2 && addHits == 1) {
        return "12"; // 2+1 - Dwunasta nagroda
      } else {
        return "Brak nagrody";
      }
    } else {
      return "Nieznana loteria";
    }
  }
}
