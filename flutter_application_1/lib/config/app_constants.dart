/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'E-Learning DApp';
  static const String appVersion = '1.0.0';

  // Blockchain Configuration
  // TODO: Replace with your deployed contract addresses after deployment
  static const String coursePaymentContractAddress =
      '0x0000000000000000000000000000000000000000';
  static const String certificateContractAddress =
      '0x0000000000000000000000000000000000000000';

  // Sepolia Testnet Configuration
  static const String sepoliaRpcUrl =
      'https://sepolia.infura.io/v3/YOUR_API_KEY'; // TODO: Add your Infura/Alchemy key
  static const int sepoliaChainId = 11155111;

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String purchasesCollection = 'purchases';
  static const String progressCollection = 'progress';
  static const String learningPatternsCollection = 'learning_patterns';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleInstructor = 'instructor';

  // Course Categories
  static const List<String> courseCategories = [
    'Blockchain',
    'Web Development',
    'Mobile Development',
    'Data Science',
    'AI & Machine Learning',
    'Cybersecurity',
    'Design',
    'Business',
    'Other',
  ];

  // Video Settings
  static const int progressSaveInterval = 5; // Save progress every 5 seconds
  static const double videoCompletionThreshold = 0.9; // 90% watched = completed

  // Pagination
  static const int coursesPerPage = 10;
  static const int videosPerPage = 20;

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork =
      'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please log in again.';
  static const String errorBlockchain = 'Blockchain transaction failed.';
}
