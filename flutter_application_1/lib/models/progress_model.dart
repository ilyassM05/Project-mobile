class ProgressModel {
  final String userId;
  final String courseId;
  final List<String> completedVideoIds;
  final Map<String, int> quizScores; // quizId -> score
  final bool isCertificateUnlocked;
  final DateTime lastAccessed;

  ProgressModel({
    required this.userId,
    required this.courseId,
    this.completedVideoIds = const [],
    this.quizScores = const {},
    this.isCertificateUnlocked = false,
    required this.lastAccessed,
  });

  ProgressModel copyWith({
    String? userId,
    String? courseId,
    List<String>? completedVideoIds,
    Map<String, int>? quizScores,
    bool? isCertificateUnlocked,
    DateTime? lastAccessed,
  }) {
    return ProgressModel(
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      completedVideoIds: completedVideoIds ?? this.completedVideoIds,
      quizScores: quizScores ?? this.quizScores,
      isCertificateUnlocked:
          isCertificateUnlocked ?? this.isCertificateUnlocked,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}
