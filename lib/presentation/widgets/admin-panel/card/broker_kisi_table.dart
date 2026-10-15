import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/dashboard/admin /admin_advisor_model.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';

class PanelKisiCard extends StatefulWidget {
  final AdminAdvisorModel? advisorsData;
  
  const PanelKisiCard({
    super.key,
    this.advisorsData,
  });

  @override
  State<PanelKisiCard> createState() => _PanelKisiCardState();
}

class _PanelKisiCardState extends State<PanelKisiCard> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSort = "Hepsi";
  String _searchText = "";
  bool _showAll = false;

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null)
      return "Başlangıç: " + DateFormat('dd/MM/yyyy').format(_startDate!);
    if (_startDate != null && _endDate != null)
      return "${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}";
    return "Tarih aralığı seçin";
  }

  List<AdvisorItem> get _filteredAdvisors {
    if (widget.advisorsData?.advisors == null) return [];
    
    List<AdvisorItem> filteredAdvisors = List<AdvisorItem>.from(widget.advisorsData!.advisors);
    
    // Tarih filtresi
    if (_startDate != null || _endDate != null) {
      filteredAdvisors = filteredAdvisors.where((advisor) {
        if (advisor.lastTransaction == null) return false;
        try {
          final transactionDate = DateTime.parse(advisor.lastTransaction!);
          final transactionDateOnly = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
          
          if (_startDate != null && _endDate != null) {
            final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return transactionDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
                   transactionDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
          } else if (_startDate != null) {
            final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            return transactionDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1)));
          } else if (_endDate != null) {
            final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return transactionDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
          }
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    // Arama filtresi
    if (_searchText.isNotEmpty) {
      filteredAdvisors = filteredAdvisors.where((advisor) =>
        advisor.advisorTitle.toLowerCase().contains(_searchText.toLowerCase()) ||
        (advisor.typeDescription?.toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
        (advisor.officeTitle?.toLowerCase().contains(_searchText.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Sıralama: varsayılan (Hepsi) = son işlem tarihine göre en yeni en üstte (web ile aynı)
    int sortByLastTransaction(AdvisorItem a, AdvisorItem b) {
      if (a.lastTransaction == null && b.lastTransaction == null) return 0;
      if (a.lastTransaction == null) return 1;
      if (b.lastTransaction == null) return -1;
      try {
        final aDate = DateTime.parse(a.lastTransaction!);
        final bDate = DateTime.parse(b.lastTransaction!);
        return bDate.compareTo(aDate); // en yeni önce
      } catch (e) {
        return 0;
      }
    }
    if (_selectedSort == "Fiyat Göre (Önce en yüksek)") {
      filteredAdvisors.sort((a, b) => (b.revenue ?? 0).compareTo(a.revenue ?? 0));
    } else if (_selectedSort == "Fiyat Göre (Önce en düşük)") {
      filteredAdvisors.sort((a, b) => (a.revenue ?? 0).compareTo(b.revenue ?? 0));
    } else if (_selectedSort == "Tarihe Göre (Önce en yeni ilan)") {
      filteredAdvisors.sort(sortByLastTransaction);
    } else if (_selectedSort == "Tarihe Göre (Önce en eski ilan)") {
      filteredAdvisors.sort((a, b) => -sortByLastTransaction(a, b));
    } else {
      // Hepsi / varsayılan: son işlem tarihi en yeni en üstte
      filteredAdvisors.sort(sortByLastTransaction);
    }

    return filteredAdvisors;
  }

  List<AdvisorItem> get _displayedAdvisors {
    // Filtrelenmiş ve sıralanmış verileri kullan
    final filtered = _filteredAdvisors;
    
    // Tümünü Gör durumunda tüm verileri döndür
    if (_showAll) {
      return filtered;
  }

    // Normal durumda ilk 5 öğeyi göster
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık ve Filtreler
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kişi Listesi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Mobil ve web uyumlu filtreler
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Colors.white,
                                value: _selectedSort,
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: "Gelişmiş Sıralama",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          const BorderSide(color: Colors.grey)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          const BorderSide(color: Colors.grey)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Colors.grey, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  "Hepsi",
                                  "Fiyat Göre (Önce en yüksek)",
                                  "Fiyat Göre (Önce en düşük)",
                                  "Tarihe Göre (Önce en yeni ilan)",
                                  "Tarihe Göre (Önce en eski ilan)"
                                ]
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSort = value!;
                                  });
                                },
                              ),
                            ),

                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              value: _selectedSort,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "Gelişmiş Sıralama",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: [
                                "Hepsi",
                                "Fiyat Göre (Önce en yüksek)",
                                "Fiyat Göre (Önce en düşük)",
                                "Tarihe Göre (Önce en yeni ilan)",
                                "Tarihe Göre (Önce en eski ilan)"
                              ]
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSort = value!;
                                });
                              },
                            ),
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
                    minTime: DateTime(2020, 1, 1),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateText,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFFE53935)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Ara...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchText = "";
                      _selectedSort = "Hepsi";
                      _startDate = null;
                      _endDate = null;
                      _showAll = false;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                  label: const Text("Filtreyi Temizle",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(238, 46, 36, 1),
            borderRadius: BorderRadius.circular(10),
          ),
                            child: Row(
                    children: [
                      const Icon(Icons.person_2_outlined, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Toplam Kişi Sayısı: ${widget.advisorsData?.totalCount ?? 0}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
        ),
        const SizedBox(height: 8),
        // Container(
        //   margin: const EdgeInsets.only(bottom: 10),
        //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        //   decoration: BoxDecoration(
        //     color: const Color.fromRGBO(238, 46, 36, 1),
        //     borderRadius: BorderRadius.circular(10),
        //   ),
        //   child: Row(
        //     children: const [
        //       Icon(Icons.list_alt_outlined, color: Colors.white),
        //       SizedBox(width: 10),
        //       Expanded(
        //         child: Text(
        //           "Excel Çıktısı",
        //           style: TextStyle(
        //               color: Colors.white,
        //               fontWeight: FontWeight.bold,
        //               fontSize: 16),
        //           textAlign: TextAlign.left,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // Tümünü Gör/Gizle butonu
        if (_filteredAdvisors.length > 5)
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
        _displayedAdvisors.isEmpty
            ? EmptyDataView(
                compact: true,
                icon: Icons.people_outline_rounded,
                title: 'Veri yok',
                subtitle: (widget.advisorsData?.advisors.isNotEmpty ?? false)
                    ? 'Bu filtreye uygun kişi yok'
                    : 'Gösterilecek kişi kaydı yok',
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _displayedAdvisors.length,
                itemBuilder: (context, index) {
                  final advisor = _displayedAdvisors[index];
                  return _buildAdvisorCard(advisor);
                },
              ),
      ],
    );
  }

  Widget _buildAdvisorCard(AdvisorItem advisor) {
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
                        advisor.typeDescription ?? "Danışman",
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
                Text("Ofis: ", style: TextStyle(fontWeight: FontWeight.w600)),
                Text(advisor.officeTitle ?? "Belirtilmemiş"),
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
                        text: "₺${_formatPrice(advisor.revenue?.toString() ?? "0")}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("Son İşlem Tarihi: ", style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _formatLastTransaction(advisor.lastTransaction),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
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

  String _formatPrice(String priceString) {
    try {
      final price = double.parse(priceString);
      return NumberFormat('#,##0.00', 'tr_TR').format(price);
    } catch (e) {
      return '0,00';
    }
  }

  /// Son işlem tarihi: dd.MM.yyyy HH:mm. Veri yoksa "00.00.000 00:00" (N/A yok).
  String _formatLastTransaction(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "00.00.000 00:00";
    try {
      final date = DateTime.parse(dateString.trim()).toLocal();
      final tarih = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      final saat = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return "$tarih $saat";
    } catch (e) {
      return "00.00.000 00:00";
    }
  }

}
