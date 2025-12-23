import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String quizId;
  final String courseId;
  final String videoId; // Quiz after watching a video
  final String title;
  final List<QuizQuestion> questions;
  final int passingScore; // Percentage needed to pass (e.g., 70)
  final DateTime createdAt;

  QuizModel({
    required this.quizId,
    required this.courseId,
    required this.videoId,
    required this.title,
    required this.questions,
    this.passingScore = 70,
    required this.createdAt,
  });

  int get totalQuestions => questions.length;
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'courseId': courseId,
      'videoId': videoId,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'passingScore': passingScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quizId'] as String,
      courseId: json['courseId'] as String,
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      passingScore: json['passingScore'] as int? ?? 70,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class QuizQuestion {
  final String questionId;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final int points;
  final String? explanation; // Optional explanation after answering

  QuizQuestion({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.points = 10,
    this.explanation,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'points': points,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionId: json['questionId'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctOptionIndex: json['correctOptionIndex'] as int,
      points: json['points'] as int? ?? 10,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizResult {
  final String resultId;
  final String userId;
  final String quizId;
  final int score;
  final int totalPoints;
  final List<QuizAnswer> answers;
  final DateTime completedAt;
  final bool passed;

  QuizResult({
    required this.resultId,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.totalPoints,
    required this.answers,
    required this.completedAt,
    required this.passed,
  });

  double get percentage => (score / totalPoints) * 100;

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'userId': userId,
      'quizId': quizId,
      'score': score,
      'totalPoints': totalPoints,
      'answers': answers.map((a) => a.toJson()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'passed': passed,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      resultId: json['resultId'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      score: json['score'] as int,
      totalPoints: json['totalPoints'] as int,
      answers: (json['answers'] as List)
          .map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      completedAt: QuizModel._parseDate(json['completedAt']),
      passed: json['passed'] as bool,
    );
  }
}

class QuizAnswer {
  final String questionId;
  final int selectedOptionIndex;
  final bool isCorrect;

  QuizAnswer({
    required this.questionId,
    required this.selectedOptionIndex,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionIndex': selectedOptionIndex,
      'isCorrect': isCorrect,
    };
  }

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'] as String,
      selectedOptionIndex: json['selectedOptionIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
    );
  }
}
