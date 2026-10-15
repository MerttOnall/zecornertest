import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/task/task_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Devam Ediyor':
      case 'IN_PROGRESS':
        return const Color(0xFFFB8C00);
      case 'Atandı':
      case 'ASSIGNED':
        return const Color(0xFF1976D2);
      case 'Tamamlandı':
      case 'COMPLETED':
        return const Color(0xFF43A047);
      case 'İptal Edildi':
      case 'CANCELLED':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${DateFormat('dd/MM/yyyy').format(date)} -';
  }

  String _formatTime(DateTime date) {
    return '${DateFormat('HH:mm').format(date)} -';
  }

  void _onStatusChanged(String? value) {
    if (value == null) return;
    setState(() {
      _task = _task.copyWith(state: Task.pickerLabelToApiState(value));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Görev durumu "$value" olarak güncellendi'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participants = _task.relatedContacts;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_task);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AdminPanelAppBar(
          title: 'Görev',
          useBackButton: true,
          onMenuPressed: () => Navigator.of(context).pop(_task),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görev durumu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _task.pickerStatusLabel,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          style: TextStyle(
                            color: _statusColor(_task.stateDescription),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          items: Task.cardPickerStatuses.map((state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: _statusColor(state),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(state),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _onStatusChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF23263B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Görev tipi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _task.typeDescription,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF23263B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_task.priorityDescription.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Öncelik',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _task.priorityDescription,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF23263B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Görev Başlangıç Tarihi',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF23263B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(_task.startTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF23263B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_task.startTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF23263B),
                          ),
                        ),
                      ],
                    ),
                    if (_task.endTime != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Görev Bitiş Tarihi',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF23263B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(_task.endTime!),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF23263B),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_task.endTime!),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF23263B),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (participants.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Katılımcılar',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF23263B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: participants
                            .map(
                              (c) => Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  radius: 12,
                                  child: Text(
                                    c.title.isNotEmpty
                                        ? c.title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                label: Text(c.title),
                                backgroundColor: Colors.white,
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/edit-task-manager',
                      arguments: _task,
                    );
                    if (!mounted) return;
                    if (result is Task) {
                      setState(() => _task = result);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFFE53935)),
                  label: const Text(
                    'Düzenle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
