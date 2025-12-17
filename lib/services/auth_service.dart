import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';


/// Handles user authentication and session management.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the current logged-in user, or null if guest.
  User? get currentUser => _auth.currentUser;

  /// Determines if the current session is a guest session.
  bool get isGuest => currentUser == null;

  /// Signs in with email and password.
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Registers a new user and creates their profile entry.
  Future<void> signUp(String email, String password, String username) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create initial user profile in Realtime DB
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          username: username,
        );
        
        final userProfileData = newUser.toJson();
        print('Creating user profile: $userProfileData'); // Debug log
        
        await _db.child('users/${newUser.id}/profile').set(userProfileData);
        
        print('User profile created successfully for ${newUser.username}'); // Debug log
      }
    } catch (e) {
      print('Error in signUp: $e'); // Debug log
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Deletes the current user account and their data.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Optional: Delete user data from Realtime Database before deleting auth account
      await _db.child('users/${user.uid}').remove();
      await user.delete();
    }
  }
}
