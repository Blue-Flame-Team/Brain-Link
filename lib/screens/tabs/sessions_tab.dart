import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:intl/intl.dart' as intl;

class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  final FirestoreService firestoreService = FirestoreService();
  String _selectedTab = 'النشطة الآن';
  final Set<String> _remindedSessions = {};

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8F9FD);
    const deepPurple = Color(0xFF5E35B1);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'sessions_fab',
        onPressed: () => Navigator.pushNamed(context, '/add-session'),
        backgroundColor: deepPurple,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(
          Icons.video_call_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCustomHeader(context),
              const SizedBox(height: 20),
              const Text(
                "جلسات المذاكرة",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "انضم إلى جلسات البرمجة المشتركة وتفاعل مع\nمجتمع المطورين بسهولة.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildTabs(),
              const SizedBox(height: 24),

              StreamBuilder<List<Session>>(
                stream: firestoreService.getSessions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Text("لا توجد جلسات متاحة"),
                    );
                  }

                  List<Session> filtered = snapshot.data!;
                  if (_selectedTab == 'النشطة الآن') {
                    filtered = snapshot.data!.where((s) => s.isLive).toList();
                  } else if (_selectedTab == 'القادمة') {
                    filtered = snapshot.data!
                        .where(
                          (s) =>
                              !s.isLive && s.startTime.isAfter(DateTime.now()),
                        )
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Text("لا توجد جلسات متاحة في هذا القسم"),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSessionCard(context, filtered[index]),
                        );
                      },
                    ),
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
              const CircleAvatar(
                backgroundColor: deepPurple,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabItem("النشطة الآن", true),
          const SizedBox(width: 12),
          _tabItem("القادمة", false),
          const SizedBox(width: 12),
          _tabItem("الكل", false),
        ],
      ),
    );
  }

  Widget _tabItem(String text, bool hasDot) {
    const deepPurple = Color(0xFF5E35B1);
    bool isSelected = _selectedTab == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? deepPurple : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: deepPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDot) ...[
              const Icon(Icons.circle, color: Colors.redAccent, size: 10),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Session session) {
    const tealColor = Color(0xFF00BFA5);
    const deepPurple = Color(0xFF5E35B1);

    final dateFormat = intl.DateFormat('hh:mm a', 'en_US');
    final timeStr = session.isLive
        ? "نشط الآن"
        : "يبدأ في ${dateFormat.format(session.startTime)}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: deepPurple.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: session.isLive
                      ? Colors.red.withValues(alpha: 0.1)
                      : deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isLive
                      ? Icons.sensors_rounded
                      : Icons.event_available_rounded,
                  color: session.isLive ? Colors.redAccent : deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: session.isLive ? Colors.redAccent : deepPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            session.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: deepPurple,
                    radius: 16,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.hostName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "المضيف",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${session.participantsCount}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: session.isLive
                ? ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(session.meetingUrl);
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'لا يمكن فتح هذا الرابط برجاء التأكد من صحته',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text(
                      "انضمام الآن",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : _remindedSessions.contains(session.id)
                ? OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _remindedSessions.remove(session.id);
                      });
                    },
                    icon: const Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: Colors.green,
                    ),
                    label: const Text(
                      "تم التذكير",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _remindedSessions.add(session.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تفعيل التذكير لهذه الجلسة'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: deepPurple,
                    ),
                    label: const Text(
                      "تذكيرني",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: deepPurple,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: deepPurple, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
