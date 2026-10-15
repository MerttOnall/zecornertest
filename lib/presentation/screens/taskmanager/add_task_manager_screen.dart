import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class AddTaskManagerScreen extends StatefulWidget {
  const AddTaskManagerScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskManagerScreen> createState() => _AddTaskManagerScreenState();
}

class _AddTaskManagerScreenState extends State<AddTaskManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedPriority;
  final List<String> priorities = ['Düşük', 'Orta', 'Yüksek'];

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final TextEditingController _notesController = TextEditingController();

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null) return "Başlangıç: ${_format(_startDate!)}";
    if (_startDate != null && _endDate != null) return "${_format(_startDate!)} - ${_format(_endDate!)}";
    return "Tarih aralığı seçin";
  }

  String _format(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  String _formatTime(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _endTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst başlık ve kapatma
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Görev Oluştur',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      IconButton(
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Görev Başlığı
                  const Text('Görev Başlığı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
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
                  // Tarih Aralığı
                  const Text('Tarih Aralığı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      DatePicker.showDatePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime(2020, 1, 1),
                        maxTime: DateTime(2100, 12, 31),
                        onConfirm: (date) async {
                          final pickedStartTime = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
                          setState(() {
                            _startDate = date;
                            _startTime = pickedStartTime;
                          });
                          DatePicker.showDatePicker(
                            context,
                            showTitleActions: true,
                            minTime: date,
                            maxTime: DateTime(2100, 12, 31),
                            onConfirm: (endDate) async {
                              final pickedEndTime = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
                              setState(() {
                                _endDate = endDate;
                                _endTime = pickedEndTime;
                              });
                            },
                            currentTime: _endDate ?? date,
                            locale: LocaleType.tr,
                          );
                        },
                        currentTime: _startDate ?? DateTime.now(),
                        locale: LocaleType.tr,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: _dateText,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Seçili tarih ve saat
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _startDate != null && _endDate != null
                            ? "${_format(_startDate!)} - ${_format(_endDate!)}"
                            : _startDate != null ? _format(_startDate!) : '',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _startTime != null && _endTime != null
                            ? "${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}"
                            : _startTime != null ? _formatTime(_startTime!) : '',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Açıklama',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 8,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'İsteğe bağlı açıklama yazın',
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                        borderSide: BorderSide(
                            color: Colors.red.shade400, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Öncelik
                  const Text('Öncelik', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    items: priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedPriority = v),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Seçiniz',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Katılımcı Ara
                  const Text('Katılımcı Ara', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Ara',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
