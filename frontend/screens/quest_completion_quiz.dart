import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestCompletionHelper {
  static const Color oceanBlue = Color(0xFF1684A7);
  static const Color tealGreen = Color(0xFF0EA391);
  static const Color sunnyYellow = Color(0xFFFAF179);
  static const Color creamBg = Color(0xFFF4F1EA);

  /// Shows the completion dialog asking user if they want to take a quiz
  static void showCompletionDialog(BuildContext context, {String? questId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: creamBg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: oceanBlue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'QUEST COMPLETED!',
          style: GoogleFonts.pressStart2p(
            fontSize: 14,
            color: oceanBlue,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: sunnyYellow, size: 48),
            const SizedBox(height: 12),
            Text(
              'To avail a discount take a quiz!',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // NO BUTTON -> Dismiss, no discount
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: oceanBlue,
                  content: Text(
                    'No quiz taken. No discount coupon awarded.',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'NO',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ),
          // YES BUTTON -> Launches AI Quiz Screen
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AIQuizScreen(questId: questId),
                ),
              );
            },
            child: Text(
              'YES',
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic AI Quiz Screen
class AIQuizScreen extends StatefulWidget {
  final String? questId;

  const AIQuizScreen({super.key, this.questId});

  @override
  State<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends State<AIQuizScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _aiQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _fetchAIQuestions();
  }

  /// Fetches AI-generated questions from Supabase or Edge Function
  Future<void> _fetchAIQuestions() async {
    try {
      final supabase = Supabase.instance.client;

      // OPTION 1: Query table containing AI generated questions by teammate
      final response = await supabase
          .from('quiz_questions')
          .select()
          .eq('quest_id', widget.questId ?? '@quests.id');

      // OPTION 2: Call Supabase Edge Function / AI Endpoint (Uncomment if using Edge Function)
      // final response = await supabase.functions.invoke('generate-quiz', body: {'quest_id': widget.questId});

      if (response != null && (response as List).isNotEmpty) {
        setState(() {
          _aiQuestions = List<Map<String, dynamic>>.from(
            response.map(
              (q) => {
                'question': q['question_text'],
                'options': List<String>.from(q['options']),
                'answer': q['correct_option'],
              },
            ),
          );
          _isLoading = false;
        });
      } else {
        // Fallback placeholder questions if database is empty or generating
        _loadFallbackQuestions();
      }
    } catch (e) {
      debugPrint('Error fetching AI questions: $e');
      _loadFallbackQuestions();
    }
  }

  void _loadFallbackQuestions() {
    if (mounted) {
      setState(() {
        _aiQuestions = [
          {
            'question': 'AI GENERATED: What historical era does this monument belong to?',
            'options': [
              'Mughal Era',
              'British Colonial',
              'Gupta Empire',
              'Vedic Era',
            ],
            'answer': 1,
          },
          {
            'question': 'AI GENERATED: What primary material was used in constructing this site?',
            'options': ['Red Sandstone', 'Lakhori Bricks', 'Granite', 'Marble'],
            'answer': 1,
          },
        ];
        _isLoading = false;
      });
    }
  }

  void _answerQuestion(int selectedIndex) {
    if (selectedIndex == _aiQuestions[_currentQuestionIndex]['answer']) {
      _score++;
    }

    if (_currentQuestionIndex < _aiQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showDiscountCoupon();
    }
  }

  void _showDiscountCoupon() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuestCompletionHelper.creamBg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: QuestCompletionHelper.oceanBlue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'CONGRATULATIONS!',
          style: GoogleFonts.pressStart2p(
            fontSize: 12,
            color: QuestCompletionHelper.tealGreen,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard,
              color: QuestCompletionHelper.oceanBlue,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'AI Quiz Completed!\nScore: $_score/${_aiQuestions.length}',
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: QuestCompletionHelper.sunnyYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: QuestCompletionHelper.oceanBlue,
                  width: 2,
                ),
              ),
              child: SelectableText(
                'COUPON: QUEST2026',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: QuestCompletionHelper.oceanBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use code for 20% OFF!',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to map
            },
            child: Text(
              'CLAIM & CLOSE',
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: QuestCompletionHelper.oceanBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestCompletionHelper.creamBg,
      appBar: AppBar(
        backgroundColor: QuestCompletionHelper.oceanBlue,
        title: Text(
          'AI HERITAGE QUIZ',
          style: GoogleFonts.pressStart2p(fontSize: 11, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: QuestCompletionHelper.tealGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Generating AI Quiz...',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: QuestCompletionHelper.oceanBlue,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_aiQuestions.length}',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: QuestCompletionHelper.tealGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _aiQuestions[_currentQuestionIndex]['question'],
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...(_aiQuestions[_currentQuestionIndex]['options']
                          as List<String>)
                      .asMap()
                      .entries
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: QuestCompletionHelper.oceanBlue,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _answerQuestion(entry.key),
                            child: Text(
                              entry.value,
                              style: GoogleFonts.pressStart2p(
                                fontSize: 8,
                                color: QuestCompletionHelper.oceanBlue,
                              ),
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
  });
}
