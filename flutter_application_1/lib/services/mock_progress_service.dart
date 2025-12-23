import '../models/progress_model.dart';
import '../models/course_model.dart';
import 'mock_data_service.dart';

class MockProgressService {
  // In-memory storage for progress: userId_courseId -> ProgressModel
  static final Map<String, ProgressModel> _progressStore = {};

  // Get progress for a course
  static ProgressModel getProgress(String userId, String courseId) {
    final key = '${userId}_$courseId';
    if (!_progressStore.containsKey(key)) {
      _progressStore[key] = ProgressModel(
        userId: userId,
        courseId: courseId,
        lastAccessed: DateTime.now(),
      );
    }
    return _progressStore[key]!;
  }

  // Mark video as completed
  static void markVideoCompleted(
    String userId,
    String courseId,
    String videoId,
  ) {
    final progress = getProgress(userId, courseId);
    if (!progress.completedVideoIds.contains(videoId)) {
      final updatedVideos = List<String>.from(progress.completedVideoIds)
        ..add(videoId);

      _progressStore['${userId}_$courseId'] = progress.copyWith(
        completedVideoIds: updatedVideos,
        lastAccessed: DateTime.now(),
      );

      _checkCertificateUnlock(userId, courseId);
    }
  }

  // Save quiz score
  static void saveQuizScore(
    String userId,
    String courseId,
    String quizId,
    int score,
  ) {
    final progress = getProgress(userId, courseId);
    final updatedScores = Map<String, int>.from(progress.quizScores);

    // Only update if new score is higher
    if (!updatedScores.containsKey(quizId) || score > updatedScores[quizId]!) {
      updatedScores[quizId] = score;

      _progressStore['${userId}_$courseId'] = progress.copyWith(
        quizScores: updatedScores,
        lastAccessed: DateTime.now(),
      );

      _checkCertificateUnlock(userId, courseId);
    }
  }

  // Check if certificate should be unlocked
  static void _checkCertificateUnlock(String userId, String courseId) {
    final progress = getProgress(userId, courseId);
    final course = MockDataService.getCourseById(courseId);

    if (course == null) return;

    // Check if all videos are completed
    final allVideosCompleted = course.videos.every(
      (v) => progress.completedVideoIds.contains(v.videoId),
    );

    // Check if all quizzes are passed (if any)
    final quizzes = MockDataService.getQuizzesForCourse(courseId);
    final allQuizzesPassed = quizzes.every((q) {
      final score = progress.quizScores[q.quizId] ?? 0;
      final maxScore = q.totalPoints;
      final percentage = (score / maxScore) * 100;
      return percentage >= q.passingScore;
    });

    if (allVideosCompleted &&
        allQuizzesPassed &&
        !progress.isCertificateUnlocked) {
      _progressStore['${userId}_$courseId'] = progress.copyWith(
        isCertificateUnlocked: true,
      );
    }
  }

  // Get progress percentage (0.0 to 1.0)
  static double getProgressPercentage(String userId, String courseId) {
    final progress = getProgress(userId, courseId);
    final course = MockDataService.getCourseById(courseId);

    if (course == null || course.videos.isEmpty) return 0.0;

    final quizzes = MockDataService.getQuizzesForCourse(courseId);
    final totalItems = course.videos.length + quizzes.length;

    if (totalItems == 0) return 0.0;

    int completedItems = progress.completedVideoIds.length;

    // Count passed quizzes
    for (var quiz in quizzes) {
      final score = progress.quizScores[quiz.quizId] ?? 0;
      final maxScore = quiz.totalPoints;
      if (maxScore > 0 && (score / maxScore) * 100 >= quiz.passingScore) {
        completedItems++;
      }
    }

    return (completedItems / totalItems).clamp(0.0, 1.0);
  }
}
