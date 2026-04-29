import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:brain_link/navigation/AppRoutes.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? _selectedRole;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> roles = [
    {
      "title": "Student",
      "desc": "I want to learn and explore basics",
      "icon": Icons.school_outlined,
      "key": "student",
    },
    {
      "title": "Junior Developer",
      "desc": "I building projects and starting career",
      "icon": Icons.code_rounded,
      "key": "junior",
    },
    {
      "title": "Senior Developer",
      "desc": "I lead projects and mentor teams",
      "icon": Icons.psychology_outlined,
      "key": "senior",
    },
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),
              _buildHeaderIcon(),
              const SizedBox(height: 25),
              const Text(
                "Choose your role",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E35B1),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "It helps us customize your experience and display relevant content.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: roles.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final item = roles[index];
                  return _roleCard(
                    item['title'],
                    item['desc'],
                    item['icon'],
                    item['key'],
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildContinueButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_search_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _roleCard(String title, String desc, IconData icon, String role) {
    bool isSelected = _selectedRole == role;
    const Color deepPurple = Color(0xFF5E35B1);

    return GestureDetector(
      onTap: () async {
        await _audioPlayer.play(AssetSource('sounds/click.mp3'));
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? deepPurple : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? deepPurple.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: deepPurple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: deepPurple, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 10),
              const Icon(
                Icons.check_circle_rounded,
                color: deepPurple,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _selectedRole == null
            ? null
            : () async {
                await _audioPlayer.play(AssetSource('sounds/click.mp3'));
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E35B1),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "Continue",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
