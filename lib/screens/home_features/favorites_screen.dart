import 'package:flutter/material.dart';
import 'package:brain_link/helpers/db_helper.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Post> _favoritePosts = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favList = await DbHelper.instance.getFavorites();
      setState(() {
        _favoritePosts = favList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  Future<void> _removeFromFavorites(Post post) async {
    await DbHelper.instance.deleteFavorite(post.id);
    setState(() => _favoritePosts.removeWhere((p) => p.id == post.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إزالة ${post.authorName} من المفضلات')),
      );
    }
  }

  Future<void> _toggleLike(Post post) async {
    if (_currentUserId == null) return;
    final isLiked = post.likedBy.contains(_currentUserId);
    try {
      await FirebaseFirestore.instance.collection('posts').doc(post.id).update({
        'likedBy': isLiked
            ? FieldValue.arrayRemove([_currentUserId])
            : FieldValue.arrayUnion([_currentUserId]),
        'likesCount': FieldValue.increment(isLiked ? -1 : 1),
      });

      final index = _favoritePosts.indexWhere((p) => p.id == post.id);
      if (index == -1) return;

      final updatedLikes = List<String>.from(post.likedBy);
      if (isLiked) {
        updatedLikes.remove(_currentUserId);
      } else {
        updatedLikes.add(_currentUserId!);
      }

      final updatedPost = Post(
        id: post.id,
        authorId: post.authorId,
        authorName: post.authorName,
        authorRole: post.authorRole,
        timeStamp: post.timeStamp,
        content: post.content,
        hasCodeSnippet: post.hasCodeSnippet,
        snippetCode: post.snippetCode,
        likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
        commentsCount: post.commentsCount,
        likedBy: updatedLikes,
      );

      await DbHelper.instance.insertFavorite(updatedPost);

      setState(() {
        _favoritePosts[index] = updatedPost;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF6A1B9A);
    const bgColor = Color(0xFFF5F5F5);
    final isLikedColor = Colors.red;
    final greyColor = Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلات', style: TextStyle(color: Colors.white)),
        backgroundColor: deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoritePosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد بوستات مفضلة بعد',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favoritePosts.length,
              itemBuilder: (context, index) {
                final post = _favoritePosts[index];
                final isLiked =
                    _currentUserId != null &&
                    post.likedBy.contains(_currentUserId);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: deepPurple,
                      child: Text(
                        post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : '؟',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      post.content.length > 50
                          ? '${post.content.substring(0, 50)}...'
                          : post.content,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? isLikedColor : greyColor,
                          ),
                          onPressed: () => _toggleLike(post),
                        ),
                        Text(
                          '${post.likesCount}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () => _removeFromFavorites(post),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
