import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:brain_link/services/firestore_service.dart';
import 'package:brain_link/model/app_models.dart';

class AddLibraryScreen extends StatefulWidget {
  final String? initialCategory;

  const AddLibraryScreen({super.key, this.initialCategory});

  @override
  State<AddLibraryScreen> createState() => _AddLibraryScreenState();
}

class _AddLibraryScreenState extends State<AddLibraryScreen> {
  final _titleController = TextEditingController();
  String _selectedType = 'PDF';
  bool _isLoading = false;

  File? _selectedFile;
  Uint8List? _fileBytes;
  String? _selectedFileName;
  String? _selectedFileSizeStr;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'الكتب التقنية';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'zip', 'docx', 'jpg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      setState(() {
        _fileBytes = file.bytes;
        _selectedFile = kIsWeb || file.path == null ? null : File(file.path!);
        _selectedFileName = file.name;
        final mb = file.size / (1024 * 1024);
        _selectedFileSizeStr = "${mb.toStringAsFixed(1)} MB";

        final ext = file.extension?.toUpperCase() ?? 'PDF';
        if (['PDF', 'ZIP', 'DOCX'].contains(ext)) {
          _selectedType = ext;
        }
      });
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty ||
        (_selectedFile == null && _fileBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة العنوان واختيار ملف!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String fileUrl = '';
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'library_files/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName',
      );
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(_fileBytes!);
      } else {
        uploadTask = ref.putFile(_selectedFile!);
      }
      final snapshot = await uploadTask;
      fileUrl = await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage Upload Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء رفع الملف: $e')));
      }
      return;
    }

    final newItem = LibraryItem(
      id: '',
      title: _titleController.text.trim(),
      type: _selectedType,
      size: _selectedFileSizeStr ?? '0 MB',
      rating: '0.0',
      views: '0',
      fileUrl: fileUrl,
      category: _selectedCategory,
    );

    await FirestoreService().addLibraryItem(newItem);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const deepPurple = Color(0xFF5E35B1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'إضافة مرجع أو كتاب',
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
                hintText: 'اسم المرجع / الكتاب',
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
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: ['PDF', 'ZIP', 'DOCX'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items:
                  [
                    'الكتب التقنية',
                    'كورسات مرئية',
                    'ملخصات سريعة',
                    'أكواد جاهزة',
                    'قوالب وتصاميم',
                    'عام',
                  ].map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: InputDecoration(
                hintText: 'التصنيف',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // File Picking Area
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: deepPurple.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      (_selectedFile == null && _fileBytes == null)
                          ? Icons.upload_file_rounded
                          : Icons.check_circle_rounded,
                      size: 50,
                      color: (_selectedFile == null && _fileBytes == null)
                          ? Colors.grey
                          : Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (_selectedFile == null && _fileBytes == null)
                          ? 'اضغط هنا لاختيار الملف'
                          : _selectedFileName!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: (_selectedFile == null && _fileBytes == null)
                            ? Colors.grey[600]
                            : Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                        'رفع الملف وإضافته للمكتبة',
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
