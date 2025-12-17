import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/rawg_service.dart';
import '../services/auth_service.dart';


/// Central state manager for game library, discovery, and user session.
class GameManager extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final RawgService _rawgService = RawgService();
  final AuthService _authService = AuthService();

  // Public getters for services
  FirebaseService get firebaseService => _firebaseService;
  AuthService get authService => _authService;

  List<Game> _userGames = [];
  UserModel? _currentUserProfile;
  List<Game> _searchResults = [];
  List<Game> _trendingGames = [];
  List<Game> _newReleases = [];
  List<Game> _topRated = [];
  bool _isLoading = false;
  
  // Platform filtering state
  bool _filterByOwnedPlatforms = false;

  StreamSubscription? _userGamesSubscription;
  StreamSubscription? _userProfileSubscription;

  GameManager() {
    _init();
  }

  void _init() {
    // Listen to Auth State Changes
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        // User Logged In
        _subscribeToUserData(user.uid);
      } else {
        // Guest / Logged Out
        _unsubscribeUserData();
        _userGames = [];
        _currentUserProfile = null;
        notifyListeners();
      }
    });

    _loadTrending();
  }

  void _subscribeToUserData(String userId) {
    _userGamesSubscription?.cancel();
    _userGamesSubscription = _firebaseService.getUserGames(userId).listen((games) {
      _userGames = games;
      notifyListeners();
    });

    _userProfileSubscription?.cancel();
    _userProfileSubscription = _firebaseService.getUserProfile(userId).listen((profile) {
      _currentUserProfile = profile as UserModel?;
      notifyListeners();
    });
  }

  void _unsubscribeUserData() {
    _userGamesSubscription?.cancel();
    _userProfileSubscription?.cancel();
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

  // Getters - User Session
  User? get currentUser => _authService.currentUser;
  bool get isGuest => _authService.isGuest;
  UserModel? get userProfile => _currentUserProfile;

  // Getters - Game Lists
  List<Game> get games => List.unmodifiable(_userGames);
  List<Game> get searchResults => List.unmodifiable(_searchResults);
  
  // Filtered Discovery Lists
  List<Game> get trendingGames => _applyPlatformFilter(_trendingGames);
  List<Game> get newReleases => _applyPlatformFilter(_newReleases);
  List<Game> get topRated => _applyPlatformFilter(_topRated);

  bool get isLoading => _isLoading;
  bool get isPlatformFilterEnabled => _filterByOwnedPlatforms;

  // Getters - Filtered by Status
  List<Game> get playingGames => _userGames.where((g) => g.status == 'Playing').toList();
  List<Game> get completedGames => _userGames.where((g) => g.status == 'Completed').toList();
  List<Game> get plannedGames => _userGames.where((g) => g.status == 'Plan to Play').toList();
  List<Game> get onHoldGames => _userGames.where((g) => g.status == 'On Hold').toList();
  List<Game> get droppedGames => _userGames.where((g) => g.status == 'Dropped').toList();
  List<Game> get favoriteGames => _userGames.where((g) => g.isFavorite).toList();

  // Getters - Statistics
  int get totalGames => _userGames.length;
  int get playingCount => playingGames.length;
  int get completedCount => completedGames.length;
  int get plannedCount => plannedGames.length;
  int get favoriteCount => favoriteGames.length;

  double get averageRating {
    final ratedGames = _userGames.where(
      (g) => g.personalRating != null && g.personalRating! > 0,
    );
    if (ratedGames.isEmpty) return 0.0;
    return ratedGames.map((g) => g.personalRating!).reduce((a, b) => a + b) /
        ratedGames.length;
  }

  // Helper: Filter logic
  List<Game> _applyPlatformFilter(List<Game> rawList) {
    if (!_filterByOwnedPlatforms || isGuest || _currentUserProfile == null) {
      return List.unmodifiable(rawList);
    }
    
    final owned = _currentUserProfile!.ownedPlatforms.map((p) => p.toLowerCase()).toSet();
    if (owned.isEmpty) return List.unmodifiable(rawList);

    return rawList.where((game) {
      // Game platforms are comma-separated string in current model
      // We check if ANY of the game's platforms match owned platforms
      final gamePlatforms = game.platform.toLowerCase();
      return owned.any((op) => gamePlatforms.contains(op));
    }).toList();
  }


  // Actions

  void togglePlatformFilter(bool enabled) {
    _filterByOwnedPlatforms = enabled;
    notifyListeners();
  }

  /// Updates user profile details locally and remotely
  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    List<String>? ownedPlatforms,
  }) async {
    if (isGuest) return;
    
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (ownedPlatforms != null) updates['owned_platforms'] = ownedPlatforms;

    if (updates.isNotEmpty) {
      await _firebaseService.updateUserProfile(currentUser!.uid, updates);
    }
  }

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
  Future<void> addGame(Game game, {
    String status = 'Plan to Play',
    String? playedOnPlatform,
    double? personalRating,
  }) async {
    if (isGuest) throw Exception('Must be logged in to add games');

    final exists = _userGames.any((g) => g.id == game.id);
    if (exists) return;

    final newGame = game.copyWith(
      status: status,
      playedOnPlatform: playedOnPlatform,
      personalRating: personalRating,
    );
    await _firebaseService.saveGame(currentUser!.uid, newGame);
  }

  /// Removes a game from user's library.
  Future<void> removeGame(int gameId) async {
    if (isGuest) return;
    await _firebaseService.removeGame(currentUser!.uid, gameId);
  }

  /// Updates game status and/or rating.
  Future<void> updateGameDetails({
    required int id,
    String? status,
    double? personalRating, // Renamed from platformRating
    String? playedOnPlatform,
  }) async {
    if (isGuest) return;

    final index = _userGames.indexWhere((g) => g.id == id);
    if (index != -1) {
      final game = _userGames[index];
      await _firebaseService.updateGameStatus(
        currentUser!.uid,
        id,
        status ?? game.status,
        personalRating ?? game.personalRating,
        game.isFavorite,
        playedOnPlatform ?? game.playedOnPlatform,
      );
    }
  }

  /// Toggles favorite status for a game.
  Future<void> toggleFavorite(int id) async {
    if (isGuest) return;

    final index = _userGames.indexWhere((g) => g.id == id);
    if (index != -1) {
      final game = _userGames[index];
      await _firebaseService.updateGameStatus(
        currentUser!.uid,
        id,
        game.status,
        game.personalRating,
        !game.isFavorite,
        game.playedOnPlatform,
      );
    }
  }

  Game? getGameByTitle(String title) {
    try {
      return _userGames.firstWhere((g) => g.title == title);
    } catch (_) {
      return null;
    }
  }

  Game? getGameById(int id) {
    try {
      return _userGames.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
