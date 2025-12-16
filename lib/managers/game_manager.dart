import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/game_model.dart';
import '../services/firebase_service.dart';
import '../services/rawg_service.dart';

/// Central state manager for game library and discovery features.
/// 
/// Handles user's game collection (from Firebase) and
/// fetches trending/popular games from RAWG API.
class GameManager extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final RawgService _rawgService = RawgService();

  List<Game> _userGames = [];
  List<Game> _searchResults = [];
  List<Game> _trendingGames = [];
  List<Game> _newReleases = [];
  List<Game> _topRated = [];
  bool _isLoading = false;

  StreamSubscription<List<Game>>? _gamesSubscription;
  StreamSubscription<User?>? _authSubscription;

  GameManager() {
    _init();
  }

  void _init() {
    // Listen for auth state changes to reinitialize game subscription
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('GameManager: Auth state changed, user: ${user?.uid}');
      _setupGameSubscription(user);
    });
    _loadTrending();
  }

  void _setupGameSubscription(User? user) {
    // Cancel existing subscription
    _gamesSubscription?.cancel();
    
    // Clear games when logged out
    if (user == null) {
      debugPrint('GameManager: User is null, clearing games');
      _userGames = [];
      notifyListeners();
      return;
    }

    debugPrint('GameManager: Setting up subscription for user: ${user.uid}');
    
    // Subscribe to user's games with the current user's ID
    _gamesSubscription = _firebaseService.getUserGames(user.uid).listen(
      (games) {
        debugPrint('GameManager: Received ${games.length} games from stream');
        _userGames = games;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('GameManager: Stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _gamesSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    try {
      _trendingGames = await _rawgService.getTrendingGames();
      _newReleases = await _rawgService.getNewReleases();
      _topRated = await _rawgService.getTopRated();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending/new/top: $e');
    }
  }

  // Getters - Game Lists
  List<Game> get games => List.unmodifiable(_userGames);
  List<Game> get searchResults => List.unmodifiable(_searchResults);
  List<Game> get trendingGames => List.unmodifiable(_trendingGames);
  List<Game> get newReleases => List.unmodifiable(_newReleases);
  List<Game> get topRated => List.unmodifiable(_topRated);
  bool get isLoading => _isLoading;

  // Getters - Filtered by Status
  List<Game> get playingGames =>
      _userGames.where((g) => g.status == 'Playing').toList();
  List<Game> get completedGames =>
      _userGames.where((g) => g.status == 'Completed').toList();
  List<Game> get plannedGames =>
      _userGames.where((g) => g.status == 'Plan to Play').toList();
  List<Game> get onHoldGames =>
      _userGames.where((g) => g.status == 'On Hold').toList();
  List<Game> get droppedGames =>
      _userGames.where((g) => g.status == 'Dropped').toList();
  List<Game> get favoriteGames => _userGames.where((g) => g.isFavorite).toList();

  // Getters - Statistics
  int get totalGames => _userGames.length;
  int get playingCount => playingGames.length;
  int get completedCount => completedGames.length;
  int get plannedCount => plannedGames.length;
  int get favoriteCount => favoriteGames.length;

  double get averageRating {
    final ratedGames = _userGames.where(
      (g) => g.platformRating != null && g.platformRating! > 0,
    );
    if (ratedGames.isEmpty) return 0.0;
    return ratedGames.map((g) => g.platformRating!).reduce((a, b) => a + b) /
        ratedGames.length;
  }

  // Actions

  /// Searches games from RAWG API.
  Future<void> searchGames(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _rawgService.searchGames(query);
    } catch (e) {
      debugPrint('Search failed: $e');
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a game to user's library.
  Future<void> addGame(Game game, {String status = 'Plan to Play'}) async {
    final exists = _userGames.any((g) => g.id == game.id);
    if (exists) return;

    final newGame = game.copyWith(
      status: status,
      isFavorite: game.isFavorite, // Preserve the favorite flag
    );
    await _firebaseService.saveGame(newGame);
  }

  /// Removes a game from user's library.
  Future<void> removeGame(int gameId) async {
    await _firebaseService.removeGame(gameId);
  }

  /// Updates game status and/or rating.
  Future<void> updateGameDetails({
    required int id,
    String? status,
    double? platformRating,
  }) async {
    final index = _userGames.indexWhere((g) => g.id == id);
    if (index != -1) {
      final game = _userGames[index];
      await _firebaseService.updateGameStatus(
        id,
        status ?? game.status,
        platformRating ?? game.platformRating,
        game.isFavorite,
      );
    }
  }

  /// Toggles favorite status for a game.
  Future<void> toggleFavorite(int id) async {
    final index = _userGames.indexWhere((g) => g.id == id);
    if (index != -1) {
      final game = _userGames[index];
      await _firebaseService.updateGameStatus(
        id,
        game.status,
        game.platformRating,
        !game.isFavorite,
      );
    }
  }

  /// Finds a game in library by title.
  Game? getGameByTitle(String title) {
    try {
      return _userGames.firstWhere((g) => g.title == title);
    } catch (_) {
      return null;
    }
  }

  /// Finds a game in library by ID.
  Game? getGameById(int id) {
    try {
      return _userGames.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
