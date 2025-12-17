import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user profile data in Firebase.
class UserDataService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Gets the gaming platforms owned by a user.
  Future<List<String>> getUserPlatforms(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId/platforms').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is List) {
          return data.cast<String>();
        } else if (data is Map) {
          return data.values.cast<String>().toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting user platforms: $e');
      return [];
    }
  }

  /// Saves the gaming platforms owned by a user.
  Future<void> saveUserPlatforms(String userId, List<String> platforms) async {
    try {
      await _database.child('users/$userId/platforms').set(platforms);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user platforms: $e');
      rethrow;
    }
  }

  /// Gets the user's bio.
  Future<String?> getUserBio(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId/bio').get();
      
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user bio: $e');
      return null;
    }
  }

  /// Saves the user's bio.
  Future<void> saveUserBio(String userId, String bio) async {
    try {
      await _database.child('users/$userId/bio').set(bio);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user bio: $e');
      rethrow;
    }
  }

  /// Gets full user profile data.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Updates user profile data.
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _database.child('users/$userId').update(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}
