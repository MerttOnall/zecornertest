import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/core/utils/zedosya_utils.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/zedosya/zedosya_api_repository.dart';

class AddZeDosyaScreen extends StatefulWidget {
  const AddZeDosyaScreen({Key? key}) : super(key: key);

  @override
  State<AddZeDosyaScreen> createState() => _AddZeDosyaScreenState();
}

class _AddZeDosyaScreenState extends State<AddZeDosyaScreen> {
  bool viewPermission = true;
  PlatformFile? _selectedFile;
  PlatformFile? _previewFile;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  String? selectedCategory;
  bool isFavorite = false;
  bool _isSaving = false;

  late final ContactApiRepository _contactRepository;
  late final ZeDosyaApiRepository _zeDosyaRepository;

  final List<String> categories = [
    'Sözleşme',
    'Form',
    'Rapor',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _contactRepository = ContactApiRepository();
    _zeDosyaRepository = ZeDosyaApiRepository(dio: Dio());
  }

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickMainFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ZeDosyaUtils.allPickExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        _showSnack('Dosya boyutu 10MB\'dan büyük olamaz.', isError: true);
        return;
      }
      if (file.path == null) {
        _showSnack('Dosya okunamadı. Lütfen tekrar deneyin.', isError: true);
        return;
      }

      setState(() => _selectedFile = file);
    } catch (e) {
      _showSnack('Dosya seçilirken hata oluştu.', isError: true);
    }
  }

  Future<void> _pickPreviewFile() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
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
        _previewFile = PlatformFile(
          name: image.name,
          path: image.path,
          size: size,
        );
      });
    } catch (e) {
      _showSnack('Görsel seçilirken hata oluştu.', isError: true);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Dosya başlığı zorunludur.', isError: true);
      return;
    }
    if (_selectedFile?.path == null) {
      _showSnack('Lütfen bir dosya seçin.', isError: true);
      return;
    }
    if (selectedCategory == null) {
      _showSnack('Lütfen dosya kategorisi seçin.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mainFile = File(_selectedFile!.path!);
      final uploadResult = await _contactRepository.uploadFile(mainFile, 'document');
      final fileUuid = uploadResult.fold<String?>(
        (failure) {
          _showSnack('Dosya yüklenemedi: ${failure.message}', isError: true);
          return null;
        },
        (id) => id,
      );
      if (fileUuid == null) return;

      String? thumbnailId;
      if (_previewFile?.path != null) {
        final previewUpload = await _contactRepository.uploadFile(
          File(_previewFile!.path!),
          'thumbnail',
        );
        thumbnailId = previewUpload.fold((_) => null, (id) => id);
      }

      final fileName = _selectedFile!.name;
      final subTitle = subtitleController.text.trim().isNotEmpty
          ? subtitleController.text.trim()
          : ZeDosyaUtils.subTitleFromFileName(fileName);

      final createResult = await _zeDosyaRepository.createFile(
        title: title,
        subTitle: subTitle,
        fileName: fileName,
        uuid: fileUuid,
        category: ZeDosyaUtils.formCategoryToId(selectedCategory),
        thumbnail: thumbnailId,
        featured: isFavorite,
        status: viewPermission ? 1 : 0,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dosya Oluştur',
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Switch(
                      value: viewPermission,
                      activeColor: Colors.red[700],
                      onChanged: _isSaving ? null : (v) => setState(() => viewPermission = v),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Görüntüleme Yetkisi Ayarı',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Bu dosyayı kimlerin görebileceğini ayarlayın.',
                      child: Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FilePickerField(
                  label: 'Dosya',
                  hint: 'Belge veya fotoğraf seçin',
                  onTap: _isSaving ? () {} : _pickMainFile,
                  value: _selectedFile?.name,
                ),
                const SizedBox(height: 16),
                _FilePickerField(
                  label: 'Dosya Önizleme',
                  hint: 'Görsel seçin (isteğe bağlı)',
                  onTap: _isSaving ? () {} : _pickPreviewFile,
                  value: _previewFile?.name,
                ),
                const SizedBox(height: 16),
                _TextFieldWithLabel(
                  label: 'Dosya Başlığı',
                  controller: titleController,
                  hint: 'Başlık giriniz',
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),
                _TextFieldWithLabel(
                  label: 'Dosya Alt Başlığı',
                  controller: subtitleController,
                  hint: 'Boş bırakılırsa dosya türü kullanılır',
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dosya Kategorisi',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    value: selectedCategory,
                    items: categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving ? null : (v) => setState(() => selectedCategory = v),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    icon: Icon(Icons.expand_more, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isFavorite,
                      activeColor: Colors.red[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: _isSaving ? null : (v) => setState(() => isFavorite = v ?? false),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Sık Kullanılanlara Ekle',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}

class _FilePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  final String? value;

  const _FilePickerField({
    required this.label,
    required this.hint,
    required this.onTap,
    this.value,
    Key? key,
  }) : super(key: key);

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

class _TextFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  const _TextFieldWithLabel({
    required this.label,
    required this.controller,
    required this.hint,
    this.enabled = true,
    Key? key,
  }) : super(key: key);

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
