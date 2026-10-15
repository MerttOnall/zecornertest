import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:zecorner/core/cubit/announcement_cubit.dart';
import 'package:zecorner/infrastructure/announcement/announcement_api_repository.dart';

class AddAnnouncementScreen extends StatefulWidget {
  const AddAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late AnnouncementCubit _announcementCubit;
  
  bool scheduleLater = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? selectedCategory = 'default';
  List<int> selectedContactTypes = [];
  bool selectAll = false;
  
  final Map<String, String> categoryMap = {
    'default': 'Genel Duyuru',
    'maintenance': 'Bakım',
    'info': 'Bilgilendirme',
  };

  @override
  void initState() {
    super.initState();
    _announcementCubit = AnnouncementCubit(AnnouncementApiRepository());
    _announcementCubit.loadContactTypes();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _announcementCubit.close();
    super.dispose();
  }

  void _toggleContactType(int id) {
    setState(() {
      if (selectedContactTypes.contains(id)) {
        selectedContactTypes.remove(id);
      } else {
        selectedContactTypes.add(id);
      }
      selectAll = selectedContactTypes.length == _announcementCubit.contactTypes.length;
    });
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      selectAll = value;
      if (value) {
        selectedContactTypes = _announcementCubit.contactTypes.map((ct) => ct.id).toList();
      } else {
        selectedContactTypes.clear();
      }
    });
  }

  void _createAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      if (selectedContactTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen en az bir grup seçin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _announcementCubit.createAnnouncement(
        title: _titleController.text,
        startTime: _startDate!,
        endTime: _endDate!,
        category: selectedCategory!,
        contactTypes: selectedContactTypes,
        content: _contentController.text.isNotEmpty ? _contentController.text : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _announcementCubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              BlocConsumer<AnnouncementCubit, AnnouncementState>(
                listener: (context, state) {
                  if (state is AnnouncementCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Duyuru başarıyla oluşturuldu'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true); // Başarılı olunca geri dön
                  } else if (state is AnnouncementCreateError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.failure.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AnnouncementCreating;
                  
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            const Text(
                              'Duyuru Oluştur',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Başlangıç Tarihi
                            const Text(
                              'Başlangıç Tarihi',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                DatePicker.showDateTimePicker(
                                  context,
                                  showTitleActions: true,
                                  minTime: DateTime.now(),
                                  maxTime: DateTime(2100, 12, 31),
                                  onConfirm: (date) {
                                    setState(() {
                                      _startDate = date;
                                      // Bitiş tarihi başlangıçtan önce olamaz
                                      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                                        _endDate = _startDate!.add(const Duration(hours: 1));
                                      }
                                    });
                                  },
                                  currentTime: _startDate ?? DateTime.now(),
                                  locale: LocaleType.tr,
                                );
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: _startDate != null
                                        ? "${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year} ${_startDate!.hour.toString().padLeft(2, '0')}:${_startDate!.minute.toString().padLeft(2, '0')}"
                                        : '',
                                  ),
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[700]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red.shade400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Bitiş Tarihi
                            const Text(
                              'Bitiş Tarihi',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                DatePicker.showDateTimePicker(
                                  context,
                                  showTitleActions: true,
                                  minTime: _startDate ?? DateTime.now(),
                                  maxTime: DateTime(2100, 12, 31),
                                  onConfirm: (date) {
                                    setState(() {
                                      _endDate = date;
                                    });
                                  },
                                  currentTime: _endDate ?? DateTime.now().add(const Duration(hours: 1)),
                                  locale: LocaleType.tr,
                                );
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: _endDate != null
                                        ? "${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year} ${_endDate!.hour.toString().padLeft(2, '0')}:${_endDate!.minute.toString().padLeft(2, '0')}"
                                        : '',
                                  ),
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[700]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red.shade400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Duyuru Kategorisi
                            const Text(
                              'Duyuru Kategorisi',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedCategory,
                              items: categoryMap.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => selectedCategory = v),
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade400),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Duyuru Başlığı
                            const Text(
                              'Duyuru Başlığı',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleController,
                              validator: (v) => v == null || v.isEmpty ? 'Başlık giriniz' : null,
                              decoration: InputDecoration(
                                hintText: 'Başlık girin',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade400),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Duyuru İçeriği
                            const Text(
                              'Duyuru İçeriği (Opsiyonel)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _contentController,
                              maxLines: 6,
                              minLines: 4,
                              decoration: const InputDecoration(
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
                            // Duyuru Gönderilecek Gruplar
                            const Text(
                              'Duyuru Gönderilecek Gruplar',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            // Tümünü Seç Switch
                            Row(
                              children: [
                                Switch(
                                  value: selectAll,
                                  onChanged: _toggleSelectAll,
                                  activeColor: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tümünü Seç',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Contact Types List
                            if (_announcementCubit.contactTypes.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(color: Color(0xFFE53935)),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _announcementCubit.contactTypes.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final contactType = _announcementCubit.contactTypes[index];
                                    final isSelected = selectedContactTypes.contains(contactType.id);
                                    
                                    return CheckboxListTile(
                                      title: Text(contactType.name),
                                      value: isSelected,
                                      onChanged: (value) => _toggleContactType(contactType.id),
                                      activeColor: const Color(0xFFE53935),
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 18),
                            // Seçilen Gruplar Gösterimi
                            if (selectedContactTypes.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedContactTypes.map((id) {
                                  final name = _announcementCubit.getContactTypeName(id);
                                  return Chip(
                                    label: Text(name),
                                    backgroundColor: Colors.purple.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.purple),
                                    onDeleted: () => _toggleContactType(id),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 28),
                            // Kaydet butonu
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _createAnnouncement,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
      ),
    );
  }
}
