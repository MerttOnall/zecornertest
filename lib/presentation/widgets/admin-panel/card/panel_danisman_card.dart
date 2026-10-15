import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/dashboard/admin /admin_advisor_model.dart';

class PanelDanismanCard extends StatefulWidget {
  final AdminAdvisorModel? advisorData;
  
  const PanelDanismanCard({
    super.key,
    this.advisorData,
  });

  @override
  State<PanelDanismanCard> createState() => _PanelDanismanCardState();
}

class _PanelDanismanCardState extends State<PanelDanismanCard> {
  static const Color _primaryRed = Color(0xFFEE2E24);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _fieldFill = Color(0xFFF9FAFB);

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSort = "Hepsi";
  String _searchText = "";
  bool _showAllAdvisors = false;
  int _filterUiEpoch = 0;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _sortOptions = [
    "Hepsi",
    "Fiyat Göre (Önce en yüksek)",
    "Fiyat Göre (Önce en düşük)",
    "Tarihe Göre (Önce en yeni ilan)",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isInSelectedDateRange(String? dateString) {
    if (_startDate == null) return true;
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final parsed = DateTime.parse(dateString);
      final day = _dateOnly(parsed);
      final start = _dateOnly(_startDate!);
      if (day.isBefore(start)) return false;
      if (_endDate != null) {
        final end = _dateOnly(_endDate!);
        if (day.isAfter(end)) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  List<AdvisorItem> get _advisors {
    final advisors = widget.advisorData?.advisors ?? [];
    // API'den gelen verileri son işlem tarihine göre sırala (en yeni en üstte)
    final sortedAdvisors = List<AdvisorItem>.from(advisors);
    sortedAdvisors.sort((a, b) {
      if (a.lastTransaction == null) return 1;
      if (b.lastTransaction == null) return -1;
      try {
        return DateTime.parse(b.lastTransaction!).compareTo(DateTime.parse(a.lastTransaction!));
      } catch (e) {
        return 0;
      }
    });
    return sortedAdvisors;
  }

  List<AdvisorItem> get _filteredAdvisors {
    List<AdvisorItem> filtered = _advisors
        .where((advisor) =>
            advisor.advisorTitle.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    // Tarih filtresini uygula (gün bazlı, dahil)
    if (_startDate != null) {
      filtered = filtered
          .where((advisor) => _isInSelectedDateRange(advisor.lastTransaction))
          .toList();
    }

    // Sıralama uygula
    if (_selectedSort == "Fiyat Göre (Önce en yüksek)") {
      filtered.sort((a, b) => (b.revenue ?? 0).compareTo(a.revenue ?? 0));
    } else if (_selectedSort == "Fiyat Göre (Önce en düşük)") {
      filtered.sort((a, b) => (a.revenue ?? 0).compareTo(b.revenue ?? 0));
    } else if (_selectedSort == "Tarihe Göre (Önce en yeni ilan)") {
      filtered.sort((a, b) {
        if (a.lastTransaction == null) return 1;
        if (b.lastTransaction == null) return -1;
        try {
          return DateTime.parse(b.lastTransaction!)
              .compareTo(DateTime.parse(a.lastTransaction!));
        } catch (_) {
          return 0;
        }
      });
    } else {
      filtered.sort((a, b) {
        if (a.lastTransaction == null) return 1;
        if (b.lastTransaction == null) return -1;
        try {
          return DateTime.parse(b.lastTransaction!)
              .compareTo(DateTime.parse(a.lastTransaction!));
        } catch (_) {
          return 0;
        }
      });
    }

    return filtered;
  }

  List<AdvisorItem> get _displayedAdvisors {
    final filtered = _filteredAdvisors;
    if (_showAllAdvisors) return filtered;
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0.0;
    return "₺${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  /// Son işlem tarihi: dd.MM.yyyy HH:mm. Veri yoksa "00.00.000 00:00" (N/A yok).
  String _formatDateAndTime(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString.toLowerCase() == 'null') {
      return "00.00.000 00:00";
    }
    try {
      final date = DateTime.parse(dateString.trim()).toLocal();
      final tarih = DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
      final saat = DateFormat('HH:mm', 'tr_TR').format(date);
      return "$tarih $saat";
    } catch (e) {
      return "00.00.000 00:00";
    }
  }

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null) {
      return "Başlangıç: ${DateFormat('dd/MM/yyyy').format(_startDate!)}";
    }
    if (_startDate != null && _endDate != null) {
      return "${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}";
    }
    return "Tarih aralığı seçin";
  }

  InputDecoration _filterFieldDecoration({
    required String label,
    Widget? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _primaryRed,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: _textSecondary.withOpacity(0.85),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _fieldFill,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primaryRed.withOpacity(0.45), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final isActive = value != "Hepsi";
    return DropdownButtonFormField<String>(
      key: ValueKey('advisor-$label-$value-$_filterUiEpoch'),
      dropdownColor: Colors.white,
      value: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isActive ? _primaryRed : _textSecondary,
      ),
      style: const TextStyle(
        color: _textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: _filterFieldDecoration(
        label: label,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: isActive ? _primaryRed : _textSecondary,
        ),
      ).copyWith(
        fillColor: isActive ? _primaryRed.withOpacity(0.04) : _fieldFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isActive ? _primaryRed.withOpacity(0.28) : _borderLight,
          ),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _pickDateRange() async {
    final pickedStart = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2020, 1, 1),
      maxTime: DateTime(2100, 12, 31),
      currentTime: _startDate ?? DateTime.now(),
      locale: LocaleType.tr,
    );
    if (!mounted || pickedStart == null) return;

    final pickedEnd = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: pickedStart,
      maxTime: DateTime(2100, 12, 31),
      currentTime: _endDate ?? pickedStart,
      locale: LocaleType.tr,
    );
    if (!mounted) return;

    setState(() {
      _startDate = _dateOnly(pickedStart);
      _endDate = pickedEnd == null ? null : _dateOnly(pickedEnd);
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchText = "";
      _showAllAdvisors = false;
      _selectedSort = "Hepsi";
      _startDate = null;
      _endDate = null;
      _filterUiEpoch++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = _startDate != null || _endDate != null;
    final filteredCount = _filteredAdvisors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderLight.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryRed.withOpacity(0.6),
                      _primaryRed.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryRed.withOpacity(0.14),
                                _primaryRed.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryRed.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: _primaryRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kişi Listesi",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Filtrele ve sırala",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      label: "Gelişmiş Sıralama",
                      value: _selectedSort,
                      items: _sortOptions,
                      icon: Icons.sort_rounded,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedSort = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: hasDateFilter
                                ? _primaryRed.withOpacity(0.04)
                                : _fieldFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasDateFilter
                                  ? _primaryRed.withOpacity(0.28)
                                  : _borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: hasDateFilter
                                    ? _primaryRed
                                    : _textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dateText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: hasDateFilter
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: hasDateFilter
                                        ? _textPrimary
                                        : _textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasDateFilter)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: _textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchText = value);
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      decoration: _filterFieldDecoration(
                        label: "Arama",
                        hintText: "Arama Yap",
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: _searchText.isNotEmpty
                              ? _primaryRed
                              : _textSecondary,
                        ),
                      ).copyWith(
                        fillColor: _searchText.isNotEmpty
                            ? _primaryRed.withOpacity(0.04)
                            : _fieldFill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _searchText.isNotEmpty
                                ? _primaryRed.withOpacity(0.28)
                                : _borderLight,
                          ),
                        ),
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchText = "";
                                  });
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _textSecondary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(
                          Icons.filter_alt_off_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "Filtreyi Temizle",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEE2E24), Color(0xFFE53935)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primaryRed.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Toplam Kişi Sayısı: ${widget.advisorData?.totalCount ?? 0}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filteredCount > 5)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllAdvisors = !_showAllAdvisors;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllAdvisors
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _primaryRed,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllAdvisors ? "Tümünü Gizle" : "Tümünü Gör",
                      style: const TextStyle(
                        color: _primaryRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _displayedAdvisors.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _advisors.isEmpty
                            ? Icons.person_rounded
                            : Icons.search_off_rounded,
                        color: _textSecondary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _advisors.isEmpty
                            ? 'Danışman verileri yükleniyor...'
                            : 'Filtreye uygun kişi bulunamadı',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _displayedAdvisors.length,
                itemBuilder: (context, index) {
                  final advisor = _displayedAdvisors[index];
                  return _buildAdvisorCard(
                    context: context,
                    advisor: advisor,
                  );
                },
              ),
      ],
    );
  }

  Widget _buildAdvisorCard({
    required BuildContext context,
    required AdvisorItem advisor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advisor.advisorTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advisor.typeDescription ?? "N/A",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(
              height: 24,
              thickness: 1,
              color: Color(0xFFF5F5F5),
            ),
            Row(
              children: [
                Text("Ofis: ",style: TextStyle(fontWeight: FontWeight.w600),),
                Text(advisor.officeTitle ?? "N/A"),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "Toplam Kazanç: ",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: _formatCurrency(advisor.revenue?.toString() ?? "0"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Son İşlem Tarihi: ",style: TextStyle(fontWeight: FontWeight.w600),),
                        Expanded(
                          child: Text(
                            _formatDateAndTime(advisor.lastTransaction),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}