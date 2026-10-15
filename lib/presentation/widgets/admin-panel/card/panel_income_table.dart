import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';

class PanelIncomeTable extends StatefulWidget {
  const PanelIncomeTable({super.key});

  @override
  State<PanelIncomeTable> createState() => _PanelIncomeTableState();
}

class _PanelIncomeTableState extends State<PanelIncomeTable> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSort = "Hepsi";
  String _selectedStatus = "Hepsi";
  String _searchText = "";
  bool _showAll = false;

  // Statik veri listesi (örnek)
  final List<Map<String, String>> _allIncomes = List.generate(
    12,
    (index) => {
      'consultant': 'Danışman ${index + 1}',
      'customer': 'Müşteri ${index + 1}',
      'buyerCommission': '₺${(20000 + index * 1000).toStringAsFixed(2).replaceAll('.', ',')}',
      'sellerCommission': '₺${(20000 + index * 500).toStringAsFixed(2).replaceAll('.', ',')}',
      'type': index % 2 == 0 ? 'Kiralandı' : 'Satıldı',
      'netProfit': '₺${(40000 + index * 1500).toStringAsFixed(2).replaceAll('.', ',')}',
      'date': '${28 - (index % 28)} Şubat 2025 ${13 + (index % 11)}:${19 + (index % 40)}',
    },
  );

  List<Map<String, String>> get _displayedIncomes {
    // Tümünü Gör durumunda tüm verileri döndür
    if (_showAll) {
      return _allIncomes;
    }
    
    // Normal durumda ilk 5 öğeyi göster
    return _allIncomes.length > 5 ? _allIncomes.sublist(0, 5) : _allIncomes;
  }

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null)
      return "Başlangıç: " + DateFormat('dd/MM/yyyy').format(_startDate!);
    if (_startDate != null && _endDate != null)
      return "${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}";
    return "Tarih aralığı seçin";
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
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: const Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "Ofis Gelir Tablosu",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                                  "A-Z",
                                  "Z-A",
                                  "En Yüksek Kazanç",
                                  "En Düşük Kazanç"
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Colors.white,
                                value: _selectedStatus,
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: "Durum",
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
                                items: ["Hepsi", "Kiralandı", "Satıldı"]
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
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
                                "A-Z",
                                "Z-A",
                                "En Yüksek Kazanç",
                                "En Düşük Kazanç"
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
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              value: _selectedStatus,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16),
                              decoration: InputDecoration(
                                labelText: "Durum",
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
                              items: ["Hepsi", "Kiralandı", "Satıldı"]
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
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
                          size: 18, color: Color(0xFF10B981)),
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
                    const Icon(Icons.search, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Arama Yap',
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
                      _selectedStatus = "Hepsi";
                      _startDate = null;
                      _endDate = null;
                      _showAll = false;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, color: Color(0xFF10B981)),
                  label: const Text("Filtreyi Temizle",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
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
              Icon(Icons.monetization_on, color: const Color(0xFF10B981), size: 22),
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
                            text: "459.000,00",
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
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xFF10B981).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.list_alt_outlined, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Excel Çıktısı",
                  style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Tümünü Gör/Gizle butonu
        if (_allIncomes.length > 5)
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
                      color: const Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAll ? "Tümünü Gizle" : "Tümünü Gör",
                      style: const TextStyle(
                        color: Color(0xFF10B981),
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

        // Gelir Kartları
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _displayedIncomes.length,
          itemBuilder: (context, index) {
            final income = _displayedIncomes[index];
            return _buildIncomeCard(
              consultant: income['consultant']!,
              customername: "Müşteri: ",
              customer: income['customer']!,
              buyerCommission: income['buyerCommission']!,
              sellerCommission: income['sellerCommission']!,
              type: income['type']!,
              netProfit: income['netProfit']!,
              date: income['date']!,
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncomeCard({
    required String consultant,
    required String customername,
    required String customer,
    required String buyerCommission,
    required String sellerCommission,
    required String type,
    required String netProfit,
    required String date,
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
                        consultant,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            customername,
                            style: TextStyle(
                              color: const Color.fromRGBO(238, 46, 36, 1),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            customer,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_horiz,
                  color: Colors.grey[400],
                  size: 20,
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
                Expanded(
                  child: _buildKapanisInfo("Kapanış Fiyatı:", buyerCommission),
                ),
              ],
            ),
            SizedBox(height: 10),
            Column(
              children: [
                _buildKapanisInfo("Alıcı Komisyon:", buyerCommission),
                SizedBox(height: 10),
                _buildKapanisInfo("Satıcı Komisyon:", sellerCommission),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Net Kazanç:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color.fromRGBO(238, 46, 36, 1),
                  ),
                ),
                Text(
                  netProfit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color.fromRGBO(238, 46, 36, 1),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "İşlem Tarihi:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  date,
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

  Widget _buildKapanisInfo(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
