import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:zecorner/presentation/widgets/bform/assigned_person_picker.dart';

const _kRed = Color(0xFFE53935);

const kBformStatusOptions = <(String, String)>[
  ('called', 'Arandı'),
  ('interviewed', 'Görüşüldü'),
  ('unanswered', 'Cevapsız'),
  ('not-available', 'Müsait Değil'),
  ('rejected', 'Olumsuz'),
  ('approved', 'Onaylandı'),
];

/// Görüşme şekli — web başarılı kayıt: contact_type = mail | video | face-to-face | phone
/// `not-interviewed` buraya konmamalı (Durum alanına ait; API "invalid operation" döner).
const kBformInterviewTypes = <(String, String)>[
  ('mail', 'Mail İle İletişim'),
  ('video', 'Video Görüşme'),
  ('face-to-face', 'Yüzyüze Görüşme'),
  ('phone', 'Telefon İle Görüşüldü'),
];

class BformStatusRecordResult {
  const BformStatusRecordResult({
    required this.statusType,
    required this.contactType,
    this.assignedPerson,
    this.rating,
    this.description,
    this.history = const [],
  });

  final String statusType;
  final String contactType;
  final ContactSearchModel? assignedPerson;
  final int? rating;
  final String? description;
  final List<BformStatusHistory> history;
}

Future<BformStatusRecordResult?> showBformStatusRecordSheet({
  required BuildContext context,
  required int formId,
  required BformApiRepository repository,
  String? formType,
  String initialStatus = 'called',
  String initialInterviewType = 'mail',
}) {
  return showDialog<BformStatusRecordResult>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _BformStatusRecordDialog(
        formId: formId,
        repository: repository,
        formType: formType,
        initialStatus: initialStatus,
        initialInterviewType: initialInterviewType,
      );
    },
  );
}

class _BformStatusRecordDialog extends StatefulWidget {
  const _BformStatusRecordDialog({
    required this.formId,
    required this.repository,
    this.formType,
    required this.initialStatus,
    required this.initialInterviewType,
  });

  final int formId;
  final BformApiRepository repository;
  final String? formType;
  final String initialStatus;
  final String initialInterviewType;

  @override
  State<_BformStatusRecordDialog> createState() =>
      _BformStatusRecordDialogState();
}

class _BformStatusRecordDialogState extends State<_BformStatusRecordDialog> {
  late String _statusType;
  late String _interviewType;
  ContactSearchModel? _assignedPerson;
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _statusType = widget.initialStatus;
    // Eski yanlış varsayılan "not-interviewed" gelirse mail'e çek
    final interview = widget.initialInterviewType;
    final validInterview =
        kBformInterviewTypes.any((e) => e.$1 == interview);
    _interviewType = validInterview ? interview : 'mail';
  }

  @override
  void dispose() {
    _ratingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int? get _rating {
    final raw = _ratingController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> _save() async {
    final rating = _rating;
    if (rating != null && (rating < 0 || rating > 5)) {
      setState(() => _error = 'Puan 0 ile 5 arasında olmalıdır');
      return;
    }

    if (_assignedPerson == null) {
      setState(() => _error = 'Lütfen atanan kişiyi seçiniz');
      return;
    }

    if (_assignedPerson!.contactNo <= 0) {
      setState(() => _error = 'Atanan kişi geçersiz. Listeden tekrar seçin.');
      return;
    }

    // API: görüşme şekli "not-interviewed" + related_contact = invalid operation
    if (_interviewType == 'not-interviewed' ||
        !kBformInterviewTypes.any((e) => e.$1 == _interviewType)) {
      setState(() => _error =
          'Görüşme şekli olarak Mail / Video / Yüzyüze / Telefon seçin.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final statusToSend =
        (_assignedPerson != null && _statusType == 'not-interviewed')
            ? 'called'
            : _statusType;

    final result = await widget.repository.createStatusRecord(
      formId: widget.formId,
      statusType: statusToSend,
      contactType: _interviewType,
      relatedContact: _assignedPerson?.contactNo,
      rating: rating,
      description: _descriptionController.text.trim(),
      formType: widget.formType,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        final raw = failure.message.trim();
        final lower = raw.toLowerCase();
        String friendly;
        if (lower.contains('invalid operation')) {
          friendly =
              'Geçersiz işlem. Durum ve görüşme şeklini kontrol edin (ör. Arandı + Mail İle İletişim).';
        } else if (lower.contains('internal server')) {
          friendly =
              'Durum kaydı kaydedilemedi. Atanan kişiyi kontrol edip tekrar deneyin.';
        } else {
          friendly = raw.isEmpty ? 'Durum kaydı kaydedilemedi' : raw;
        }
        setState(() {
          _isSaving = false;
          _error = friendly;
        });
      },
      (history) {
        Navigator.of(context).pop(
          BformStatusRecordResult(
            statusType: statusToSend,
            contactType: _interviewType,
            assignedPerson: _assignedPerson,
            rating: rating,
            description: _descriptionController.text.trim(),
            history: history,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Başvuru Formu Durum Kaydı Oluştur',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RedIconButton(
                      icon: Icons.close_rounded,
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DropdownField<String>(
                        label: 'Durum',
                        value: _statusType,
                        items: kBformStatusOptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.$1,
                                child: Text(item.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _statusType = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        label: 'Görüşme Şekli',
                        value: _interviewType,
                        items: kBformInterviewTypes
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.$1,
                                child: Text(item.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _interviewType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AssignedPersonPicker(
                        useFormAssignables: true,
                        onChanged: (person) => setState(() {
                          _assignedPerson = person;
                          // Atama + Görüşülmedi = API invalid operation
                          if (person != null &&
                              _statusType == 'not-interviewed') {
                            _statusType = 'called';
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Puan',
                        child: TextField(
                          controller: _ratingController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                          decoration: _inputDecoration(hint: '0-5 arası'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Açıklama',
                        child: TextField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: _inputDecoration(hint: ''),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: _kRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kRed.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kRed, width: 1.4),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
        decoration: _inputDecoration(hint: ''),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _RedIconButton extends StatelessWidget {
  const _RedIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kRed,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
