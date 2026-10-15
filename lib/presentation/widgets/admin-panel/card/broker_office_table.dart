import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/dashboard/office/office_sales_model.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';

class BrokerOfficeTable extends StatefulWidget {
  final OfficeSalesModel? salesData;
  final String? totalRevenue; // API'den gelen total_revenue değeri
  final int? selectedYear; // Grafikten gelen yıl filtresi
  final int? selectedMonth; // Grafikten gelen ay filtresi
  
  const BrokerOfficeTable({
    super.key,
    this.salesData,
    this.totalRevenue,
    this.selectedYear,
    this.selectedMonth,
  });

  @override
  State<BrokerOfficeTable> createState() => _BrokerOfficeTableState();
}

class _BrokerOfficeTableState extends State<BrokerOfficeTable> {
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
  bool _showAll = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SaleModel> get _filteredSales {
    if (widget.salesData?.sales == null) return [];
    
    List<SaleModel> filteredSales = List<SaleModel>.from(widget.salesData!.sales);
    
    // Grafik filtreleri (yıl/ay) - Öncelikli
    if (widget.selectedYear != null && widget.selectedMonth != null) {
      filteredSales = filteredSales.where((sale) {
        try {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.year == widget.selectedYear && saleDate.month == widget.selectedMonth;
        } catch (e) {
          return false;
        }
      }).toList();
    } else if (widget.selectedYear != null) {
      filteredSales = filteredSales.where((sale) {
        try {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.year == widget.selectedYear;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    // Tarih filtresi (widget içindeki tarih seçicileri) - Grafik filtreleri yoksa kullan
    if ((widget.selectedYear == null && widget.selectedMonth == null) && 
        (_startDate != null || _endDate != null)) {
      filteredSales = filteredSales.where((sale) {
        try {
          final saleDate = DateTime.parse(sale.date);
          final saleDateOnly = DateTime(saleDate.year, saleDate.month, saleDate.day);
          
          if (_startDate != null && _endDate != null) {
            final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return saleDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
                   saleDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
          } else if (_startDate != null) {
            final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            return saleDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1)));
          } else if (_endDate != null) {
            final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return saleDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
          }
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    // Arama filtresi
    if (_searchText.isNotEmpty) {
      filteredSales = filteredSales.where((sale) =>
        sale.advisorTitle.toLowerCase().contains(_searchText.toLowerCase()) ||
        sale.customerTitle.toLowerCase().contains(_searchText.toLowerCase()) ||
        sale.listingTitle.toLowerCase().contains(_searchText.toLowerCase())
      ).toList();
    }
    
    // Durum filtresi
    if (_selectedStatus != "Hepsi") {
      filteredSales = filteredSales.where((sale) {
        if (_selectedStatus == "Satıldı") return sale.state == "SOLD";
        if (_selectedStatus == "Kiralandı") return sale.state == "RENTED";
        return true;
      }).toList();
    }
    
    // Sıralama
    if (_selectedSort != "Hepsi") {
      switch (_selectedSort) {
        case "Fiyat Göre (Önce en yüksek)":
          filteredSales.sort((a, b) {
            final aPrice = a.closingPrice != null 
                ? double.tryParse(a.closingPrice!) ?? a.price.toDouble()
                : a.price.toDouble();
            final bPrice = b.closingPrice != null 
                ? double.tryParse(b.closingPrice!) ?? b.price.toDouble()
                : b.price.toDouble();
            return bPrice.compareTo(aPrice);
          });
          break;
        case "Fiyat Göre (Önce en düşük)":
          filteredSales.sort((a, b) {
            final aPrice = a.closingPrice != null 
                ? double.tryParse(a.closingPrice!) ?? a.price.toDouble()
                : a.price.toDouble();
            final bPrice = b.closingPrice != null 
                ? double.tryParse(b.closingPrice!) ?? b.price.toDouble()
                : b.price.toDouble();
            return aPrice.compareTo(bPrice);
          });
          break;
        case "Tarihe Göre (Önce en yeni ilan)":
          filteredSales.sort((a, b) {
            try {
              final aDate = DateTime.parse(a.date);
              final bDate = DateTime.parse(b.date);
              return bDate.compareTo(aDate); // En yeni önce
            } catch (e) {
              return 0;
            }
          });
          break;
        case "Tarihe Göre (Önce en eski ilan)":
          filteredSales.sort((a, b) {
            try {
              final aDate = DateTime.parse(a.date);
              final bDate = DateTime.parse(b.date);
              return aDate.compareTo(bDate); // En eski önce
            } catch (e) {
              return 0;
            }
          });
          break;
      }
    }
    
    return filteredSales;
  }

  List<SaleModel> get _displayedSales {
    // Filtrelenmiş ve sıralanmış verileri kullan
    final filtered = _filteredSales;
    
    // Tümünü Gör durumunda tüm verileri döndür
    if (_showAll) {
      return filtered;
  }

    // Normal durumda ilk 5 öğeyi göster
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }
  
  String get _filteredTotalRevenue {
    // Eğer API'den totalRevenue gelmişse onu kullan, yoksa filtrelenmiş verilerden hesapla
    if (widget.totalRevenue != null && widget.totalRevenue!.isNotEmpty) {
      return widget.totalRevenue!;
    }
    
    // Filtrelenmiş verilerin toplam kazancını hesapla
    final filtered = _filteredSales;
    double total = 0.0;
    for (var sale in filtered) {
      try {
        total += double.parse(sale.totalComission);
      } catch (e) {
        // Hata durumunda atla
      }
    }
    return total.toStringAsFixed(2);
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

  Widget _buildTableFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final isActive = value != "Hepsi";
    return DropdownButtonFormField<String>(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        final sortDropdown = _buildTableFilterDropdown(
                          label: "Gelişmiş Sıralama",
                          value: _selectedSort,
                          items: const [
                            "Hepsi",
                            "Fiyat Göre (Önce en yüksek)",
                            "Fiyat Göre (Önce en düşük)",
                            "Tarihe Göre (Önce en yeni ilan)",
                            "Tarihe Göre (Önce en eski ilan)",
                          ],
                          icon: Icons.sort_rounded,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSort = value);
                          },
                        );
                        final statusDropdown = _buildTableFilterDropdown(
                          label: "Durum",
                          value: _selectedStatus,
                          items: const ["Hepsi", "Kiralandı", "Satıldı"],
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
                    GestureDetector(
                      onTap: () async {
                        final pickedStart = await DatePicker.showDatePicker(
                          context,
                          showTitleActions: true,
                          minTime: DateTime(2025, 1, 1),
                          maxTime: DateTime(2100, 12, 31),
                          currentTime: _startDate ?? DateTime.now(),
                          locale: LocaleType.tr,
                        );
                        if (pickedStart != null) {
                          final pickedEnd = await DatePicker.showDatePicker(
                            context,
                            showTitleActions: true,
                            minTime: pickedStart,
                            maxTime: DateTime(2100, 12, 31),
                            currentTime: _endDate ?? pickedStart,
                            locale: LocaleType.tr,
                          );
                          setState(() {
                            _startDate = pickedStart;
                            _endDate = pickedEnd;
                          });
                        }
                      },
                      child: Container(
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      decoration: _filterFieldDecoration(
                        label: "Ara",
                        hintText: "Ara...",
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
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchText = "";
                            _selectedSort = "Hepsi";
                            _selectedStatus = "Hepsi";
                            _startDate = null;
                            _endDate = null;
                            _showAll = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Filtreyi Temizle",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
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
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Toplam Net Kazanç:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "₺",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: _formatPrice(_filteredTotalRevenue).replaceFirst("₺", ""),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Toplam Markaya Getiri:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "₺",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: "32.130,00",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Tümünü Gör/Gizle butonu
        if (_filteredSales.length > 5)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color.fromRGBO(238, 46, 36, 1),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAll ? "Tümünü Gizle" : "Tümünü Gör",
                      style: const TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _displayedSales.isEmpty
            ? EmptyDataView(
                compact: true,
                icon: Icons.receipt_long_rounded,
                title: 'Veri yok',
                subtitle: (widget.salesData?.sales.isNotEmpty ?? false)
                    ? 'Bu filtreye uygun kayıt yok'
                    : 'Gösterilecek gelir kaydı yok',
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _displayedSales.length,
                itemBuilder: (context, index) {
                  final sale = _displayedSales[index];
                  return _buildSaleCard(
                    context: context,
                    sale: sale,
                  );
                },
              ),
      ],
    );
  }

  Widget _buildSaleCard({
    required BuildContext context,
    required SaleModel sale,
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(238, 46, 36, 1),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.advisorTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Müşteri: ${sale.customerTitle}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sale.state == "SOLD" ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sale.state == "SOLD" ? "Satıldı" : "Kiralandı",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: ListTile(
                            leading: Icon(Icons.visibility, color: Color(0xFFE53935)),
                            title: Text("Görüntüle"),
                            onTap: () {
                              Navigator.pop(context);
                              // Burada detay sayfasına yönlendirme veya başka işlem eklenebilir
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
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
                      "Kapanış Fiyatı",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sale.closingPrice != null 
                          ? "₺${_formatPrice(sale.closingPrice!)}"
                          : "₺${_formatPrice(sale.price.toString())}",
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
                      "Net Kazanç",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₺${_formatPrice(sale.totalComission)}",
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
              children: [
                Text(
                  "İşlem Tarihi:",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
                SizedBox(width: 5),
                Text(
                  _formatDate(sale.date),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(String priceString) {
    try {
      final price = double.parse(priceString);
      return NumberFormat('#,##0.00', 'tr_TR').format(price);
    } catch (e) {
      return '0,00';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${date.day} ${months[date.month]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
