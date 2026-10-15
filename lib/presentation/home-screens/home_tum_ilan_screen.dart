import 'package:flutter/material.dart';
import 'dart:async';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/router/app_router.dart';
import '../../infrastructure/list/listing_repository.dart';
import '../../infrastructure/provinces/provinces_repository.dart';
import '../../infrastructure/provinces/provinces_detail_repo.dart';
import '../../models/list/listing_model.dart';
import '../../models/province/provinces_model.dart';
import '../../models/province/provinces_detail_model.dart';
import '../../core/utils/image_utils.dart';

class HomeTumIlansScreen extends StatefulWidget {
  const HomeTumIlansScreen({super.key});

  @override
  State<HomeTumIlansScreen> createState() => _HomeTumIlansScreenState();
}

class _HomeTumIlansScreenState extends State<HomeTumIlansScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;

  // Repository ve API verileri
  final ListingRepository _repository = ListingRepository();
  List<ListingModel> _listings = [];
  int _currentPage = 1;
  int _totalPages = 1; // ignore: unused_field
  int _totalCount = 0;
  bool _hasMoreData = true;
  bool _loadingMore = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  
  // Cache kontrolü
  bool _isDataCached = false;
  
  // Filtreleme değişkenleri
  String _search = '';
  String _kategori = '';
  String _tip = '';
  String? _il;
  String? _ilce;
  String? _mahalle;
  int? _minFiyat;
  int? _maxFiyat;
  int? _minM2;
  int? _maxM2;
  String _sort = 'Tarih - En Yeni';
  final GlobalKey _sortDropdownKey = GlobalKey(); // Dropdown butonunun pozisyonu için

  static const Color _filterRed = Color.fromRGBO(238, 46, 36, 1);

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Statik ilan listesi kaldırıldı - artık API'den veri çekiyoruz

  List<ListingModel> get filteredIlans {
    List<ListingModel> list = _listings.where((listing) {
      // Kategori filtresi (emlak tipi: konut, is-yeri, arsa)
      if (_kategori.isNotEmpty) {
        final rt = listing.realEstateType.toLowerCase();
        if (_kategori == 'konut' && !rt.contains('konut')) return false;
        if (_kategori == 'is-yeri' && !rt.contains('is-yeri')) return false;
        if (_kategori == 'arsa' && !rt.contains('arsa')) return false;
      }
      
      // Tip filtresi (satılık/kiralık)
      if (_tip.isNotEmpty && listing.type != _tip) return false;
      
      // İl filtresi
      if (_il != null && _il!.isNotEmpty && listing.provinceName != _il) return false;
      
      // İlçe filtresi
      if (_ilce != null && _ilce!.isNotEmpty && listing.districtName != _ilce) return false;
      
      // Mahalle filtresi
      if (_mahalle != null && _mahalle!.isNotEmpty && listing.quarterName != _mahalle) return false;
      
      // Minimum fiyat filtresi
      if (_minFiyat != null && listing.price < _minFiyat!) return false;
      
      // Maksimum fiyat filtresi
      if (_maxFiyat != null && listing.price > _maxFiyat!) return false;
      
      // m2 filtresi (brüt/net/m2)
      final listingM2 = listing.properties['m2-brut']?.numberValue ?? listing.properties['m2-net']?.numberValue ?? listing.properties['m2']?.numberValue;
      if (_minM2 != null && (listingM2 == null || listingM2 < _minM2!)) return false;
      if (_maxM2 != null && (listingM2 == null || listingM2 > _maxM2!)) return false;
      
      // Arama filtresi (başlıkta arama)
      if (_search.isNotEmpty && !listing.title.toLowerCase().contains(_search.toLowerCase())) return false;
      
      return true;
    }).toList();
    
    // Sıralama
    if (_sort == 'Tarih - En Yeni') {
      // Varsayılan sıralama (API'den gelen sıralama - zaten en yeni)
      list.sort((a, b) {
        // createdAt String olduğu için direkt karşılaştır
        final dateCompare = b.createdAt.compareTo(a.createdAt);
        if (dateCompare != 0) return dateCompare;
        return b.id.compareTo(a.id);
      });
    } else if (_sort == 'Tarih - En Eski') {
      list.sort((a, b) {
        final dateCompare = a.createdAt.compareTo(b.createdAt);
        if (dateCompare != 0) return dateCompare;
        return a.id.compareTo(b.id);
      });
    } else if (_sort == 'Fiyat - Artan') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'Fiyat - Azalan') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    
    return list;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.99, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    
    // Cache kontrollü veri yükleme
    _loadDataIfNeeded();
  }

  /// Cache kontrollü veri yükleme
  Future<void> _loadDataIfNeeded() async {
    print('🔍 Cache kontrol ediliyor...');
    print('📊 _isDataCached: $_isDataCached');
    print('📊 _listings.length: ${_listings.length}');
    
    // Eğer cache'de veriler varsa hiç API çağrısı yapma
    if (_isDataCached && _listings.isNotEmpty) {
      setState(() {
        _loading = false; // Loading'i kapat
      });
      print('📦 ✅ Cache\'den ${_listings.length} ilan gösteriliyor - API çağrısı YOK!');
      return;
    }
    
    // Cache yoksa sadece o zaman API çağrısı yap
    print('🔄 Cache boş - ilk kez API çağrısı yapılıyor...');
    await _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false}) async {
    print('📡 _loadData başlatıldı: refresh=$refresh, page=$_currentPage');
    
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _listings.clear();
        _hasMoreData = true;
        _errorMessage = null;
        _loading = true;
      });
      print('🔄 Refresh mode: sayfa 1\'e reset edildi');
    } else if (_currentPage == 1) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
      print('🔄 İlk sayfa yükleniyor');
    }

    try {
      final filters = <String, dynamic>{};
      if (_search.isNotEmpty) {
        filters['search'] = _search;
        print('🔍 Arama filtresi: $_search');
      }

      print('🌐 API çağrısı başlatılıyor: sayfa $_currentPage, limit 10');
      print('📋 Filters: $filters');

      final result = await _repository.getListings(
        page: _currentPage,
        limit: 10,
        filters: filters,
      );
      
      print('📡 API çağrısı tamamlandı, sonuç işleniyor...');

      result.fold(
        (failure) {
          print('❌ API Hatası: ${failure.message}');
          setState(() {
            _loading = false;
            _loadingMore = false;
            _errorMessage = failure.message;
          });
        },
        (response) {
          print('✅ API başarılı! Toplam: ${response.totalCount}, Bu sayfa: ${response.listings.length}');
          setState(() {
            if (refresh || _currentPage == 1) {
              _listings = response.listings;
              print('🔄 Liste değiştirildi: ${_listings.length} ilan');
            } else {
              _listings.addAll(response.listings);
              print('➕ Listeye eklendi: +${response.listings.length}, toplam: ${_listings.length}');
            }
            _totalCount = response.totalCount;
            _totalPages = response.totalPages;
            _hasMoreData = _currentPage < response.totalPages;
            _loading = false;
            _loadingMore = false;
            _errorMessage = null;
            
            // Başarılı yükleme sonrası cache'i işaretle
            _isDataCached = true;
          });
          print('✅ State güncellendi: loading=$_loading, totalCount=$_totalCount');
        },
      );
    } catch (e) {
      print('💥 Beklenmeyen hata: $e');
      setState(() {
        _loading = false;
        _loadingMore = false;
        _errorMessage = 'Hata: $e';
      });
    }
    
    print('🏁 _loadData tamamlandı');
  }

  Future<void> _loadMoreData() async {
    if (_loadingMore || !_hasMoreData) return;

    setState(() {
      _loadingMore = true;
      _currentPage++;
    });

    await _loadData();
  }

  Future<void> _refreshData() async {
    print('🔄 PULL-TO-REFRESH: Cache temizleniyor ve yeniden yükleniyor');
    setState(() {
      _isDataCached = false; // Cache'i temizle
      _listings.clear(); // Mevcut listeyi temizle
    });
    await _loadData(refresh: true);
  }

  void _applyFilters() {
    print('🔍 ARAMA/FİLTRE: Bütün ilanlara göre API ile filtreleme');
    setState(() {
      _isDataCached = false;
      _listings.clear();
    });

    // API'ye tüm filtreleri gönder - filtreleme sunucudaki bütün ilanlar üzerinde yapılsın
    final apiFilters = <String, dynamic>{};
    if (_search.isNotEmpty) apiFilters['search'] = _search;
    if (_tip.isNotEmpty) apiFilters['listing_type'] = _tip;
    if (_minFiyat != null) apiFilters['price_min'] = _minFiyat;
    if (_maxFiyat != null) apiFilters['price_max'] = _maxFiyat;
    if (_il != null && _il!.isNotEmpty) apiFilters['province'] = _il;
    if (_ilce != null && _ilce!.isNotEmpty) apiFilters['district'] = _ilce;
    if (_mahalle != null && _mahalle!.isNotEmpty) apiFilters['quarter'] = _mahalle;
    if (_kategori.isNotEmpty) apiFilters['real_estate_type'] = _kategori;
    if (_minM2 != null) apiFilters['m2_min'] = _minM2;
    if (_maxM2 != null) apiFilters['m2_max'] = _maxM2;

    print('📋 API filtreleri (bütün ilanlara göre): $apiFilters');
    _loadDataWithFilters(apiFilters);
  }

  /// Filtrelerle veri yükleme - API'deki bütün ilanlar üzerinde filtre uygulanır, tüm eşleşen sayfalar çekilir
  Future<void> _loadDataWithFilters(Map<String, dynamic> filters) async {
    try {
      setState(() {
        _loading = true;
        _currentPage = 1;
        _errorMessage = null;
      });

      const int pageSize = 100;
      List<ListingModel> allFiltered = [];
      int totalCount = 0;
      int totalPages = 1;
      int page = 1;

      while (true) {
        final result = await _repository.getListings(
          page: page,
          limit: pageSize,
          filters: filters,
        );

        final response = result.fold(
          (failure) {
            setState(() {
              _loading = false;
              _errorMessage = failure.message;
            });
            return null;
          },
          (r) => r,
        );

        if (response == null) return;

        allFiltered.addAll(response.listings);
        totalCount = response.totalCount;
        totalPages = response.totalPages;

        if (page >= totalPages || response.listings.length < pageSize) {
          break;
        }
        page++;
      }

      setState(() {
        _listings = allFiltered;
        _totalCount = totalCount;
        _totalPages = totalPages;
        _hasMoreData = false; // Filtre modunda tüm veri yüklendi, daha fazla sayfa yok
        _currentPage = 1;
        _loading = false;
        _errorMessage = null;
        _isDataCached = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Hata: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Sıralama dropdown menüsü widget'ı
  Widget _buildSortDropdown() {
    return GestureDetector(
      onTap: () => _showSortDropdown(context),
      child: Container(
        key: _sortDropdownKey,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _sort,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  /// Sıralama dropdown menüsünü göster
  void _showSortDropdown(BuildContext context) {
    final sortOptions = ['Tarih - En Yeni', 'Tarih - En Eski', 'Fiyat - Artan', 'Fiyat - Azalan'];

    // Butonun pozisyonunu al
    final RenderBox? buttonBox = _sortDropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final buttonSize = buttonBox.size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Backdrop
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Dropdown content - butonun hemen altında
                Positioned(
                  top: buttonPosition.dy + buttonSize.height + 5,
                  left: buttonPosition.dx,
                  width: buttonSize.width,
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping inside
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sıralama seçenekleri
                          ...sortOptions.map((option) {
                            final isSelected = _sort == option;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _sort = option;
                                  });
                                  Navigator.pop(context);
                                  // Sıralama değiştiğinde sadece local filtreleme yap (API çağrısı yok)
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color.fromRGBO(238, 46, 36, 0.08) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(color: const Color.fromRGBO(238, 46, 36, 0.3), width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected ? const Color.fromRGBO(238, 46, 36, 1) : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TumIlanFilterSheet(
          initialKategori: _kategori,
          initialTip: _tip,
          initialIl: _il,
          initialIlce: _ilce,
          initialMahalle: _mahalle,
          initialMinFiyat: _minFiyat,
          initialMaxFiyat: _maxFiyat,
          initialMinM2: _minM2,
          initialMaxM2: _maxM2,
          filterRed: _filterRed,
          onApply: (kategori, tip, il, ilce, mahalle, minFiyat, maxFiyat, minM2, maxM2) {
            setState(() {
              _kategori = kategori;
              _tip = tip;
              _il = il;
              _ilce = ilce;
              _mahalle = mahalle;
              _minFiyat = minFiyat;
              _maxFiyat = maxFiyat;
              _minM2 = minM2;
              _maxM2 = maxM2;
            });
            Navigator.pop(context);
            _applyFilters();
          },
          onClear: () {
            setState(() {
              _kategori = '';
              _tip = '';
              _il = null;
              _ilce = null;
              _mahalle = null;
              _minFiyat = null;
              _maxFiyat = null;
              _minM2 = null;
              _maxM2 = null;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tüm İlanlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: _filterRed),
            onPressed: _showFilterSheet,
            tooltip: 'Filtrele',
          ),
          // Development only - reset loading state
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _resetLoadingState,
          //   tooltip: 'Reset Loading',
          // ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 400;
                    return isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(238, 46, 36, 1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${filteredIlans.length} Adet İlan Bulundu',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildSortDropdown(),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(238, 46, 36, 1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${filteredIlans.length} Adet İlan Bulundu',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildSortDropdown(),
                            ],
                          );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'İlan başlığına göre arama...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                    
                                                // Debounce search - setState ile local filtreleme
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                              // Sadece setState ile local filtreleme (API çağrısı yok)
                              setState(() {});
                            });
                  },
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: _loading
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, i) => _skeletonCard(),
                      )
                    : filteredIlans.isEmpty
                        ? const Center(child: Text('Sonuç bulunamadı.', style: TextStyle(fontSize: 16)))
                                                : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              // Sayfa sonuna gelince otomatik yükle
                              if (!_loadingMore && 
                                  _hasMoreData && 
                                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                                _loadMoreData();
                              }
                              return false;
                            },
                            child: RefreshIndicator(
                              onRefresh: _refreshData,
                              color: _filterRed,
                              backgroundColor: Colors.white,
                              strokeWidth: 2.2,
                              displacement: 36,
                              child: Column(
                                children: [
                                  if (_errorMessage != null)
                                    Container(
                                      margin: const EdgeInsets.all(16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red[700]),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(color: Colors.red[700]),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _refreshData(),
                                            child: const Text('Yeniden Dene'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                      itemCount: filteredIlans.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, i) {
                                        if (i >= filteredIlans.length) {
                                          // Sadece loading indicator (buton yok)
                                          return _buildLoadingIndicator();
                                        }
                                        
                                        final listing = filteredIlans[i];
                                        return _modernIlanCard(listing, i);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(currentIndex: 3, onTap: (index) {}),
    );
  }

  Widget _modernIlanCard(ListingModel listing, int index) {
    // Şimdilik sadece ID kullan (slug 500 hatası veriyor)
    final String detailIdentifier = listing.id;
    final bool isKiralik = listing.type.toLowerCase() == 'kiralik';
    final String typeLabel = isKiralik ? 'Kiralık' : 'Satılık';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.homeIlanDetail,
          arguments: {
            'id': detailIdentifier,
            'listing': listing,
          },
        );
      },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 110,
                  height: 130,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    child: _buildListingImage(listing.coverPicture),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${listing.districtName}, ${listing.provinceName}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _infoIcon(Icons.meeting_room, _formatOdaSayisi(listing.properties['oda-sayisi']?.value)),
                                const SizedBox(width: 10),
                                _infoIcon(Icons.square_foot, '${listing.properties['m2-brut']?.numberValue ?? listing.properties['m2-net']?.numberValue ?? '-'} m²'),
                                const SizedBox(width: 10),
                                _infoIcon(Icons.layers, _formatKat(listing.properties['bulundugu-kat']?.value)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${listing.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ${listing.currency}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(238, 46, 36, 1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Kiralık / Satılık etiketi - sağ alt, full kırmızı + beyaz yazı
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(238, 46, 36, 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: const Color.fromRGBO(238, 46, 36, 1)),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      );

  /// Oda sayısını formatla (örn: "2+1", "3+1", "1+0")
  String _formatOdaSayisi(String? odaSayisi) {
    // Null, boş veya geçersiz değerler için "-" döndür
    if (odaSayisi == null || 
        odaSayisi.isEmpty || 
        odaSayisi == '-' || 
        odaSayisi == 'oda-sayisi' ||
        odaSayisi.toLowerCase().contains('undefined') ||
        odaSayisi.toLowerCase().contains('null')) {
      return '-';
    }
    
    // Debug için gerçek veriyi görelim
    print('🏠 Oda sayısı verisi: "$odaSayisi"');
    
    // API'den "oda-sayisi-21" formatında geliyorsa parse et
    if (odaSayisi.contains('oda-sayisi-')) {
      final number = odaSayisi.replaceAll('oda-sayisi-', '');
      print('🔍 Parsed number: "$number"');
      
      // Eğer number boş ise veya geçersizse
      if (number.isEmpty || number == '0' || number == '00') {
        return '-';
      }
      
      // Sadece 1-2 haneli sayıları kabul et, diğerleri geçersiz
      if (number.length > 2) {
        print('⚠️ Geçersiz oda sayısı formatı (çok uzun): "$number"');
        return '-';
      }
      
      // İki haneli sayıyı oda+salon formatına çevir
      if (number.length == 2 && RegExp(r'^\d{2}$').hasMatch(number)) {
        final oda = number[0];
        final salon = number[1];
        
        // Mantıksız değerler (örn: 9+9) kontrolü
        final odaNum = int.tryParse(oda) ?? 0;
        final salonNum = int.tryParse(salon) ?? 0;
        
        if (odaNum > 6 || salonNum > 5) {
          print('⚠️ Mantıksız oda sayısı: $oda+$salon');
          return '-';
        }
        
        return '$oda+$salon';
      }
      
      // Tek haneli sayı ise +1 ekle (sadece 1-5 arası)
      if (number.length == 1 && RegExp(r'^\d$').hasMatch(number)) {
        final num = int.tryParse(number) ?? 0;
        if (num == 0 || num > 5) {
          return '-';
        }
        return '$number+1';
      }
      
      // Diğer durumlar geçersiz
      print('⚠️ Parse edilemeyen oda sayısı: "$number"');
      return '-';
    }
    
    // Eğer sadece "oda-sayisi" yazıyorsa boş demektir
    if (odaSayisi.toLowerCase() == 'oda-sayisi') {
      return '-';
    }
    
    // Eğer zaten formatlanmışsa (+ içeriyorsa) olduğu gibi döndür
    if (odaSayisi.contains('+')) {
      return odaSayisi;
    }
    
    // Eğer sadece sayı ise "+1" ekle (örn: "2" -> "2+1")
    if (RegExp(r'^\d+$').hasMatch(odaSayisi)) {
      // 0 ise boş göster
      if (odaSayisi == '0') {
        return '-';
      }
      return '$odaSayisi+1';
    }
    
    // Diğer durumlarda olduğu gibi döndür ama debug et
    print('⚠️ Beklenmeyen oda sayısı formatı: "$odaSayisi"');
    return odaSayisi;
  }

  /// Kat bilgisini formatla (örn: "11. Kat", "Giriş Katı Kot 2")
  String _formatKat(String? kat) {
    // Null, boş veya geçersiz değerler için "-" döndür
    if (kat == null || 
        kat.isEmpty || 
        kat == '-' || 
        kat == 'bulundugu-kat' ||
        kat.toLowerCase().contains('undefined') ||
        kat.toLowerCase().contains('null')) {
      return '-';
    }
    
    final katLower = kat.toLowerCase().trim();
    
    // "giris-alti-kot-2" formatını parse et
    if (katLower.contains('giris') || katLower.contains('giriş')) {
      // "giris-alti-kot-2" veya "giriş-altı-kot-2" formatı
      final parts = kat.split('-');
      String kotValue = '';
      
      // Kot değerini bul
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].toLowerCase() == 'kot' && i + 1 < parts.length) {
          kotValue = parts[i + 1];
          break;
        }
      }
      
      if (kotValue.isNotEmpty) {
        return 'Giriş Katı Kot $kotValue';
      }
      return 'Giriş Katı';
    }
    
    // "bulundugu-kat-11" formatını parse et
    if (katLower.contains('bulundugu-kat-')) {
      final number = kat.replaceAll(RegExp(r'bulundugu-kat-', caseSensitive: false), '');
      
      if (number.isEmpty || number == '0') {
        return 'Zemin Kat';
      }
      
      // Sadece sayı ise "11. Kat" formatında döndür
      if (RegExp(r'^\d+$').hasMatch(number)) {
        return '$number. Kat';
      }
      
      return number;
    }
    
    // Eğer sadece "bulundugu-kat" yazıyorsa boş demektir
    if (katLower == 'bulundugu-kat') {
      return '-';
    }
    
    // "kat 11" veya "kat11" formatını parse et
    final katMatch = RegExp(r'kat\s*(\d+)', caseSensitive: false).firstMatch(kat);
    if (katMatch != null) {
      final number = katMatch.group(1)!;
      return '$number. Kat';
    }
    
    // Sadece sayı ise "11. Kat" formatında döndür
    if (RegExp(r'^\d+$').hasMatch(kat)) {
      if (kat == '0') {
        return 'Zemin Kat';
      }
      return '$kat. Kat';
    }
    
    // Özel durumlar
    switch (katLower) {
      case 'zemin':
      case '0':
        return 'Zemin Kat';
      case 'bodrum':
      case '-1':
        return 'Bodrum Kat';
      case 'çatı':
      case 'cati':
        return 'Çatı Katı';
      default:
        // Eğer içinde "kat" kelimesi varsa ve sayı varsa formatla
        final hasKat = katLower.contains('kat');
        final numberMatch = RegExp(r'\d+').firstMatch(kat);
        if (hasKat && numberMatch != null) {
          return '${numberMatch.group(0)}. Kat';
        }
        // Diğer durumlarda olduğu gibi döndür
        return kat;
    }
  }

  /// Loading indicator widget'i (otomatik scroll için)
  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(238, 46, 36, 1)),
                strokeWidth: 3,
              ),
              SizedBox(height: 12),
              Text(
                'Daha fazla ilan yükleniyor...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: 120, height: 16),
                  const SizedBox(height: 8),
                  _skeletonBox(width: 80, height: 12),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _skeletonBox(width: 32, height: 12),
                      const SizedBox(width: 10),
                      _skeletonBox(width: 32, height: 12),
                      const SizedBox(width: 10),
                      _skeletonBox(width: 32, height: 12),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _skeletonBox(width: 60, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({double width = 60, double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// S3'ten resim göstermek için widget builder
  Widget _buildListingImage(String? s3Id) {
    // S3 ID'si yoksa veya geçersizse "Resim Yok" göster
    if (!ImageUtils.isValidS3Id(s3Id)) {
      print('⚠️ Resim ID yok veya geçersiz: $s3Id');
      return ImageUtils.getNoImageWidget(size: 35);
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);
    print('🖼️ Resim yükleniyor: ${s3Id?.substring(0, 8)}...');

    return Image.network(
      imageUrl,
      width: 110,
      height: 130,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Resim başarıyla yüklendi
          return child;
        }
        // Resim yükleniyor
        return ImageUtils.getLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Resim yükleme hatası: ${s3Id?.substring(0, 8)}... - $error');
        // Resim yüklenemedi
        return ImageUtils.getFailedImageWidget(size: 35);
      },
    );
  }
}

/// Filtre bottom sheet - il/ilçe/mahalle refProvinces & refProvince/:code API ile
class _TumIlanFilterSheet extends StatefulWidget {
  final String initialKategori;
  final String initialTip;
  final String? initialIl;
  final String? initialIlce;
  final String? initialMahalle;
  final int? initialMinFiyat;
  final int? initialMaxFiyat;
  final int? initialMinM2;
  final int? initialMaxM2;
  final Color filterRed;
  final void Function(String kategori, String tip, String? il, String? ilce, String? mahalle, int? minFiyat, int? maxFiyat, int? minM2, int? maxM2) onApply;
  final VoidCallback onClear;

  const _TumIlanFilterSheet({
    required this.initialKategori,
    required this.initialTip,
    this.initialIl,
    this.initialIlce,
    this.initialMahalle,
    this.initialMinFiyat,
    this.initialMaxFiyat,
    this.initialMinM2,
    this.initialMaxM2,
    required this.filterRed,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_TumIlanFilterSheet> createState() => _TumIlanFilterSheetState();
}

class _TumIlanFilterSheetState extends State<_TumIlanFilterSheet> {
  static const Color _filterRedLight = Color.fromRGBO(238, 46, 36, 0.08);
  static const Color _filterRedBorder = Color.fromRGBO(238, 46, 36, 0.3);

  String _kategori = '';
  String _tip = '';
  ProvinceModel? _selectedProvince;
  DistrictModel? _selectedDistrict;
  QuarterModel? _selectedQuarter;
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<QuarterModel> _quarters = [];
  bool _loadingProvinces = false;
  bool _loadingDistricts = false;
  final TextEditingController _minFiyatController = TextEditingController();
  final TextEditingController _maxFiyatController = TextEditingController();
  final TextEditingController _minM2Controller = TextEditingController();
  final TextEditingController _maxM2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kategori = widget.initialKategori;
    _tip = widget.initialTip;
    if (widget.initialMinFiyat != null) _minFiyatController.text = widget.initialMinFiyat.toString();
    if (widget.initialMaxFiyat != null) _maxFiyatController.text = widget.initialMaxFiyat.toString();
    if (widget.initialMinM2 != null) _minM2Controller.text = widget.initialMinM2.toString();
    if (widget.initialMaxM2 != null) _maxM2Controller.text = widget.initialMaxM2.toString();
    _loadProvinces();
  }

  @override
  void dispose() {
    _minFiyatController.dispose();
    _maxFiyatController.dispose();
    _minM2Controller.dispose();
    _maxM2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final repository = ProvincesRepository();
      final result = await repository.getAllProvinces();
      result.fold(
        (failure) => setState(() => _loadingProvinces = false),
        (provincesModel) {
          setState(() {
            _provinces = provincesModel.provinces;
            _loadingProvinces = false;
          });
          _loadInitialSelections();
        },
      );
    } catch (_) {
      setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadInitialSelections() async {
    if (widget.initialIl == null || widget.initialIl!.isEmpty || _provinces.isEmpty) return;
    ProvinceModel? province;
    for (final p in _provinces) {
      if (_norm(p.name) == _norm(widget.initialIl!)) { province = p; break; }
    }
    if (province == null) return;
    setState(() => _selectedProvince = province);
    await _loadDistricts(province.code);
    if (widget.initialIlce == null || widget.initialIlce!.isEmpty || _districts.isEmpty) return;
    DistrictModel? district;
    for (final d in _districts) {
      if (_norm(d.name) == _norm(widget.initialIlce!)) { district = d; break; }
    }
    if (district == null) return;
    final selectedDistrict = district;
    setState(() {
      _selectedDistrict = selectedDistrict;
      _quarters = selectedDistrict.quarters;
    });
    if (widget.initialMahalle == null || widget.initialMahalle!.isEmpty || _quarters.isEmpty) return;
    QuarterModel? quarter;
    for (final q in _quarters) {
      if (_norm(q.name) == _norm(widget.initialMahalle!)) { quarter = q; break; }
    }
    if (quarter != null) setState(() => _selectedQuarter = quarter);
  }

  String _norm(String s) => s.trim().toLowerCase();

  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _quarters = [];
      _selectedDistrict = null;
      _selectedQuarter = null;
    });
    try {
      final repository = ProvincesDetailRepository();
      final result = await repository.getProvinceDetails(provinceCode);
      result.fold(
        (failure) => setState(() => _loadingDistricts = false),
        (detailModel) => setState(() {
          _districts = detailModel.districts;
          _loadingDistricts = false;
        }),
      );
    } catch (_) {
      setState(() => _loadingDistricts = false);
    }
  }

  void _onProvinceChanged(ProvinceModel? v) {
    setState(() {
      _selectedProvince = v;
      _selectedDistrict = null;
      _selectedQuarter = null;
      _districts = [];
      _quarters = [];
    });
    if (v != null) _loadDistricts(v.code);
  }

  void _onDistrictChanged(DistrictModel? v) {
    setState(() {
      _selectedDistrict = v;
      _selectedQuarter = null;
      _quarters = v?.quarters ?? [];
    });
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? widget.filterRed : _filterRedLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? widget.filterRed : _filterRedBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check, size: 18, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? Colors.white : widget.filterRed)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(displayText(e)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emlak Tipi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(label: 'Konut', isSelected: _kategori == 'konut', onTap: () => setState(() => _kategori = _kategori == 'konut' ? '' : 'konut')),
                        _buildFilterChip(label: 'Ticari', isSelected: _kategori == 'is-yeri', onTap: () => setState(() => _kategori = _kategori == 'is-yeri' ? '' : 'is-yeri')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('İlan Tipi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(label: 'Kiralık', isSelected: _tip == 'kiralik', onTap: () => setState(() => _tip = _tip == 'kiralik' ? '' : 'kiralik')),
                        _buildFilterChip(label: 'Satılık', isSelected: _tip == 'satilik', onTap: () => setState(() => _tip = _tip == 'satilik' ? '' : 'satilik')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('İl Seçimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _loadingProvinces
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        : _buildDropdown<ProvinceModel>(hint: 'İl Seçiniz', value: _selectedProvince, items: _provinces, displayText: (p) => p.name, onChanged: _onProvinceChanged),
                    const SizedBox(height: 12),
                    const Text('İlçe Seçimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _loadingDistricts
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        : _buildDropdown<DistrictModel>(hint: 'İlçe Seçiniz', value: _selectedDistrict, items: _districts, displayText: (d) => d.name, onChanged: _onDistrictChanged),
                    const SizedBox(height: 12),
                    const Text('Mahalle Seçimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 8),
                    _buildDropdown<QuarterModel>(hint: 'Mahalle Seçiniz', value: _selectedQuarter, items: _quarters, displayText: (q) => q.name, onChanged: (v) => setState(() => _selectedQuarter = v)),
                    const SizedBox(height: 20),
                    const Text('Fiyat Aralığı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minFiyatController,
                            decoration: InputDecoration(hintText: 'Min', suffixText: '₺', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.filterRed, width: 1.5))),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _maxFiyatController,
                            decoration: InputDecoration(hintText: 'Max', suffixText: '₺', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.filterRed, width: 1.5))),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('m2 Aralığı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minM2Controller,
                            decoration: InputDecoration(hintText: 'Min', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.filterRed, width: 1.5))),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _maxM2Controller,
                            decoration: InputDecoration(hintText: 'Max', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.filterRed, width: 1.5))),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final minFiyat = int.tryParse(_minFiyatController.text.trim());
                          final maxFiyat = int.tryParse(_maxFiyatController.text.trim());
                          final minM2 = int.tryParse(_minM2Controller.text.trim());
                          final maxM2 = int.tryParse(_maxM2Controller.text.trim());
                          widget.onApply(
                            _kategori,
                            _tip,
                            _selectedProvince?.name,
                            _selectedDistrict?.name,
                            _selectedQuarter?.name,
                            minFiyat,
                            maxFiyat,
                            minM2,
                            maxM2,
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: widget.filterRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                        child: const Text('Uygula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _kategori = '';
                            _tip = '';
                            _selectedProvince = null;
                            _selectedDistrict = null;
                            _selectedQuarter = null;
                            _districts = [];
                            _quarters = [];
                            _minFiyatController.clear();
                            _maxFiyatController.clear();
                            _minM2Controller.clear();
                            _maxM2Controller.clear();
                          });
                          widget.onClear();
                        },
                        child: Text('Filtreyi Temizle', style: TextStyle(color: widget.filterRed, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

