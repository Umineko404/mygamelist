class Game {
  final String title;
  final String genre;
  final String platform;
  final double rating;
  final String imageUrl;
  final String description;
  final String releaseDate;
  final String status;
  final bool isFavorite;

  Game({
    required this.title,
    required this.genre,
    required this.platform,
    required this.rating,
    required this.imageUrl,
    required this.description,
    required this.releaseDate,
    required this.status,
    this.isFavorite = false,
  });

  Game copyWith({
    String? title,
    String? genre,
    String? platform,
    double? rating,
    String? imageUrl,
    String? description,
    String? releaseDate,
    String? status,
    bool? isFavorite,
  }) {
    return Game(
      title: title ?? this.title,
      genre: genre ?? this.genre,
      platform: platform ?? this.platform,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}