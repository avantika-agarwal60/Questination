import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/pixel_journal.dart';
import 'screens/xp_manager.dart';
import 'screens/city_book.dart';
import 'screens/quest_service.dart';

// ── Colour tokens ────────────────────────────────────────────────────────────
const _kYellow = Color(0xFFFFD54F);
const _kYellowDk = Color(0xFFF9A825);
const _kMint = Color(0xFF81C784);
const _kMintDk = Color(0xFF43A047);
const _kGreen = Color(0xFF1E5228);
const _kGreenMid = Color(0xFF2D7A3A);
const _kWoodMid = Color(0xFF7B4F2E);
const _kCream = Color(0xFFFFF8E1);
const _kBlue = Color(0xFF7DA8C4);

// CityBook now lives in screens/city_book.dart — it used to be redefined
// here with a different shape than quest_service.dart's version, which
// meant QuestService's persistence couldn't actually be used from this
// screen. Both files now share the one model.

// ── Bookshelf screen (Journal Window Home Page) ─────────────────────────────────────────
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with TickerProviderStateMixin {
  final List<String> _questPool = [
    'Varanasi',
    'Delhi',
    'Kolkata',
    'Chennai',
    'Pune',
    'Agra',
  ];
  int _questPoolIdx = 0;
  bool _questDialogVisible = false;

  late final List<CityBook> _books;
  late AnimationController _newBookCtrl;
  late Animation<double> _newBookAnim;
  int? _newBookIndex;

  @override
  void initState() {
    super.initState();

    _books = [
      CityBook(
        id: 'lko_01',
        name: 'Lucknow',
        emoji: '🕌',
        spineColor: _kBlue,
        labelColor: _kGreen,
        coverAsset: 'assets/lkospinee.png',
        isLucknow: true,
        unlocked: true,
      ),
    ];

    _newBookCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _newBookAnim = CurvedAnimation(
      parent: _newBookCtrl,
      curve: Curves.easeOutBack,
    );

    // Was missing before — accepted quests lived only in the in-memory
    // _books list and vanished on every restart. This restores whatever
    // was previously saved via QuestService/SharedPreferences.
    _restoreSavedQuests();
  }

  Future<void> _restoreSavedQuests() async {
    final saved = await QuestService.getAcceptedQuests();
    if (!mounted || saved.isEmpty) return;

    setState(() {
      for (final book in saved) {
        final alreadyPresent = _books.any((b) => b.id == book.id);
        if (!alreadyPresent) {
          _books.add(book);
          // Keep _questPoolIdx in sync so the same city can't be offered
          // again from _questPool.
          final poolIdx = _questPool.indexOf(book.name);
          if (poolIdx != -1 && poolIdx >= _questPoolIdx) {
            _questPoolIdx = poolIdx + 1;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _newBookCtrl.dispose();
    super.dispose();
  }

  // ── Quest Actions ──────────────────────────────────────────────────────────

  void _showQuestDialog() {
    if (_questPoolIdx >= _questPool.length) return;
    HapticFeedback.mediumImpact();
    setState(() => _questDialogVisible = true);
  }

  void _acceptQuest() {
    final city = _questPool[_questPoolIdx++];
    setState(() {
      _questDialogVisible = false;
      _newBookIndex = _books.length;

      _books.add(
        CityBook(
          id: city.toLowerCase(),
          name: city,
          emoji: _emojiFor(city),
          spineColor: _colorFor(city),
          coverAsset: _assetFor(city),
          labelColor: const Color(0xFFE8D8B8),
          isLucknow: false,
          isQuestAccepted: true,
          unlocked: false, 
        ),
      );
    });
    _newBookCtrl.forward(from: 0);
    XpManager().addQuestXp();
    HapticFeedback.heavyImpact();
    // Was missing before — accepted quests never made it to
    // SharedPreferences, so QuestService.getAcceptedQuests() always came
    // back empty on the next launch.
    QuestService.saveAcceptedQuests(_books);
  }

  void _declineQuest() => setState(() => _questDialogVisible = false);

  String? _assetFor(String city) {
    if (city == 'Varanasi') return 'assets/varanasi.png';
    return null;
  }

  String _emojiFor(String city) =>
      const {
        'Varanasi': '🪔',
        'Delhi': '🏛️',
        'Kolkata': '🌸',
        'Chennai': '🐚',
        'Pune': '⛰️',
        'Agra': '🕍',
      }[city] ??
      '📖';

  Color _colorFor(String city) =>
      const {
        'Varanasi': Color(0xFF7B3F3F),
        'Delhi': Color(0xFF604828),
        'Kolkata': Color(0xFF804060),
        'Chennai': Color(0xFF406040),
        'Pune': Color(0xFF405060),
        'Agra': Color(0xFF806040),
      }[city] ??
      const Color(0xFF506070);

  // ── Handle Journal Selection ──────────────────────────────────────────────

  void _handleBookTap(CityBook book) {
    if (!book.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kCream,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Travel to ${book.name} to unlock this journal!',
            style: GoogleFonts.vt323(fontSize: 18, color: _kGreen),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Was `const PixelJournalMainScreen()` with no arguments before, so
    // every city (once unlocked) opened the same hardcoded Lucknow
    // journal. citySlug is passed through to fetchJournalPages() —
    // confirm with your teammate exactly what value their
    // `journal_pages` rows key off (city id vs. a real quest id) so this
    // lines up with their schema.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PixelJournalMainScreen(
          citySlug: book.id,
          cityName: book.name.toUpperCase(),
        ),
      ),
    );
  }

  // ── Build Screen ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/whitebg.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const _XpBarWidget(),
                Expanded(
                  child: _buildShelvesScroll(),
                ),
                _buildFooterNav(),
              ],
            ),
          ),

          if (_questDialogVisible) _buildQuestOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 100,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: 8),
          Text(
            'YOUR ADVENTURES, COLLECTED',
            textAlign: TextAlign.center,
            style: GoogleFonts.vt323(
              fontSize: 20,
              color: _kGreenMid,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Uniform Navigation Footer ───────────────────────────────────────────────

  Widget _buildFooterNav() {
    return Container(
      decoration: BoxDecoration(
        color: _kCream,
        border: Border(
          top: BorderSide(color: _kGreen.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          _buildFooterButton(
            icon: Icons.map_rounded,
            label: 'QUEST PAGE',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _kCream,
                  content: Text(
                    'Quest Page coming soon!',
                    style: GoogleFonts.vt323(fontSize: 16, color: _kGreen),
                  ),
                ),
              );
            },
          ),
          _buildFooterButton(
            icon: Icons.menu_book_rounded,
            label: 'JOURNAL PAGE',
            isActive: true, // Currently active (BookshelfScreen)
            onTap: () {},
          ),
          _buildFooterButton(
            icon: Icons.brush_rounded,
            label: 'ARTISANS PAGE',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _kCream,
                  content: Text(
                    'Artisans Page coming soon!',
                    style: GoogleFonts.vt323(fontSize: 16, color: _kGreen),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? _kGreen : _kWoodMid.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE7F5E7) : const Color(0xFFF7FAF3),
            border: Border(
              top: BorderSide(
                color: isActive ? const Color(0xFF49A36A) : const Color(0xFFDDE8D9),
                width: isActive ? 3 : 1,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.pressStart2p(
                  fontSize: 4.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShelvesScroll() {
    final questsLeft = _questPoolIdx < _questPool.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _JournalStack(
            books: _books,
            newBookIndex: _newBookIndex,
            newBookAnim: _newBookAnim,
            onBookTap: _handleBookTap,
          ),
          const SizedBox(height: 24),
          if (questsLeft) _QuestStackSlot(onTap: _showQuestDialog),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestOverlay() {
    final city = _questPool[_questPoolIdx];
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: _kCream,
            border: Border.all(color: _kYellowDk, width: 3),
            boxShadow: [
              BoxShadow(
                color: _kYellow.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '★  NEW QUEST  ★',
                style: GoogleFonts.pressStart2p(
                  fontSize: 9,
                  color: _kGreen,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              Text(_emojiFor(city), style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 14),
              Text(
                city.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  fontSize: 13,
                  color: _kGreen,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A new city adventure awaits!\nTravel to $city and document your journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(
                  fontSize: 20,
                  color: _kWoodMid,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _kMintDk.withOpacity(0.5)),
                  color: _kMint.withOpacity(0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Text(
                      'GPS required to unlock\njournal at destination',
                      style: GoogleFonts.vt323(
                        fontSize: 17,
                        color: _kGreen,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuestButton(
                      label: '✗  DECLINE',
                      onTap: _declineQuest,
                      primary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuestButton(
                      label: '✓  ACCEPT',
                      onTap: _acceptQuest,
                      primary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalStack extends StatelessWidget {
  final List<CityBook> books;
  final int? newBookIndex;
  final Animation<double> newBookAnim;
  final void Function(CityBook) onBookTap;

  const _JournalStack({
    required this.books,
    required this.newBookIndex,
    required this.newBookAnim,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    const double journalHeight = 110.0;
    const double visibleSpineHeight = 75.0; 
    final totalHeight = journalHeight + (books.length - 1) * visibleSpineHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(books.length, (i) {
          final topOffset = i * visibleSpineHeight;

          return Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            height: journalHeight,
            child: _StackedJournal(
              key: ValueKey('journal_${books[i].name}_$i'),
              book: books[i],
              isNew: i == newBookIndex,
              newBookAnim: newBookAnim,
              onTap: () => onBookTap(books[i]),
              height: journalHeight,
            ),
          );
        }),
      ),
    );
  }
}

class _StackedJournal extends StatefulWidget {
  final CityBook book;
  final bool isNew;
  final Animation<double> newBookAnim;
  final VoidCallback onTap;
  final double height;

  const _StackedJournal({
    super.key,
    required this.book,
    required this.isNew,
    required this.newBookAnim,
    required this.onTap,
    required this.height,
  });

  @override
  State<_StackedJournal> createState() => _StackedJournalState();
}

class _StackedJournalState extends State<_StackedJournal> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget journal = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: widget.height,
          transform: Matrix4.translationValues(0, _isHovered ? -8.0 : 0.0, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.book.coverUrl != null)
                  Image.network(
                    widget.book.coverUrl!,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) => _DrawnJournal(book: widget.book),
                  )
                else if (widget.book.coverAsset != null)
                  Image.asset(
                    widget.book.coverAsset!,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  )
                else
                  _DrawnJournal(book: widget.book),

                if (!widget.book.unlocked)
                  Positioned(
                    right: 14,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔒 ', style: TextStyle(fontSize: 8)),
                          Text(
                            'LOCKED',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 7,
                              color: const Color(0xFFFFF8E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (widget.book.unlocked)
                  Positioned(
                    right: 14,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E5228).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OPEN',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 7,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.isNew) return journal;

    return AnimatedBuilder(
      animation: widget.newBookAnim,
      builder: (context, child) {
        final scale = widget.newBookAnim.value;
        return Transform.scale(
          scale: scale <= 0 ? 0.01 : scale,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: journal,
    );
  }
}

class _DrawnJournal extends StatelessWidget {
  final CityBook book;

  const _DrawnJournal({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: book.spineColor,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                book.name.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  fontSize: 13,
                  color: book.labelColor,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              book.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestStackSlot extends StatefulWidget {
  final VoidCallback onTap;

  const _QuestStackSlot({required this.onTap});

  @override
  State<_QuestStackSlot> createState() => _QuestStackSlotState();
}

class _QuestStackSlotState extends State<_QuestStackSlot> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 86,
          decoration: BoxDecoration(
            color: _kCream.withOpacity(_hovered ? 0.85 : 0.70),
            border: Border.all(
              color: _kYellowDk.withOpacity(_hovered ? 0.95 : 0.65),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+',
                style: GoogleFonts.pressStart2p(
                  fontSize: 18,
                  color: _kYellowDk,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'ACCEPT NEW QUEST',
                style: GoogleFonts.pressStart2p(
                  fontSize: 8,
                  color: _kGreen,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XpBarWidget extends StatelessWidget {
  const _XpBarWidget();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: XpManager(),
      builder: (context, _) {
        final xp = XpManager();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              border: Border.all(color: _kMintDk.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barW = constraints.maxWidth;
                    final progress = xp.stageProgress;
                    final charX = (barW * progress - 20).clamp(0.0, barW - 40);
                    return SizedBox(
                      height: 52,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _ProgressBar(progress: progress),
                          ),
                          Positioned(
                            bottom: 14,
                            left: charX,
                            child: Image.asset(
                              'assets/character.png',
                              height: 38,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.directions_walk,
                                      size: 34, color: Color(0xFF1E5228)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stage ${xp.stage}',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 7,
                        color: _kGreen,
                      ),
                    ),
                    Text(
                      '${xp.xp} XP',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 7,
                        color: _kGreenMid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        border: Border.all(color: _kMintDk, width: 2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF81C784), Color(0xFF43A047)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _QuestButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  State<_QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends State<_QuestButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary
        ? const Color(0xFF2A4A20)
        : const Color(0xFF3A1010);
    final border = widget.primary ? _kMintDk : const Color(0xFF803030);

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _down ? border : bg,
          border: Border.all(color: border, width: 3),
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(
            fontSize: 7,
            color: _kCream,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}