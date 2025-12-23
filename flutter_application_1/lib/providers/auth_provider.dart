// =============================================================================
// AUTH PROVIDER - Manages User Authentication State
// =============================================================================
// WHAT IS THIS FILE?
// This is a "Provider" - a state management class that handles user login.
// When a user logs in or out, this class notifies all widgets to update.
//
// WHY DO WE NEED THIS?
// - Keeps track of who is logged in
// - Shares login status across the entire app
// - Handles login, logout, and registration logic
//
// KEY CONCEPTS:
// - ChangeNotifier: When data changes, it tells widgets to rebuild
// - notifyListeners(): Updates all widgets listening to this provider
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  // The service that talks to Firebase Auth
  final AuthService _authService = AuthService();

  // ---------------------------------------------------------------------------
  // STATE VARIABLES - Data we track
  // ---------------------------------------------------------------------------
  UserModel?
  _currentUser; // The currently logged in user (null if not logged in)
  bool _isLoading =
      false; // Are we waiting for something? (shows loading spinner)
  String? _errorMessage; // Error message to display to user

  // ---------------------------------------------------------------------------
  // GETTERS - Allow other widgets to read our state
  // ---------------------------------------------------------------------------
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Is anyone logged in?
  bool get isAuthenticated => _currentUser != null;

  // Is the current user an instructor? (for showing different screens)
  bool get isInstructor => _currentUser?.isInstructor ?? false;

  // Is the current user a student?
  bool get isStudent => _currentUser?.isStudent ?? false;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR - Runs when AuthProvider is created
  // ---------------------------------------------------------------------------
  AuthProvider() {
    // Listen to auth state changes (Firebase tells us when login status changes)
    _authService.authStateChanges.listen(
      (User? user) async {
        if (user != null) {
          // User just logged in - load their profile data
          try {
            await Future.delayed(const Duration(milliseconds: 500));
            await _loadUserData(user.uid);
          } catch (e) {
            print('Error in auth state listener: $e');
          }
        } else {
          // User logged out - clear current user
          _currentUser = null;
          _isLoading = false;
          notifyListeners(); // Tell widgets to update!
        }
      },
      onError: (error) {
        print('Auth state listener error: $error');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LOAD USER DATA - Fetch user profile from Firestore database
  // ---------------------------------------------------------------------------
  Future<void> _loadUserData(String userId) async {
    try {
      // Get user data from database
      _currentUser = await _authService.getUserData(userId);
      _isLoading = false;
      notifyListeners(); // Tell widgets to update!
    } catch (e) {
      print('Error loading user data: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN UP - Create a new user account
  // ---------------------------------------------------------------------------
  // Called when user submits registration form
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, // "student" or "instructor"
  }) async {
    try {
      _isLoading = true; // Show loading spinner
      _errorMessage = null; // Clear any previous errors
      notifyListeners();

      // Call Firebase to create account
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null; // Success if user was created
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Failed
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN IN - Log into existing account
  // ---------------------------------------------------------------------------
  // Called when user submits login form
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Call Firebase to verify credentials
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT - Log out the current user
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut(); // Tell Firebase to log out
      _currentUser = null; // Clear local user data

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE WALLET ADDRESS - Connect blockchain wallet to account
  // ---------------------------------------------------------------------------
  // Used for Web3/blockchain integration
  Future<void> updateWalletAddress(String walletAddress) async {
    try {
      if (_currentUser == null) return;

      // Save wallet address to database
      await _authService.updateUserProfile(
        userId: _currentUser!.userId,
        walletAddress: walletAddress,
      );

      // Update local user data
      _currentUser = _currentUser!.copyWith(
        walletAddress: walletAddress,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE DISPLAY NAME - Change user's name
  // ---------------------------------------------------------------------------
  Future<void> updateDisplayName(String displayName) async {
    try {
      if (_currentUser == null) return;

      await _authService.updateUserProfile(
        userId: _currentUser!.userId,
        displayName: displayName,
      );

      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // RESET PASSWORD - Send password reset email
  // ---------------------------------------------------------------------------
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CLEAR ERROR - Remove error message from screen
  // ---------------------------------------------------------------------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
