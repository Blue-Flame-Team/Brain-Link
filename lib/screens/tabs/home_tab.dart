import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:brain_link/screens/home_features/comments_sheet.dart';
import 'package:brain_link/screens/home_features/favorites_screen.dart';
import 'package:brain_link/helpers/db_helper.dart';

String _formatTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inDays > 365) return 'منذ ${diff.inDays ~/ 365} سنة';
  if (diff.inDays >= 30) return 'منذ ${diff.inDays ~/ 30} شهر';
  if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
  if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
  if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
  return 'الآن';
}

class HomeTab extends StatefulWidget {
  final VoidCallback? onViewAllSessions;
  final VoidCallback? onProfileTapped;

  const HomeTab({super.key, this.onViewAllSessions, this.onProfileTapped});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final firestoreService = FirestoreService();
  final Map<String, ValueNotifier<bool>> _favoriteNotifiers = {};

  @override
  void dispose() {
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  ValueNotifier<bool> _getFavoriteNotifier(String postId) {
    if (!_favoriteNotifiers.containsKey(postId)) {
      final notifier = ValueNotifier<bool>(false);
      DbHelper.instance.isFavorite(postId).then((isFav) {
        notifier.value = isFav;
      });
      _favoriteNotifiers[postId] = notifier;
    }
    return _favoriteNotifiers[postId]!;
  }

  void _toggleFavorite(Post post) async {
    final notifier = _getFavoriteNotifier(post.id);
    final wasFavorite = notifier.value;
    if (wasFavorite) {
      await DbHelper.instance.deleteFavorite(post.id);
      notifier.value = false;
    } else {
      await DbHelper.instance.insertFavorite(post);
      notifier.value = true;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid != post.authorId) {
        final currentName = currentUser.displayName ?? 'مستخدم';
        await firestoreService.addFavoriteNotification(
          authorId: post.authorId,
          postId: post.id,
          favoritedByUserName: currentName,
        );
      }
    }
  }

  void _openFavoritesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
    for (var entry in _favoriteNotifiers.entries) {
      final isFav = await DbHelper.instance.isFavorite(entry.key);
      entry.value.value = isFav;
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);
    const bgColor = Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => Navigator.pushNamed(context, '/add-post'),
        backgroundColor: deepPurple,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomHeader(context),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "الجلسات النشطة",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: widget.onViewAllSessions,
                      child: Text(
                        "عرض الكل",
                        style: TextStyle(
                          fontSize: 14,
                          color: deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SESSIONS STREAM BUILDER
              SizedBox(
                height: 195,
                child: StreamBuilder<List<Session>>(
                  stream: firestoreService.getSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("لا توجد جلسات حالياً"));
                    }

                    final sessions = snapshot.data!
                        .where(
                          (s) =>
                              s.isLive || s.startTime.isAfter(DateTime.now()),
                        )
                        .take(5)
                        .toList();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildSessionCard(sessions[index]),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "المجتمع النشط",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // POSTS STREAM BUILDER
              StreamBuilder<List<Post>>(
                stream: firestoreService.getPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("لا توجد منشورات حتى الآن"),
                    );
                  }
                  final posts = snapshot.data!;
                  for (var post in posts) {
                    _getFavoriteNotifier(post.id);
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: _buildPostCard(context, post),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: deepPurple.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "BrainLink",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Colors.black87,
                  ),
                  onPressed: _openFavoritesScreen,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onProfileTapped,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: deepPurple.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: deepPurple,
                    radius: 18,
                    child: Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    const deepPurple = Color(0xFF5E35B1);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      //margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: deepPurple.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: deepPurple.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: deepPurple,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: session.isLive
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    if (session.isLive)
                      const Icon(
                        Icons.circle,
                        color: Colors.redAccent,
                        size: 8,
                      ),
                    if (session.isLive) const SizedBox(width: 6),
                    Text(
                      session.isLive ? "مباشر الآن" : "قادم",
                      style: TextStyle(
                        color: session.isLive
                            ? Colors.redAccent
                            : Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            session.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: deepPurple,
                radius: 12,
                child: Icon(Icons.person, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                session.hostName,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    const deepPurple = Color(0xFF5E35B1);
    final favoriteNotifier = _getFavoriteNotifier(post.id);
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_id';
    final isLiked = post.likedBy.contains(currentUserId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: deepPurple.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const CircleAvatar(
                  backgroundColor: deepPurple,
                  radius: 22,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${post.authorRole} • ${_formatTimeAgo(post.timeStamp)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (post.authorId == currentUserId)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('حذف المنشور'),
                          content: const Text(
                            'هل أنت متأكد من حذف هذا المنشور؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'حذف',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await FirestoreService().deletePost(post.id);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          if (post.hasCodeSnippet && post.snippetCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                post.snippetCode,
                style: const TextStyle(
                  color: Color(0xFFA6ACCD),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInteractionAction(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                post.likesCount.toString(),
                Colors.redAccent,
                isActive: isLiked,
                onTap: () {
                  FirestoreService().toggleLikePost(
                    post.id,
                    post.likedBy,
                    currentUserId,
                  );
                },
              ),
              const SizedBox(width: 24),
              _buildFavoriteAction(favoriteNotifier, post),
              const SizedBox(width: 24),
              _buildInteractionAction(
                Icons.chat_bubble_outline_rounded,
                post.commentsCount.toString(),
                deepPurple,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentsSheet(post: post),
                  );
                },
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Share.share("مشاركة من تطبيق BrainLink:\n${post.content}");
                },
                child: Icon(
                  Icons.share_rounded,
                  color: Colors.grey[400],
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionAction(
    IconData icon,
    String count,
    Color activeColor, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.grey.shade500,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: isActive ? activeColor : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteAction(ValueNotifier<bool> isFavNotifier, Post post) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFavNotifier,
      builder: (context, isFav, _) {
        return InkWell(
          onTap: () => _toggleFavorite(post),
          child: Row(
            children: [
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.redAccent : Colors.grey.shade500,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                isFav ? "مفضلة" : "أضف",
                style: TextStyle(
                  color: isFav ? Colors.redAccent : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
