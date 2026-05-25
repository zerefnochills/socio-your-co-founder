import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignInInstance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn();
    return _googleSignInInstance!;
  }

  // ── Mock In-Memory Authentication State ───────────────────────
  static User? _mockUser;
  static final _mockAuthChanges = StreamController<User?>.broadcast();

  // Stream of auth state changes — listened to by the provider
  Stream<User?> get authStateChanges {
    final controller = StreamController<User?>.broadcast();
    scheduleMicrotask(() {
      if (_mockUser != null) {
        controller.add(_mockUser);
      } else {
        controller.add(_auth.currentUser);
      }
    });

    final subReal = _auth.authStateChanges().listen((user) {
      if (_mockUser == null) {
        controller.add(user);
      }
    });

    final subMock = _mockAuthChanges.stream.listen((user) {
      controller.add(user);
    });

    controller.onCancel = () {
      subReal.cancel();
      subMock.cancel();
    };

    return controller.stream;
  }

  // Current user (nullable)
  User? get currentUser => _mockUser ?? _auth.currentUser;

  // Whether the app is in mock mode (using a local mock user instead of Firebase)
  bool get isMockMode => currentUser is MockUser;

  // ── Google Sign-In ────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Get the auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user doc in Firestore
      await _createUserDocIfNeeded(userCredential.user!);

      return userCredential;
    } catch (e) {
      print("Google Sign-In failed, falling back to local Mock Google User: $e");
      final mockGoogleUser = MockUser(
        uid: 'mock_google_user',
        displayName: 'Ayush Kumar',
        email: 'ayush@socio.ai',
        photoURL: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=120',
      );
      _mockUser = mockGoogleUser;
      _mockAuthChanges.add(mockGoogleUser);
      return MockUserCredential(mockGoogleUser);
    }
  }

  // ── Dev/Anonymous Sign-In ─────────────────────────────────────
  Future<User?> signInAnonymously() async {
    try {
      // 1. Try real Firebase anonymous auth first
      final userCredential = await _auth.signInAnonymously();
      await _createUserDocIfNeeded(userCredential.user!);
      return userCredential.user;
    } catch (e) {
      // 2. Fall back to a local MockUser when Firebase anonymous sign-in is disabled or fails
      print("Firebase Anonymous auth failed, falling back to local Mock User: $e");
      final guest = MockUser(
        uid: 'guest_user',
        displayName: 'Guest Founder',
        email: 'guest@socio.ai',
        photoURL: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=120',
      );
      _mockUser = guest;
      _mockAuthChanges.add(guest);
      return guest;
    }
  }

  // ── Create user document in Firestore on first sign-in ───────
  Future<void> _createUserDocIfNeeded(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // First time — create the document
      await userRef.set({
        'name': user.displayName ?? 'Founder',
        'email': user.email ?? '',
        'photo_url': user.photoURL ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    // If doc already exists, don't overwrite — just let them in
  }

  Future<void> signOut() async {
    _mockUser = null;
    _mockAuthChanges.add(null);
    final List<Future> signOutFutures = [_auth.signOut()];
    try {
      if (_googleSignInInstance != null) {
        signOutFutures.add(_googleSignInInstance!.signOut());
      }
    } catch (_) {}
    await Future.wait(signOutFutures);
  }

  // ── Get user display name ─────────────────────────────────────
  String get displayName =>
      currentUser?.displayName?.split(' ').first ?? 'Founder';

  // ── Get user UID ──────────────────────────────────────────────
  String? get uid => currentUser?.uid;

  // ── Error handler ─────────────────────────────────────────────
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with this email.');
      case 'network-request-failed':
        return Exception('No internet connection.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MockUser — implements standard Firebase User interface with noSuchMethod proxy
// ─────────────────────────────────────────────────────────────────────────────
class MockUser implements User {
  @override
  final String uid;

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  final String? photoURL;

  MockUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  @override
  final User? user;

  MockUserCredential(this.user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
