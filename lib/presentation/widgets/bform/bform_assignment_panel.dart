import 'package:flutter/material.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/presentation/widgets/bform/assigned_person_picker.dart';
import 'package:zecorner/presentation/widgets/bform/bform_status_record_sheet.dart';

const _kRed = Color(0xFFE53935);

/// Son atanan kişi + durum listesi + durum kaydı popup'ı.
class BformAssignmentPanel extends StatefulWidget {
  const BformAssignmentPanel({
    super.key,
    required this.bform,
    required this.repository,
    required this.formType,
    this.onSaved,
  });

  final BformApiModel bform;
  final BformApiRepository repository;
  final String formType;
  final VoidCallback? onSaved;

  @override
  State<BformAssignmentPanel> createState() => _BformAssignmentPanelState();
}

class _BformAssignmentPanelState extends State<BformAssignmentPanel> {
  late String _lastAssignedName;
  late String _lastAssignedType;
  late String? _lastAssignedPicture;
  late List<BformStatusHistory> _statusHistory;
  late String? _lastAssignedEmail;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _lastAssignedName = widget.bform.relatedPersonName;
    _lastAssignedType = widget.bform.relatedPersonType;
    _lastAssignedPicture = widget.bform.rcPicture;
    _lastAssignedEmail = null;
    _statusHistory = List<BformStatusHistory>.from(
      widget.bform.statusHistory ?? const [],
    );
    _loadStatusHistory();
  }

  Future<void> _loadStatusHistory() async {
    final result = await widget.repository.getFormStatusHistory(
      formId: widget.bform.id,
      formType: widget.formType,
    );
    if (!mounted) return;
    result.fold(
      (_) {
        setState(() => _loadingHistory = false);
      },
      (history) {
        final sorted = _sortNewestFirst(history);
        setState(() {
          _loadingHistory = false;
          if (sorted.isNotEmpty) {
            _statusHistory = sorted;
            final last = sorted.first;
            if (last.assignedFullName.isNotEmpty) {
              _lastAssignedName = last.assignedFullName;
              _lastAssignedType = last.typeDescription ?? _lastAssignedType;
              _lastAssignedPicture = last.picture ?? _lastAssignedPicture;
              _lastAssignedEmail = last.email;
            }
          }
        });
      },
    );
  }

  List<BformStatusHistory> _sortNewestFirst(List<BformStatusHistory> source) {
    final list = List<BformStatusHistory>.from(source);
    DateTime key(BformStatusHistory h) =>
        h.createdAt ?? h.date ?? DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => key(b).compareTo(key(a)));
    return list;
  }

  Future<void> _openStatusPopup() async {
    final result = await showBformStatusRecordSheet(
      context: context,
      formId: widget.bform.id,
      repository: widget.repository,
      formType: widget.formType,
    );
    if (result == null || !mounted) return;

    final person = result.assignedPerson;
    setState(() {
      if (person != null) {
        _lastAssignedName = person.title;
        _lastAssignedType = person.typeDescription;
        _lastAssignedPicture = person.picture;
        _lastAssignedEmail = person.email;
      }
      if (result.history.isNotEmpty) {
        _statusHistory = _sortNewestFirst(result.history);
      } else {
        _statusHistory = [
          BformStatusHistory(
            id: DateTime.now().millisecondsSinceEpoch,
            statusType: result.statusType,
            contactType: result.contactType,
            relatedContact: person?.contactNo,
            name: person?.title.split(' ').first,
            surname: person != null && person.title.split(' ').length > 1
                ? person.title.split(' ').skip(1).join(' ')
                : null,
            description: result.description,
            rating: result.rating,
            createdAt: DateTime.now(),
            email: person?.email,
            typeDescription: person?.typeDescription,
            picture: person?.picture,
          ),
          ..._statusHistory,
        ];
      }
      _loadingHistory = false;
    });

    // Sunucudan taze liste (en yeni önde)
    await _loadStatusHistory();
    if (!mounted) return;

    // Parent: sheet kapat + liste refresh (+ snackbar)
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasPerson =
        _lastAssignedName.isNotEmpty && _lastAssignedName != '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Başvuruya Son Atanan Kullanıcı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (hasPerson)
          AssignedPersonCard(
            name: _lastAssignedName,
            email: _lastAssignedEmail,
            role: _lastAssignedType == '-' ? null : _lastAssignedType,
            picture: _lastAssignedPicture,
            compact: true,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Henüz atanan kişi yok',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Başvuru Durum Listesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Material(
              color: _kRed,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _openStatusPopup,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _loadingHistory
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kRed,
                      ),
                    ),
                  ),
                )
              : _statusHistory.isEmpty
              ? Text(
                  'Bu başvuru için herhangi bir işlem yapılmamış',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _statusHistory.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _StatusHistoryItem(status: _statusHistory[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatusHistoryItem extends StatelessWidget {
  const _StatusHistoryItem({required this.status});

  final BformStatusHistory status;

  @override
  Widget build(BuildContext context) {
    final assignedName = status.assignedFullName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.statusTypeDisplay,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          if (status.contactType.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              status.contactTypeDisplay,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (assignedName.isNotEmpty) ...[
            const SizedBox(height: 8),
            AssignedPersonCard(
              name: assignedName,
              email: status.email,
              role: status.typeDescription,
              picture: status.picture,
              compact: true,
            ),
          ],
          if (status.description != null && status.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              status.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ofis dışındaki başvuru formları (danışman / satış) — Ofis ile aynı
/// Kaydet → onay → sheet kapat → liste yenile akışı.
Future<void> showBformAssignmentDetailSheet({
  required BuildContext context,
  required BformApiModel bform,
  required BformApiRepository repository,
  required String formType,
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isSale = formType == 'sale-request';

      Widget detailRow({
        required IconData icon,
        required String label,
        required String value,
      }) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: const Color(0xFFE53935)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? '-' : value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            bform.fullName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: bform.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bform.statusDisplay,
                              style: TextStyle(
                                color: bform.statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          detailRow(
                            icon: Icons.email_outlined,
                            label: 'E-posta',
                            value: bform.mail,
                          ),
                          detailRow(
                            icon: Icons.phone_outlined,
                            label: 'Telefon',
                            value: bform.phone,
                          ),
                          if (isSale) ...[
                            detailRow(
                              icon: Icons.home_outlined,
                              label: 'Gayrimenkul',
                              value: bform.propertyTypeDisplay,
                            ),
                            detailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Konum',
                              value: bform.districtText,
                            ),
                          ] else ...[
                            detailRow(
                              icon: Icons.work_outline,
                              label: 'Meslek',
                              value: bform.professionDescription ?? '-',
                            ),
                            detailRow(
                              icon: Icons.school_outlined,
                              label: 'Eğitim',
                              value: bform.educationDescription ?? '-',
                            ),
                            detailRow(
                              icon: Icons.location_city_outlined,
                              label: 'İl / İlçe',
                              value: bform.districtText,
                            ),
                          ],
                          detailRow(
                            icon: Icons.person_outline,
                            label: 'İlgili Kişi',
                            value: bform.relatedPersonName,
                          ),
                          detailRow(
                            icon: Icons.event_outlined,
                            label: 'Başvuru Tarihi',
                            value: bform.formattedDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    BformAssignmentPanel(
                      bform: bform,
                      repository: repository,
                      formType: formType,
                      onSaved: () {
                        Navigator.of(sheetContext).pop();
                        onSaved?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
