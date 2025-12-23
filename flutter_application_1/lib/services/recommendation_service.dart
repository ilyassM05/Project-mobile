import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/course_model.dart';
import 'firestore_service.dart';

// =============================================================================
// RECOMMENDATION SERVICE - AI Course Recommendations in Flutter
// =============================================================================
// WHAT DOES THIS FILE DO?
// This file loads the trained MLP model and uses it to recommend courses.
//
// HOW IT WORKS:
// 1. Load the TFLite model (trained in Python, converted to mobile format)
// 2. Load course embeddings (64-number "fingerprints" for each course)
// 3. When user views a course, find similar courses using cosine similarity
// 4. Return top 5 most similar courses as recommendations
// =============================================================================

/// Course data with its embedding (64 numbers that represent the course)
/// Think of embedding as a "fingerprint" - similar courses have similar fingerprints!
class CourseSimilarityData {
  final String id; // Course ID (e.g., "javascript_fundamentals")
  final String title; // Course title (e.g., "JavaScript Fundamentals")
  final String category; // Category (e.g., "Web Development")
  final List<String> tags; // Tags (e.g., ["JavaScript", "Frontend"])
  final List<double> embedding; // 64 numbers = course "fingerprint"

  CourseSimilarityData({
    required this.id,
    required this.title,
    required this.category,
    required this.tags,
    required this.embedding,
  });

  // Convert JSON data to Dart object
  factory CourseSimilarityData.fromJson(Map<String, dynamic> json) {
    return CourseSimilarityData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      embedding: List<double>.from(
        (json['embedding'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }
}

// =============================================================================
// MAIN RECOMMENDATION SERVICE CLASS
// =============================================================================
class RecommendationService {
  // ---------------------------------------------------------------------------
  // VARIABLES TO STORE THE LOADED MODEL AND DATA
  // ---------------------------------------------------------------------------

  // The TFLite interpreter runs the neural network on mobile
  Interpreter? _interpreter;
  Map<String, int>? _userMapping;
  Map<String, int>? _courseMapping;

  // Embedding-Based MLP model components
  Interpreter? _similarityInterpreter; // Runs the MLP on mobile
  List<CourseSimilarityData>?
  _courseSimilarityData; // All courses with embeddings
  Map<String, int>? _categoryToIdx; // "Web Dev" -> 0, "Mobile" -> 1
  Map<String, int>? _tagToIdx; // "JavaScript" -> 0, "Python" -> 1
  int? _featureDim; // Input size (number of features)
  int? _embeddingDim; // Output size (64 numbers)

  final FirestoreService _firestoreService = FirestoreService();

  // Check if models are loaded
  bool get isLoaded => _interpreter != null;
  bool get isSimilarityModelLoaded => _courseSimilarityData != null;

  /// Load the user-course recommendation model
  Future<void> loadModel() async {
    try {
      // Load TFLite Model
      _interpreter = await Interpreter.fromAsset(
        'assets/model/recommendation_model.tflite',
      );
      print('Recommendation Model Loaded Successfully');

      // Load Mappings
      final jsonString = await rootBundle.loadString(
        'assets/model/label_encoders.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      // Convert dynamic maps to Map<String, int>
      _userMapping = Map<String, int>.from(data['user_mapping']);
      _courseMapping = Map<String, int>.from(data['course_mapping']);
    } catch (e) {
      print('Error loading recommendation model: $e');
      // Handle missing model gracefully (e.g., in dev mode)
    }
  }

  /// Load the Embedding-Based MLP course similarity model
  Future<void> loadCourseSimilarityModel() async {
    try {
      // Load the course similarity model
      _similarityInterpreter = await Interpreter.fromAsset(
        'assets/model/course_similarity_model.tflite',
      );
      print('Course Similarity Model Loaded Successfully');

      // Load encoders and precomputed embeddings
      final jsonString = await rootBundle.loadString(
        'assets/model/course_similarity_encoders.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      // Parse course data with embeddings
      _courseSimilarityData = (data['courses'] as List)
          .map((c) => CourseSimilarityData.fromJson(c))
          .toList();

      // Parse category and tag mappings
      _categoryToIdx = Map<String, int>.from(data['category_to_idx'] ?? {});
      _tagToIdx = Map<String, int>.from(data['tag_to_idx'] ?? {});
      _featureDim = data['feature_dim'] ?? 0;
      _embeddingDim = data['embedding_dim'] ?? 64;

      print(
        'Loaded ${_courseSimilarityData!.length} course embeddings for similarity',
      );
    } catch (e) {
      print('Error loading course similarity model: $e');
    }
  }

  /// Get user-based recommendations using MLP
  Future<List<CourseModel>> getRecommendations(String userId) async {
    if (!isLoaded || _userMapping == null || _courseMapping == null) {
      print('Model not loaded, fetching random featured courses');
      return _firestoreService.getAllCourses();
    }

    try {
      // 1. Get all courses
      final allCourses = await _firestoreService.getAllCourses();

      // 2. Prepare Inputs
      // Check if user exists in mapping, otherwise use default/fallback (e.g. 0)
      // Realistically, for new users not in training set, we should use a "generic" user embedding or fallback logic
      int userIdx = _userMapping![userId] ?? 0;

      var inputUser = <double>[];
      var inputCourse = <double>[];
      var courseIndices = <int>[];

      for (var course in allCourses) {
        // Map courseId to model index
        if (_courseMapping!.containsKey(course.courseId)) {
          int courseIdx = _courseMapping![course.courseId]!;

          inputUser.add(userIdx.toDouble());
          inputCourse.add(courseIdx.toDouble());
          courseIndices.add(allCourses.indexOf(course));
        }
      }

      if (inputCourse.isEmpty) return [];

      // 3. Run Inference
      // Input shape: [N, 1] for both user and course
      // Output shape: [N, 1] (probability)

      var outputBuffer = List.filled(
        inputCourse.length,
        0.0,
      ).reshape([inputCourse.length, 1]);

      _interpreter!.runForMultipleInputs(
        [
          inputUser.reshape([inputUser.length, 1]),
          inputCourse.reshape([inputCourse.length, 1]),
        ],
        {0: outputBuffer},
      );

      // 4. Sort courses by score
      final scores = <Map<String, dynamic>>[];
      for (int i = 0; i < inputCourse.length; i++) {
        scores.add({
          'course': allCourses[courseIndices[i]],
          'score': outputBuffer[i][0],
        });
      }

      scores.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      // Return top 5
      return scores.take(5).map((e) => e['course'] as CourseModel).toList();
    } catch (e) {
      print('Error generating recommendations: $e');
      return [];
    }
  }

  /// Get related courses using Embedding-Based MLP similarity
  ///
  /// This method uses the trained MLP embeddings to find courses
  /// that are semantically similar to the current course.
  /// Example: JavaScript course → React, Node.js (similar embeddings)
  Future<List<CourseModel>> getRelatedCourses(CourseModel currentCourse) async {
    // Load similarity model if not loaded
    if (!isSimilarityModelLoaded) {
      await loadCourseSimilarityModel();
    }

    try {
      final allCourses = await _firestoreService.getAllCourses();

      // If MLP model is available, use it
      if (isSimilarityModelLoaded && _courseSimilarityData != null) {
        return _getMLPBasedRelatedCourses(currentCourse, allCourses);
      }

      // Fallback to category-based matching
      return _getCategoryBasedRelatedCourses(currentCourse, allCourses);
    } catch (e) {
      print('Error finding related courses: $e');
      return [];
    }
  }

  /// Embedding-Based MLP course similarity using learned embeddings
  ///
  /// This method works with ANY course by:
  /// 1. Computing an embedding for the current course using the MLP
  /// 2. Computing embeddings for all other courses
  /// 3. Ranking by cosine similarity between embedding vectors
  List<CourseModel> _getMLPBasedRelatedCourses(
    CourseModel currentCourse,
    List<CourseModel> allCourses,
  ) {
    print('Computing MLP-based recommendations for: ${currentCourse.title}');

    // Step 1: Get or compute embedding for the current course
    List<double>? currentEmbedding = _getEmbeddingForCourse(currentCourse);

    if (currentEmbedding == null) {
      print('Could not compute embedding for course, using category fallback');
      return _getCategoryBasedRelatedCourses(currentCourse, allCourses);
    }

    // Step 2: Compute similarity with all other courses
    final similarities = <Map<String, dynamic>>[];

    for (var otherCourse in allCourses) {
      // Skip the current course
      if (otherCourse.courseId == currentCourse.courseId) {
        continue;
      }

      // Get embedding for this course
      final otherEmbedding = _getEmbeddingForCourse(otherCourse);
      if (otherEmbedding == null) continue;

      // Compute cosine similarity
      final similarity = _cosineSimilarity(currentEmbedding, otherEmbedding);

      similarities.add({'course': otherCourse, 'score': similarity});
    }

    // Step 3: Sort by similarity score (highest first)
    similarities.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // Step 4: Return top 5 most similar courses
    final relatedCourses = <CourseModel>[];
    for (var sim in similarities.take(5)) {
      final course = sim['course'] as CourseModel;
      final score = sim['score'] as double;
      relatedCourses.add(course);
      print(
        'MLP Recommendation: ${course.title} (similarity: ${score.toStringAsFixed(3)})',
      );
    }

    // If we have fewer than 5, supplement with category-based
    if (relatedCourses.length < 5) {
      final categoryBased = _getCategoryBasedRelatedCourses(
        currentCourse,
        allCourses,
      );
      for (var course in categoryBased) {
        if (!relatedCourses.contains(course) &&
            course.courseId != currentCourse.courseId) {
          relatedCourses.add(course);
          if (relatedCourses.length >= 5) break;
        }
      }
    }

    return relatedCourses.take(5).toList();
  }

  /// Get embedding for any course - either from precomputed data or by running inference
  List<double>? _getEmbeddingForCourse(CourseModel course) {
    // First, try to find a matching precomputed embedding by content similarity
    if (_courseSimilarityData != null) {
      CourseSimilarityData? bestMatch;
      int bestScore = 0;

      for (var simData in _courseSimilarityData!) {
        int score = 0;

        // Check title similarity (keywords)
        final courseTitleWords = course.title.toLowerCase().split(' ').toSet();
        final simTitleWords = simData.title.toLowerCase().split(' ').toSet();
        score += courseTitleWords.intersection(simTitleWords).length * 3;

        // Check category match (map common variations)
        final normalizedCategory = _normalizeCategory(course.category);
        final simNormalizedCategory = _normalizeCategory(simData.category);
        if (normalizedCategory == simNormalizedCategory) {
          score += 5;
        }

        // Check tag overlap
        final courseTagsLower = course.tags.map((t) => t.toLowerCase()).toSet();
        final simTagsLower = simData.tags.map((t) => t.toLowerCase()).toSet();
        score += courseTagsLower.intersection(simTagsLower).length * 2;

        if (score > bestScore) {
          bestScore = score;
          bestMatch = simData;
        }
      }

      // Use precomputed embedding if we found a good match
      if (bestMatch != null && bestScore >= 3) {
        print(
          'Using precomputed embedding from: ${bestMatch.title} (match score: $bestScore)',
        );
        return bestMatch.embedding;
      }
    }

    // Otherwise, compute embedding using TFLite model
    return _computeEmbeddingForCourse(course);
  }

  /// Normalize category names to handle variations
  String _normalizeCategory(String category) {
    final lower = category.toLowerCase();

    // Map variations to standard categories
    if (lower.contains('programming') ||
        lower.contains('web') ||
        lower.contains('development') ||
        lower.contains('frontend') ||
        lower.contains('backend')) {
      return 'development';
    }
    if (lower.contains('mobile') ||
        lower.contains('flutter') ||
        lower.contains('android') ||
        lower.contains('ios')) {
      return 'mobile';
    }
    if (lower.contains('blockchain') ||
        lower.contains('web3') ||
        lower.contains('crypto') ||
        lower.contains('defi')) {
      return 'blockchain';
    }
    if (lower.contains('data') ||
        lower.contains('machine') ||
        lower.contains('ai') ||
        lower.contains('learning')) {
      return 'data_science';
    }
    if (lower.contains('design') ||
        lower.contains('ui') ||
        lower.contains('ux') ||
        lower.contains('figma')) {
      return 'design';
    }
    if (lower.contains('security') ||
        lower.contains('cyber') ||
        lower.contains('hacking')) {
      return 'security';
    }
    if (lower.contains('devops') ||
        lower.contains('cloud') ||
        lower.contains('aws') ||
        lower.contains('docker')) {
      return 'devops';
    }
    if (lower.contains('business') ||
        lower.contains('marketing') ||
        lower.contains('product')) {
      return 'business';
    }

    return lower;
  }

  /// Compute embedding for a course using the TFLite model
  List<double>? _computeEmbeddingForCourse(CourseModel course) {
    if (_similarityInterpreter == null ||
        _categoryToIdx == null ||
        _tagToIdx == null ||
        _featureDim == null) {
      return null;
    }

    try {
      // Build feature vector
      final numCategories = _categoryToIdx!.length;
      final numTags = _tagToIdx!.length;

      // Category one-hot encoding
      final categoryVec = List<double>.filled(numCategories, 0.0);
      final categoryIdx = _categoryToIdx![course.category];
      if (categoryIdx != null) {
        categoryVec[categoryIdx] = 1.0;
      }

      // Tags multi-hot encoding
      final tagVec = List<double>.filled(numTags, 0.0);
      for (var tag in course.tags) {
        final tagIdx = _tagToIdx![tag];
        if (tagIdx != null) {
          tagVec[tagIdx] = 1.0;
        }
      }

      // Concatenate features
      final features = [...categoryVec, ...tagVec];

      // Run inference
      final input = [features];
      final output = List.filled(
        _embeddingDim!,
        0.0,
      ).reshape([1, _embeddingDim!]);

      _similarityInterpreter!.run(input, output);

      return List<double>.from(output[0]);
    } catch (e) {
      print('Error computing embedding: $e');
      return null;
    }
  }

  // ===========================================================================
  // COSINE SIMILARITY - How we compare two course embeddings
  // ===========================================================================
  // WHAT IS COSINE SIMILARITY?
  // - Two embeddings are like arrows (vectors) in 64-dimensional space
  // - If arrows point in SAME direction = courses are SIMILAR (score = 1)
  // - If arrows point in OPPOSITE directions = courses are DIFFERENT (score = -1)
  // - If arrows are PERPENDICULAR = no relationship (score = 0)
  //
  // FORMULA: cos(θ) = (A · B) / (||A|| × ||B||)
  // - A · B = dot product (multiply corresponding numbers and add up)
  // - ||A|| = length of vector A
  // ===========================================================================
  double _cosineSimilarity(List<double> a, List<double> b) {
    // Both embeddings must have same size (64 numbers)
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0; // A · B (numerator)
    double normA = 0.0; // ||A||² (for denominator)
    double normB = 0.0; // ||B||² (for denominator)

    // Loop through all 64 dimensions
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i]; // Multiply and add: a₀×b₀ + a₁×b₁ + ...
      normA += a[i] * a[i]; // Sum of squares: a₀² + a₁² + ...
      normB += b[i] * b[i]; // Sum of squares: b₀² + b₁² + ...
    }

    // Avoid division by zero
    if (normA == 0 || normB == 0) return 0.0;

    // Final formula: dotProduct / (sqrt(normA) * sqrt(normB))
    // Result: -1 to 1, where 1 = identical, 0 = unrelated
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Fallback: Category-based related courses
  List<CourseModel> _getCategoryBasedRelatedCourses(
    CourseModel currentCourse,
    List<CourseModel> allCourses,
  ) {
    // Filter by same category, exclude current course
    final related = allCourses.where((c) {
      return c.courseId != currentCourse.courseId &&
          c.category == currentCourse.category;
    }).toList();

    // Sort by tag overlap and rating
    related.sort((a, b) {
      final aTagOverlap = a.tags
          .toSet()
          .intersection(currentCourse.tags.toSet())
          .length;
      final bTagOverlap = b.tags
          .toSet()
          .intersection(currentCourse.tags.toSet())
          .length;

      if (aTagOverlap != bTagOverlap) {
        return bTagOverlap.compareTo(aTagOverlap);
      }
      return b.rating.compareTo(a.rating);
    });

    return related.take(5).toList();
  }

  void close() {
    _interpreter?.close();
    _similarityInterpreter?.close();
  }
}
