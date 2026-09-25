import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Check if user has admin privileges
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check specific primary admin email
    if (user.email?.toLowerCase() == 'admin@gmail.com') {
      return true;
    }

    try {
      // Check in Firestore users/roles collection
      final userDoc = await _firestore.collection(AppConstants.colUsers).doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['role'] == AppConstants.roleAdmin) {
          return true;
        }
      }

      // Check custom claims
      final idTokenResult = await user.getIdTokenResult();
      if (idTokenResult.claims?['admin'] == true || idTokenResult.claims?['role'] == 'admin') {
        return true;
      }
    } catch (e) {
      // Fallback
    }

    return false;
  }

  /// Create student auth account (optional helper for admin)
  Future<UserCredential> createStudentAuth({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send Password Reset Email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
