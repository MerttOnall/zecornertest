import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/core/utils/zedosya_utils.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/zedosya/zedosya_api_repository.dart';
import 'package:zecorner/models/zedosya/zedosya_api_model.dart';

class EditZeDosyaScreen extends StatefulWidget {
  final ZeDosyaApiModel file;

  const EditZeDosyaScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<EditZeDosyaScreen> createState() => _EditZeDosyaScreenState();
}

class _EditZeDosyaScreenState extends State<EditZeDosyaScreen> {
  late bool viewPermission;
  PlatformFile? _selectedFile;
  PlatformFile? _previewFile;
  late final TextEditingController titleController;
  late final TextEditingController subtitleController;
  String? selectedCategory;
  late bool isFavorite;
  bool _isSaving = false;
  bool _isDeleting = false;

  late String _currentUuid;
  late String _currentFileName;
  String? _currentThumbnail;

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

    titleController = TextEditingController(text: widget.file.title);
    subtitleController = TextEditingController(text: widget.file.subTitle);
    selectedCategory =
        ZeDosyaUtils.formCategoryFromId(widget.file.category) ?? categories.first;
    isFavorite = widget.file.featured;
    viewPermission = widget.file.status != 0;
    _currentUuid = widget.file.uuid;
    _currentFileName = widget.file.fileName;
    _currentThumbnail = widget.file.thumbnail;
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
    if (_isSaving || _isDeleting) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Dosya başlığı zorunludur.', isError: true);
      return;
    }
    if (selectedCategory == null) {
      _showSnack('Lütfen dosya kategorisi seçin.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      var uuid = _currentUuid;
      var fileName = _currentFileName;

      if (_selectedFile?.path != null) {
        final uploadResult = await _contactRepository.uploadFile(
          File(_selectedFile!.path!),
          'document',
        );
        final newUuid = uploadResult.fold<String?>(
          (failure) {
            _showSnack('Dosya yüklenemedi: ${failure.message}', isError: true);
            return null;
          },
          (id) => id,
        );
        if (newUuid == null) return;
        uuid = newUuid;
        fileName = _selectedFile!.name;
      }

      var thumbnail = _currentThumbnail;
      if (_previewFile?.path != null) {
        final previewUpload = await _contactRepository.uploadFile(
          File(_previewFile!.path!),
          'thumbnail',
        );
        thumbnail = previewUpload.fold((_) => thumbnail, (id) => id);
      }

      final subTitle = subtitleController.text.trim().isNotEmpty
          ? subtitleController.text.trim()
          : ZeDosyaUtils.subTitleFromFileName(fileName);

      final updateResult = await _zeDosyaRepository.updateFile(
        id: widget.file.id,
        title: title,
        subTitle: subTitle,
        fileName: fileName,
        uuid: uuid,
        category: ZeDosyaUtils.formCategoryToId(selectedCategory),
        thumbnail: thumbnail,
        featured: isFavorite,
        status: viewPermission ? 1 : 0,
        connectedContacts: widget.file.connectedContacts,
      );

      updateResult.fold(
        (failure) => _showSnack('Güncelleme hatası: ${failure.message}', isError: true),
        (_) {
          _showSnack('Dosya güncellendi.', isError: false);
          if (mounted) Navigator.of(context).pop(true);
        },
      );
    } catch (e) {
      _showSnack('Beklenmeyen hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_isSaving || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dosyayı Sil'),
        content: Text('"${widget.file.title}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final result = await _zeDosyaRepository.deleteFile(widget.file.id);
      result.fold(
        (failure) => _showSnack('Silme hatası: ${failure.message}', isError: true),
        (_) {
          _showSnack('Dosya silindi.', isError: false);
          if (mounted) Navigator.of(context).pop(true);
        },
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
    final busy = _isSaving || _isDeleting;

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
                      'Dosya Düzenle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.red[700], size: 30),
                      onPressed: busy ? null : () => Navigator.of(context).pop(),
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
                      onChanged: busy ? null : (v) => setState(() => viewPermission = v),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Görüntüleme Yetkisi Ayarı',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FilePickerField(
                  label: 'Dosya',
                  hint: _currentFileName,
                  onTap: busy ? () {} : _pickMainFile,
                  value: _selectedFile?.name,
                ),
                const SizedBox(height: 16),
                _FilePickerField(
                  label: 'Dosya Önizleme',
                  hint: _currentThumbnail ?? 'Görsel seçin (isteğe bağlı)',
                  onTap: busy ? () {} : _pickPreviewFile,
                  value: _previewFile?.name,
                ),
                const SizedBox(height: 16),
                _TextFieldWithLabel(
                  label: 'Dosya Başlığı',
                  controller: titleController,
                  hint: 'Başlık giriniz',
                  enabled: !busy,
                ),
                const SizedBox(height: 16),
                _TextFieldWithLabel(
                  label: 'Dosya Alt Başlığı',
                  controller: subtitleController,
                  hint: 'Alt başlık giriniz',
                  enabled: !busy,
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
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: busy ? null : (v) => setState(() => selectedCategory = v),
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
                      onChanged: busy ? null : (v) => setState(() => isFavorite = v ?? false),
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
                    onPressed: busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Güncelle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: busy ? null : _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isDeleting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.red[700]),
                          )
                        : const Text('Dosyayı Sil'),
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
