import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';
import 'package:intl/intl.dart' as intl;

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLive = false;
  bool _isLoading = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان الجلسة')),
      );
      return;
    }

    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رابط الاجتماع')),
      );
      return;
    }

    if (!_isLive && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء تحديد موعد الجلسة')));
      return;
    }

    setState(() => _isLoading = true);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    DateTime startTime = DateTime.now();
    if (!_isLive && _selectedDate != null && _selectedTime != null) {
      startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final String hostName = currentUser?.displayName ?? 'مستخدم';

    final newSession = Session(
      id: '',
      title: _titleController.text.trim(),
      hostName: hostName,
      startTime: startTime,
      isLive: _isLive,
      tags: tags.isEmpty ? ['عام'] : tags,
      participantsCount: 0,
      meetingUrl: _urlController.text.trim(),
    );

    await FirestoreService().addSession(newSession);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'بدء جلسة جديدة',
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
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'عنوان الجلسة',
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
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'الوسوم (افصل بينها بفاصلة كـ Flutter, Dart)',
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
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'رابط الاجتماع (Zoom, Google Meet, إلخ)',
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
                'مباشر الآن؟',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'إيقاف الخيار يعني جدولة الجلسة ليتم عرضها قريباً',
              ),
              value: _isLive,
              activeThumbColor: Colors.redAccent,
              onChanged: (val) => setState(() => _isLive = val),
            ),
            if (!_isLive) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null || _selectedTime == null
                            ? 'تحديد موعد الجلسة'
                            : '${intl.DateFormat('yyyy/MM/dd').format(_selectedDate!)} - ${_selectedTime!.format(context)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: deepPurple,
                      ),
                    ],
                  ),
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
                        'إطلاق الجلسة',
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
