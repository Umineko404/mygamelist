import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/game_model.dart';
import '../models/user_model.dart';

/// Firebase Realtime Database service for user game library.
/// 
/// Handles CRUD operations for user's game collection and profile.
class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Streams user's game library from Firebase.
  Stream<List<Game>> getUserGames(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    
    return _db.child('users/$userId/games').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      try {
        // Handle if data is List (Firebase array behavior for integer keys)
        if (data is List) {
          return data
              .where((e) => e != null)
              .map((e) {
                try {
                  final json = Map<String, dynamic>.from(e as Map);
                  return Game.fromJson(json);
                } catch (err) {
                  debugPrint('Error parsing individual game (list): $err');
                  return null;
                }
              })
              .whereType<Game>()
              .toList();
        }

        // Handle if data is Map
        final gamesMap = data as Map<dynamic, dynamic>;
        return gamesMap.entries.map((e) {
          try {
            final gameData = e.value as Map<dynamic, dynamic>;
            final json = gameData.cast<String, dynamic>();
            return Game.fromJson(json);
          } catch (err) {
            debugPrint('Error parsing individual game (map): $err');
            return null;
          }
        }).whereType<Game>().toList();
        
      } catch (e) {
        debugPrint('Critical error parsing user games: $e');
        return [];
      }
    });
  }

  /// Streams user profile data.
  Stream<UserModel?> getUserProfile(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _db.child('users/$userId/profile').onValue.map((event) {
      final data = event.snapshot.value;
      debugPrint('getUserProfile - Raw data: $data'); // Debug log
      
      if (data == null) {
        debugPrint('getUserProfile - No data found for user $userId');
        return null;
      }
      
      try {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> profileData = Map<String, dynamic>.from(data as Map);
        
        final userModel = UserModel.fromJson(profileData, userId);
        debugPrint('getUserProfile - Loaded user: ${userModel.username}'); // Debug log
        return userModel;
      } catch (e) {
        debugPrint('Error parsing user profile: $e');
        debugPrint('Data type: ${data.runtimeType}');
        debugPrint('Data content: $data');
        return null;
      }
    });
  }

  /// Saves a game to user's library.
  Future<void> saveGame(String userId, Game game) async {
    if (userId.isEmpty) throw Exception('User not logged in');
    await _db.child('users/$userId/games/${game.id}').set(game.toJson());
  }

  /// Removes a game from user's library.
  Future<void> removeGame(String userId, int gameId) async {
    if (userId.isEmpty) throw Exception('User not logged in');
    await _db.child('users/$userId/games/$gameId').remove();
  }

  /// Updates game status, rating, fields etc.
  Future<void> updateGameStatus(
    String userId,
    int gameId,
    String status,
    double? personalRating,
    bool isFavorite,
    String? playedOnPlatform,
  ) async {
    if (userId.isEmpty) throw Exception('User not logged in');
    
    await _db.child('users/$userId/games/$gameId').update({
      'status': status,
      'personalRating': personalRating,
      'isFavorite': isFavorite,
      'playedOnPlatform': playedOnPlatform,
    });
  }

  /// Updates user profile (avatar, owned platforms).
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) throw Exception('User not logged in');
    await _db.child('users/$userId/profile').update(data);
  }
}
