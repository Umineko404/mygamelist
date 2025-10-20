import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../data/sample_data.dart';

class GameManager extends ChangeNotifier {
  final List<Game> _games = List.from(sampleGames);

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get playingGames => _games.where((g) => g.status == 'Playing').toList();
  List<Game> get completedGames => _games.where((g) => g.status == 'Completed').toList();
  List<Game> get plannedGames => _games.where((g) => g.status == 'Plan to Play').toList();
  List<Game> get favoriteGames => _games.where((g) => g.isFavorite).toList();

  int get totalGames => _games.length;
  int get playingCount => playingGames.length;
  int get completedCount => completedGames.length;
  int get plannedCount => plannedGames.length;
  int get favoriteCount => favoriteGames.length;

  double get averageRating => _games.isEmpty ? 0 : _games.map((g) => g.rating).where((r) => r > 0).reduce((a, b) => a + b) / _games.where((g) => g.rating > 0).length;

  Game? getGameByTitle(String title) => _games.firstWhere((g) => g.title == title, orElse: () => sampleGames.first);

  void updateGameDetails({required String title, String? status, double? rating}) {
    final index = _games.indexWhere((g) => g.title == title);
    if (index != -1) {
      _games[index] = _games[index].copyWith(
        status: status,
        rating: rating,
      );
      notifyListeners();
    }
  }

  void toggleFavorite(String title) {
    final index = _games.indexWhere((g) => g.title == title);
    if (index != -1) {
      final game = _games[index];
      _games[index] = game.copyWith(isFavorite: !game.isFavorite);
      notifyListeners();
    }
  }
}