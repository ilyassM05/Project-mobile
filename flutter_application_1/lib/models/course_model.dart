import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String videoId;
  final String title;
  final String? description;
  final String url; // Firebase Storage URL
  final String? thumbnailUrl;
  final int duration; // Duration in seconds
  final int order; // Order in the course

  VideoModel({
    required this.videoId,
    required this.title,
    this.description,
    required this.url,
    this.thumbnailUrl,
    required this.duration,
    this.order = 0,
  });

  // Get formatted duration
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'order': order,
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      order: json['order'] ?? 0,
    );
  }
}

class CourseModel {
  final String courseId;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final double priceETH;
  final String category;
  final List<String> tags;
  final String thumbnailUrl;
  final List<VideoModel> videos;
  final int totalDuration; // Total duration in seconds
  final int studentsCount;
  final double rating; // Course rating (0-5)
  final int enrolledCount; // Total number of enrolled students
  final String? level; // Beginner, Intermediate, Advanced
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.priceETH,
    required this.category,
    required this.tags,
    required this.thumbnailUrl,
    required this.videos,
    required this.totalDuration,
    this.studentsCount = 0,
    this.rating = 0.0,
    this.enrolledCount = 0,
    this.level,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'priceETH': priceETH.toString(),
      'category': category,
      'tags': tags,
      'thumbnailUrl': thumbnailUrl,
      'videos': videos.map((v) => v.toJson()).toList(),
      'totalDuration': totalDuration,
      'studentsCount': studentsCount,
      'rating': rating,
      'enrolledCount': enrolledCount,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructorId: json['instructorId'] ?? '',
      instructorName: json['instructorName'] ?? '',
      // Handle priceETH whether it's String, double, or int
      priceETH: _parsePrice(json['priceETH']),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videos:
          (json['videos'] as List?)
              ?.map((v) => VideoModel.fromJson(v))
              .toList() ??
          [],
      totalDuration: json['totalDuration'] ?? 0,
      studentsCount: json['studentsCount'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      enrolledCount: json['enrolledCount'] ?? 0,
      level: json['level'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // Get formatted price for display
  String get formattedPrice => '${priceETH.toStringAsFixed(4)} ETH';

  // Get formatted duration
  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Get number of videos
  int get videoCount => videos.length;

  // Create a copy with updated fields
  CourseModel copyWith({
    String? courseId,
    String? title,
    String? description,
    String? instructorId,
    String? instructorName,
    double? priceETH,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    List<VideoModel>? videos,
    int? totalDuration,
    int? studentsCount,
    double? rating,
    int? enrolledCount,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      priceETH: priceETH ?? this.priceETH,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videos: videos ?? this.videos,
      totalDuration: totalDuration ?? this.totalDuration,
      studentsCount: studentsCount ?? this.studentsCount,
      rating: rating ?? this.rating,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
