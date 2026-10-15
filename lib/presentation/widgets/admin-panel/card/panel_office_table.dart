import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/dashboard/admin /admin_office_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_advisor_model.dart';

class PanelOfficeTable extends StatefulWidget {
  final AdminOfficeModel? officeData;
  /// Advisors verisinden ofis bazlı son işlem tarihi (last_transaction) doldurulur
  final AdminAdvisorModel? advisorData;
  final GlobalKey? tumunuGorKey;
  final bool tumunuGorInRedZone;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  /// Tarih aralığı değişince ofis gelirini API'den yeniden çekmek için.
  final void Function(DateTime start, DateTime end)? onDateRangeChanged;

  const PanelOfficeTable({
    super.key,
    this.officeData,
    this.advisorData,
    this.tumunuGorKey,
    this.tumunuGorInRedZone = false,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateRangeChanged,
  });

  @override
  State<PanelOfficeTable> createState() => _PanelOfficeTableState();
}

class _PanelOfficeTableState extends State<PanelOfficeTable> {
  static const Color _primaryRed = Color(0xFFEE2E24);
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _fieldFill = Color(0xFFF9FAFB);

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSort = "Hepsi";
  String _selectedStatus = "Hepsi";
  String _searchText = "";
  bool _showAllOffices = false;
  int _filterUiEpoch = 0;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _sortOptions = [
    "Hepsi",
    "Fiyat Göre (Önce en yüksek)",
    "Fiyat Göre (Önce en düşük)",
    "Tarihe Göre (Önce en yeni ilan)",
  ];

  static const List<String> _statusOptions = [
    "Hepsi",
    "1. Bölge",
    "2. Bölge",
  ];

  DateTime get _yearStart {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialStartDate != null || widget.onDateRangeChanged != null) {
      _startDate = widget.initialStartDate ?? _yearStart;
      _endDate = widget.initialEndDate ?? _today;
    }
  }

  void _notifyDateRange() {
    final start = _startDate ?? _yearStart;
    final end = _endDate ?? _today;
    widget.onDateRangeChanged?.call(start, end);
  }

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

  /// Ofis listesi; advisorData varsa her ofis için lastTransaction advisors'daki en güncel tarihten doldurulur
  List<OfficeItem> get _offices {
    final offices = widget.officeData?.offices ?? [];
    if (offices.isEmpty) return [];
    final advisors = widget.advisorData?.advisors ?? [];
    if (advisors.isEmpty) return offices;

    // Ofis id -> o ofisteki danışmanların en güncel last_transaction
    final Map<int, String> officeLastTx = {};
    for (final a in advisors) {
      if (a.office == null || a.lastTransaction == null || a.lastTransaction!.isEmpty) continue;
      final officeId = a.office!;
      try {
        final date = DateTime.parse(a.lastTransaction!);
        final existing = officeLastTx[officeId];
        if (existing == null || date.isAfter(DateTime.parse(existing))) {
          officeLastTx[officeId] = a.lastTransaction!;
        }
      } catch (_) {}
    }

    return offices.map((o) {
      final fromAdvisors = officeLastTx[o.office];
      if (fromAdvisors != null && (o.lastTransaction == null || o.lastTransaction!.isEmpty)) {
        return o.copyWith(lastTransaction: fromAdvisors);
      }
      return o;
    }).toList();
  }

  List<OfficeItem> get _filteredOffices {
    List<OfficeItem> filtered = _offices
        .where((office) =>
            office.officeTitle.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    // Tarih filtresi: API tarih aralığı kullanılıyorsa ciro zaten o aralığa göre gelir.
    // Aksi halde son işlem tarihine göre yerelde süz.
    if (widget.onDateRangeChanged == null && _startDate != null) {
      filtered = filtered
          .where((office) => _isInSelectedDateRange(office.lastTransaction))
          .toList();
    }

    // Durum filtresini uygula (Bölge bazlı)
    if (_selectedStatus != "Hepsi") {
      if (_selectedStatus == "1. Bölge") {
        filtered = filtered.where((office) => office.region == 1).toList();
      } else if (_selectedStatus == "2. Bölge") {
        filtered = filtered.where((office) => office.region == 2).toList();
      }
    }

    // Sıralama: varsayılan = son işlem tarihi en yeni en üstte (en yakınlar üstte)
    int sortByLastTransaction(OfficeItem a, OfficeItem b) {
      if (a.lastTransaction == null && b.lastTransaction == null) return 0;
      if (a.lastTransaction == null) return 1; // null en sonda
      if (b.lastTransaction == null) return -1;
      try {
        final da = DateTime.parse(a.lastTransaction!);
        final db = DateTime.parse(b.lastTransaction!);
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    }
    if (_selectedSort == "Fiyat Göre (Önce en yüksek)") {
      filtered.sort((a, b) => (b.revenue ?? 0).compareTo(a.revenue ?? 0));
    } else if (_selectedSort == "Fiyat Göre (Önce en düşük)") {
      filtered.sort((a, b) => (a.revenue ?? 0).compareTo(b.revenue ?? 0));
    } else if (_selectedSort == "Tarihe Göre (Önce en yeni ilan)") {
      filtered.sort(sortByLastTransaction);
    } else {
      filtered.sort(sortByLastTransaction);
    }

    return filtered;
  }

  List<OfficeItem> get _displayedOffices {
    final filtered = _filteredOffices;
    
    // Tümünü Gör durumunda tüm filtrelenmiş verileri döndür
    if (_showAllOffices) {
      return filtered;
    }
    
    // Normal durumda ilk 5 ofisi döndür
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  String _formatCurrency(String amount) {
    final value = double.tryParse(amount) ?? 0.0;
    return "₺${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  /// Son işlem tarihi: dd.MM.yyyy HH:mm (örn. 01.03.2026 10:48). Veri yoksa "00.00.000 00:00".
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "00.00.000 00:00";
    try {
      final date = DateTime.parse(dateString);
      final tarih = DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
      final saat = DateFormat('HH:mm', 'tr_TR').format(date);
      return "$tarih $saat";
    } catch (e) {
      print('Tarih parse hatası: $dateString - $e');
      return "00.00.000 00:00";
    }
  }

  String _getRegionText(int? region) {
    if (region == null) return "N/A";
    return "$region. Bölge";
  }

  String _formatBrandRevenue(String revenue) {
    final value = double.tryParse(revenue) ?? 0.0;
    final brandRevenue = value * 0.07;
    return "₺${brandRevenue.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  // Toplam net kazanç hesapla (filtrelenmiş ofis cirolarının toplamı)
  double _calculateTotalNetEarnings() {
    return _filteredOffices.fold(0.0, (total, office) {
      final revenue = office.revenue ?? 0.0;
      return total + revenue;
    });
  }

  // Toplam markaya getiri hesapla (toplam net kazancın %7'si)
  double _calculateTotalBrandReturn() {
    final totalNetEarnings = _calculateTotalNetEarnings();
    return totalNetEarnings * 0.07;
  }

  // Toplam net kazanç formatla
  String _formatTotalNetEarnings() {
    final total = _calculateTotalNetEarnings();
    return "₺${total.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  // Toplam markaya getiri formatla
  String _formatTotalBrandReturn() {
    final total = _calculateTotalBrandReturn();
    return "₺${total.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null)
      return "Başlangıç: " + DateFormat('dd/MM/yyyy').format(_startDate!);
    if (_startDate != null && _endDate != null)
      return "${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}";
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
      key: ValueKey('office-$label-$value-$_filterUiEpoch'),
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
    final now = DateTime.now();
    final pickedStart = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(now.year - 5, 1, 1),
      maxTime: DateTime(now.year, 12, 31),
      currentTime: _startDate ?? _yearStart,
      locale: LocaleType.tr,
    );
    if (!mounted || pickedStart == null) return;

    final pickedEnd = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: pickedStart,
      maxTime: DateTime(now.year, 12, 31),
      currentTime: _endDate ?? _today,
      locale: LocaleType.tr,
    );
    if (!mounted) return;

    setState(() {
      _startDate = _dateOnly(pickedStart);
      _endDate = _dateOnly(pickedEnd ?? _today);
      if (_endDate!.isBefore(_startDate!)) {
        _endDate = _startDate;
      }
    });
    _notifyDateRange();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchText = "";
      _showAllOffices = false;
      _selectedSort = "Hepsi";
      _selectedStatus = "Hepsi";
      if (widget.onDateRangeChanged != null) {
        _startDate = _yearStart;
        _endDate = _today;
      } else {
        _startDate = null;
        _endDate = null;
      }
      _filterUiEpoch++;
    });
    _notifyDateRange();
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = _startDate != null || _endDate != null;

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
                            Icons.apartment_rounded,
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
                                "Ofis Gelir Tablosu",
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        final sortDropdown = _buildFilterDropdown(
                          label: "Gelişmiş Sıralama",
                          value: _selectedSort,
                          items: _sortOptions,
                          icon: Icons.sort_rounded,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSort = value);
                          },
                        );
                        final statusDropdown = _buildFilterDropdown(
                          label: "Durum",
                          value: _selectedStatus,
                          items: _statusOptions,
                          icon: Icons.map_outlined,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedStatus = value);
                          },
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: sortDropdown),
                              const SizedBox(width: 10),
                              Expanded(child: statusDropdown),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            sortDropdown,
                            const SizedBox(height: 10),
                            statusDropdown,
                          ],
                        );
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
                        label: "Ofis Ara",
                        hintText: "Ofis Ara...",
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
        _buildSummaryCard(
          icon: Icons.monetization_on_rounded,
          label: "Toplam Net Kazanç",
          value: _formatTotalNetEarnings(),
        ),
        _buildSummaryCard(
          icon: Icons.trending_up_rounded,
          label: "Toplam Markaya Getiri",
          value: _formatTotalBrandReturn(),
        ),
        const SizedBox(height: 8),
        if (_filteredOffices.length > 5)
          Container(
            key: widget.tumunuGorKey,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllOffices = !_showAllOffices;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllOffices
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.tumunuGorInRedZone
                          ? Colors.white
                          : _primaryRed,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllOffices ? "Tümünü Gizle" : "Tümünü Gör",
                      style: TextStyle(
                        color: widget.tumunuGorInRedZone
                            ? Colors.white
                            : _primaryRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _displayedOffices.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _offices.isEmpty
                            ? Icons.business_rounded
                            : Icons.search_off_rounded,
                        color: _textSecondary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _offices.isEmpty
                            ? 'Ofis verileri yükleniyor...'
                            : 'Filtreye uygun ofis bulunamadı',
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
                itemCount: _displayedOffices.length,
                itemBuilder: (context, index) {
                  final office = _displayedOffices[index];
                  return _buildOfficeCard(
                    context: context,
                    office: office,
                  );
                },
              ),
      ],
    );
  }

  Widget _buildOfficeCard({
    required BuildContext context,
    required OfficeItem office,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.officeTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRegionText(office.region),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // IconButton(
                //   icon: Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                //   onPressed: () {
                //     showModalBottomSheet(
                //       backgroundColor: Colors.white,
                //       context: context,
                //       builder: (context) {
                //         return SafeArea(
                //           child: ListTile(
                //             leading: Icon(Icons.visibility, color: Color(0xFFE53935)),
                //             title: Text("Görüntüle"),
                //             onTap: () {
                //               Navigator.pop(context);
                //               // Burada detay sayfasına yönlendirme veya başka işlem eklenebilir
                //             },
                //           ),
                //         );
                //       },
                //     );
                //   },
                // ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF5F5F5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ofis Cirosu",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(office.revenue?.toString() ?? "0"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Markaya Getiri",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatBrandRevenue(office.revenue?.toString() ?? "0"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Son İşlem Tarihi:",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _formatDate(office.lastTransaction),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
