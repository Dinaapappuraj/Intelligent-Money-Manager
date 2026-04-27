import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Sign up
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign up failed (Firebase): ${e.message}");
      return null;
    } on PlatformException catch (e) {
      debugPrint("Sign up failed (Platform): ${e.message}");
      return null;
    }
  }

  // Sign in
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign in failed (Firebase): ${e.message}");
      return null;
    } on PlatformException catch (e) {
      debugPrint("Sign in failed (Platform): ${e.message}");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- NEW PRODUCTION METHODS ---
  Future<bool> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      // We need to notify listeners so the UI updates
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Failed to update display name: $e");
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate the user to confirm their identity
      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      // If re-authentication is successful, update the password
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Failed to change password: ${e.message}");
      return false; // You can pass e.message to the UI for specific errors
    }
  }
}

