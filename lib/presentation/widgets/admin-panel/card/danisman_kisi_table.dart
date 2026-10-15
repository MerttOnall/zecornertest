import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/dashboard/advisor/advisor_sales_model.dart';
import 'package:zecorner/infrastructure/dashboard/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';

class DanismanKisiTable extends StatefulWidget {
  const DanismanKisiTable({super.key});

  @override
  State<DanismanKisiTable> createState() => _DanismanKisiTableState();
}

class _DanismanKisiTableState extends State<DanismanKisiTable> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedSort = "Hepsi";
  String _selectedStatus = "Hepsi";
  String _searchText = "";

  // API Data
  final DashboardRepository _dashboardRepo = DashboardRepository();
  AdvisorSalesModel? _salesData;
  bool _isLoading = false;
  int _userContactNo = 0;
  int _advisorId = 0;
  String _userFullName = '';

  // Pagination kaldırıldı - sadece "Tümünü Gör" özelliği kullanılıyor
  int _totalCount = 0;
  static const int _pageSize = 5; // İlk yüklemede 5 kart göster
  bool _showAllSales = false; // Tümünü göster/gizle için

  // Arama için debounce timer
  Timer? _searchDebounce;

  String get _dateText {
    if (_startDate == null && _endDate == null) return "Tarih aralığı seçin";
    if (_startDate != null && _endDate == null)
      return "Başlangıç: " + DateFormat('dd/MM/yyyy').format(_startDate!);
    if (_startDate != null && _endDate != null)
      return "${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}";
    return "Tarih aralığı seçin";
  }

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Satış verilerini API'den yükle
  Future<void> _loadSalesData() async {
    print('🔄 _loadSalesData çağrıldı');
    setState(() {
      _isLoading = true;
    });

    try {
      // API parametrelerini hazırla - Web'deki gibi tarih formatı
      final startDate = _startDate ?? DateTime(2025, 1, 1);
      final endDate = _endDate ??
          DateTime(2025, 9, 1, 23, 59, 59); // Web'deki gibi saat ekle

      print('🎯 Sales API çağrısı yapılıyor...');
      print('📅 Start Date: ${startDate.toIso8601String()}');
      print('📅 End Date: ${endDate.toIso8601String()}');

      // Doğrudan API çağrısı yap - her zaman page 0
      final salesData = await _fetchSalesDataDirect(startDate, endDate);
      if (salesData != null) {
        _salesData = salesData;
        _totalCount = salesData.totalCount;
        print('✅ Sales Model oluşturuldu: ${_salesData.toString()}');
        print('📊 Toplam Satış: ${_salesData!.sales.length}');
        print('💰 Toplam Gelir: ${_salesData!.totalRevenue}');
        print('📊 Toplam Kayıt: $_totalCount');
      } else {
        print('❌ Sales verisi alınamadı');
        _salesData = null;
      }
    } catch (e) {
      print('❌ Sales verileri yüklenirken hata: $e');
      _salesData = null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Danışman sales için doğrudan API çağrısı
  Future<AdvisorSalesModel?> _fetchSalesDataDirect(
      DateTime startDate, DateTime endDate) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await _loadCurrentAdvisor();
      final token = pref.getString('userJWT');

      if (token == null || token.isEmpty) {
        print('❌ Sales API: Token yok');
        return null;
      }

      final String baseUrl = '${EnvApi.origin}';
      final String apiKey = 'ed017c68-24ca-4239-ae68-0fa041391855';
      final String appId = 'zecorner';

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // URL encode tarih parametreleri
      final encodedStartDate = Uri.encodeComponent(startDate.toIso8601String());
      final encodedEndDate = Uri.encodeComponent(endDate.toIso8601String());

      // Status filtresi - "Hepsi" ise gönderme
      String statusParam = "";
      if (_selectedStatus != "Hepsi") {
        if (_selectedStatus == "Kiralandı") {
          statusParam = "&status=RENTED";
        } else if (_selectedStatus == "Satıldı") {
          statusParam = "&status=SOLD";
        }
      }

      // Arama filtresi - boş değilse gönder
      String searchParam = "";
      if (_searchText.isNotEmpty) {
        searchParam = "&search=${Uri.encodeComponent(_searchText)}";
      }

      // Sunucu sayfası ofis genelini döndürebilir. Önce geniş çek,
      // sonra yalnızca oturumdaki danışmanın kayıtlarını bırak.
      const currentPageSize = 1000;
      final url =
          "$baseUrl/api/zecorner/dashboard/advisor/sales/?page=1&startDate=$encodedStartDate&pageSize=$currentPageSize&endDate=$encodedEndDate&sortOrder=desc&sortColumn=date$statusParam$searchParam";

      print('🌐 Sales API URL: $url');
      print(
          '🔍 Filtreler - Status: $_selectedStatus, Search: $_searchText, StartDate: $_startDate, EndDate: $_endDate');

      final dio = Dio();
      final response = await dio.get(url, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Sales API Response: $data');
        return AdvisorSalesModel.fromJson(data);
      } else {
        print('❌ Sales API Error: ${response.statusCode} - ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      print('❌ Sales API DioException: ${e.message} - ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Sales API Genel hata: $e');
      return null;
    }
  }

  /// Para formatı için yardımcı metot
  String _formatPrice(String priceString) {
    try {
      final price = double.tryParse(priceString) ?? 0.0;
      final integerPart = price.toInt().toString();
      final formattedInteger = integerPart.replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
      return "₺$formattedInteger,00";
    } catch (e) {
      return "₺0,00";
    }
  }

  Future<void> _loadCurrentAdvisor() async {
    final pref = await SharedPreferences.getInstance();
    final contactNo = int.tryParse(pref.getString('userID')?.trim() ?? '') ?? 0;
    final advisorId = pref.getInt('advisorId') ?? 0;
    final name = [
      pref.getString('userName') ?? '',
      pref.getString('userSurname') ?? '',
    ].join(' ').trim();
    _userContactNo = contactNo;
    _advisorId = advisorId;
    _userFullName = name;
  }

  String _fold(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _samePerson(int id, String title) {
    if (_userContactNo > 0 && id == _userContactNo) return true;
    if (_advisorId > 0 && id == _advisorId) return true;
    final mine = _fold(_userFullName);
    final theirs = _fold(title);
    return mine.isNotEmpty && theirs.isNotEmpty && mine == theirs;
  }

  bool _canIdentifyAdvisor() =>
      _userContactNo > 0 || _advisorId > 0 || _userFullName.trim().isNotEmpty;

  double _amount(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text == '-') return 0;
    return double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  /// Danışmanın bu kayıtta gördüğü taraf.
  /// İlan sahibi satıcı tarafıdır. Alıcı komisyonu yalnızca alıcı
  /// danışmanı kendisiyse görünür; aksi halde başka danışmanın tutarıdır.
  _OwnSide _ownSide(SaleModel sale) {
    final side = _fold(sale.commissionSide);
    if (side == 'seller' || side == 'satici' || side == 'satıcı') {
      return _OwnSide.seller;
    }
    if (side == 'buyer' || side == 'alici' || side == 'alıcı') {
      return _OwnSide.buyer;
    }
    if (side == 'both' || side == 'all') {
      return _OwnSide.both;
    }

    final isListingAdvisor = _samePerson(sale.advisor, sale.advisorTitle);
    final isSeller = sale.sellerAdvisor > 0
        ? _samePerson(sale.sellerAdvisor, sale.sellerAdvisorTitle)
        : isListingAdvisor;
    final isBuyer = sale.buyerAdvisor > 0
        ? _samePerson(sale.buyerAdvisor, sale.buyerAdvisorTitle)
        : false;

    if (!isSeller && !isBuyer && !isListingAdvisor) return _OwnSide.none;
    if (isSeller && isBuyer) return _OwnSide.both;
    if (isBuyer) return _OwnSide.buyer;

    final sellerAmount = _amount(sale.sellerCommission);
    final buyerAmount = _amount(sale.buyerComission);
    if (sellerAmount <= 0 && buyerAmount > 0 && sale.buyerAdvisor <= 0) {
      return _OwnSide.buyer;
    }
    return _OwnSide.seller;
  }

  List<SaleModel> get _ownSales {
    final sales = _salesData?.sales ?? const <SaleModel>[];
    if (!_canIdentifyAdvisor()) return const [];
    return sales.where((sale) => _ownSide(sale) != _OwnSide.none).toList();
  }

  List<SaleModel> get _visibleSales {
    final own = _ownSales;
    if (_showAllSales || own.length <= _pageSize) return own;
    return own.take(_pageSize).toList();
  }

  double _ownNet(SaleModel sale) {
    switch (_ownSide(sale)) {
      case _OwnSide.seller:
        return _amount(sale.sellerCommission);
      case _OwnSide.buyer:
        return _amount(sale.buyerComission);
      case _OwnSide.both:
        return _amount(sale.sellerCommission) + _amount(sale.buyerComission);
      case _OwnSide.none:
        return 0;
    }
  }

  /// Toplam gelir — yalnızca danışmanın kendi tarafı
  String _getTotalRevenue() {
    final total = _ownSales.fold<double>(0, (sum, sale) => sum + _ownNet(sale));
    return _formatPrice(total.toString());
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
                "Danışman Gelir Tablosu",
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
                                  _loadSalesData(); // Filtre değiştiğinde veriyi yeniden yükle
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
                                _loadSalesData(); // Filtre değiştiğinde veriyi yeniden yükle
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
                    _loadSalesData(); // Tarih değiştiğinde veriyi yeniden yükle
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
                          hintText: 'Arama Yap',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                          // Debounce: 500ms bekle, sonra arama yap
                          _searchDebounce?.cancel();
                          _searchDebounce =
                              Timer(const Duration(milliseconds: 500), () {
                            _loadSalesData(); // Arama değiştiğinde veriyi yeniden yükle
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
                      _startDate = null;
                      _endDate = null;
                      _selectedStatus = "Hepsi";
                      _searchText = "";
                      _showAllSales = false; // Tümünü göster modunu da kapat
                    });
                    _loadSalesData(); // Filtreyi temizle ve veriyi yeniden yükle
                  },
                  icon: const Icon(Icons.filter_alt_off, color: Colors.white),
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
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Toplam Net Kazanç: ${_getTotalRevenue()}",
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
        //         ),

        // Tümünü Gör/Gizle linki
        if (_ownSales.length > _pageSize)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllSales = !_showAllSales;
                  });
                  _loadSalesData(); // Veriyi yeniden yükle
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllSales
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFFE53935),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllSales ? "Tümünü Gizle" : "Tümünü Gör",
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(height: 10),

        // Gelir Kartları
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE53935),
                ),
              )
            : _visibleSales.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _visibleSales.length,
                    itemBuilder: (context, index) {
                      final sale = _visibleSales[index];
                      final side = _ownSide(sale);
                      final showSeller =
                          side == _OwnSide.seller || side == _OwnSide.both;
                      final showBuyer =
                          side == _OwnSide.buyer || side == _OwnSide.both;
                      return _buildIncomeCard(
                        consultant: sale.listingTitle,
                        customername: "Müşteri: ",
                        customer: sale.customerTitle,
                        buyerCommission: showBuyer
                            ? (_amount(sale.buyerComission) > 0
                                ? _formatPrice(sale.buyerComission)
                                : "-")
                            : null,
                        sellerCommission: showSeller
                            ? (_amount(sale.sellerCommission) > 0
                                ? _formatPrice(sale.sellerCommission)
                                : "-")
                            : null,
                        type: sale.state == "RENTED" ? "Kiralandı" : "Satıldı",
                        netProfit: _formatPrice(_ownNet(sale).toString()),
                        date: DateFormat('dd MMMM yyyy HH:mm')
                            .format(DateTime.parse(sale.date)),
                      );
                    },
                  )
                : const EmptyDataView(
                    compact: true,
                    icon: Icons.inbox_rounded,
                    title: 'Veri yok',
                    subtitle: 'Gösterilecek gelir kaydı yok',
                  ),

        // Pagination Kontrolleri kaldırıldı - sadece "Tümünü Gör/Gizle" özelliği kullanılıyor
      ],
    );
  }

  Widget _buildIncomeCard({
    required String consultant,
    required String customername,
    required String customer,
    String? buyerCommission,
    String? sellerCommission,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    color: type == "Kiralandı"
                        ? Colors.blue.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: type == "Kiralandı" ? Colors.blue : Colors.green,
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
            if (buyerCommission != null || sellerCommission != null)
              Column(
                children: [
                  if (buyerCommission != null)
                    _buildKapanisInfo("Alıcı Komisyon:", buyerCommission),
                  if (buyerCommission != null && sellerCommission != null)
                    const SizedBox(height: 10),
                  if (sellerCommission != null)
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

  Widget _buildCommissionInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
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

enum _OwnSide { seller, buyer, both, none }
