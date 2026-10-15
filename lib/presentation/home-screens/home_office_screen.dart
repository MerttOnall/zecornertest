import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/infrastructure/office/office_repo.dart';
import 'package:zecorner/models/office/office_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class HomeOfficeScreen extends StatefulWidget {
  const HomeOfficeScreen({super.key});

  @override
  State<HomeOfficeScreen> createState() => _HomeOfficeScreenState();
}

class _HomeOfficeScreenState extends State<HomeOfficeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedCity;
  String? selectedDistrict;
  int _currentIndex = 1;

  String _search = '';

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Repository ve state management
  final OfficeRepository _officeRepo = OfficeRepository();
  List<OfficeModel> _allOffices = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Çok yakında ofisleri - sabit kalacak
  final List<Map<String, dynamic>> soonOffices = [
    {
      'logo': 'Yatırım Gayrimenkul',
      'location': 'İstanbul / Kadıköy / Caddebostan Mah.',
      'city': 'İstanbul',
      'district': 'Kadıköy',
    },
  ];

  List<OfficeModel> get filteredActiveOffices {
    List<OfficeModel> list = List.from(_allOffices);
    final addressSplit = (String addr) => addr.split(' / ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // İl filtresi (adresin ilk parçası: İl)
    if (selectedCity != null && selectedCity!.isNotEmpty) {
      list = list.where((office) {
        final parts = addressSplit(office.officeAddress);
        if (parts.isEmpty) return false;
        final il = parts[0];
        return il == selectedCity;
      }).toList();
    }

    // İlçe filtresi (adresin ikinci parçası: İlçe)
    if (selectedDistrict != null && selectedDistrict!.isNotEmpty) {
      list = list.where((office) {
        final parts = addressSplit(office.officeAddress);
        if (parts.length < 2) return false;
        return parts[1] == selectedDistrict;
      }).toList();
    }

    // Arama filtresi
    if (_search.isNotEmpty) {
      list = list.where((office) =>
        office.officeTitle.toLowerCase().contains(_search.toLowerCase()) ||
        office.officeSlug.toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }

    list.sort((a, b) => a.officeTitle.compareTo(b.officeTitle));
    return list;
  }

  List<Map<String, dynamic>> get filteredSoonOffices {
    List<Map<String, dynamic>> list = List.from(soonOffices);
    if (selectedCity != null && selectedCity!.isNotEmpty) {
      list = list.where((o) => o['city'] == selectedCity).toList();
    }
    if (selectedDistrict != null && selectedDistrict!.isNotEmpty) {
      list = list.where((o) => o['district'] == selectedDistrict).toList();
    }
    if (_search.isNotEmpty) {
      list = list.where((o) => o['logo'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    list.sort((a, b) => (a['logo'] as String).compareTo(b['logo'] as String));
    return list;
  }

  /// Mevcut ofislerden benzersiz illeri çıkar (adres formatı: "İl / İlçe / ...")
  List<String> get availableCities {
    if (_allOffices.isEmpty) return [];
    final partsList = _allOffices.map((office) {
      final parts = office.officeAddress.split(' / ').map((e) => e.trim()).where((e) => e.isNotEmpty);
      return parts.isEmpty ? null : parts.first;
    }).whereType<String>().toSet().toList();
    partsList.sort();
    return partsList;
  }

  /// Seçili ile göre mevcut ilçeleri çıkar (adres formatı: "İl / İlçe / ...")
  List<String> get availableDistricts {
    if (_allOffices.isEmpty || selectedCity == null || selectedCity!.isEmpty) return [];
    final districts = _allOffices
        .where((office) {
          final parts = office.officeAddress.split(' / ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          return parts.isNotEmpty && parts[0] == selectedCity;
        })
        .map((office) {
          final parts = office.officeAddress.split(' / ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          return parts.length >= 2 ? parts[1] : '';
        })
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _loadOffices();
  }

  /// Ofisleri API'den yükle
  Future<void> _loadOffices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _officeRepo.getAllOffices(limit: 100);
      
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
          print('❌ Ofisler yüklenemedi: ${failure.message}');
        },
        (officeResponse) {
          setState(() {
            _allOffices = officeResponse.offices;
            _isLoading = false;
            _errorMessage = null;
          });
          print('✅ ${officeResponse.offices.length} ofis yüklendi');
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Beklenmeyen hata oluştu: $e';
      });
      print('❌ Ofis yükleme hatası: $e');
    }
  }

  /// Ofisleri yenile
  Future<void> _refreshOffices() async {
    await _loadOffices();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
      ),
      drawer: const HomeSidebar(currentPage: 'Ofislerimiz'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Üstte sayaç
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 46, 36, 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filteredActiveOffices.length} Adet Ofis Bulundu',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                // Arama kutusu
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ofis adına göre arama...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _search = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                // Filtre Alanı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      // İl Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: selectedCity,
                              hint: const Text(
                                "İl",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black87,
                              ),
                              items: availableCities
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedCity = newValue;
                                  selectedDistrict = null; // İl değişince ilçe sıfırlanır
                                });
                              },
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // İlçe Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedCity != null && availableDistricts.isNotEmpty
                                ? Colors.white
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: selectedDistrict,
                              hint: Text(
                                "İlçe",
                                style: TextStyle(
                                  color: selectedCity != null && availableDistricts.isNotEmpty
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: selectedCity != null && availableDistricts.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                              items: availableDistricts
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: selectedCity != null && availableDistricts.isNotEmpty
                                  ? (newValue) {
                                      setState(() {
                                        selectedDistrict = newValue;
                                      });
                                    }
                                  : null,
                              style: TextStyle(
                                color: selectedCity != null && availableDistricts.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filtreyi Temizle Butonu
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCity = null;
                            selectedDistrict = null;
                            _search = '';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Temizle",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tüm Ofisler Başlığı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        "Tüm Ofisler",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Loading, Error ve Success states
                      if (_isLoading)
                        const AppStatusView.loading(
                          title: 'Ofisler hazırlanıyor.',
                          message: 'Ofis listesi yüklenirken lütfen bekleyin.',
                        )
                      else if (_errorMessage != null)
                        AppStatusView.error(
                          message: _errorMessage,
                          retryLabel: 'Yeniden Dene',
                          onRetry: _refreshOffices,
                        )
                      else ...[
                        ...filteredActiveOffices.map((office) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _buildOfficeCard(office: office),
                        )),
                        if (filteredActiveOffices.isEmpty)
                          const AppStatusView.missing(
                            title: 'Ofis bulunamadı',
                            message: 'Arama kriterlerinize uygun ofis kaydı yok.',
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Çok Yakında Başlığı
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 16),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         "Çok Yakında",
                //         style: TextStyle(
                //           fontSize: 24,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       const SizedBox(height: 16),
                //       ...filteredSoonOffices.map((o) => Padding(
                //         padding: const EdgeInsets.only(bottom: 18),
                //         child: _buildOfficeCardd(
                //           logo: o['logo'],
                //           location: o['location'],
                //         ),
                //       )),
                //       if (filteredSoonOffices.isEmpty)
                //         const Padding(
                //           padding: EdgeInsets.symmetric(vertical: 32),
                //           child: Center(child: Text('Sonuç bulunamadı.', style: TextStyle(fontSize: 16))),
                //         ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }



  Widget _buildOfficeCard({required OfficeModel office}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.homeOfficeDetail,
          arguments: office,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Alanı - Sola hizalı
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 20, right: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildOfficeLogo(office.officeLogo),
            ),
          ),
          const SizedBox(height: 20),
          // Ofis başlığı - Sola hizalı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  office.officeTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bilgi Alanı - Merkez hizalı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Konum
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Color.fromRGBO(238, 46, 36, 1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        office.officeAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Telefon
                if (office.officePhone.isNotEmpty && office.officePhone != 'Belirtilmedi') ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: Color.fromRGBO(238, 46, 36, 1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          office.officePhone,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                // Email
                if (office.officeEmail.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: Color.fromRGBO(238, 46, 36, 1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          office.officeEmail,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                // Üye sayısı
                if (office.totalMembers > 0) ...[
                  Row(
                    children: [
                      ...List.generate(
                        (office.totalMembers > 3 ? 3 : office.totalMembers), 
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      if (office.totalMembers > 3) ...[
                        const SizedBox(width: 8),
                        Text(
                          "+${office.totalMembers - 3} Daha",
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey.shade700, 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: office.sizeCategory == 'Küçük' 
                      //       ? Colors.blue.shade400
                      //       : office.sizeCategory == 'Orta' 
                      //         ? Colors.orange.shade400
                      //         : Colors.green.shade400,
                      //     borderRadius: BorderRadius.circular(16),
                      //   ),
                      //   child: Text(
                      //     "${office.totalMembers} Üye",
                      //     style: const TextStyle(
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w600,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Kalite skoru
                // Row(
                //   children: [
                //     Icon(
                //       Icons.star,
                //       size: 18,
                //       color: office.qualityScore >= 80 
                //         ? Colors.green
                //         : office.qualityScore >= 60 
                //           ? Colors.orange
                //           : Colors.red,
                //     ),
                //     const SizedBox(width: 6),
                //     Text(
                //       "Kalite: ${office.qualityScore}/100",
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w500,
                //         color: office.qualityScore >= 80 
                //           ? Colors.green.shade700
                //           : office.qualityScore >= 60 
                //             ? Colors.orange.shade700
                //             : Colors.red.shade700,
                //       ),
                //     ),
                //     const Spacer(),
                //     Text(
                //       office.qualityCategory,
                //       style: TextStyle(
                //         fontSize: 12,
                //         fontWeight: FontWeight.w600,
                //         color: Colors.grey.shade600,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }


  /// S3'ten ofis logosu göstermek için widget builder
  Widget _buildOfficeLogo(String? s3Id) {
    // S3 ID'si yoksa veya geçersizse placeholder göster
    if (!ImageUtils.isValidS3Id(s3Id)) {
      return Container(
        width: 160,
        height: 80,
        color: Colors.transparent,
        child: const Icon(
          Icons.business_outlined,
          size: 52,
          color: Colors.grey,
        ),
      );
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getS3FileUrl(s3Id);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200,
        maxHeight: 100,
        minWidth: 120,
        minHeight: 60,
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 160,
            height: 80,
            color: Colors.transparent,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(238, 46, 36, 1)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 160,
            height: 80,
            color: Colors.transparent,
            child: const Icon(
              Icons.business_outlined,
              size: 52,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

}
