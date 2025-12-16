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
        final List<Game> games = [];
        
        if (data is Map) {
          final gamesMap = data;
          for (final entry in gamesMap.entries) {
            try {
              final gameData = entry.value;
              if (gameData is Map) {
                final json = _convertToStringDynamicMap(gameData);
                games.add(Game.fromJson(json));
              }
            } catch (e) {
              debugPrint('FirebaseService: Error parsing game ${entry.key}: $e');
            }
          }
        }
        
        debugPrint('FirebaseService: Parsed ${games.length} games');
        return games;
      } catch (e) {
        debugPrint('FirebaseService: Error parsing user games: $e');
        return <Game>[];
      }
    });
  }

  /// Recursively converts a dynamic map to Map with String keys
  Map<String, dynamic> _convertToStringDynamicMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertToStringDynamicMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), _convertList(value));
        } else {
          return MapEntry(key.toString(), value);
        }
      });
    }
    return {};
  }

  /// Converts a list, handling nested maps
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertToStringDynamicMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
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
