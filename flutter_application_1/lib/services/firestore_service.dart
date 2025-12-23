import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';
import '../models/progress_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== COURSES ====================

  // ==================== COURSES ====================

  /// Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching courses: $e');
      throw e; // Rethrow to let provider handle it
    }
  }

  /// Create a new course
  Future<void> createCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.courseId)
          .set(course.toJson());

      // Also add the videos to the subcollection
      final batch = _firestore.batch();
      for (var video in course.videos) {
        final videoRef = _firestore
            .collection('courses')
            .doc(course.courseId)
            .collection('videos')
            .doc(video.videoId);
        batch.set(videoRef, video.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('Error creating course: $e');
      throw e;
    }
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (!doc.exists) return null;

      // Get videos subcollection
      final videosSnapshot = await doc.reference
          .collection('videos')
          .orderBy('order')
          .get();
      final videos = videosSnapshot.docs
          .map(
            (vDoc) => VideoModel.fromJson({...vDoc.data(), 'videoId': vDoc.id}),
          )
          .toList();

      return CourseModel.fromJson({
        ...doc.data()!,
        'courseId': doc.id,
        'videos': videos.map((v) => v.toJson()).toList(),
      });
    } catch (e) {
      print('Error fetching course: $e');
      throw e;
    }
  }

  /// Get courses by category
  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    try {
      if (category == 'All') return getAllCourses();

      final snapshot = await _firestore
          .collection('courses')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching courses by category: $e');
      throw e;
    }
  }

  /// Search courses
  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      final lowerQuery = query.toLowerCase();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final title = (data['title'] as String? ?? '').toLowerCase();
            final description = (data['description'] as String? ?? '')
                .toLowerCase();
            final instructor = (data['instructorName'] as String? ?? '')
                .toLowerCase();
            final tags = List<String>.from(data['tags'] ?? []);

            return title.contains(lowerQuery) ||
                description.contains(lowerQuery) ||
                instructor.contains(lowerQuery) ||
                tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          })
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error searching courses: $e');
      throw e;
    }
  }

  /// Get featured courses (top rated)
  Future<List<CourseModel>> getFeaturedCourses({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching featured courses: $e');
      throw e;
    }
  }

  /// Get recent courses
  Future<List<CourseModel>> getRecentCourses({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching recent courses: $e');
      throw e;
    }
  }

  /// Get popular courses (most enrolled)
  Future<List<CourseModel>> getPopularCourses({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('enrolledCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching popular courses: $e');
      throw e;
    }
  }

  // ==================== QUIZZES ====================

  /// Get quiz for a video
  Future<QuizModel?> getQuizForVideo(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('videoId', isEqualTo: videoId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return QuizModel.fromJson({...doc.data(), 'quizId': doc.id});
    } catch (e) {
      print('Error fetching quiz for video: $e');
      return null;
    }
  }

  /// Get all quizzes for a course
  Future<List<QuizModel>> getQuizzesForCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs
          .map((doc) => QuizModel.fromJson({...doc.data(), 'quizId': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching quizzes for course: $e');
      return [];
    }
  }

  // ==================== PROGRESS ====================

  /// Get user progress for a course
  Future<ProgressModel?> getProgress(String userId, String courseId) async {
    try {
      final doc = await _firestore
          .collection('progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .get();

      if (!doc.exists) {
        // Create default progress
        return ProgressModel(
          userId: userId,
          courseId: courseId,
          lastAccessed: DateTime.now(),
        );
      }

      final data = doc.data()!;
      return ProgressModel(
        userId: userId,
        courseId: courseId,
        completedVideoIds: List<String>.from(data['completedVideoIds'] ?? []),
        quizScores: Map<String, int>.from(data['quizScores'] ?? {}),
        isCertificateUnlocked: data['isCertificateUnlocked'] ?? false,
        lastAccessed: (data['lastAccessed'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Error fetching progress: $e');
      return ProgressModel(
        userId: userId,
        courseId: courseId,
        lastAccessed: DateTime.now(),
      );
    }
  }

  /// Mark video as completed
  Future<void> markVideoCompleted(
    String userId,
    String courseId,
    String videoId,
  ) async {
    try {
      final docRef = _firestore
          .collection('progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        List<String> completedVideos = [];
        if (snapshot.exists) {
          completedVideos = List<String>.from(
            snapshot.data()?['completedVideoIds'] ?? [],
          );
        }

        if (!completedVideos.contains(videoId)) {
          completedVideos.add(videoId);
        }

        transaction.set(docRef, {
          'completedVideoIds': completedVideos,
          'lastAccessed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error marking video completed: $e');
    }
  }

  /// Save quiz score
  Future<void> saveQuizScore(
    String userId,
    String courseId,
    String quizId,
    int score,
  ) async {
    try {
      final docRef = _firestore
          .collection('progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        Map<String, int> quizScores = {};
        if (snapshot.exists) {
          final data = snapshot.data()?['quizScores'];
          if (data != null) {
            quizScores = Map<String, int>.from(data);
          }
        }

        // Only update if new score is higher
        if (!quizScores.containsKey(quizId) || score > quizScores[quizId]!) {
          quizScores[quizId] = score;
        }

        transaction.set(docRef, {
          'quizScores': quizScores,
          'lastAccessed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error saving quiz score: $e');
    }
  }

  /// Update certificate unlock status
  Future<void> updateCertificateStatus(
    String userId,
    String courseId,
    bool isUnlocked,
  ) async {
    try {
      await _firestore
          .collection('progress')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .set({
            'isCertificateUnlocked': isUnlocked,
            'lastAccessed': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating certificate status: $e');
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all unique categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((category) => category != null)
          .cast<String>()
          .toSet()
          .toList();
      categories.insert(0, 'All');
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return ['All'];
    }
  }

  // ==================== PURCHASES ====================

  /// Record a course purchase
  Future<void> purchaseCourse(
    String userId,
    String courseId, {
    String? transactionHash,
  }) async {
    try {
      await _firestore.collection('purchases').doc('${userId}_$courseId').set({
        'userId': userId,
        'courseId': courseId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'transactionHash': transactionHash,
      });

      // Increment enrolled count on the course
      await _firestore.collection('courses').doc(courseId).update({
        'enrolledCount': FieldValue.increment(1),
      });

      print('Purchase recorded: $userId bought $courseId');
    } catch (e) {
      print('Error recording purchase: $e');
    }
  }

  /// Check if user has purchased a course
  Future<bool> hasPurchasedCourse(String userId, String courseId) async {
    try {
      final doc = await _firestore
          .collection('purchases')
          .doc('${userId}_$courseId')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking purchase: $e');
      return false;
    }
  }

  /// Get all courses purchased by a user
  Future<List<String>> getPurchasedCourseIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();
    } catch (e) {
      print('Error fetching purchased courses: $e');
      return [];
    }
  }

  // ==================== COURSE MANAGEMENT (INSTRUCTOR) ====================

  /// Delete a course (instructor only)
  Future<void> deleteCourse(String courseId) async {
    try {
      // Delete all videos subcollection first
      final videosSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('videos')
          .get();

      final batch = _firestore.batch();
      for (var doc in videosSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the course document
      batch.delete(_firestore.collection('courses').doc(courseId));

      await batch.commit();
      print('Course deleted: $courseId');
    } catch (e) {
      print('Error deleting course: $e');
      throw e;
    }
  }

  /// Update a course (instructor only)
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.courseId)
          .update(course.toJson());
      print('Course updated: ${course.courseId}');
    } catch (e) {
      print('Error updating course: $e');
      throw e;
    }
  }

  /// Get courses by instructor ID
  Future<List<CourseModel>> getCoursesByInstructor(String instructorId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('instructorId', isEqualTo: instructorId)
          .get();

      return snapshot.docs
          .map(
            (doc) => CourseModel.fromJson({...doc.data(), 'courseId': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error fetching instructor courses: $e');
      return [];
    }
  }

  /// Get completed courses with certificates for a user
  Future<List<Map<String, dynamic>>> getCompletedCoursesWithCertificates(
    String userId,
  ) async {
    try {
      // Get all user progress from the 'progress' collection
      final progressSnapshot = await _firestore
          .collection('progress')
          .doc(userId)
          .collection('courses')
          .get();

      final completedCourses = <Map<String, dynamic>>[];

      for (var doc in progressSnapshot.docs) {
        final courseId = doc.id;
        final progress = doc.data();
        final completedVideoIds = List<String>.from(
          progress['completedVideoIds'] ?? [],
        );

        // Get the course details to check total videos
        final courseDoc = await _firestore
            .collection('courses')
            .doc(courseId)
            .get();

        if (courseDoc.exists) {
          final courseData = courseDoc.data()!;

          // Get video count from course
          final videosSnapshot = await courseDoc.reference
              .collection('videos')
              .get();
          final totalVideos = videosSnapshot.docs.length;

          // Check if all videos are completed (course finished)
          if (totalVideos > 0 && completedVideoIds.length >= totalVideos) {
            completedCourses.add({
              'courseId': courseId,
              'courseTitle': courseData['title'] ?? 'Unknown Course',
              'instructorName': courseData['instructorName'] ?? 'Unknown',
              'completedAt': progress['lastAccessed'],
              'thumbnailUrl': courseData['thumbnailUrl'],
            });
          }
        }
      }

      return completedCourses;
    } catch (e) {
      print('Error fetching completed courses: $e');
      return [];
    }
  }
}
