import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../config/app_theme.dart';
import '../../models/course_model.dart';
// Note: VideoModel is part of course_model.dart

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  int _currentStep = 0;

  // Course Details
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Blockchain';
  String _selectedLevel = 'Beginner';

  // Content
  List<VideoModel> _videos = [];
  bool _isLoading = false;

  Future<void> _submitCourse() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create Course Logic
      final courseId = DateTime.now().millisecondsSinceEpoch.toString();
      final course = CourseModel(
        courseId: courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        instructorId: user.userId,
        instructorName: user.displayName,
        priceETH: double.tryParse(_priceController.text) ?? 0.0,
        category: _selectedCategory,
        tags: [_selectedCategory], // Simplified tags
        thumbnailUrl: 'https://placehold.co/600x400/png', // Placeholder
        videos: _videos,
        totalDuration: _videos.fold(0, (sum, v) => sum + v.duration),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Defaults
        studentsCount: 0,
        enrolledCount: 0,
        rating: 0.0,
        level: _selectedLevel,
      );

      await FirestoreService().createCourse(course);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating course: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addVideo() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final urlController = TextEditingController();
        final durationController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Video Lesson'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Video Title'),
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Video URL (mp4)'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (e.g. 10:30)',
                  hintText: 'MM:SS',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  // Parse duration "MM:SS" to seconds
                  int durationSeconds = 0;
                  final parts = durationController.text.split(':');
                  if (parts.length == 2) {
                    final minutes = int.tryParse(parts[0]) ?? 0;
                    final seconds = int.tryParse(parts[1]) ?? 0;
                    durationSeconds = minutes * 60 + seconds;
                  }

                  setState(() {
                    _videos.add(
                      VideoModel(
                        videoId: DateTime.now().millisecondsSinceEpoch
                            .toString(),
                        title: titleController.text,
                        description: '',
                        url: urlController.text,
                        thumbnailUrl: '',
                        duration: durationSeconds,
                        order: _videos.length,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Course')),
      body: Stack(
        children: [
          Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingL),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          _currentStep == 2 ? 'Submit Course' : 'Continue',
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _submitCourse();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            steps: [
              Step(
                title: const Text('Details'),
                content: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course Title',
                      ),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (ETH)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Content'),
                content: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addVideo,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Video'),
                    ),
                    if (_videos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppTheme.spacingM),
                        child: Text('No videos added yet'),
                      ),
                    ..._videos.map(
                      (v) => ListTile(
                        title: Text(v.title),
                        subtitle: Text(v.url),
                        trailing: Text(v.formattedDuration),
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text('Review'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title: ${_titleController.text}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Price: ${_priceController.text} ETH'),
                    const SizedBox(height: 8),
                    Text('Videos: ${_videos.length}'),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
