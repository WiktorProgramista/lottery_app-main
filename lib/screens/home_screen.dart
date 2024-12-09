import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottery_app/constants.dart';
import 'package:lottery_app/screens/bet_list_screen.dart';
import 'package:lottery_app/screens/choose_numbers.dart';
import 'package:lottery_app/screens/profile_screen.dart';
import 'package:lottery_app/screens/user_wins_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista ekranów do przełączania
  final List<Widget> _screens = [
    const HomeView(), // Ekran główny
    const UserWinsScreen(), // Ekran wygranych
    const BetListScreen(), // Ekran zakładów
    const ProfileScreen() // Ekran profilu
  ];

  // Zmiana indeksu podczas kliknięcia w element dolnej nawigacji
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNav(context),
      body: _screens[_selectedIndex], // Wyświetla odpowiedni ekran
    );
  }

  Widget bottomNav(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svg/home.svg',
           
          ),
          label: 'Strona główna',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svg/chart.svg',
            
          ),
          label: 'Wygrane',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svg/bars.svg',
            
          ),
          label: 'Zakłady',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/svg/profile.svg',
            
          ),
        
          label: 'Konto',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: theme.textTheme.bodyMedium,
      onTap: _onItemTapped,
    );
  }
}

// Oddzielny widget reprezentujący ekran główny
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        children: lotterys.map((lotteryName) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Center(
                child: Column(
                  children: [
                    SvgPicture.asset(
                      lotteryName.imagePath,
                      width: 80.0,
                      height: 80.0,
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChooseNumbers(
                                lottery: lotteryName,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Zagraj',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
