import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/infrastructure/visit/visit_repository.dart';
import 'package:zecorner/presentation/screens/franchise_map/franchise_map_data.dart';

/// Saha ziyaretinin salt okunur görünümü. Düzenle ile aynı sayfada forma döner.
class FranchiseVisitDetailScreen extends StatefulWidget {
  final FieldVisit visit;
  final ValueChanged<FieldVisit> onUpdated;

  const FranchiseVisitDetailScreen({
    super.key,
    required this.visit,
    required this.onUpdated,
  });

  @override
  State<FranchiseVisitDetailScreen> createState() =>
      _FranchiseVisitDetailScreenState();
}

class _FranchiseVisitDetailScreenState extends State<FranchiseVisitDetailScreen> {
  static const _red = Color(0xFFEE2E24);
  static const _ink = Color(0xFF1C1412);
  static const _muted = Color(0xFF8A756C);
  static const _line = Color(0xFFF0E7E2);
  static const _paper = Color(0xFFF7F3EF);

  final VisitRepository _repository = VisitRepository();
  late FieldVisit _visit;
  late final TextEditingController _officeController;
  late final TextEditingController _personController;
  late final TextEditingController _noteController;

  bool _editing = false;
  bool _saving = false;
  bool _attempted = false;
  int _score = 0;
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    _officeController = TextEditingController(text: _visit.officeName);
    _personController = TextEditingController(text: _visit.personName);
    _noteController = TextEditingController();
    _score = _visit.score;
    _notes = List<String>.from(_visit.notes);
  }

  @override
  void dispose() {
    _officeController.dispose();
    _personController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startEditing() {
    HapticFeedback.selectionClick();
    setState(() {
      _editing = true;
      _attempted = false;
      _officeController.text = _visit.officeName;
      _personController.text = _visit.personName;
      _noteController.clear();
      _score = _visit.score == 0 ? 3 : _visit.score;
      _notes = List<String>.from(_visit.notes);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _attempted = false;
      _noteController.clear();
    });
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes = [..._notes, text];
      _noteController.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final office = _officeController.text.trim();
    final person = _personController.text.trim();
    if (office.isEmpty || person.isEmpty || _score < 1) {
      setState(() => _attempted = true);
      return;
    }
    final notes = [
      ..._notes,
      if (_noteController.text.trim().isNotEmpty) _noteController.text.trim(),
    ];
    setState(() => _saving = true);
    final result = await _repository.updateVisit(
      current: _visit,
      officeName: office,
      metPerson: person,
      score: _score,
      notes: notes,
    );
    if (!mounted) return;
    if (result.error != null || result.visits.isEmpty) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Ziyaret güncellenemedi.')),
      );
      return;
    }
    final saved = result.visits.first;
    widget.onUpdated(saved);
    setState(() {
      _visit = saved;
      _editing = false;
      _saving = false;
      _attempted = false;
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ziyaret güncellendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Column(
        children: [
          _editing ? _editHeader() : _hero(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                if (_editing) _editForm() else _viewBody(),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _hero() {
    final place = [
      _visit.ilName,
      _visit.ilceName,
      _visit.mahalleName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join('  ·  ');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1612), Color(0xFFB42318), Color(0xFFEE2E24)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _shortDate(_visit.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAHA ZİYARETİ',
                      style: TextStyle(
                        color: Color(0xFFFFD2CC),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _visit.officeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _scoreOrb(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _scoreDots(),
                              const SizedBox(height: 6),
                              Text(
                                place.isEmpty ? 'Konum belirtilmedi' : place,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1612), Color(0xFFEE2E24)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 20, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: _saving ? null : _cancelEditing,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Ziyareti düzenle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreOrb() {
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.4),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${_visit.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            TextSpan(
              text: '/5',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreDots() {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Container(
            width: i <= _visit.score ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= _visit.score
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _viewBody() {
    final notes = _visit.notes.where((note) => note.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Görüşme'),
        const SizedBox(height: 12),
        _detailTile(
          icon: Icons.storefront_outlined,
          tint: const Color(0xFFEE2E24),
          label: 'Ofis',
          value: _visit.officeName,
        ),
        _detailTile(
          icon: Icons.person_outline_rounded,
          tint: const Color(0xFFB45309),
          label: 'Görüşülen kişi',
          value: _visit.personName,
        ),
        if (_visit.createdByTitle.trim().isNotEmpty)
          _detailTile(
            icon: Icons.badge_outlined,
            tint: const Color(0xFF7C3AED),
            label: 'Kaydeden',
            value: _visit.createdByTitle,
          ),
        if (_hasPlace) ...[
          const SizedBox(height: 10),
          const _SectionTitle('Konum'),
          const SizedBox(height: 12),
          _placeCard(),
        ],
        const SizedBox(height: 10),
        const _SectionTitle('Notlar'),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          const _EmptyNotes()
        else
          _notesCard(notes),
      ],
    );
  }

  Widget _placeCard() {
    final parts = <(String, String)>[
      if ((_visit.ilName ?? '').trim().isNotEmpty) ('İl', _visit.ilName!.trim()),
      if ((_visit.ilceName ?? '').trim().isNotEmpty) ('İlçe', _visit.ilceName!.trim()),
      if ((_visit.mahalleName ?? '').trim().isNotEmpty)
        ('Mahalle', _visit.mahalleName!.trim()),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.place_rounded, color: _red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final part in parts)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.$1,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        part.$2,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesCard(List<String> notes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: _line),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: TextStyle(
                    color: _red.withValues(alpha: 0.85),
                    fontSize: 28,
                    height: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      notes[i],
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF3A1612).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _editForm() {
    final missingOffice = _attempted && _officeController.text.trim().isEmpty;
    final missingPerson = _attempted && _personController.text.trim().isEmpty;
    final missingScore = _attempted && _score < 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          label: 'Ofis adı',
          controller: _officeController,
          icon: Icons.storefront_outlined,
          error: missingOffice ? 'Ofis adı gerekli' : null,
        ),
        const SizedBox(height: 12),
        _field(
          label: 'Görüşülen kişi',
          controller: _personController,
          icon: Icons.person_outline,
          error: missingPerson ? 'Kişi adı gerekli' : null,
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Puan'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var value = 1; value <= 5; value++) ...[
              if (value > 1) const SizedBox(width: 8),
              Expanded(child: _scoreChip(value)),
            ],
          ],
        ),
        if (missingScore) ...[
          const SizedBox(height: 6),
          const Text(
            'Puan seçin',
            style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 18),
        const _SectionTitle('Notlar'),
        const SizedBox(height: 8),
        for (var i = 0; i < _notes.length; i++) ...[
          _editableNote(i),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addNote(),
                decoration: _inputDecoration('Not ekle'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: _addNote,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scoreChip(int value) {
    final selected = _score == value;
    final color = scoreColor(value);
    return Material(
      color: selected ? color : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? color : _line),
      ),
      child: InkWell(
        onTap: () => setState(() => _score = value),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: selected ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? error,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) {
        if (_attempted) setState(() {});
      },
      decoration: _inputDecoration(label, icon: icon, error: error),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    String? error,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      prefixIcon: icon == null ? null : Icon(icon, color: _muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _red, width: 1.4),
      ),
    );
  }

  Widget _editableNote(int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _notes[index],
              style: const TextStyle(color: _ink, height: 1.35),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _notes = [..._notes]..removeAt(index);
            }),
            icon: const Icon(Icons.close, size: 18, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: _paper,
      child: SafeArea(
        top: false,
        child: _editing
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _cancelEditing,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        minimumSize: const Size.fromHeight(54),
                        shape: buttonShape,
                      ),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _primaryButton('Kaydet', _saving ? null : _save)),
                ],
              )
            : _primaryButton('Düzenle', _startEditing, icon: Icons.edit_outlined),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {IconData? icon}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _red.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: _saving && label == 'Kaydet'
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.check_rounded, size: 18),
        label: Text(
          _saving && label == 'Kaydet' ? 'Kaydediliyor' : label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  bool get _hasPlace => [
        _visit.ilName,
        _visit.ilceName,
        _visit.mahalleName,
      ].any((part) => part != null && part.trim().isNotEmpty);

  String _shortDate(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}  ·  $hour:$minute';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF8A756C),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A1612).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'Bu ziyarete not eklenmemiş.',
        style: TextStyle(color: Color(0xFF8A756C), height: 1.4),
      ),
    );
  }
}
