// =============================================================================
// COURSE PROVIDER - Manages Course Data State
// =============================================================================
// WHAT IS THIS FILE?
// This is a "Provider" that handles all course-related data.
// It fetches courses from Firebase and makes them available to all widgets.
//
// WHY DO WE NEED THIS?
// - Caches course data (don't need to fetch from database every time)
// - Shares course list across all screens
// - Handles filtering, searching, and categorizing courses
//
// KEY CONCEPTS:
// - Firestore: Firebase's NoSQL database (stores our courses)
// - notifyListeners(): Tells widgets to rebuild with new data
// =============================================================================

import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';

class CourseProvider with ChangeNotifier {
  // Service that talks to Firebase Firestore database
  final FirestoreService _firestoreService = FirestoreService();

  // ---------------------------------------------------------------------------
  // STATE VARIABLES - Course data we store
  // ---------------------------------------------------------------------------
  List<CourseModel> _allCourses = []; // All courses in database
  List<CourseModel> _featuredCourses = []; // Highlighted/promoted courses
  List<CourseModel> _recentCourses = []; // Recently added courses
  List<CourseModel> _popularCourses = []; // Courses with most enrollments
  List<String> _categories = ['All']; // List of categories (e.g., "Web Dev")

  bool _isLoading = false; // Are we fetching data?
  String? _errorMessage; // Error message to display

  // ---------------------------------------------------------------------------
  // GETTERS - Allow widgets to read our data
  // ---------------------------------------------------------------------------
  List<CourseModel> get allCourses => _allCourses;
  List<CourseModel> get featuredCourses => _featuredCourses;
  List<CourseModel> get recentCourses => _recentCourses;
  List<CourseModel> get popularCourses => _popularCourses;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // LOAD ALL COURSES - Fetch every course from database
  // ---------------------------------------------------------------------------
  Future<void> loadAllCourses() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners(); // Show loading spinner

      // Query Firestore database for all courses
      _allCourses = await _firestoreService.getAllCourses();

      _isLoading = false;
      notifyListeners(); // Update UI with courses
    } catch (e) {
      _errorMessage = 'Failed to load courses: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD FEATURED COURSES - Get highlighted courses for home screen
  // ---------------------------------------------------------------------------
  Future<void> loadFeaturedCourses({int limit = 3}) async {
    try {
      _featuredCourses = await _firestoreService.getFeaturedCourses(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading featured courses: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD RECENT COURSES - Get newest courses
  // ---------------------------------------------------------------------------
  Future<void> loadRecentCourses({int limit = 3}) async {
    try {
      _recentCourses = await _firestoreService.getRecentCourses(limit: limit);
      notifyListeners();
    } catch (e) {
      print('Error loading recent courses: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD POPULAR COURSES - Get courses with most students
  // ---------------------------------------------------------------------------
  Future<void> loadPopularCourses({int limit = 5}) async {
    try {
      _popularCourses = await _firestoreService.getPopularCourses(limit: limit);
      notifyListeners();
    } catch (e) {
      print('Error loading popular courses: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD CATEGORIES - Get list of all course categories
  // ---------------------------------------------------------------------------
  Future<void> loadCategories() async {
    try {
      _categories = await _firestoreService.getCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // GET COURSE BY ID - Fetch a specific course
  // ---------------------------------------------------------------------------
  // First checks cache (already loaded courses), then fetches from database
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      // Check if we already have this course in memory (cache)
      final cached = _allCourses.firstWhere(
        (course) => course.courseId == courseId,
        orElse: () => CourseModel(
          courseId: '',
          title: '',
          description: '',
          instructorId: '',
          instructorName: '',
          thumbnailUrl: '',
          category: '',
          tags: [],
          priceETH: 0,
          rating: 0,
          enrolledCount: 0,
          totalDuration: 0,
          level: '',
          videos: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (cached.courseId.isNotEmpty) return cached;

      // Not in cache - fetch from Firestore database
      return await _firestoreService.getCourseById(courseId);
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH COURSES - Find courses matching search query
  // ---------------------------------------------------------------------------
  Future<List<CourseModel>> searchCourses(String query) async {
    try {
      if (query.isEmpty) return _allCourses; // Empty query = show all
      return await _firestoreService.searchCourses(query);
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // GET COURSES BY CATEGORY - Filter courses by category
  // ---------------------------------------------------------------------------
  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    try {
      if (category == 'All') return _allCourses; // "All" = no filter
      return await _firestoreService.getCoursesByCategory(category);
    } catch (e) {
      print('Error getting courses by category: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // INITIALIZE - Load all data when app starts
  // ---------------------------------------------------------------------------
  // Future.wait() runs all these in parallel (faster!)
  Future<void> initialize() async {
    await Future.wait([
      loadAllCourses(),
      loadFeaturedCourses(),
      loadRecentCourses(),
      loadCategories(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // CLEAR ERROR - Remove error message
  // ---------------------------------------------------------------------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
