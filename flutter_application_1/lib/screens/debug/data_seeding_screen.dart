import 'package:flutter/material.dart';
import '../../services/data_seeding_service.dart';
import '../../config/app_theme.dart';

/// Debug screen to seed Firestore data
/// This screen should only be used during development
class DataSeedingScreen extends StatefulWidget {
  const DataSeedingScreen({super.key});

  @override
  State<DataSeedingScreen> createState() => _DataSeedingScreenState();
}

class _DataSeedingScreenState extends State<DataSeedingScreen> {
  final DataSeedingService _seedingService = DataSeedingService();
  bool _isSeeding = false;
  String _message = 'Ready to seed data';

  Future<void> _seedData() async {
    setState(() {
      _isSeeding = true;
      _message = 'Seeding data...';
    });

    try {
      await _seedingService.seedAllData();
      setState(() {
        _message = '✅ Data seeded successfully!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all courses and quizzes from Firestore. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSeeding = true;
      _message = 'Clearing data...';
    });

    try {
      await _seedingService.clearAllData();
      setState(() {
        _message = '✅ Data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _updateInstructorNames() async {
    setState(() {
      _isSeeding = true;
      _message = 'Updating instructor names...';
    });

    try {
      await _seedingService.updateInstructorNames();
      setState(() {
        _message = '✅ Instructor names updated!';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Seeding'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload,
                size: 100,
                color: _isSeeding ? Colors.grey : AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                _message,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              if (_isSeeding)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _seedData,
                    icon: const Icon(Icons.upload),
                    label: const Text('Seed Mock Data to Firestore'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateInstructorNames,
                    icon: const Icon(Icons.person),
                    label: const Text('Update to Moroccan Names'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _clearData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXL),
              Card(
                color: AppTheme.infoColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Tap "Seed Mock Data" to populate Firestore',
                      ),
                      const Text(
                        '2. This will upload 3 courses and 17 quizzes',
                      ),
                      const Text('3. Only run once per database'),
                      const Text('4. Check Firebase Console to verify'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
