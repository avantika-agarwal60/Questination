import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('https://ukeeynyryrqbwaotuail.supabase.co');
  const supabasePublishableKey = String.fromEnvironment('sb_publishable_Z_75l5TMK4XamkoW8MOTJw_Jxx2sQ7E');

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Missing Supabase config. Run with: flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const QuestJournalApp());
}

class QuestJournalApp extends StatelessWidget {
  const QuestJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      // Was `PixelJournalMainScreen` before, which skipped the bookshelf
      // entirely. BookshelfScreen is the actual home screen from your demo
      // video (XP bar, journal shelf, Accept New Quest).
      home: const BookshelfScreen(),
    );
  }
}