import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/discussion_model.dart';

/// Firebase service for discussions and comments.
class DiscussionService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@').first;

  /// Streams all discussions ordered by last reply time.
  Stream<List<Discussion>> getDiscussions() {
    return _db
        .child('discussions')
        .orderByChild('lastReplyAt')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Discussion>[];

      try {
        final discussionsMap = data as Map<dynamic, dynamic>;
        final discussions = discussionsMap.entries.map((e) {
          final json = Map<String, dynamic>.from(e.value as Map);
          return Discussion.fromJson(json, e.key.toString());
        }).toList();

        // Sort by lastReplyAt descending (most recent first)
        discussions.sort((a, b) => b.lastReplyAt.compareTo(a.lastReplyAt));
        return discussions;
      } catch (e) {
        debugPrint('DiscussionService: Error parsing discussions: $e');
        return <Discussion>[];
      }
    });
  }

  /// Gets a single discussion by ID.
  Future<Discussion?> getDiscussion(String id) async {
    final snapshot = await _db.child('discussions/$id').get();
    if (!snapshot.exists || snapshot.value == null) return null;

    final json = Map<String, dynamic>.from(snapshot.value as Map);
    return Discussion.fromJson(json, id);
  }

  /// Creates a new discussion.
  Future<String?> createDiscussion({
    required String title,
    required String content,
    required String category,
  }) async {
    if (_userId == null) return null;

    final ref = _db.child('discussions').push();
    final now = DateTime.now().millisecondsSinceEpoch;

    await ref.set({
      'title': title,
      'content': content,
      'category': category,
      'authorId': _userId,
      'authorName': _userName ?? 'Anonymous',
      'createdAt': now,
      'lastReplyAt': now,
      'replyCount': 0,
    });

    return ref.key;
  }

  /// Streams comments for a discussion (top-level comments only).
  Stream<List<Comment>> getComments(String discussionId) {
    return _db
        .child('comments')
        .orderByChild('discussionId')
        .equalTo(discussionId)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Comment>[];

      try {
        final commentsMap = data as Map<dynamic, dynamic>;
        final comments = commentsMap.entries
            .map((e) {
              final json = Map<String, dynamic>.from(e.value as Map);
              return Comment.fromJson(json, e.key.toString());
            })
            .where((c) => c.parentId == null) // Only top-level comments
            .toList();

        // Sort by createdAt ascending (oldest first)
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return comments;
      } catch (e) {
        debugPrint('DiscussionService: Error parsing comments: $e');
        return <Comment>[];
      }
    });
  }

  /// Streams replies to a specific comment.
  Stream<List<Comment>> getReplies(String parentCommentId) {
    return _db
        .child('comments')
        .orderByChild('parentId')
        .equalTo(parentCommentId)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Comment>[];

      try {
        final repliesMap = data as Map<dynamic, dynamic>;
        final replies = repliesMap.entries.map((e) {
          final json = Map<String, dynamic>.from(e.value as Map);
          return Comment.fromJson(json, e.key.toString());
        }).toList();

        // Sort by createdAt ascending
        replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return replies;
      } catch (e) {
        debugPrint('DiscussionService: Error parsing replies: $e');
        return <Comment>[];
      }
    });
  }

  /// Adds a comment to a discussion.
  Future<bool> addComment({
    required String discussionId,
    required String content,
    String? parentId,
  }) async {
    if (_userId == null) return false;

    try {
      final ref = _db.child('comments').push();
      final now = DateTime.now().millisecondsSinceEpoch;

      await ref.set({
        'discussionId': discussionId,
        'content': content,
        'authorId': _userId,
        'authorName': _userName ?? 'Anonymous',
        'createdAt': now,
        'parentId': parentId,
        'replyCount': 0,
      });

      // Update discussion's lastReplyAt and replyCount
      final discussionRef = _db.child('discussions/$discussionId');
      await discussionRef.update({
        'lastReplyAt': now,
      });

      // Increment reply count using transaction
      await discussionRef.child('replyCount').runTransaction((value) {
        return Transaction.success((value as int? ?? 0) + 1);
      });

      // If this is a reply to a comment, increment parent's replyCount
      if (parentId != null) {
        await _db.child('comments/$parentId/replyCount').runTransaction((value) {
          return Transaction.success((value as int? ?? 0) + 1);
        });
      }

      return true;
    } catch (e) {
      debugPrint('DiscussionService: Error adding comment: $e');
      return false;
    }
  }

  /// Seeds initial discussions (call once to populate Firebase).
  Future<void> seedDiscussions() async {
    final snapshot = await _db.child('discussions').get();
    if (snapshot.exists) {
      debugPrint('DiscussionService: Discussions already exist, skipping seed');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final discussions = [
      {
        'title': 'What are your predictions for The Game Awards 2025?',
        'content': 'The Game Awards are coming up! I think Elden Ring: Nightreign will win GOTY. What are your predictions for the winners this year?',
        'authorId': 'system',
        'authorName': 'GamerX123',
        'category': 'General',
        'createdAt': now - 7200000, // 2 hours ago
        'lastReplyAt': now - 7200000,
        'replyCount': 0,
      },
      {
        'title': 'Silent Hill f: Return to Form or a New Direction?',
        'content': 'With Silent Hill f being developed by a new team, do you think it will capture the essence of the original games or take the series in a completely new direction?',
        'authorId': 'system',
        'authorName': 'HorrorFanatic',
        'category': 'Silent Hill',
        'createdAt': now - 18000000, // 5 hours ago
        'lastReplyAt': now - 18000000,
        'replyCount': 0,
      },
      {
        'title': 'Is Metaphor: ReFantazio the true Persona successor?',
        'content': 'Atlus has really outdone themselves with Metaphor. The combat system, the world-building, everything feels like a natural evolution. What do you all think?',
        'authorId': 'system',
        'authorName': 'AtlusFan',
        'category': 'JRPG',
        'createdAt': now - 86400000, // 1 day ago
        'lastReplyAt': now - 86400000,
        'replyCount': 0,
      },
      {
        'title': 'Looking for co-op partners for Forza Horizon 6!',
        'content': 'Just got the game and looking for people to race with! Drop your gamertags below if you want to team up for some online races.',
        'authorId': 'system',
        'authorName': 'SpeedDemon',
        'category': 'Racing',
        'createdAt': now - 172800000, // 2 days ago
        'lastReplyAt': now - 172800000,
        'replyCount': 0,
      },
    ];

    for (final discussion in discussions) {
      await _db.child('discussions').push().set(discussion);
    }

    debugPrint('DiscussionService: Seeded ${discussions.length} discussions');
  }
}
