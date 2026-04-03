import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:mehd_ai_flutter/models/user_profile.dart';

/// FILE 1 — auth_service.dart
///
/// Build Debrief:
/// This is the single gateway to Firebase Authentication. Every auth operation
/// goes through here — the UI never touches FirebaseAuth directly.
///
/// Why Firebase Auth was chosen:
/// 1. Password hashing is automatic (bcrypt) — we never see raw passwords.
/// 2. OAuth token management for Google, Apple, etc. is built in.
/// 3. Rate limiting prevents brute-force attacks on user accounts.
/// 4. Email verification and password reset flows are production-ready.
/// 5. For a financial app, rolling custom auth is dangerous — one mistake in
///    password storage and user money is at risk. Firebase handles this at
///    Google-scale with SOC 2 compliance.
///
/// Error handling strategy: every method returns a result string.
/// `null` = success, non-null = human-readable error message.
/// The UI simply checks `if (error != null)` and shows the message.
/// This means the app NEVER crashes from an auth failure.

class AuthService extends ChangeNotifier {
  // Lazy getters to prevent "App not initialized" errors on web parallel boot
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final SharedPreferences prefs;
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;

  User? get currentUser => _isFirebaseReady ? _auth.currentUser : _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn {
    if (!_isFirebaseReady) return _currentUser != null;
    return _currentUser != null || _auth.currentUser != null;
  }
  User? get immediateCurrentUser {
    if (!_isFirebaseReady) return _currentUser;
    return _auth.currentUser ?? _currentUser;
  }
  
  bool _isFirebaseReady = false;
  bool get isFirebaseReady => _isFirebaseReady;

  AuthService({required this.prefs}) {
    _initAsync();
  }

  Future<void> _initAsync() async {
    // Poll for Firebase ready state in parallel boot scenario
    int attempts = 0;
    while (Firebase.apps.isEmpty && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (Firebase.apps.isNotEmpty) {
      _isFirebaseReady = true;
      // Listen to auth state changes — if user logs out anywhere, we know instantly
      _auth.authStateChanges().listen((User? user) {
        _currentUser = user;
        if (user != null) {
          _loadUserProfile(user.uid);
        } else {
          _userProfile = null;
        }
        notifyListeners();
      });
      notifyListeners();
    } else {
      debugPrint("DEN_AUTH: Firebase failed to initialize in time.");
    }
  }

  /// Waiter for UI to ensure Firebase is ready before auth operations
  Future<void> ensureFirebaseReady() async {
    if (_isFirebaseReady) return;
    int attempts = 0;
    while (!_isFirebaseReady && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  /// Stream of auth state changes — used by SplashScreen to route users
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a new account with email and password, then creates Firestore doc
  Future<String?> signUpWithEmail(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name.trim());

      // Create user document in Firestore with default settings
      if (credential.user != null) {
        final profile = UserProfile(
          userId: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
          brokerType: BrokerType.demo,
          riskPercent: 1.0,
          paperTradingMode: true,
          onboardingComplete: false,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(profile.toJson());

        _userProfile = profile;
        _currentUser = credential.user;
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _handleAuthError(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Something went wrong. Please check your connection.';
    }
  }

  /// Signs in with email and password, loads user profile from Firestore
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserProfile(credential.user!.uid);
        _currentUser = credential.user;
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _handleAuthError(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Something went wrong. Please check your connection.';
    }
  }

  /// Google OAuth sign in — creates Firestore doc on first login
  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'Google sign in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user doc exists — if not, create it (first-time Google user)
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          final profile = UserProfile(
            userId: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Trader',
            email: userCredential.user!.email ?? '',
            brokerType: BrokerType.demo,
            riskPercent: 1.0,
            paperTradingMode: true,
            onboardingComplete: false,
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(profile.toJson());

          _userProfile = profile;
        } else {
          _userProfile = UserProfile.fromJson(doc.data() as Map<String, dynamic>);
        }

        _currentUser = userCredential.user;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Google sign in failed. Please try again.';
    }
  }

  /// Signs out and clears all local state
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Returns the current Firebase user (may be null)
  User? getCurrentUser() => _auth.currentUser;

  /// Sends a password reset email
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Could not send reset email. Please try again.';
    }
  }

  /// Loads user profile from Firestore — called on every sign in
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromJson(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  /// Converts Firebase error codes to friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
