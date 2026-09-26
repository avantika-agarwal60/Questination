// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'india_map_welcome.dart';
import 'map_region.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials
  await Supabase.initialize(
    url: 'https://ukeeynyryrqbwaotuail.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrZWV5bnlyeXJxYndhb3R1YWlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4ODE1MTksImV4cCI6MjEwNDQ1NzUxOX0.msUEXK_0wPovZXYQP_5Ab_SU3eXpqStBx2E9v2lLaqU',
  );

  final user = supabase.auth.currentUser;
  debugPrint('Supabase initialized successfully. Active session user: $user');

  runApp(const QuestinationApp());
}

// Global reference helper for database operations
final supabase = Supabase.instance.client;

class QuestinationApp extends StatelessWidget {
  const QuestinationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questination',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F1EA), // Pixel Journal Cream
        primaryColor: const Color(0xFF1684A7),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showingWelcomeScreen = true;

  void _switchToMapTab() {
    setState(() {
      _showingWelcomeScreen = false;
      _currentIndex =
          1; // Switches to MAP tab while retaining bottom navigation footer
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show India welcome screen initial view
    if (_showingWelcomeScreen) {
      return IndiaMapWelcomeScreen(onExplorePressed: _switchToMapTab);
    }

    // Pages corresponding to bottom tabs: Quests, Map, Journal, Verification, Artisans
    final List<Widget> pages = [
      const QuestsTab(),
      const QuestMapWidget(),
      const JournalTab(),
      const VerificationCheckInTab(),
      const ArtisanMarketplaceTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pixel Compass / Mascot Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A88F),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.explore,
                color: Color(0xFFFCE868),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            // Pixel Logo matching Questination typography
            Text(
              'Questination',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00A88F), // #00A88F Teal Green
                shadows: [
                  const Shadow(offset: Offset(2, 2), color: Color(0xFF1684A7)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      // Footer with Green Theme (#00A88F) and persistent bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF00A88F), // Footer Green Color
        selectedItemColor: const Color(0xFFFCE868), // Selected Yellow
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: GoogleFonts.pressStart2p(fontSize: 7),
        unselectedLabelStyle: GoogleFonts.pressStart2p(fontSize: 7),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'QUESTS'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'JOURNAL'),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'CHECK-IN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'ARTISANS',
          ),
        ],
      ),
    );
  }
}

// QUESTS TAB
class QuestsTab extends StatelessWidget {
  const QuestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'YOUR ADVENTURES, COLLECTED',
          style: GoogleFonts.pressStart2p(
            fontSize: 9,
            color: const Color(0xFF1684A7),
          ),
        ),
        const SizedBox(height: 16),
        _buildQuestCard(
          'Dilkusha Kothi',
          '18th-century English Baroque ruins',
          '+350 XP',
        ),
        _buildQuestCard(
          'Rumi Darwaza',
          '60ft grand entrance archway',
          '+180 XP',
        ),
      ],
    );
  }

  Widget _buildQuestCard(String title, String desc, String xp) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF1684A7), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 9,
                    color: const Color(0xFF1684A7),
                  ),
                ),
                Text(
                  xp,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: const Color(0xFF00A88F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// JOURNAL TAB (Pixel Journal Page)
class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'PIXEL JOURNAL',
            style: GoogleFonts.pressStart2p(
              fontSize: 11,
              color: const Color(0xFF1684A7),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1684A7), width: 3),
              ),
              child: Center(
                child: Text(
                  '+ ADD JOURNAL PHOTO\n\n[ LUCKNOW MEMORIES ]',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: Colors.black45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CHECK-IN TAB
class VerificationCheckInTab extends StatelessWidget {
  const VerificationCheckInTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERIFICATION CHECK-IN',
            style: GoogleFonts.pressStart2p(
              fontSize: 10,
              color: const Color(0xFF1684A7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A88F),
            ),
            child: Text(
              'GPS CHECK-IN',
              style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ARTISANS TAB
class ArtisanMarketplaceTab extends StatelessWidget {
  const ArtisanMarketplaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'LOCAL ARTISAN DEALS',
        style: GoogleFonts.pressStart2p(
          fontSize: 10,
          color: const Color(0xFF1684A7),
        ),
      ),
    );
  }
}
