import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/game_model.dart';

/// Firebase Realtime Database service for user game library.
/// 
/// Handles CRUD operations for user's game collection.
class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gets the current authenticated user's ID.
  /// Returns null if not authenticated.
  String? get userId => _auth.currentUser?.uid;

  /// Checks if user is authenticated.
  bool get isAuthenticated => userId != null;

  /// Streams user's game library from Firebase.
  Stream<List<Game>> getUserGames(String uid) {
    debugPrint('FirebaseService: Setting up stream for user: $uid');
    return _db.child('users/$uid/games').onValue.map((event) {
      final data = event.snapshot.value;
      debugPrint('FirebaseService: Received data update, data exists: ${data != null}');
      if (data == null) return <Game>[];

      try {
        final gamesMap = data as Map<dynamic, dynamic>;
        final games = gamesMap.entries.map((e) {
          final gameData = e.value as Map<dynamic, dynamic>;
          final json = gameData.cast<String, dynamic>();
          return Game.fromJson(json);
        }).toList();
        debugPrint('FirebaseService: Parsed ${games.length} games');
        return games;
      } catch (e) {
        debugPrint('FirebaseService: Error parsing user games: $e');
        return <Game>[];
      }
    });
  }

  /// Saves a game to user's library.
  Future<void> saveGame(Game game) async {
    if (userId == null) return;
    await _db.child('users/$userId/games/${game.id}').set(game.toJson());
  }

  /// Removes a game from user's library.
  Future<void> removeGame(int gameId) async {
    if (userId == null) return;
    await _db.child('users/$userId/games/$gameId').remove();
  }

  /// Updates game status, rating, and favorite flag.
  Future<void> updateGameStatus(
    int gameId,
    String status,
    double? platformRating,
    bool isFavorite,
  ) async {
    if (userId == null) return;
    await _db.child('users/$userId/games/$gameId').update({
      'status': status,
      'platformRating': platformRating,
      'isFavorite': isFavorite,
    });
  }
}
