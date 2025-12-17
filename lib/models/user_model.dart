/// Represents a registered user's profile information.
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final List<String> ownedPlatforms;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.ownedPlatforms = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] ?? '',
      username: json['username'] ?? 'User',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      ownedPlatforms: json['owned_platforms'] != null
          ? List<String>.from(json['owned_platforms'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'owned_platforms': ownedPlatforms,
    };
  }

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    String? bio,
    List<String>? ownedPlatforms,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      ownedPlatforms: ownedPlatforms ?? this.ownedPlatforms,
    );
  }
}
