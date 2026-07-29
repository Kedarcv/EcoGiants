import 'dart:convert';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/services/api_service.dart';
import 'package:deep_waste/services/nvidia_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonQuizScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final String lessonTopic;
  final int xpReward;

  const LessonQuizScreen({
    Key? key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonTopic,
    required this.xpReward,
  }) : super(key: key);

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  final NvidiaChatService _chatService = NvidiaChatService();
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isAnswering = false;
  String? _selectedAnswer;
  bool? _isCorrect;
  String _feedback = '';
  bool _quizComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prompt = '''You are a quiz generator for an eco-education app. Generate exactly 5 unique multiple-choice quiz questions about "${widget.lessonTopic}" for waste management education in Zimbabwe.

IMPORTANT: Return ONLY a valid JSON array. No markdown, no code fences, no explanation text before or after.

Each question must have exactly these 4 fields:
- "question": the question text (clear, concise)
- "options": array of exactly 4 answer strings
- "correctIndex": 0-based index of the correct answer
- "explanation": 1-2 sentence explanation

Create questions that test:
1. Basic definition/knowledge
2. Real-world application scenario
3. Common misconception
4. Advanced/tricky case
5. Practical action step

The questions should be specific to Zimbabwe context where possible (e.g., mention local bins, Harare, ZOU campus).

Example valid output:
[{"question":"What bin does plastic go in?","options":["Black bin","Blue bin","Green bin","Red bin"],"correctIndex":1,"explanation":"Blue bins are for recyclable materials like plastic, paper, and glass."}]

Return ONLY the JSON array, nothing else.''';

    try {
      final response = await _chatService.sendMessageSync(prompt);
      debugPrint('NVIDIA response: ${response.substring(0, response.length > 200 ? 200 : response.length)}...');
      final parsed = _parseQuestionsResponse(response);
      
      if (parsed != null && parsed.length >= 3) {
        setState(() {
          _questions = parsed;
          _isLoading = false;
        });
      } else {
        debugPrint('Parse failed, raw response: $response');
        // Try again with a simpler prompt
        await _retryWithSimplerPrompt();
      }
    } catch (e) {
      debugPrint('Error generating questions: $e');
      _showError('Failed to generate questions: $e');
    }
  }

  Future<void> _retryWithSimplerPrompt() async {
    final retryPrompt = '''Generate 5 quiz questions about ${widget.lessonTopic} waste management.

Return a JSON array like this:
[{"question":"Question text?","options":["A","B","C","D"],"correctIndex":0,"explanation":"Why this is correct."}]

Make questions about: definitions, proper disposal methods, environmental impact, common mistakes, and best practices.

Return ONLY the JSON array.''';

    try {
      final response = await _chatService.sendMessageSync(retryPrompt);
      final parsed = _parseQuestionsResponse(response);
      
      if (parsed != null && parsed.length >= 3) {
        setState(() {
          _questions = parsed;
          _isLoading = false;
        });
      } else {
        _showError('Unable to generate questions. Please try again.');
      }
    } catch (e) {
      _showError('Network error. Please check your connection and try again.');
    }
  }

  List<Map<String, dynamic>>? _parseQuestionsResponse(String response) {
    try {
      String jsonStr = response.trim();
      
      // Remove markdown code fences
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Find JSON array
      final startIndex = jsonStr.indexOf('[');
      final endIndex = jsonStr.lastIndexOf(']');
      
      if (startIndex == -1 || endIndex == -1) return null;
      
      jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      
      final List<dynamic> parsed = jsonDecode(jsonStr);
      
      // Validate each question
      final validQuestions = <Map<String, dynamic>>[];
      for (var q in parsed) {
        if (q is Map<String, dynamic> &&
            q.containsKey('question') &&
            q.containsKey('options') &&
            q.containsKey('correctIndex') &&
            q.containsKey('explanation')) {
          final options = q['options'];
          if (options is List && options.length == 4) {
            validQuestions.add(Map<String, dynamic>.from(q));
          }
        }
      }
      
      return validQuestions.length >= 3 ? validQuestions : null;
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _selectAnswer(String answer, int index) {
    if (_isAnswering) return;
    
    setState(() {
      _selectedAnswer = answer;
      _isAnswering = true;
      
      final correctIndex = _questions[_currentQuestionIndex]['correctIndex'] as int;
      _isCorrect = index == correctIndex;
      
      if (_isCorrect!) {
        _score++;
        _feedback = 'Correct! ${_questions[_currentQuestionIndex]['explanation']}';
      } else {
        final correctAnswer = _questions[_currentQuestionIndex]['options'][correctIndex];
        _feedback = 'The correct answer is "$correctAnswer". ${_questions[_currentQuestionIndex]['explanation']}';
      }
      
      HapticFeedback.mediumImpact();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswering = false;
        _isCorrect = null;
        _feedback = '';
      });
    } else {
      setState(() => _quizComplete = true);
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    try {
      final user = await DatabaseManager.instance.getUser();
      if (user == null) return;

      final percentage = _score / _questions.length;
      int xpEarned = 0;
      if (percentage >= 0.8) {
        xpEarned = widget.xpReward;
      } else if (percentage >= 0.6) {
        xpEarned = (widget.xpReward * 0.6).toInt();
      } else if (percentage >= 0.4) {
        xpEarned = (widget.xpReward * 0.3).toInt();
      }

      if (xpEarned > 0) {
        // Update local DB
        final updatedUser = user.copyWith(
          totalPoints: user.totalPoints + xpEarned,
          ecoLevel: User.calculateLevel(user.totalPoints + xpEarned),
        );
        await DatabaseManager.instance.updateUser(updatedUser);
        await DatabaseManager.instance.updateRealUserInLeaderboard(updatedUser);

        // Submit to backend
        final prefs = await SharedPreferences.getInstance();
        final studentNumber = prefs.getString('student_number') ?? '';
        if (studentNumber.isNotEmpty) {
          await ApiService.instance.submitQuiz(
            studentNumber: studentNumber,
            lessonTopic: widget.lessonTopic,
            score: _score,
            totalQuestions: _questions.length,
            pointsEarned: xpEarned,
          );
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: Text(widget.lessonTitle),
        elevation: 0,
        actions: [
          if (!_isLoading && !_quizComplete && _questions.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_score/${_questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _quizComplete
                  ? _buildResults()
                  : _buildQuestion(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(color: Color(0xFF0D9488)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating Quiz Questions...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'EcoBot is creating questions about ${widget.lessonTopic}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Powered by ZOU\'s AI engine for educational content.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateQuestions,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    
    final question = _questions[_currentQuestionIndex];
    final options = (question['options'] as List).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question['question'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Options
          ...List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = _selectedAnswer == option;
            final isCorrectOption = index == (question['correctIndex'] as int);
            
            Color bgColor = Colors.white;
            Color borderColor = Colors.grey.shade200;
            Color textColor = const Color(0xFF1F2937);

            if (_isAnswering) {
              if (isSelected && _isCorrect == true) {
                bgColor = const Color(0xFFECFDF5);
                borderColor = const Color(0xFF10B981);
                textColor = const Color(0xFF065F46);
              } else if (isSelected && _isCorrect == false) {
                bgColor = const Color(0xFFFEF2F2);
                borderColor = const Color(0xFFEF4444);
                textColor = const Color(0xFF991B1B);
              } else if (isCorrectOption && _isCorrect == false) {
                bgColor = const Color(0xFFECFDF5);
                borderColor = const Color(0xFF10B981);
              }
            }

            return GestureDetector(
              onTap: _isAnswering ? null : () => _selectAnswer(option, index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isAnswering
                            ? (isSelected
                                ? (_isCorrect! ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                : (isCorrectOption ? const Color(0xFF10B981) : Colors.grey.shade200))
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isAnswering && isSelected
                            ? Icon(
                                _isCorrect! ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 18,
                              )
                            : _isAnswering && isCorrectOption && !_isCorrect!
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _isAnswering
                                          ? (isSelected
                                              ? Colors.white
                                              : (isCorrectOption ? Colors.white : Colors.grey.shade600))
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Feedback
          if (_isAnswering) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect! ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect! ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCorrect! ? Icons.check_circle : Icons.lightbulb,
                    color: _isCorrect! ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _feedback,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isCorrect! ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final percentage = (_score / _questions.length * 100).toInt();
    final xpEarned = percentage >= 80
        ? widget.xpReward
        : percentage >= 60
            ? (widget.xpReward * 0.6).toInt()
            : percentage >= 40
                ? (widget.xpReward * 0.3).toInt()
                : 0;

    String grade;
    Color gradeColor;
    IconData gradeIcon;

    if (percentage >= 90) {
      grade = 'Excellent!';
      gradeColor = const Color(0xFF10B981);
      gradeIcon = Icons.emoji_events;
    } else if (percentage >= 70) {
      grade = 'Great Job!';
      gradeColor = const Color(0xFF3B82F6);
      gradeIcon = Icons.thumb_up;
    } else if (percentage >= 50) {
      grade = 'Good Effort!';
      gradeColor = const Color(0xFFF59E0B);
      gradeIcon = Icons.sentiment_satisfied;
    } else {
      grade = 'Keep Learning!';
      gradeColor = const Color(0xFFEF4444);
      gradeIcon = Icons.school;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(gradeIcon, size: 64, color: gradeColor),
            ),
            const SizedBox(height: 24),
            Text(
              grade,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: gradeColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat('Score', '$_score/${_questions.length}', const Color(0xFF3B82F6)),
                  _buildResultStat('Accuracy', '$percentage%', gradeColor),
                  _buildResultStat('XP Earned', '+$xpEarned', const Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (xpEarned > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'POINTS EARNED',
                      style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$xpEarned XP',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score at least 40% to earn XP. Try again!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex = 0;
                        _score = 0;
                        _selectedAnswer = null;
                        _isAnswering = false;
                        _isCorrect = null;
                        _feedback = '';
                        _quizComplete = false;
                        _questions = [];
                      });
                      _generateQuestions();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('New Quiz', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
