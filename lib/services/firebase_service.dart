import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/game_model.dart';

/// Firebase Realtime Database service for user game library.
/// 
/// Handles CRUD operations for user's game collection.
class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // TODO: Replace with actual user authentication
  final String _userId = 'test_user_1';

  /// Streams user's game library from Firebase.
  Stream<List<Game>> getUserGames() {
    return _db.child('users/$_userId/games').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      try {
        final gamesMap = data as Map<dynamic, dynamic>;
        return gamesMap.entries.map((e) {
          final gameData = e.value as Map<dynamic, dynamic>;
          final json = gameData.cast<String, dynamic>();
          return Game.fromJson(json);
        }).toList();
      } catch (e) {
        debugPrint('Error parsing user games: $e');
        return [];
      }
    });
  }

  /// Saves a game to user's library.
  Future<void> saveGame(Game game) async {
    await _db.child('users/$_userId/games/${game.id}').set(game.toJson());
  }

  /// Removes a game from user's library.
  Future<void> removeGame(int gameId) async {
    await _db.child('users/$_userId/games/$gameId').remove();
  }

  /// Updates game status, rating, and favorite flag.
  Future<void> updateGameStatus(
    int gameId,
    String status,
    double? platformRating,
    bool isFavorite,
  ) async {
    await _db.child('users/$_userId/games/$gameId').update({
      'status': status,
      'platformRating': platformRating,
      'isFavorite': isFavorite,
    });
  }
}
