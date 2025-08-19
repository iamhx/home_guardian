import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_guardian/services/firebase_messaging_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isInitializing = true; // For app startup Firebase auth check
  bool _isAuthenticating = false; // For login/register operations
  String? _errorMessage;

  // Password visibility states
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  // Getters
  bool get isLoggedIn => _user != null;
  User? get user => _user;
  String? get username => _user?.displayName ?? _user?.email?.split('@')[0];
  String? get email => _user?.email;
  bool get isInitializing => _isInitializing; // For main app loading check
  bool get isLoading => _isAuthenticating; // For login/register button loading
  String? get errorMessage => _errorMessage;
  bool get obscureLoginPassword => _obscureLoginPassword;
  bool get obscureRegisterPassword => _obscureRegisterPassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitializing =
          false; // Set initializing to false after initial auth check
      notifyListeners();
    });
  }

  // Password visibility toggles
  void toggleLoginPasswordVisibility() {
    _obscureLoginPassword = !_obscureLoginPassword;
    notifyListeners();
  }

  void toggleRegisterPasswordVisibility() {
    _obscureRegisterPassword = !_obscureRegisterPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      throw _errorMessage!;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      throw _errorMessage!;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;

      // Update display name with username
      await _user?.updateDisplayName(username);
      await _user?.reload();
      _user = _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      throw _errorMessage!;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      throw _errorMessage!;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticating = true;
    notifyListeners();
    await FirebaseMessagingService.unsubscribeFromWakeWordTopic();
    try {
      await _auth.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Failed to logout. Please try again.';
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      throw _errorMessage!;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      throw _errorMessage!;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
