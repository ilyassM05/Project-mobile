// =============================================================================
// MAIN.DART - Entry Point of the Flutter Application
// =============================================================================
// WHAT IS THIS FILE?
// This is the first file that runs when the app starts.
// It sets up Firebase, initializes state management, and decides which screen to show.
//
// KEY CONCEPTS:
// - Firebase: Backend service for authentication and database
// - Provider: State management library (shares data across the app)
// - MaterialApp: The root widget that configures the app
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/instructor/instructor_dashboard_screen.dart';
import 'services/data_seeding_service.dart';

// =============================================================================
// MAIN FUNCTION - App Entry Point
// =============================================================================
// This is where the app starts executing.
// "async" means it can wait for things to finish (like Firebase loading).
void main() async {
  // Required: Ensures Flutter is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Initialize Firebase (connect to backend)
  // Firebase handles: user login, database, cloud storage, etc.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // STEP 2: Seed the database with sample courses (ONE-TIME SETUP)
  // ⚠️ In production, you would remove these lines!
  final seeder = DataSeedingService();
  await seeder.seedAllData(); // Add sample courses to database
  await seeder.updateInstructorNames();
  print('✅ Database seeding complete! Remove these lines from main.dart');

  // STEP 3: Start the Flutter app
  runApp(const MyApp());
}

// =============================================================================
// MYAPP CLASS - Root Widget of the Application
// =============================================================================
// This widget wraps the entire app and provides:
// - State management (AuthProvider, CourseProvider)
// - Theme (colors, fonts)
// - Navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider: Makes AuthProvider and CourseProvider available
    // to ALL widgets in the app (like global variables)
    return MultiProvider(
      providers: [
        // AuthProvider: Handles user login/logout/registration
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // CourseProvider: Handles course data (fetch, search, filter)
        ChangeNotifierProvider(create: (_) => CourseProvider()),
      ],
      child: MaterialApp(
        title: 'E-Learning DApp', // App name
        debugShowCheckedModeBanner: false, // Hide "DEBUG" banner
        theme: AppTheme.lightTheme, // App colors and styles
        home: const AuthWrapper(), // First screen to show
      ),
    );
  }
}

// =============================================================================
// AUTHWRAPPER - Decides Which Screen to Show Based on Login Status
// =============================================================================
// This widget checks if the user is logged in:
// - NOT logged in → Show LoginScreen
// - Logged in as STUDENT → Show HomeScreen
// - Logged in as INSTRUCTOR → Show InstructorDashboardScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AuthProvider to check login status
    final authProvider = Provider.of<AuthProvider>(context);

    // Show loading spinner while checking if user is logged in
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // DECISION TREE: Which screen to show?
    if (authProvider.isAuthenticated) {
      // User IS logged in
      if (authProvider.isInstructor) {
        // User is an INSTRUCTOR → Show instructor dashboard
        return const InstructorDashboardScreen();
      }
      // User is a STUDENT → Show home screen with courses
      return const HomeScreen();
    } else {
      // User is NOT logged in → Show login screen
      return const LoginScreen();
    }
  }
}
