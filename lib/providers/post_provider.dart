import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';

class PostProvider with ChangeNotifier {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  bool _hasError = false;
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> get comments => _comments;

  List<Map<String, dynamic>> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // Fetch all posts from the server
  Future<void> fetchPosts(int userId) async {
    _isLoading = true;
    notifyListeners();

    final url = '${APIConfig.postsUrl}?user_id=$userId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _posts = List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new post
  Future<bool> createPost({
    required int userId,
    required int moodId,
    required int moodScore,
    required String content,
    required bool isPosted,
    required String postDate,
  }) async {
    final url = APIConfig.postsUrl;

    final Map<String, dynamic> postData = {
      'user_id': userId,
      'mood_id': moodId,
      'mood_score': moodScore,
      'content': content,
      'is_posted': isPosted ? 1 : 0, // Convert boolean to integer (1 or 0)
      'post_date': postDate,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 201) {
        // Post successfully created, optionally refetch posts
        await fetchPosts(userId);
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> updatePost({
    required int postId,
    required int userId,
    required int moodId,
    required int moodScore,
    required String content,
    required bool isPosted,
    required String postDate,
    required String updatedAt,
  }) async {
    final url = '${APIConfig.postsUrl}?action=update_post';

    final Map<String, dynamic> postData = {
      'post_id': postId,
      'user_id': userId,
      'mood_id': moodId,
      'mood_score': moodScore,
      'content': content,
      'is_posted': isPosted ? 1 : 0, // Convert boolean to integer (1 or 0)
      'post_date': postDate,
      'updated_at': updatedAt,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        await fetchPosts(userId);
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> removePost(int postId) async {
    final url = '${APIConfig.postsUrl}?action=delete_post';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'post_id': postId}),
      );

      if (response.statusCode == 200) {
        _posts.removeWhere((post) => post['post_id'] == postId);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<void> searchPosts(String query, int userId) async {
    final url =
        '${APIConfig.postsUrl}?action=search_posts&query=$query&user_id=$userId';
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        _posts = data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to search posts');
      }
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPostsByStatus(int userId, int isPosted) async {
    final url =
        '${APIConfig.postsUrl}?action=get_posts_by_status&user_id=$userId&is_posted=$isPosted';
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _posts = List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (error) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all posts from local state
  void clearPosts() {
    _posts = [];
    notifyListeners();
  }

  Future<void> fetchComments(int postId) async {
    final url = '${APIConfig.postsUrl}?action=get_comments&post_id=$postId';
    _hasError = false;

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        _comments = data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (error) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchFirstComment(int postId) async {
    final url =
        '${APIConfig.postsUrl}?action=get_first_comment&post_id=$postId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load first comment');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<int> fetchCommentCount(int postId) async {
    final url =
        '${APIConfig.postsUrl}?action=get_comment_count&post_id=$postId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['comment_count'];
      } else {
        throw Exception('Failed to load comment count');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addComment(int postId, int userId, String comment) async {
    final url = '${APIConfig.postsUrl}?action=add_comment';

    final Map<String, dynamic> commentData = {
      'post_id': postId,
      'user_id': userId,
      'comment': comment,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(commentData),
      );

      if (response.statusCode == 201) {
        await fetchComments(postId);
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<String?> fetchLastSubMood(int userId) async {
    final url =
        '${APIConfig.postsUrl}?action=get_last_sub_mood&user_id=$userId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sub_mood'];
      } else {
        throw Exception('Failed to load last sub mood');
      }
    } catch (error) {
      rethrow;
    }
  }
}
