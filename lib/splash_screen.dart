import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const oceanBlue = Color(0xFF1684A7);
    const tealGreen = Color(0xFF0EA391);
    const sunnyYellow = Color(0xFFFAF179);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: tealGreen,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: oceanBlue, width: 4),
                boxShadow: const [
                  BoxShadow(color: oceanBlue, offset: Offset(4, 4)),
                ],
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 64,
                color: sunnyYellow,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'QUESTERS',
              style: GoogleFonts.pressStart2p(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: oceanBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'EXPLORE INDIA IN PIXELS',
              style: GoogleFonts.pressStart2p(fontSize: 8, color: tealGreen),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: tealGreen,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
