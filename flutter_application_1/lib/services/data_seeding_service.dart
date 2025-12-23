import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/quiz_model.dart';
import 'mock_data_service.dart';
import 'auth_service.dart';
import '../config/app_constants.dart';

/// Service to seed initial data to Firestore from mock data
/// Run this once to populate your Firebase database
class DataSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Seed all courses and quizzes to Firestore
  Future<void> seedAllData() async {
    print('🌱 Starting data seeding...');

    try {
      // Seed Instructor Account
      await _seedInstructorAccount();

      // Get mock data
      final courses = MockDataService.getAllCourses();
      final quizzes = MockDataService.mockQuizzes;

      // Seed courses
      await _seedCourses(courses);

      // Seed quizzes
      await _seedQuizzes(quizzes);

      print('✅ Data seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding data: $e');
    }
  }

  /// Seed courses to Firestore
  Future<void> _seedCourses(List<CourseModel> courses) async {
    print('📚 Seeding ${courses.length} courses...');

    for (var course in courses) {
      try {
        // Prepare course data (without videos)
        final courseData = {
          'title': course.title,
          'description': course.description,
          'instructorId': course.instructorId,
          'instructorName': course.instructorName,
          'priceETH': course.priceETH,
          'category': course.category,
          'tags': course.tags,
          'thumbnailUrl': course.thumbnailUrl,
          'totalDuration': course.totalDuration,
          'studentsCount': course.studentsCount,
          'rating': course.rating,
          'enrolledCount': course.enrolledCount,
          'level': course.level,
          'createdAt': Timestamp.fromDate(course.createdAt),
          'updatedAt': course.updatedAt != null
              ? Timestamp.fromDate(course.updatedAt!)
              : null,
        };

        // Create course document
        final courseRef = _firestore.collection('courses').doc(course.courseId);
        await courseRef.set(courseData);

        // Add videos as subcollection
        for (var video in course.videos) {
          await courseRef.collection('videos').doc(video.videoId).set({
            'title': video.title,
            'description': video.description,
            'url': video.url,
            'thumbnailUrl': video.thumbnailUrl,
            'duration': video.duration,
            'order': video.order,
          });
        }

        print('  ✓ Seeded course: ${course.title}');
      } catch (e) {
        print('  ✗ Error seeding course ${course.title}: $e');
      }
    }
  }

  /// Seed quizzes to Firestore
  Future<void> _seedQuizzes(List<QuizModel> quizzes) async {
    print('📝 Seeding ${quizzes.length} quizzes...');

    for (var quiz in quizzes) {
      try {
        await _firestore.collection('quizzes').doc(quiz.quizId).set({
          'courseId': quiz.courseId,
          'videoId': quiz.videoId,
          'title': quiz.title,
          'passingScore': quiz.passingScore,
          'questions': quiz.questions
              .map(
                (q) => {
                  'questionId': q.questionId,
                  'question': q.question,
                  'options': q.options,
                  'correctOptionIndex': q.correctOptionIndex,
                  'points': q.points,
                  'explanation': q.explanation,
                },
              )
              .toList(),
          'createdAt': Timestamp.fromDate(quiz.createdAt),
        });

        print('  ✓ Seeded quiz: ${quiz.title}');
      } catch (e) {
        print('  ✗ Error seeding quiz ${quiz.title}: $e');
      }
    }
  }

  /// Clear all data from Firestore
  Future<void> clearAllData() async {
    print('🗑️  Clearing all data...');

    try {
      // Delete all courses
      final coursesSnapshot = await _firestore.collection('courses').get();
      for (var doc in coursesSnapshot.docs) {
        // Delete videos subcollection
        final videosSnapshot = await doc.reference.collection('videos').get();
        for (var videoDoc in videosSnapshot.docs) {
          await videoDoc.reference.delete();
        }
        // Delete course
        await doc.reference.delete();
      }

      // Delete all quizzes
      final quizzesSnapshot = await _firestore.collection('quizzes').get();
      for (var doc in quizzesSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }

  /// Seed the instructor accounts (given by school/university)
  Future<void> _seedInstructorAccount() async {
    print('👨‍🏫 Seeding instructor accounts...');

    // List of instructors with their credentials
    final instructors = [
      {
        'email': 'ilyass.moutmir@instructor.edu',
        'password': 'instructor123',
        'name': 'Ilyass Moutmir',
      },
      {
        'email': 'adnane.raghai@instructor.edu',
        'password': 'instructor123',
        'name': 'Adnane Raghai',
      },
    ];

    for (var instructor in instructors) {
      try {
        await _authService.signUp(
          email: instructor['email']!,
          password: instructor['password']!,
          displayName: instructor['name']!,
          role: AppConstants.roleInstructor,
        );
        print(
          '  ✓ Created instructor: ${instructor['name']} (${instructor['email']})',
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('  ! ${instructor['name']} account already exists');
        } else {
          print('  ✗ Error creating ${instructor['name']}: $e');
        }
      }
    }
  }

  /// Update existing course instructor names to Moroccan names
  Future<void> updateInstructorNames() async {
    print('🌍 Updating instructor names to Moroccan names...');

    final nameMap = {
      'Sarah Johnson': 'Ilyass Moutmir',
      'Michael Chen': 'Adnane Raghai',
      'Emma Martinez': 'Fatima Zahra Benjelloun',
    };

    try {
      final snapshot = await _firestore.collection('courses').get();

      for (var doc in snapshot.docs) {
        final currentName = doc.data()['instructorName'] as String?;
        if (currentName != null && nameMap.containsKey(currentName)) {
          await doc.reference.update({'instructorName': nameMap[currentName]});
          print(
            '  ✓ Updated "${doc.data()['title']}" -> ${nameMap[currentName]}',
          );
        }
      }

      print('✅ Instructor names updated successfully!');
    } catch (e) {
      print('❌ Error updating instructor names: $e');
    }
  }
}
