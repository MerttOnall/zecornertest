import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateNoteDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialCustomer;
  final String? initialListing;
  final String? initialDate;
  final bool isEdit;

  const CreateNoteDialog({
    Key? key,
    this.initialTitle,
    this.initialContent,
    this.initialCustomer,
    this.initialListing,
    this.initialDate,
    this.isEdit = false,
  }) : super(key: key);

  @override
  _CreateNoteDialogState createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customerController = TextEditingController();
  final _listingController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _customerController.text = widget.initialCustomer ?? '';
    _listingController.text = widget.initialListing ?? '';
    if (widget.initialDate != null) {
      try {
        _selectedDate = DateFormat('dd/MM/yyyy - HH:mm').parse(widget.initialDate!);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customerController.dispose();
    _listingController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık boş olamaz!')),
      );
      return;
    }
    final newNote = {
      'title': _titleController.text,
      'content': _contentController.text,
      'date': DateFormat('dd/MM/yyyy - HH:mm').format(_selectedDate!),
      'customer': _customerController.text,
      'listing': _listingController.text,
    };
    Navigator.of(context).pop(newNote);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(label: "Not Başlığı", controller: _titleController),
                  const SizedBox(height: 24),
                  _buildTextField(label: "Not İçeriği", controller: _contentController, maxLines: 6),
                  const SizedBox(height: 24),
                  _buildDateField(),
                  const SizedBox(height: 24),
                  _buildTextField(label: "İlgili Müşteri", controller: _customerController, hint: "Ara"),
                  const SizedBox(height: 24),
                  _buildTextField(label: "İlgili İlan", controller: _listingController, hint: "Ara"),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isEdit ? "Not Düzenle" : "Not Oluştur",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFD9363E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromRGBO(238, 46, 36, 1),
              width: 2,
            ),
          ),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tarih", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          onTap: _pickDate,
          controller: TextEditingController(
            text: _selectedDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
          ),
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromRGBO(238, 46, 36, 1),
              width: 2,
            ),
          ),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveNote,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD9363E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
} 