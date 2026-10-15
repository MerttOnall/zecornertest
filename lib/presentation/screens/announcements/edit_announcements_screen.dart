import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class EditAnnouncementsScreen extends StatefulWidget {
  const EditAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<EditAnnouncementsScreen> createState() => _EditAnnouncementsScreenState();
}

class _EditAnnouncementsScreenState extends State<EditAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool scheduleLater = false;
  DateTime? _date;
  String? selectedCategory = 'Genel Duyuru';
  final List<String> categories = ['Genel Duyuru', 'Bilgilendirme', 'Etkinlik', 'Önemli'];

  // Dinamik controllerlar
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? selectedGroup;
  List<String> selectedRoles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _date = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = ModalRoute.of(context)?.settings.arguments as Map?;
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      selectedCategory = data['category'] ?? 'Genel Duyuru';
      // Tarih aralığı stringini DateTime'a çevirme örneği (sadece başlangıç tarihi alınır)
      if (data['dateRange'] != null && data['dateRange'].toString().contains('-')) {
        final dateStr = data['dateRange'].toString().split('-').first.trim();
        try {
          final parts = dateStr.split(' ');
          final dateParts = parts[0].split('/');
          final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
          _date = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        } catch (_) {}
      }
      selectedRoles = List<String>.from(data['roles'] ?? []);
      // İçerik ve grup örnek
      _contentController.text = data['content'] ?? '';
      selectedGroup = data['group'] ?? null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      const Text('Duyuru Düzenle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 18),
                      // İleri Tarihe Planla
                      Row(
                        children: [
                          Switch(
                            value: scheduleLater,
                            onChanged: (v) => setState(() => scheduleLater = v),
                            activeColor: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text('İleri Tarihe Planla', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Tarih Aralığı
                      const Text('Tarih Aralığı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          DatePicker.showDateTimePicker(
                            context,
                            showTitleActions: true,
                            minTime: DateTime(2020, 1, 1),
                            maxTime: DateTime(2100, 12, 31),
                            onConfirm: (date) {
                              setState(() {
                                _date = date;
                              });
                            },
                            currentTime: _date ?? DateTime.now(),
                            locale: LocaleType.tr,
                          );
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _date != null ? "${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year} - ${_date!.hour.toString().padLeft(2, '0')}:${_date!.minute.toString().padLeft(2, '0')}" : '',
                            ),
                            decoration: InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[700]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Duyuru Kategorisi
                      const Text('Duyuru Kategorisi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: categories.contains(selectedCategory) ? selectedCategory : null,
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => selectedCategory = v),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Duyuru Başlığı
                      const Text('Duyuru Başlığı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Başlık girin',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Duyuru İçeriği
                      const Text('Duyuru İçeriği', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 6,
                        minLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Duyuru içeriği girin...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Duyuru Gönderilecek Gruplar alanı (dropdown ve tümünü seç switch)
                      const Text('Duyuru Gönderilecek Gruplar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: null,
                        hint: const Text('Duyuru Gönderilecek Gruplar'),
                        items: [
                          DropdownMenuItem(value: 'Tüm Ofis', child: Text('Tüm Ofis')),
                          DropdownMenuItem(value: 'Yönetim', child: Text('Yönetim')),
                          DropdownMenuItem(value: 'Muhasebe', child: Text('Muhasebe')),
                          DropdownMenuItem(value: 'İK', child: Text('İK')),
                        ],
                        onChanged: (v) {},
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Switch(
                            value: false,
                            onChanged: (v) {},
                            activeColor: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text('Tümünü Seç', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 28),
                      // Kaydet butonu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Silme butonu
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.delete, color: Colors.red[700]),
                          label: Text('Duyuruyu Sil', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red[700]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Duyuru Sil'),
                                content: Text('Bu duyuruyu silmek istediğinize emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('Vazgeç'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('Sil', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              Navigator.of(context).pop('deleted');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sağ üstte çarpı ikonu
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 26, color: Colors.black54),
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