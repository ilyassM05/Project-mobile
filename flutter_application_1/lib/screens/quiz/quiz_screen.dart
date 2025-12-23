import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/mock_progress_service.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  final List<int?> _selectedAnswers = [];
  bool _isAnswered = false;
  bool _showResults = false;
  int _score = 0;
  final String _userId = 'current_user'; // Mock user ID

  @override
  void initState() {
    super.initState();
    // Initialize selected answers list
    _selectedAnswers.addAll(List.filled(widget.quiz.questions.length, null));
  }

  void _selectAnswer(int optionIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
      _isAnswered = true;

      // Check if answer is correct and update score
      if (widget.quiz.questions[_currentQuestionIndex].isCorrect(optionIndex)) {
        _score += widget.quiz.questions[_currentQuestionIndex].points;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = _selectedAnswers[_currentQuestionIndex] != null;
      });
    } else {
      // Save quiz score when finishing
      MockProgressService.saveQuizScore(
        _userId,
        widget.quiz.courseId,
        widget.quiz.quizId,
        _score,
      );

      setState(() {
        _showResults = true;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _isAnswered = _selectedAnswers[_currentQuestionIndex] != null;
      });
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _selectedAnswers.addAll(List.filled(widget.quiz.questions.length, null));
      _isAnswered = false;
      _showResults = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          if (!_showResults)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: _showResults ? _buildResults() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppTheme.primaryColor,
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question
                Card(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Text(
                      question.question,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Options
                ...List.generate(question.options.length, (index) {
                  final isSelected = selectedAnswer == index;
                  final isCorrect = question.correctOptionIndex == index;
                  final showCorrect = _isAnswered && isCorrect;
                  final showWrong = _isAnswered && isSelected && !isCorrect;

                  Color? backgroundColor;
                  Color? borderColor;
                  IconData? icon;

                  if (showCorrect) {
                    backgroundColor = AppTheme.successColor.withOpacity(0.1);
                    borderColor = AppTheme.successColor;
                    icon = Icons.check_circle;
                  } else if (showWrong) {
                    backgroundColor = AppTheme.errorColor.withOpacity(0.1);
                    borderColor = AppTheme.errorColor;
                    icon = Icons.cancel;
                  } else if (isSelected) {
                    backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
                    borderColor = AppTheme.primaryColor;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(
                            color: borderColor ?? Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  borderColor?.withOpacity(0.2) ??
                                  Colors.grey[200],
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: borderColor ?? AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (icon != null) Icon(icon, color: borderColor),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Explanation
                if (_isAnswered && question.explanation != null) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  Card(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb,
                                color: AppTheme.infoColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explanation',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppTheme.infoColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0)
                const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAnswered ? _nextQuestion : null,
                  child: Text(
                    _currentQuestionIndex < widget.quiz.questions.length - 1
                        ? 'Next'
                        : 'Finish',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final percentage = (_score / widget.quiz.totalPoints) * 100;
    final passed = percentage >= widget.quiz.passingScore;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.celebration : Icons.sentiment_dissatisfied,
              size: 100,
              color: passed ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              passed ? 'Congratulations!' : 'Keep Learning!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: passed ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              passed
                  ? 'You passed the quiz!'
                  : 'You didn\'t pass this time, but don\'t give up!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      '$_score / ${widget.quiz.totalPoints}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: passed
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        passed ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Video'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _retakeQuiz,
                    child: const Text('Retake Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
