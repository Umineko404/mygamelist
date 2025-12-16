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
  String? get _userId => _auth.currentUser?.uid;

  /// Checks if user is authenticated.
  bool get isAuthenticated => _userId != null;

  /// Streams user's game library from Firebase.
  Stream<List<Game>> getUserGames() {
    if (_userId == null) {
      return Stream.value([]);
    }
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
    if (_userId == null) return;
    await _db.child('users/$_userId/games/${game.id}').set(game.toJson());
  }

  /// Removes a game from user's library.
  Future<void> removeGame(int gameId) async {
    if (_userId == null) return;
    await _db.child('users/$_userId/games/$gameId').remove();
  }

  /// Updates game status, rating, and favorite flag.
  Future<void> updateGameStatus(
    int gameId,
    String status,
    double? platformRating,
    bool isFavorite,
  ) async {
    if (_userId == null) return;
    await _db.child('users/$_userId/games/$gameId').update({
      'status': status,
      'platformRating': platformRating,
      'isFavorite': isFavorite,
    });
  }
}
