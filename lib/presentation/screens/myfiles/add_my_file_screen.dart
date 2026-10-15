import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/myfiles/my_files_repository.dart';

class AddMyFileScreen extends StatefulWidget {
  const AddMyFileScreen({super.key});

  @override
  State<AddMyFileScreen> createState() => _AddMyFileScreenState();
}

class _AddMyFileScreenState extends State<AddMyFileScreen> {
  static const _brandRed = Color(0xFFE53935);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final ContactApiRepository _uploadRepository = ContactApiRepository();
  final MyFilesRepository _myFilesRepository = MyFilesRepository(dio: Dio());

  PlatformFile? _selectedFile;
  PlatformFile? _previewFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  String _subTitleFromName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot >= fileName.length - 1) return 'other';
    switch (fileName.substring(dot + 1).toLowerCase()) {
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'pdf':
        return 'pdf';
      default:
        return fileName.substring(dot + 1).toLowerCase();
    }
  }

  Future<void> _pickMainFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
          'jpg', 'jpeg', 'png', 'webp', 'gif',
        ],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 50 * 1024 * 1024) {
        _showSnack('Dosya boyutu 50MB\'dan büyük olamaz.', isError: true);
        return;
      }
      if (file.path == null) {
        _showSnack('Dosya okunamadı. Lütfen tekrar deneyin.', isError: true);
        return;
      }
      setState(() => _selectedFile = file);
    } catch (_) {
      _showSnack('Dosya seçilirken hata oluştu.', isError: true);
    }
  }

  Future<void> _pickPreviewFile() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final file = File(image.path);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        _showSnack('Önizleme görseli 5MB\'dan büyük olamaz.', isError: true);
        return;
      }
      setState(() {
        _previewFile = PlatformFile(name: image.name, path: image.path, size: size);
      });
    } catch (_) {
      _showSnack('Görsel seçilirken hata oluştu.', isError: true);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Dosya başlığı zorunludur.', isError: true);
      return;
    }
    if (_selectedFile?.path == null) {
      _showSnack('Lütfen bir dosya seçin.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uploadResult = await _uploadRepository.uploadFile(
        File(_selectedFile!.path!),
        'document',
      );
      final fileUuid = uploadResult.fold<String?>((failure) {
        _showSnack('Dosya yüklenemedi: ${failure.message}', isError: true);
        return null;
      }, (id) => id);
      if (fileUuid == null) return;

      String? thumbnailId;
      if (_previewFile?.path != null) {
        final previewUpload = await _uploadRepository.uploadFile(
          File(_previewFile!.path!),
          'thumbnail',
        );
        thumbnailId = previewUpload.fold((_) => null, (id) => id);
      }

      final fileName = _selectedFile!.name;
      final subTitle = _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : _subTitleFromName(fileName);

      final createResult = await _myFilesRepository.createMyFile(
        title: title,
        subTitle: subTitle,
        fileName: fileName,
        uuid: fileUuid,
        thumbnail: thumbnailId,
      );

      createResult.fold(
        (failure) => _showSnack('Kayıt hatası: ${failure.message}', isError: true),
        (_) {
          _showSnack('Dosya başarıyla kaydedildi.', isError: false);
          if (mounted) Navigator.of(context).pop(true);
        },
      );
    } catch (e) {
      _showSnack('Beklenmeyen hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dosya Yükle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.red[700], size: 30),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(thickness: 1.2, color: Colors.grey[200]),
              const SizedBox(height: 16),
              _PickerField(
                label: 'Dosya',
                hint: 'Belge veya fotoğraf seçin',
                value: _selectedFile?.name,
                onTap: _isSaving ? () {} : _pickMainFile,
              ),
              const SizedBox(height: 16),
              _PickerField(
                label: 'Dosya önizleme',
                hint: 'Görsel seçin (isteğe bağlı)',
                value: _previewFile?.name,
                onTap: _isSaving ? () {} : _pickPreviewFile,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Dosya başlığı',
                controller: _titleController,
                hint: 'Başlık giriniz',
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Dosya alt başlığı',
                controller: _subtitleController,
                hint: 'Boş bırakılırsa dosya türü kullanılır',
                enabled: !_isSaving,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandRed,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Kaydet',
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
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.hint,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value == null ? Colors.grey[400] : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.add_box_rounded, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}
