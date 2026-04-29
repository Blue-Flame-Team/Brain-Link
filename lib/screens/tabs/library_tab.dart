import 'package:flutter/material.dart';
import 'package:brain_link/screens/library_features/library_category_screen.dart';
import 'package:brain_link/screens/forms/add_library_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);
    const bgColor = Color(0xFFF8F9FD);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'library_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AddLibraryScreen(initialCategory: 'عام'),
          ),
        ),
        backgroundColor: deepPurple,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(
          Icons.note_add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomHeader(context),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "المواد التعليمية",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "اكتشف مصادر برمجية، كتب، وأكواد جاهزة للمساعدة وتبادل المعرفة.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "تصفح بالأقسام",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildCategoryCard(
                    context,
                    "الكتب التقنية",
                    "كل ما يخص البرمجة",
                    Icons.menu_book_rounded,
                    Colors.blue.shade600,
                  ),
                  _buildCategoryCard(
                    context,
                    "كورسات مرئية",
                    "دورات وفيديوهات",
                    Icons.play_circle_fill_rounded,
                    deepPurple,
                  ),
                  _buildCategoryCard(
                    context,
                    "ملخصات سريعة",
                    "Cheatsheets",
                    Icons.list_alt_rounded,
                    Colors.orange.shade600,
                  ),
                  _buildCategoryCard(
                    context,
                    "أكواد جاهزة",
                    "انسخ واستخدم",
                    Icons.data_object_rounded,
                    Colors.teal.shade600,
                  ),
                  _buildCategoryCard(
                    context,
                    "قوالب وتصاميم",
                    "UI/UX و قوالب",
                    Icons.view_quilt_rounded,
                    Colors.pink.shade600,
                  ),
                  _buildCategoryCard(
                    context,
                    "عام",
                    "مصادر متنوعة أخرى",
                    Icons.category_rounded,
                    Colors.blueGrey.shade600,
                  ),
                ],
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
                ),
              ),
            ],
          ),
          Container(
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
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryCategoryScreen(categoryTitle: title),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
