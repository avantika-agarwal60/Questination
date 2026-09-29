import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all required screen widgets
import 'login_screen.dart';
import 'quest_map_widget.dart';
import 'quests_tab_widget.dart';
import 'splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/preferences_and_artisans.dart';

void main() {
  runApp(const QuestinationApp());
}

class QuestinationApp extends StatefulWidget {
  const QuestinationApp({super.key});

  @override
  State<QuestinationApp> createState() => _QuestinationAppState();
}

class _QuestinationAppState extends State<QuestinationApp> {
  // Auth state tracking
  bool _isLoggedIn = false;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questination',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
      ),
      // Switch between LoginScreen and Main Application
      home: _showSplash
          ? SplashScreen(
              onComplete: () => setState(() => _showSplash = false),
            )
          : _isLoggedIn
              ? MainNavigationContainer(
                  onLogout: () {
                    setState(() => _isLoggedIn = false);
                  },
                )
              : LoginScreen(
                  onLoginSuccess: () {
                    setState(() => _isLoggedIn = true);
                  },
                ),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationContainer({
    super.key,
    required this.onLogout,
  });

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  String? _selectedCityId;
  String? _selectedQuestId;

  void _onCityChanged(String cityId) {
    if (_selectedCityId == cityId) return;
    setState(() {
      _selectedCityId = cityId;
      _selectedQuestId = null;
    });
  }

  void _onQuestSelected(String questId, String cityId) {
    setState(() {
      _selectedCityId = cityId;
      _selectedQuestId = questId;
      _currentIndex = 1; // Auto-navigate to Map tab when a quest/city is tapped
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      QuestsListScreen(
        cityId: _selectedCityId,
        onCityChanged: _onCityChanged,
        onQuestSelected: _onQuestSelected,
      ),
      QuestMapWidget(
        cityId: _selectedCityId ?? 'city-lucknow',
        questId: _selectedQuestId,
      ),
      const BookshelfScreen(),
      const PlaceholderScreen(title: 'CHECK-IN'),
      PreferencesAndArtisansScreen(cityId: _selectedCityId),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF0EA391), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0EA391),
          selectedItemColor: const Color(0xFFFAF179),
          unselectedItemColor: Colors.white,
          selectedLabelStyle: GoogleFonts.pressStart2p(fontSize: 7),
          unselectedLabelStyle: GoogleFonts.pressStart2p(fontSize: 6),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'QUESTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'MAP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'JOURNAL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified),
              label: 'CHECK-IN',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'ARTISANS',
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title COMING SOON',
        style: GoogleFonts.pressStart2p(
          fontSize: 10,
          color: const Color(0xFF1684A7),
        ),
      ),
    );
  }
}
