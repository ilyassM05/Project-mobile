import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/course_model.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../quiz/quiz_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final CourseModel course;
  final VideoModel video;

  const VideoPlayerScreen({
    super.key,
    required this.course,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasMarkedComplete = false;
  final FirestoreService _firestoreService = FirestoreService();
  String _userId = '';
  QuizModel? _videoQuiz;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        _userId = authProvider.currentUser!.userId;
      }
      _initializePlayer();
      _loadQuiz(); // Load quiz asynchronously
    });
  }

  Future<void> _loadQuiz() async {
    final quiz = await _firestoreService.getQuizForVideo(widget.video.videoId);
    if (mounted) {
      setState(() {
        _videoQuiz = quiz;
      });
    }
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.url),
    );

    await _videoPlayerController.initialize();

    // Add listener to mark video as complete at 80% watched
    _videoPlayerController.addListener(_videoListener);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppTheme.primaryColor,
        handleColor: AppTheme.primaryColor,
        backgroundColor: Colors.grey,
        bufferedColor: AppTheme.primaryColor.withOpacity(0.3),
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _videoListener() async {
    // Mark video as complete when user watches 80% of it
    if (!_hasMarkedComplete && _videoPlayerController.value.isInitialized) {
      final position = _videoPlayerController.value.position.inSeconds;
      final duration = _videoPlayerController.value.duration.inSeconds;

      if (duration > 0 && position / duration >= 0.8) {
        _hasMarkedComplete = true;

        if (_userId.isNotEmpty) {
          await _firestoreService.markVideoCompleted(
            _userId,
            widget.course.courseId,
            widget.video.videoId,
          );
        }

        // Show completion message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Video marked as complete!'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showQuiz() {
    if (_videoQuiz != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizScreen(quiz: _videoQuiz!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No quiz available for this video'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.video.title, style: const TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const SizedBox(),
          ),

          // Video Info and Controls
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      widget.video.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),

                    // Video Duration
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.video.formattedDuration,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Description
                    if (widget.video.description != null) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        widget.video.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                    ],

                    // Quiz Button
                    if (_videoQuiz != null)
                      Card(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        child: InkWell(
                          onTap: _showQuiz,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.spacingM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusM,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.quiz,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Test Your Knowledge',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.accentColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Take quiz to check your understanding',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppTheme.accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Course Info
                    Text(
                      'From',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          widget.course.instructorName[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(widget.course.title),
                      subtitle: Text(widget.course.instructorName),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
