import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _contentController = TextEditingController();
  final _codeController = TextEditingController();
  bool _hasCode = false;
  bool _isLoading = false;

  void _submit() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final data = doc.data() ?? {};
    final String actualName =
        data['name'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'مستخدم BrainLink';
    final String actualRole = data['role'] == 'Teacher'
        ? 'معلم / خبير'
        : 'مطور / طالب';

    final newPost = Post(
      id: '',
      authorName: actualName,
      authorRole: actualRole,
      timeStamp: DateTime.now(),
      content: _contentController.text.trim(),
      hasCodeSnippet: _hasCode,
      snippetCode: _codeController.text.trim(),
      likesCount: 0,
      commentsCount: 0,
    );

    await FirestoreService().addPost(newPost);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'كتابة منشور جديد',
          style: TextStyle(color: deepPurple, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'ماذا تريد أن تناقش مع المجتمع؟',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'إرفاق كود برمجي؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _hasCode,
              activeColor: deepPurple,
              onChanged: (val) => setState(() => _hasCode = val),
            ),
            if (_hasCode) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                maxLines: 6,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'أدخل الكود هنا...',
                  fillColor: const Color(0xFF1E1E2E),
                  filled: true,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'نشر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
