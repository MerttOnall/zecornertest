import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class AddOffersScreen extends StatefulWidget {
  const AddOffersScreen({Key? key}) : super(key: key);

  @override
  State<AddOffersScreen> createState() => _AddOffersScreenState();
}

class _AddOffersScreenState extends State<AddOffersScreen> {
  bool status = true;
  bool allCategories = false;
  String? selectedCategory;
  String? selectedType;
  String? selectedAudience;
  final TextEditingController campaignNameController = TextEditingController();
  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _checkingAccess = true;
  bool _isAdmin = false;

  final List<String> categories = [
    'Giyim',
    'Elektronik',
    'Gıda',
    'Kozmetik',
    'Diğer',
  ];
  final List<String> types = [
    'Broker',
    'Gayrimenkul Danışmanı',
    'Takım Lideri',
    'Ofis Asistenı',
  ];
  final List<String> audiences = [
    'Tüm Kullanıcılar',
    'Belirli Grup',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }

  Future<void> _checkAdminAccess() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final roleCodes = await authCubit.getUserRoleCodes();
      if (!mounted) return;
      setState(() {
        _isAdmin = roleCodes.contains('role_admin') || authCubit.isAdmin;
        _checkingAccess = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _checkingAccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: AppStatusView.loading(
          title: 'Yetki kontrol ediliyor',
          message: 'Kampanya oluşturma yetkisi doğrulanıyor.',
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AppStatusView.error(
          title: 'Erişim engellendi',
          message: 'Kampanya oluşturma yalnızca admin kullanıcılar içindir.',
          onRetry: () => Navigator.of(context).maybePop(),
          retryLabel: 'Geri Dön',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst başlık ve kapatma
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kampanya Oluştur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.red[700], size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(thickness: 1.2, color: Colors.grey[200]),
                const SizedBox(height: 18),
                // Medya yükleme alanı
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 40),
                        const SizedBox(height: 8),
                        Text('Medya Yükleyin', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Durum switchi
                Row(
                  children: [
                    Switch(
                      value: status,
                      activeColor: Colors.green,
                      onChanged: (v) => setState(() => status = v),
                    ),
                    const SizedBox(width: 4),
                    Text('Durum', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Kampanya aktif/pasif durumunu ayarlayın.',
                      child: Icon(Icons.info_outline, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Temel Bilgiler başlığı
                Text('Kampanya Temel Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                // Kampanya adı
                _TextFieldWithLabel(
                  label: 'Kampanya Adı',
                  controller: campaignNameController,
                  hint: '',
                ),
                const SizedBox(height: 14),
                // Marka adı
                _TextFieldWithLabel(
                  label: 'Marka Adı',
                  controller: brandNameController,
                  hint: '',
                ),
                const SizedBox(height: 14),
                // Kategori
                Text('Kategori', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text('Birden Fazla Kategori Seçin...'),
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(cat, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    icon: Icon(Icons.expand_more, color: Colors.grey[600]),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 10),
                // Tüm kategoriler switchi
                Row(
                  children: [
                    Switch(
                      value: allCategories,
                      activeColor: Colors.red[700],
                      onChanged: (v) => setState(() => allCategories = v),
                    ),
                    const SizedBox(width: 4),
                    Text('Tüm Kategoriler', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Tüm kategorilerde geçerli olsun mu?',
                      child: Icon(Icons.info_outline, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Kampanya türü
                Text('Kampanya Türü', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    hint: const Text('Seçiniz'),
                    items: types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    icon: Icon(Icons.expand_more, color: Colors.grey[600]),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 16),
                // Açıklama
                Text('Açıklama', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                _RichTextField(controller: descriptionController),
                const SizedBox(height: 24),
                // Hedef Kitle
                const SizedBox(height: 18),
                Text('Hedef Kitle', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedAudience,
                    hint: const Text('Hedef Kitle'),
                    items: audiences
                        .map((aud) => DropdownMenuItem(
                              value: aud,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(aud, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedAudience = v),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    icon: Icon(Icons.expand_more, color: Colors.grey[600]),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 14),
                // Tüm Gruplar Katılabilir
                Row(
                  children: [
                    Switch(
                      value: false,
                      activeColor: Colors.red[700],
                      onChanged: (v) {},
                    ),
                    const SizedBox(width: 4),
                    Text('Tüm Gruplar Katılabilir', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Tüm gruplar katılabilir mi?',
                      child: Icon(Icons.info_outline, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                // Başlangıç ve Bitiş Tarihi Seç
                Row(
                  children: [
                    Switch(
                      value: false,
                      activeColor: Colors.red[700],
                      onChanged: (v) {},
                    ),
                    const SizedBox(width: 4),
                    Text('Başlangıç ve Bitiş Tarihi Seç', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Kampanya için tarih aralığı seçin.',
                      child: Icon(Icons.info_outline, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Kampanya İndirim Detayları
                Row(
                  children: [
                    Text('Kampanya İndirim Detayları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'İndirim detaylarını girin.',
                      child: Icon(Icons.info_outline, color: Colors.red, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Yüzde/TL tab barı
                _DiscountTabBar(),
                const SizedBox(height: 14),
                // İndirim Oranı
                _TextFieldWithLabel(
                  label: 'İndirim Oranı',
                  controller: TextEditingController(),
                  hint: '%10 veya ₺150',
                ),
                const SizedBox(height: 12),
                // Minimum Harcama Tutarı
                _TextFieldWithLabel(
                  label: 'Minimum Harcama Tutarı',
                  controller: TextEditingController(),
                  hint: '₺150',
                ),
                const SizedBox(height: 12),
                // İndirim Kodu
                _TextFieldWithLabel(
                  label: 'İndirim Kodu',
                  controller: TextEditingController(),
                  hint: '',
                ),
                const SizedBox(height: 18),
                // Kampanya Kuralları
                Text('Kampanya Kuralları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                // Kapsam
                _MultilineTextFieldWithLabel(
                  label: 'Kapsam',
                  controller: TextEditingController(),
                  hint: '',
                ),
                const SizedBox(height: 12),
                // Kullanım Şartları
                _MultilineTextFieldWithLabel(
                  label: 'Kullanım Şartları',
                  controller: TextEditingController(),
                  hint: '',
                ),
                const SizedBox(height: 18),
                // Kampanya Dosyası
                Text('Kampanya Dosyası', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                _FilePickerField(
                  label: '',
                  hint: 'Dosya seçiniz',
                  onTap: () {},
                  value: null,
                ),
                const SizedBox(height: 24),
                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

class _TextFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _TextFieldWithLabel({required this.label, required this.controller, required this.hint, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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

class _RichTextField extends StatelessWidget {
  final TextEditingController controller;
  const _RichTextField({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format ikonları (sadece görsel, işlevsiz)
          Row(
            children: [
              DropdownButton<String>(
                value: 'Normal',
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Başlık', child: Text('Başlık')),
                ],
                onChanged: (_) {},
                underline: SizedBox(),
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Icon(Icons.format_bold, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Icon(Icons.format_italic, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Icon(Icons.link, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Icon(Icons.format_list_bulleted, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Icon(Icons.format_list_numbered, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Icon(Icons.format_clear, size: 20, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Açıklama giriniz...',
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab bar widget
class _DiscountTabBar extends StatefulWidget {
  @override
  State<_DiscountTabBar> createState() => _DiscountTabBarState();
}

class _DiscountTabBarState extends State<_DiscountTabBar> {
  int selected = 0; // 0: %, 1: TL
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selected = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: selected == 0 ? const Color(0xFFE53935) : Colors.white,
                  border: Border.all(color: const Color(0xFFE53935), width: 2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    '%',
                    style: TextStyle(
                      color: selected == 0 ? Colors.white : const Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selected = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: selected == 1 ? const Color(0xFFE53935) : Colors.white,
                  border: Border.all(color: const Color(0xFFE53935), width: 2),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    '₺',
                    style: TextStyle(
                      color: selected == 1 ? Colors.white : const Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Çok satırlı textfield widget
class _MultilineTextFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _MultilineTextFieldWithLabel({required this.label, required this.controller, required this.hint, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
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

class _FilePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  final String? value;

  const _FilePickerField({
    required this.label,
    required this.hint,
    required this.onTap,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(value ?? hint, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
