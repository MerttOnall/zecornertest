import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:zecorner/infrastructure/task/task_repository.dart';
import 'package:zecorner/models/task/task_model.dart';

class EditTaskManagerScreen extends StatefulWidget {
  final Task task;

  const EditTaskManagerScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<EditTaskManagerScreen> createState() => _EditTaskManagerScreenState();
}

class _EditTaskManagerScreenState extends State<EditTaskManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskRepository _taskRepository = TaskRepository();

  String? selectedPriority;
  final List<String> priorities = ['Düşük', 'Orta', 'Yüksek'];

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _participantController = TextEditingController();

  bool _saving = false;

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null) return "Başlangıç: "+_format(_startDate!);
    if (_startDate != null && _endDate != null) return "${_format(_startDate!)} - ${_format(_endDate!)}";
    return "Tarih aralığı seçin";
  }

  String _format(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  String _formatTime(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _populateFromTask(widget.task);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  /// BAMMA `task.priority` → `task_priority_level` FK; ID’ler genelde 0,1,2 (1,2,3 değil).
  String? _priorityLabelFromInt(int p) {
    switch (p) {
      case 0:
        return 'Düşük';
      case 1:
        return 'Orta';
      case 2:
        return 'Yüksek';
      default:
        return null;
    }
  }

  void _populateFromTask(Task t) {
    _titleController.text = t.title;
    _notesController.text = '';
    if (t.relatedContacts.isNotEmpty) {
      _participantController.text = t.relatedContacts.first.title;
    }
    if (t.priorityDescription.isNotEmpty && priorities.contains(t.priorityDescription)) {
      selectedPriority = t.priorityDescription;
    } else {
      selectedPriority = _priorityLabelFromInt(t.priority);
    }
    _startDate = DateTime(t.startTime.year, t.startTime.month, t.startTime.day);
    _startTime = TimeOfDay(hour: t.startTime.hour, minute: t.startTime.minute);
    if (t.endTime != null) {
      _endDate = DateTime(t.endTime!.year, t.endTime!.month, t.endTime!.day);
      _endTime = TimeOfDay(hour: t.endTime!.hour, minute: t.endTime!.minute);
    } else {
      final now = DateTime.now();
      _endDate = DateTime(now.year, now.month, now.day);
      _endTime = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Önce sunucunun geçerli FK değerini koru; "Yüksek" + priority=2 iken 3 göndermek FK hatası verir.
  int _priorityIntForSave(Task baseline) {
    final sel = selectedPriority;
    if (sel == null) return baseline.priority;

    if (baseline.priorityDescription.isNotEmpty && sel == baseline.priorityDescription) {
      return baseline.priority;
    }

    final inferred = _priorityLabelFromInt(baseline.priority);
    if (inferred != null && sel == inferred) {
      return baseline.priority;
    }

    switch (sel) {
      case 'Düşük':
        return 0;
      case 'Orta':
        return 1;
      case 'Yüksek':
        return 2;
      default:
        return baseline.priority;
    }
  }

  Map<String, dynamic> _buildUpdateBody(Task baseline) {
    if (_startDate == null || _startTime == null) {
      return {};
    }
    final start = _combineDateAndTime(_startDate!, _startTime!);
    DateTime? end;
    if (_endDate != null && _endTime != null) {
      end = _combineDateAndTime(_endDate!, _endTime!);
    } else {
      end = baseline.endTime;
    }

    final priorityDesc = selectedPriority ?? baseline.priorityDescription;
    // Sade gövde: BAMMA görev güncellemesinden sonra `Create Notification` bazen
    // `related_contacts` / `contact_type` içeriğini integer kolona yanlış aktarıp
    // "[object Object]" hatası veriyor. Katılımcılar DB'de kalır; sadece alan güncellenir.
    final body = <String, dynamic>{
      'title': _titleController.text.trim(),
      'start_time': start.toIso8601String(),
      'state': baseline.state,
      'status': baseline.status,
      'priority': _priorityIntForSave(baseline),
      'type': baseline.type,
      'contact': baseline.contact,
    };
    if (end != null) {
      body['end_time'] = end.toIso8601String();
    }
    if (priorityDesc.isNotEmpty) {
      body['priority_description'] = priorityDesc;
    }
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) {
      body['notes'] = notes;
    }
    return body;
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görev başlığı gerekli')),
      );
      return;
    }

    final baseline = widget.task;
    if (baseline.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz görev kimliği')),
      );
      return;
    }

    setState(() => _saving = true);
    final body = _buildUpdateBody(baseline);
    final result = await _taskRepository.updateTask(baseline.id, body);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (updated) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updated);
      },
    );
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
                        'Görev Düzenle',
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
                    value: selectedPriority != null && priorities.contains(selectedPriority)
                        ? selectedPriority
                        : null,
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
                    controller: _participantController,
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
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kaydet',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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
