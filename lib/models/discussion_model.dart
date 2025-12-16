/// Represents a discussion thread in the community.
class Discussion {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String category;
  final DateTime createdAt;
  final DateTime lastReplyAt;
  final int replyCount;

  Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.createdAt,
    required this.lastReplyAt,
    this.replyCount = 0,
  });

  factory Discussion.fromJson(Map<String, dynamic> json, String id) {
    return Discussion(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonymous',
      category: json['category'] ?? 'General',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      lastReplyAt: DateTime.fromMillisecondsSinceEpoch(json['lastReplyAt'] ?? json['createdAt'] ?? 0),
      replyCount: json['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastReplyAt': lastReplyAt.millisecondsSinceEpoch,
      'replyCount': replyCount,
    };
  }

  /// Returns a human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastReplyAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}

/// Represents a comment on a discussion.
class Comment {
  final String id;
  final String discussionId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String? parentId; // For nested replies
  final int replyCount;

  Comment({
    required this.id,
    required this.discussionId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.parentId,
    this.replyCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json, String id) {
    return Comment(
      id: id,
      discussionId: json['discussionId'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonymous',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      parentId: json['parentId'],
      replyCount: json['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussionId': discussionId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'parentId': parentId,
      'replyCount': replyCount,
    };
  }

  /// Returns a human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}
