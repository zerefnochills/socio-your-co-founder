import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth state changes — listened to by the provider
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user (nullable)
  User? get currentUser => _auth.currentUser;

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
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Sign-in failed. Please try again.');
    }
  }

  // ── Anonymous Sign-In (For Testing/Bypass) ─────────────────────
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      await _createUserDocIfNeeded(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Anonymous sign-in failed. Please ensure Anonymous Auth is enabled in Firebase Console.');
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

  // ── Sign out ──────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Get user display name ─────────────────────────────────────
  String get displayName =>
      _auth.currentUser?.displayName?.split(' ').first ?? 'Founder';

  // ── Get user UID ──────────────────────────────────────────────
  String? get uid => _auth.currentUser?.uid;

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
