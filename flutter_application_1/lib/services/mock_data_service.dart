import '../models/course_model.dart';
import '../models/quiz_model.dart';

/// Mock data service providing sample courses, videos, and quizzes
/// This will be replaced with real Firebase data in Phase 2
class MockDataService {
  // Sample courses with expanded content
  static final List<CourseModel> mockCourses = [
    CourseModel(
      courseId: 'course_1',
      title: 'Complete Flutter Development Bootcamp',
      description:
          'Master Flutter and Dart to build beautiful, fast mobile apps for iOS and Android. Learn widgets, state management, Firebase integration, and more!',
      instructorId: 'instructor_1',
      instructorName: 'Ilyass Moutmir',
      thumbnailUrl: 'https://picsum.photos/seed/flutter/400/300',
      category: 'Programming',
      tags: ['Flutter', 'Dart', 'Mobile Development', 'Cross-Platform'],
      priceETH: 0.05,
      rating: 4.8,
      enrolledCount: 3245,
      totalDuration: 4200, // Total duration in seconds
      level: 'Beginner',
      videos: [
        VideoModel(
          videoId: 'video_1_1',
          title: 'Introduction to Flutter',
          description:
              'Learn what Flutter is and why it\'s awesome for mobile development',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          duration: 600,
          order: 1,
          thumbnailUrl: 'https://picsum.photos/seed/video1_1/400/300',
        ),
        VideoModel(
          videoId: 'video_1_2',
          title: 'Setting Up Your Development Environment',
          description:
              'Install Flutter SDK, Android Studio, and configure your IDE',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          duration: 720,
          order: 2,
          thumbnailUrl: 'https://picsum.photos/seed/video1_2/400/300',
        ),
        VideoModel(
          videoId: 'video_1_3',
          title: 'Dart Programming Basics',
          description:
              'Learn Dart fundamentals - variables, functions, and classes',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          duration: 840,
          order: 3,
          thumbnailUrl: 'https://picsum.photos/seed/video1_3/400/300',
        ),
        VideoModel(
          videoId: 'video_1_4',
          title: 'Building Your First Widget',
          description:
              'Create your first Flutter widget and understand the widget tree',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          duration: 900,
          order: 4,
          thumbnailUrl: 'https://picsum.photos/seed/video1_4/400/300',
        ),
        VideoModel(
          videoId: 'video_1_5',
          title: 'Stateless vs Stateful Widgets',
          description: 'Understanding the difference and when to use each type',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          duration: 780,
          order: 5,
          thumbnailUrl: 'https://picsum.photos/seed/video1_5/400/300',
        ),
        VideoModel(
          videoId: 'video_1_6',
          title: 'Layouts and Responsive Design',
          description:
              'Master Flutter layouts - Row, Column, Stack, and GridView',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          duration: 960,
          order: 6,
          thumbnailUrl: 'https://picsum.photos/seed/video1_6/400/300',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    CourseModel(
      courseId: 'course_2',
      title: 'Web3 & Blockchain Development with Ethereum',
      description:
          'Learn how to build decentralized applications (DApps) using Ethereum, Solidity, and Web3.js. Create smart contracts and deploy to the blockchain.',
      instructorId: 'instructor_2',
      instructorName: 'Adnane Raghai',
      thumbnailUrl: 'https://picsum.photos/seed/blockchain/400/300',
      category: 'Blockchain',
      tags: ['Ethereum', 'Solidity', 'Web3', 'Smart Contracts'],
      priceETH: 0.08,
      rating: 4.9,
      enrolledCount: 2156,
      totalDuration: 5400,
      level: 'Intermediate',
      videos: [
        VideoModel(
          videoId: 'video_2_1',
          title: 'Blockchain Fundamentals',
          description:
              'Understanding blockchain technology and distributed ledgers',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          duration: 800,
          order: 1,
          thumbnailUrl: 'https://picsum.photos/seed/video2_1/400/300',
        ),
        VideoModel(
          videoId: 'video_2_2',
          title: 'Introduction to Solidity',
          description:
              'Learn the Solidity programming language for smart contracts',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          duration: 900,
          order: 2,
          thumbnailUrl: 'https://picsum.photos/seed/video2_2/400/300',
        ),
        VideoModel(
          videoId: 'video_2_3',
          title: 'Smart Contract Development',
          description: 'Write your first smart contract on Ethereum',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          duration: 1020,
          order: 3,
          thumbnailUrl: 'https://picsum.photos/seed/video2_3/400/300',
        ),
        VideoModel(
          videoId: 'video_2_4',
          title: 'Web3.js Integration',
          description: 'Connect your DApp to the Ethereum blockchain',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          duration: 960,
          order: 4,
          thumbnailUrl: 'https://picsum.photos/seed/video2_4/400/300',
        ),
        VideoModel(
          videoId: 'video_2_5',
          title: 'Deploying to Testnet',
          description: 'Deploy your smart contract to Sepolia testnet',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          duration: 840,
          order: 5,
          thumbnailUrl: 'https://picsum.photos/seed/video2_5/400/300',
        ),
        VideoModel(
          videoId: 'video_2_6',
          title: 'Security Best Practices',
          description: 'Learn common vulnerabilities and how to avoid them',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
          duration: 880,
          order: 6,
          thumbnailUrl: 'https://picsum.photos/seed/video2_6/400/300',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CourseModel(
      courseId: 'course_3',
      title: 'UI/UX Design Masterclass',
      description:
          'Master the art of creating beautiful and user-friendly interfaces. Learn design principles, prototyping, and user research.',
      instructorId: 'instructor_3',
      instructorName: 'Fatima Zahra Benjelloun',
      thumbnailUrl: 'https://picsum.photos/seed/design/400/300',
      category: 'Design',
      tags: ['UI Design', 'UX Design', 'Figma', 'Prototyping'],
      priceETH: 0.04,
      rating: 4.7,
      enrolledCount: 4521,
      totalDuration: 3600,
      level: 'Beginner',
      videos: [
        VideoModel(
          videoId: 'video_3_1',
          title: 'Design Principles',
          description:
              'Learn fundamental design principles and visual hierarchy',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          duration: 700,
          order: 1,
          thumbnailUrl: 'https://picsum.photos/seed/video3_1/400/300',
        ),
        VideoModel(
          videoId: 'video_3_2',
          title: 'Color Theory',
          description: 'Understanding color palettes and psychology',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          duration: 600,
          order: 2,
          thumbnailUrl: 'https://picsum.photos/seed/video3_2/400/300',
        ),
        VideoModel(
          videoId: 'video_3_3',
          title: 'Typography Basics',
          description: 'Choosing and combining fonts effectively',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          duration: 540,
          order: 3,
          thumbnailUrl: 'https://picsum.photos/seed/video3_3/400/300',
        ),
        VideoModel(
          videoId: 'video_3_4',
          title: 'User Research Methods',
          description: 'Conducting user interviews and surveys',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
          duration: 780,
          order: 4,
          thumbnailUrl: 'https://picsum.photos/seed/video3_4/400/300',
        ),
        VideoModel(
          videoId: 'video_3_5',
          title: 'Wireframing and Prototyping',
          description: 'Create interactive prototypes in Figma',
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
          duration: 980,
          order: 5,
          thumbnailUrl: 'https://picsum.photos/seed/video3_5/400/300',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // Comprehensive quizzes for all videos
  static final List<QuizModel> mockQuizzes = _generateAllQuizzes();

  static List<QuizModel> _generateAllQuizzes() {
    return [
      // Flutter Course Quizzes
      QuizModel(
        quizId: 'quiz_1_1',
        courseId: 'course_1',
        videoId: 'video_1_1',
        title: 'Flutter Basics Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is Flutter?',
            options: [
              'A JavaScript framework',
              'A UI toolkit for building natively compiled applications',
              'A database system',
              'A cloud platform',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Flutter is Google\'s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.',
          ),
          QuizQuestion(
            questionId: 'q2',
            question: 'Which programming language does Flutter use?',
            options: ['Java', 'Kotlin', 'Dart', 'Swift'],
            correctOptionIndex: 2,
            points: 10,
            explanation:
                'Flutter uses Dart, a programming language developed by Google.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      QuizModel(
        quizId: 'quiz_1_2',
        courseId: 'course_1',
        videoId: 'video_1_2',
        title: 'Development Setup Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question:
                'What is the main IDE recommended for Flutter development?',
            options: [
              'Visual Studio',
              'Android Studio or VS Code',
              'Eclipse',
              'NetBeans',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Android Studio and VS Code are the officially recommended IDEs for Flutter development.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      QuizModel(
        quizId: 'quiz_1_3',
        courseId: 'course_1',
        videoId: 'video_1_3',
        title: 'Dart Fundamentals Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What keyword is used to declare a variable in Dart?',
            options: ['let', 'var', 'const', 'Both var and const'],
            correctOptionIndex: 3,
            points: 10,
            explanation:
                'Dart uses both \'var\' for mutable variables and \'const\' for compile-time constants.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      QuizModel(
        quizId: 'quiz_1_4',
        courseId: 'course_1',
        videoId: 'video_1_4',
        title: 'Widgets Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'Everything in Flutter is a:',
            options: ['Component', 'Widget', 'Element', 'Module'],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'In Flutter, everything is a widget - from structural elements like buttons to layout models.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      QuizModel(
        quizId: 'quiz_1_5',
        courseId: 'course_1',
        videoId: 'video_1_5',
        title: 'State Management Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question:
                'Which widget should you use when the UI needs to change?',
            options: [
              'StatelessWidget',
              'StatefulWidget',
              'InheritedWidget',
              'Container',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'StatefulWidget is used when the UI needs to change dynamically based on state.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      QuizModel(
        quizId: 'quiz_1_6',
        courseId: 'course_1',
        videoId: 'video_1_6',
        title: 'Layouts Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'Which widget arranges children vertically?',
            options: ['Row', 'Column', 'Stack', 'ListView'],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Column arranges its children vertically, while Row arranges them horizontally.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),

      // Blockchain Course Quizzes
      QuizModel(
        quizId: 'quiz_2_1',
        courseId: 'course_2',
        videoId: 'video_2_1',
        title: 'Blockchain Basics Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is a blockchain?',
            options: [
              'A type of cryptocurrency',
              'A distributed ledger technology',
              'A programming language',
              'A database',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Blockchain is a distributed ledger technology that records transactions across multiple computers.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      QuizModel(
        quizId: 'quiz_2_2',
        courseId: 'course_2',
        videoId: 'video_2_2',
        title: 'Solidity Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is Solidity?',
            options: [
              'A blockchain network',
              'A programming language for smart contracts',
              'A cryptocurrency',
              'A database',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Solidity is a programming language specifically designed for writing smart contracts on Ethereum.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      QuizModel(
        quizId: 'quiz_2_3',
        courseId: 'course_2',
        videoId: 'video_2_3',
        title: 'Smart Contracts Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What are smart contracts?',
            options: [
              'Legal documents',
              'Self-executing programs on blockchain',
              'Cryptocurrency wallets',
              'Mining software',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Smart contracts are self-executing programs that run on the blockchain and automatically enforce agreements.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      QuizModel(
        quizId: 'quiz_2_4',
        courseId: 'course_2',
        videoId: 'video_2_4',
        title: 'Web3.js Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is Web3.js used for?',
            options: [
              'Building websites',
              'Interacting with Ethereum blockchain',
              'Creating databases',
              'Styling web pages',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Web3.js is a JavaScript library used to interact with the Ethereum blockchain from web applications.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      QuizModel(
        quizId: 'quiz_2_5',
        courseId: 'course_2',
        videoId: 'video_2_5',
        title: 'Testnet Deployment Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'Why use a testnet before mainnet?',
            options: [
              'It\'s faster',
              'To test without spending real money',
              'It\'s more secure',
              'It\'s required by law',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Testnets allow developers to test their contracts without spending real ETH, using test tokens instead.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      QuizModel(
        quizId: 'quiz_2_6',
        courseId: 'course_2',
        videoId: 'video_2_6',
        title: 'Security Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is a reentrancy attack?',
            options: [
              'A DDoS attack',
              'An attack where a function is called repeatedly before completion',
              'A password attack',
              'A network attack',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Reentrancy is when a function is called multiple times before the first execution completes, potentially draining funds.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),

      // Design Course Quizzes
      QuizModel(
        quizId: 'quiz_3_1',
        courseId: 'course_3',
        videoId: 'video_3_1',
        title: 'Design Principles Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What does visual hierarchy help with?',
            options: [
              'Color selection',
              'Guiding user attention',
              'Font selection',
              'Code structure',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Visual hierarchy helps guide the user\'s attention to the most important elements first.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      QuizModel(
        quizId: 'quiz_3_2',
        courseId: 'course_3',
        videoId: 'video_3_2',
        title: 'Color Theory Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What are complementary colors?',
            options: [
              'Colors next to each other on the wheel',
              'Colors opposite each other on the wheel',
              'Black and white',
              'Primary colors',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Complementary colors are opposite each other on the color wheel and create high contrast.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      QuizModel(
        quizId: 'quiz_3_3',
        courseId: 'course_3',
        videoId: 'video_3_3',
        title: 'Typography Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is kerning?',
            options: [
              'Font size',
              'Space between letters',
              'Line height',
              'Font weight',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'Kerning is the adjustment of space between individual letter pairs.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      QuizModel(
        quizId: 'quiz_3_4',
        courseId: 'course_3',
        videoId: 'video_3_4',
        title: 'User Research Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is the purpose of user research?',
            options: [
              'To make the design pretty',
              'To understand user needs and behaviors',
              'To save money',
              'To speed up development',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'User research helps understand what users need, want, and how they behave.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      QuizModel(
        quizId: 'quiz_3_5',
        courseId: 'course_3',
        videoId: 'video_3_5',
        title: 'Prototyping Quiz',
        passingScore: 70,
        questions: [
          QuizQuestion(
            questionId: 'q1',
            question: 'What is a wireframe?',
            options: [
              'A final design',
              'A low-fidelity sketch of a design',
              'A color palette',
              'A font selection',
            ],
            correctOptionIndex: 1,
            points: 10,
            explanation:
                'A wireframe is a low-fidelity, simplified outline of a design showing structure and layout.',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  // Get all courses
  static List<CourseModel> getAllCourses() => mockCourses;

  // Get course by ID
  static CourseModel? getCourseById(String courseId) {
    try {
      return mockCourses.firstWhere((course) => course.courseId == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get courses by category
  static List<CourseModel> getCoursesByCategory(String category) {
    if (category == 'All') return mockCourses;
    return mockCourses.where((course) => course.category == category).toList();
  }

  // Search courses
  static List<CourseModel> searchCourses(String query) {
    final lowerQuery = query.toLowerCase();
    return mockCourses.where((course) {
      return course.title.toLowerCase().contains(lowerQuery) ||
          course.description.toLowerCase().contains(lowerQuery) ||
          course.instructorName.toLowerCase().contains(lowerQuery) ||
          course.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Get all categories
  static List<String> getCategories() {
    final categories = mockCourses
        .map((course) => course.category)
        .toSet()
        .toList();
    categories.insert(0, 'All');
    return categories;
  }

  // Get quiz for a video
  static QuizModel? getQuizForVideo(String videoId) {
    try {
      return mockQuizzes.firstWhere((quiz) => quiz.videoId == videoId);
    } catch (e) {
      return null;
    }
  }

  // Get all quizzes for a course
  static List<QuizModel> getQuizzesForCourse(String courseId) {
    return mockQuizzes.where((quiz) => quiz.courseId == courseId).toList();
  }

  // Featured courses (top rated)
  static List<CourseModel> getFeaturedCourses({int limit = 5}) {
    final sortedCourses = List<CourseModel>.from(mockCourses)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sortedCourses.take(limit).toList();
  }

  // Recent courses
  static List<CourseModel> getRecentCourses({int limit = 5}) {
    final sortedCourses = List<CourseModel>.from(mockCourses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedCourses.take(limit).toList();
  }

  // Popular courses (most enrolled)
  static List<CourseModel> getPopularCourses({int limit = 5}) {
    final sortedCourses = List<CourseModel>.from(mockCourses)
      ..sort((a, b) => b.enrolledCount.compareTo(a.enrolledCount));
    return sortedCourses.take(limit).toList();
  }
}
