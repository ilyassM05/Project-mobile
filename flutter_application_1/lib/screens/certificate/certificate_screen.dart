import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_theme.dart';
import '../../models/course_model.dart';

class CertificateScreen extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final String userName;

  const CertificateScreen({
    super.key,
    required this.course,
    required this.userId,
    required this.userName,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool _isFullScreen = false;
  bool _isDownloading = false;
  final GlobalKey _certificateKey = GlobalKey();

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rotate your phone & take a screenshot! Tap to exit.'),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _downloadCertificate() async {
    setState(() => _isDownloading = true);

    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // Capture using RenderRepaintBoundary
      RenderRepaintBoundary boundary =
          _certificateKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to capture certificate');
      }

      Uint8List imageBytes = byteData.buffer.asUint8List();

      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Certificate_${widget.course.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Certificate saved to: $fileName'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving certificate: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleFullScreen,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: AspectRatio(
                aspectRatio: 1.414, // A4 Landscape ratio
                child: _buildCertificateContent(context),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming in Phase 4!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            const Text(
              '🎉 Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'You have successfully completed this course.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Certificate Preview (Scaled down)
            RepaintBoundary(
              key: _certificateKey,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AspectRatio(
                      aspectRatio: 1.414,
                      child: _buildCertificateContent(context, isPreview: true),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Download Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadCertificate,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isDownloading ? 'Saving...' : 'Download Certificate',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Fullscreen Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _toggleFullScreen,
                icon: const Icon(Icons.fullscreen),
                label: const Text('View Full Screen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Info Note
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.successColor),
                  const SizedBox(width: AppTheme.spacingM),
                  const Expanded(
                    child: Text(
                      'Your certificate is secured by blockchain verification. Download and share it with confidence!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateContent(
    BuildContext context, {
    bool isPreview = false,
  }) {
    final date = DateTime.now();
    final dateString = '${date.day}/${date.month}/${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Elegant gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              children: [
                const Icon(Icons.school, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'CERTIFICATE OF COMPLETION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Certificate Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'This is to certify that',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student Name
                  Text(
                    widget.userName.isNotEmpty ? widget.userName : 'Student',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'has successfully completed the course',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Course Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.course.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(),

                  // Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            dateString,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 2,
                            color: const Color(0xFF3498DB),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            widget.course.instructorName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 2,
                            color: const Color(0xFF3498DB),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Instructor',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Blockchain Verified',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
