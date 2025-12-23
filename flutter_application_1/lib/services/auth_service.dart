// =============================================================================
// AUTH SERVICE - Firebase Authentication Service
// =============================================================================
// WHAT IS THIS FILE?
// This service handles all communication with Firebase Authentication.
// It provides functions for sign up, sign in, sign out, and password reset.
//
// WHAT IS FIREBASE AUTH?
// - A Google service that handles user accounts
// - Stores email/password securely (we never see passwords)
// - Handles security (rate limiting, encryption)
// - Provides streams to track login state
//
// FLOW:
// 1. User enters email + password in LoginScreen
// 2. AuthProvider calls AuthService.signIn()
// 3. AuthService talks to Firebase
// 4. Firebase verifies credentials
// 5. User gets logged in (or error is returned)
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';

class AuthService {
  // Firebase Auth instance - handles authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance - handles database (user profiles)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // AUTH STATE STREAM - Listen for login/logout events
  // ---------------------------------------------------------------------------
  // Returns a stream that emits when user logs in or out
  // Used by AuthProvider to update UI instantly
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get currently logged in user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // SIGN UP - Create a new user account
  // ---------------------------------------------------------------------------
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, // "student" or "instructor"
  }) async {
    try {
      print('🔐 Starting sign up process for: $email');

      // STEP 1: Create user in Firebase Auth
      // Firebase handles password hashing and security
      print('📝 Creating Firebase Auth user...');
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user == null) {
        print('❌ User credential returned null');
        return null;
      }
      print('✅ Firebase Auth user created: ${user.uid}');

      // STEP 2: Create our own user model with extra data
      print('📝 Creating UserModel...');
      final userModel = UserModel(
        userId: user.uid,
        email: email,
        displayName: displayName,
        role: role,
        walletAddress: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      print('✅ UserModel created');

      // STEP 3: Save user data to Firestore database
      // Firebase Auth only stores email/password
      // We store extra info (name, role) in Firestore
      print('📝 Saving to Firestore...');
      final jsonData = userModel.toJson();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(jsonData);
      print('✅ User data saved to Firestore');

      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ Unexpected error during sign up:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw 'Sign up failed: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN IN - Log into existing account
  // ---------------------------------------------------------------------------
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Ask Firebase to verify email + password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) return null;

      // Get user's full profile from Firestore
      return await getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign in failed: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT - Log out current user
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Tell Firebase to end session
    } catch (e) {
      throw 'Sign out failed: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // GET USER DATA - Fetch user profile from Firestore
  // ---------------------------------------------------------------------------
  Future<UserModel?> getUserData(String userId) async {
    try {
      // Query Firestore for user document
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      // Convert Firestore data to UserModel object
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE USER PROFILE - Change name or wallet address
  // ---------------------------------------------------------------------------
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? walletAddress,
  }) async {
    try {
      // Build update object with only changed fields
      Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (walletAddress != null) {
        updates['walletAddress'] = walletAddress;
      }

      // Update Firestore document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // RESET PASSWORD - Send password reset email
  // ---------------------------------------------------------------------------
  Future<void> resetPassword(String email) async {
    try {
      // Firebase sends email with reset link
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Password reset failed: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // HANDLE AUTH EXCEPTIONS - Convert Firebase errors to user-friendly messages
  // ---------------------------------------------------------------------------
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Quick helpers
  bool get isSignedIn => currentUser != null;
  String? get currentUserId => currentUser?.uid;
}
