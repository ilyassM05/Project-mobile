import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/course_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../video/video_player_screen.dart';
import '../certificate/certificate_screen.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/course_card.dart';
import '../../services/web3_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late CourseModel _course;
  final FirestoreService _firestoreService = FirestoreService();
  String _userId = '';
  String _userName = '';
  double _progressPercentage = 0.0;
  bool _isCertificateUnlocked = false;
  List<String> _completedVideoIds = [];
  Map<String, String> _videoQuizMap = {}; // videoId -> quizId
  bool _isLoading = true;
  bool _hasPurchased = false; // Track if user owns this course
  List<CourseModel> _relatedCourses = [];
  final RecommendationService _recommendationService = RecommendationService();
  final Web3Service _web3Service = Web3Service();

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        _userId = authProvider.currentUser!.userId;
        _userName = authProvider.currentUser!.displayName;
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Initialize Web3 for blockchain purchases (non-blocking)
    _web3Service.initialize().catchError((e) {
      print('Web3 init failed (Ganache may not be running): $e');
    });

    await Future.wait([
      _loadFullCourseDetails(),
      _loadProgress(),
      _loadQuizzes(),
      _loadRelatedCourses(),
      _loadPurchaseStatus(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPurchaseStatus() async {
    if (_userId.isEmpty) return;
    final purchased = await _firestoreService.hasPurchasedCourse(
      _userId,
      _course.courseId,
    );
    if (mounted) {
      setState(() {
        _hasPurchased = purchased;
      });
    }
  }

  Future<void> _loadFullCourseDetails() async {
    if (widget.course.videos.isEmpty) {
      final fullCourse = await _firestoreService.getCourseById(
        widget.course.courseId,
      );
      if (fullCourse != null && mounted) {
        setState(() {
          _course = fullCourse;
        });
      }
    }
  }

  Future<void> _loadProgress() async {
    if (_userId.isEmpty) return;

    final progress = await _firestoreService.getProgress(
      _userId,
      _course.courseId,
    );

    if (progress != null) {
      if (mounted) {
        setState(() {
          _completedVideoIds = progress.completedVideoIds;
          final totalVideos = _course.videos.isEmpty
              ? 1
              : _course.videos.length;
          _progressPercentage = _completedVideoIds.length / totalVideos;
          _isCertificateUnlocked = progress.isCertificateUnlocked;

          // Auto-unlock logic
          if (_progressPercentage >= 1.0 && !_isCertificateUnlocked) {
            _isCertificateUnlocked = true;
            _firestoreService.updateCertificateStatus(
              _userId,
              _course.courseId,
              true,
            );
          }
        });
      }
    }
  }

  Future<void> _loadQuizzes() async {
    final quizzes = await _firestoreService.getQuizzesForCourse(
      widget.course.courseId,
    );
    if (mounted) {
      setState(() {
        _videoQuizMap = {for (var q in quizzes) q.videoId: q.quizId};
      });
    }
  }

  Future<void> _refreshProgress() async {
    await _loadProgress();
  }

  Future<void> _loadRelatedCourses() async {
    final related = await _recommendationService.getRelatedCourses(_course);
    if (mounted) {
      setState(() {
        _relatedCourses = related;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Course Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryColor,
                        child: const Icon(
                          Icons.school,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _course.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingS),

                  // Rating, Students, Price
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 20,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _course.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      const Icon(
                        Icons.people,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_course.enrolledCount} students',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.ethColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.currency_bitcoin,
                              size: 20,
                              color: AppTheme.ethColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _course.formattedPrice,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.ethColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Progress Bar
                  Card(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Progress',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(_progressPercentage * 100).toInt()}%',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                            child: LinearProgressIndicator(
                              value: _progressPercentage,
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.successColor,
                              ),
                            ),
                          ),
                          if (_progressPercentage == 1.0) ...[
                            const SizedBox(height: AppTheme.spacingS),
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppTheme.successColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Course completed!',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Certificate Button
                  if (_isCertificateUnlocked)
                    Card(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CertificateScreen(
                                course: _course,
                                userId: _userId,
                                userName: _userName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: AppTheme.accentColor,
                                size: 40,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Certificate Available!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to view and download your certificate',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.grey[600], size: 40),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Certificate Locked',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Complete all videos and pass all quizzes to unlock',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Instructor & Category
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          _course.instructorName[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _course.instructorName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _course.category,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Tags
                  Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    children: _course.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            labelStyle: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Description
                  Text(
                    'About this course',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    _course.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Course Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.play_circle_outline,
                          '${_course.videos.length} Videos',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.access_time,
                          _course.formattedDuration,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.signal_cellular_alt,
                          _course.level ?? 'All Levels',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Video List
                  Text(
                    'Course Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                ],
              ),
            ),
          ),

          // Video List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = _course.videos[index];
              final hasQuiz = _videoQuizMap.containsKey(video.videoId);
              final isCompleted = _completedVideoIds.contains(video.videoId);
              final isLocked = !_hasPurchased;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingS,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLocked
                        ? Colors.grey.withOpacity(0.2)
                        : isCompleted
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    child: isLocked
                        ? Icon(Icons.lock, color: Colors.grey[600], size: 20)
                        : isCompleted
                        ? const Icon(Icons.check, color: AppTheme.successColor)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    video.title,
                    style: TextStyle(color: isLocked ? Colors.grey : null),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        video.formattedDuration,
                        style: TextStyle(
                          color: isLocked ? Colors.grey[400] : null,
                        ),
                      ),
                      if (hasQuiz) ...[
                        const SizedBox(width: AppTheme.spacingS),
                        Icon(
                          Icons.quiz,
                          size: 14,
                          color: isLocked
                              ? Colors.grey[400]
                              : AppTheme.accentColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Quiz',
                          style: TextStyle(
                            color: isLocked
                                ? Colors.grey[400]
                                : AppTheme.accentColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Icon(
                    isLocked ? Icons.lock_outline : Icons.play_circle_outline,
                    color: isLocked ? Colors.grey : null,
                  ),
                  onTap: () async {
                    if (isLocked) {
                      // Show purchase prompt
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🔒 Purchase this course to unlock videos',
                          ),
                          backgroundColor: AppTheme.warningColor,
                        ),
                      );
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoPlayerScreen(course: _course, video: video),
                      ),
                    );
                    _refreshProgress();
                  },
                ),
              );
            }, childCount: _course.videos.length),
          ),

          // Related Courses Section
          if (_relatedCourses.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      0,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Recommended',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                      ),
                      itemCount: _relatedCourses.length,
                      itemBuilder: (context, index) {
                        final relatedCourse = _relatedCourses[index];
                        return Container(
                          width: 260,
                          margin: const EdgeInsets.only(
                            right: AppTheme.spacingM,
                          ),
                          child: CourseCard(
                            course: relatedCourse,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseDetailScreen(course: relatedCourse),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Purchase Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _hasPurchased
              ? null
              : () async {
                  // Check if wallet is connected
                  if (!_web3Service.isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please connect your wallet in Profile first',
                        ),
                        backgroundColor: AppTheme.warningColor,
                      ),
                    );
                    return;
                  }

                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Purchase'),
                      content: Text(
                        'Purchase "${_course.title}" for ${_course.formattedPrice}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // Ensure Web3 is fully initialized before purchase
                    if (!_web3Service.isInitialized) {
                      print('Web3 not initialized, initializing now...');
                      await _web3Service.initialize();
                    }

                    // Debug info
                    print('Attempting purchase:');
                    print('  - isInitialized: ${_web3Service.isInitialized}');
                    print('  - isConnected: ${_web3Service.isConnected}');
                    print(
                      '  - isContractReady: ${_web3Service.isContractReady}',
                    );

                    // Add timeout to prevent infinite loading
                    final txHash = await _web3Service
                        .purchaseCourse(_course.courseId, _course.priceETH)
                        .timeout(
                          const Duration(seconds: 30),
                          onTimeout: () {
                            throw Exception(
                              'Transaction timed out. Is Ganache running?',
                            );
                          },
                        );

                    // Record purchase in Firestore
                    await _firestoreService.purchaseCourse(
                      _userId,
                      _course.courseId,
                      transactionHash: txHash,
                    );

                    // Update UI to unlock content
                    setState(() {
                      _hasPurchased = true;
                    });

                    if (mounted) {
                      Navigator.pop(context); // Close loading
                      final message = txHash == 'already_enrolled'
                          ? '✅ You are already enrolled! Course unlocked.'
                          : '🎉 Purchase successful! TX: ${txHash.substring(0, 10)}...';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Purchase error: $e');
                    if (mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction failed: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
            backgroundColor: _hasPurchased ? AppTheme.successColor : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_hasPurchased ? Icons.check_circle : Icons.shopping_cart),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                _hasPurchased
                    ? 'Enrolled ✓'
                    : 'Purchase for ${_course.formattedPrice}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
