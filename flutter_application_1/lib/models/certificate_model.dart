class CertificateModel {
  final int tokenId;
  final String studentAddress;
  final String courseId;
  final String courseName;
  final DateTime completionDate;

  CertificateModel({
    required this.tokenId,
    required this.studentAddress,
    required this.courseId,
    required this.courseName,
    required this.completionDate,
  });
// Firebase can only store simple data types (strings, numbers), not Dart objects 
  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'studentAddress': studentAddress,
      'courseId': courseId,
      'courseName': courseName,
      'completionDate': completionDate.toIso8601String(),
    };
  }

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      tokenId: json['tokenId'] ?? 0,
      studentAddress: json['studentAddress'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      completionDate: json['completionDate'] != null
          ? DateTime.parse(json['completionDate'])
          : DateTime.now(),
    );
  }

  // Format student address for display
  String get shortAddress {
    if (studentAddress.length > 12) {
      return '${studentAddress.substring(0, 6)}...${studentAddress.substring(studentAddress.length - 4)}';
    }
    return studentAddress;
  }

  // Get formatted completion date
  String get formattedDate {
    return '${completionDate.day}/${completionDate.month}/${completionDate.year}';
  }
}
