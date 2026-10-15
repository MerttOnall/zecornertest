// Bu sayfa '/zeilan' route'u ile açılır.
// Admin paneldeki 'Ze-İlanlar' menüsüne tıklanınca bu ekran açılır.
// Route tanımı: AppRouter.routes içinde '/zeilan': (context) => const ZeIlanScreen()
//
// Eğer başka bir yerde route eklemesi gerekiyorsa, AppRouter ve main.dart dosyalarını kontrol edin.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/screens/zeilan/ilan_detail_screen.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/infrastructure/listing/listing_api_repository.dart';
import 'package:zecorner/models/listing/listing_api_model.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:dio/dio.dart';
import 'dart:async';

/// Web geniş ekran + sağ filtre paneli eşiği
const double _kZeIlanWideBreakpoint = 900;

/// Panel, segment ve vurgular (tasarım: ~#EE3124)
const Color _kZeIlanPrimaryRed = Color(0xFFEE3124);

/// Segment satırı zemin — çok açık pembe
const Color _kZeIlanSegmentTrack = Color(0xFFFFF2F2);

typedef ZeIlanFilterApplyCallback = void Function(
  String? type,
  String? status,
  String? countryCode,
  int? provinceCode,
  int? districtCode,
  int? quarterCode,
  String? provinceName,
  String? districtName,
  String? quarterName,
  int? minPrice,
  int? maxPrice,
  int? minArea,
  int? maxArea,
);

class ZeIlanScreen extends StatefulWidget {
  const ZeIlanScreen({super.key});

  @override
  State<ZeIlanScreen> createState() => _ZeIlanScreenState();
}

class _ZeIlanScreenState extends State<ZeIlanScreen> {
  // API related variables
  late final ListingApiRepository _listingRepository;
  List<ListingApiModel> _listings = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;

  // Search and filter variables
  String _searchQuery = '';
  /// Varsayılan: tarih en yeni (API + istemci sıralaması)
  String _selectedSort = "Tarih - En Yeni";
  final List<String> _sortOptions = [
    "Tarih - En Yeni",
    "Tarih - En Eski",
    "Fiyat - Artan",
    "Fiyat - Azalan",
  ];
  OverlayEntry? _sortOverlayEntry;
  final GlobalKey _sortButtonKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  // Filter state variables
  String? _filterType; // Konut, İş Yeri, Arsa
  String? _filterStatus; // Kiralık, Satılık
  /// null = Tümü, TR / CT = ülke filtresi
  String? _filterCountryCode;
  int? _filterProvinceCode;
  int? _filterDistrictCode;
  int? _filterQuarterCode;
  int? _filterMinPrice;
  int? _filterMaxPrice;
  int? _filterMinArea;
  int? _filterMaxArea;
  String? _filterProvinceName;
  String? _filterDistrictName;
  String? _filterQuarterName;
  /// Masaüstü yan panelin parent ile senkronu (temizle / dışarıdan güncelleme)
  int _filterUiEpoch = 0;
  int _loadRequestId = 0;

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterStatus != null ||
      _filterCountryCode != null ||
      _filterProvinceCode != null ||
      _filterDistrictCode != null ||
      _filterQuarterCode != null ||
      _filterMinPrice != null ||
      _filterMaxPrice != null ||
      _filterMinArea != null ||
      _filterMaxArea != null ||
      _searchQuery.trim().isNotEmpty;

  /// API + istemci süzmesi: filtre her zaman listede doğru kalsın
  List<ListingApiModel> get _visibleListings {
    var list = List<ListingApiModel>.from(_listings);
    final q = _searchQuery.trim().toLowerCase();

    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q) ||
            e.contactTitle.toLowerCase().contains(q) ||
            e.connectedContactTitle.toLowerCase().contains(q) ||
            e.listingNo.toString().contains(q) ||
            e.displayType.toLowerCase().contains(q);
      }).toList();
    }

    final apiType = _apiListingType(_filterStatus);
    if (apiType != null) {
      list = list
          .where((e) => e.type.toLowerCase() == apiType.toLowerCase())
          .toList();
    }

    if (_filterType != null && _filterType!.isNotEmpty) {
      list = list
          .where((e) => e.displayRealEstateCategory == _filterType)
          .toList();
    }

    if (_filterProvinceCode != null) {
      list = list
          .where((e) => e.provinceCode == _filterProvinceCode)
          .toList();
    } else if ((_filterProvinceName ?? '').trim().isNotEmpty) {
      final name = _filterProvinceName!.trim().toLowerCase();
      list = list
          .where((e) => e.provinceName.toLowerCase() == name)
          .toList();
    }

    if (_filterDistrictCode != null) {
      list = list
          .where((e) => e.districtCode == _filterDistrictCode)
          .toList();
    } else if ((_filterDistrictName ?? '').trim().isNotEmpty) {
      final name = _filterDistrictName!.trim().toLowerCase();
      list = list
          .where((e) => e.districtName.toLowerCase() == name)
          .toList();
    }

    if (_filterQuarterCode != null) {
      list =
          list.where((e) => e.quarterCode == _filterQuarterCode).toList();
    } else if ((_filterQuarterName ?? '').trim().isNotEmpty) {
      final name = _filterQuarterName!.trim().toLowerCase();
      list = list
          .where((e) => e.quarterName.toLowerCase() == name)
          .toList();
    }

    if (_filterMinPrice != null) {
      list = list.where((e) => e.price >= _filterMinPrice!).toList();
    }
    if (_filterMaxPrice != null) {
      list = list.where((e) => e.price <= _filterMaxPrice!).toList();
    }

    if (_filterMinArea != null || _filterMaxArea != null) {
      list = list.where((e) {
        final area = e.areaSqm;
        if (area == null) return false;
        if (_filterMinArea != null && area < _filterMinArea!) return false;
        if (_filterMaxArea != null && area > _filterMaxArea!) return false;
        return true;
      }).toList();
    }

    return list;
  }

  /// UI (Kiralık/Satılık) → API `listing_type`
  static String? _apiListingType(String? statusUi) {
    if (statusUi == null || statusUi.isEmpty) return null;
    switch (statusUi) {
      case 'Kiralık':
        return 'kiralik';
      case 'Satılık':
        return 'satilik';
      default:
        return null;
    }
  }

  /// UI (Konut/İş Yeri/Arsa) → API `real_estate_type`
  static String? _apiRealEstateType(String? typeUi) {
    if (typeUi == null || typeUi.isEmpty) return null;
    switch (typeUi) {
      case 'Konut':
        return 'konut';
      case 'İş Yeri':
        return 'is-yeri';
      case 'Arsa':
        return 'arsa';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _listingRepository = ListingApiRepository(dio: Dio());
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    _removeSortDropdown();
    super.dispose();
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    } else if (!_hasMoreData) {
      return;
    } else if (_isLoading) {
      return;
    }

    final requestId = ++_loadRequestId;
    final page = _currentPage;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _listings = [];
      }
    });

    final result = await _listingRepository.getListings(
      page: page,
      limit: 20,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      listingType: _apiListingType(_filterStatus),
      realEstateType: _apiRealEstateType(_filterType),
      countryCode: _filterCountryCode,
      provinceCode: _filterProvinceCode,
      districtCode: _filterDistrictCode,
      quarterCode: _filterQuarterCode,
      provinceName: _filterProvinceName,
      districtName: _filterDistrictName,
      quarterName: _filterQuarterName,
      minPrice: _filterMinPrice,
      maxPrice: _filterMaxPrice,
      minArea: _filterMinArea,
      maxArea: _filterMaxArea,
      sortBy: _getSortBy(),
      sortOrder: _getSortOrder(),
    );

    if (!mounted || requestId != _loadRequestId) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(failure);
        });
      },
      (response) {
        setState(() {
          _isLoading = false;
          if (refresh || page == 1) {
            _listings = List<ListingApiModel>.from(response.listings);
          } else {
            final existing = _listings.map((e) => e.id).toSet();
            _listings = [
              ..._listings,
              ...response.listings.where((e) => !existing.contains(e.id)),
            ];
          }
          _applyClientSideSort(_listings);
          _totalPages = response.totalPages;
          _hasMoreData = page < _totalPages;
          _currentPage = page + 1;
        });
      },
    );
  }

  void _applyZeIlanFilters({
    required String? type,
    required String? status,
    required String? countryCode,
    required int? provinceCode,
    required int? districtCode,
    required int? quarterCode,
    required String? provinceName,
    required String? districtName,
    required String? quarterName,
    required int? minPrice,
    required int? maxPrice,
    required int? minArea,
    required int? maxArea,
  }) {
    setState(() {
      _filterType = type;
      _filterStatus = status;
      _filterCountryCode = countryCode;
      _filterProvinceCode = provinceCode;
      _filterDistrictCode = districtCode;
      _filterQuarterCode = quarterCode;
      _filterProvinceName = provinceName;
      _filterDistrictName = districtName;
      _filterQuarterName = quarterName;
      _filterMinPrice = minPrice;
      _filterMaxPrice = maxPrice;
      _filterMinArea = minArea;
      _filterMaxArea = maxArea;
      _filterUiEpoch++;
    });
    _loadListings(refresh: true);
  }

  void _clearZeIlanFilters() {
    setState(() {
      _filterType = null;
      _filterStatus = null;
      _filterCountryCode = null;
      _filterProvinceCode = null;
      _filterDistrictCode = null;
      _filterQuarterCode = null;
      _filterProvinceName = null;
      _filterDistrictName = null;
      _filterQuarterName = null;
      _filterMinPrice = null;
      _filterMaxPrice = null;
      _filterMinArea = null;
      _filterMaxArea = null;
      _filterUiEpoch++;
    });
    _loadListings(refresh: true);
  }

  /// API sort_by bazen yok sayılabilir; seçilen sıra her zaman listede uygulanır.
  void _applyClientSideSort(List<ListingApiModel> list) {
    if (list.isEmpty) return;
    switch (_selectedSort) {
      case 'Tarih - En Yeni':
      case 'En son eklenenler':
        list.sort(_compareNewestFirst);
        break;
      case 'Tarih - En Eski':
        list.sort((a, b) => _compareNewestFirst(b, a));
        break;
      case 'Fiyat - Artan':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat - Azalan':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        list.sort(_compareNewestFirst);
        break;
    }
  }

  /// Önce eklenme zamanı (created → updated), yoksa listing_no (genelde büyük = daha yeni).
  static int _listingRecencyMillis(ListingApiModel e) {
    var t = _parseInstantMillis(e.createdAt);
    if (t != 0) return t;
    final u = e.updatedAt;
    if (u != null && u.trim().isNotEmpty) {
      t = _parseInstantMillis(u);
      if (t != 0) return t;
    }
    return 0;
  }

  static int _parseInstantMillis(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 0;
    final asInt = int.tryParse(s);
    if (asInt != null) {
      if (asInt > 2000000000000) return asInt;
      if (asInt > 2000000000) return asInt * 1000;
    }
    var d = DateTime.tryParse(s);
    d ??= DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (d != null) return d.millisecondsSinceEpoch;
    final m = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})').firstMatch(s);
    if (m != null) {
      final day = int.tryParse(m.group(1)!);
      final month = int.tryParse(m.group(2)!);
      final year = int.tryParse(m.group(3)!);
      if (day != null && month != null && year != null) {
        d = DateTime(year, month, day);
        return d.millisecondsSinceEpoch;
      }
    }
    return 0;
  }

  static int _compareNewestFirst(ListingApiModel a, ListingApiModel b) {
    final ta = _listingRecencyMillis(a);
    final tb = _listingRecencyMillis(b);
    if (ta != tb) return tb.compareTo(ta);
    final na = a.listingNo;
    final nb = b.listingNo;
    if (na != nb) return nb.compareTo(na);
    return b.id.compareTo(a.id);
  }

  String? _getSortBy() {
    switch (_selectedSort) {
      case "Tarih - En Yeni":
      case "En son eklenenler":
        return "created_at";
      case "Tarih - En Eski":
        return "created_at";
      case "Fiyat - Artan":
        return "price";
      case "Fiyat - Azalan":
        return "price";
      default:
        return "created_at";
    }
  }

  String? _getSortOrder() {
    switch (_selectedSort) {
      case "Tarih - En Yeni":
      case "En son eklenenler":
        return "desc";
      case "Tarih - En Eski":
        return "asc";
      case "Fiyat - Artan":
        return "asc";
      case "Fiyat - Azalan":
        return "desc";
      default:
        return "desc";
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // 300ms debounce
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _loadListings(refresh: true);
    });
  }

  void _onSortChanged(String value) {
    setState(() {
      _selectedSort = value;
    });
    _loadListings(refresh: true);
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (failure is AuthFailure) {
      return failure.message;
    } else {
      return 'Beklenmeyen bir hata oluştu.';
    }
  }

  void _showSortDropdown() {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _kZeIlanWideBreakpoint) {
      _showSortOverlay();
    } else {
      _showSortBottomSheet();
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _ZeIlanSortBottomSheet(
            options: _sortOptions,
            selectedSort: _selectedSort,
            onSelect: (option) {
              Navigator.of(sheetContext).pop();
              _onSortChanged(option);
            },
          ),
        );
      },
    );
  }

  void _showSortOverlay() {
    _removeSortDropdown();
    final renderBox =
        _sortButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      _showSortBottomSheet();
      return;
    }
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final mq = MediaQuery.of(context);
    final panelW = 280.0;
    var left = offset.dx;
    left = left.clamp(8.0, mq.size.width - panelW - 8);

    _sortOverlayEntry = OverlayEntry(
      builder: (ctx) {
        return _ZeIlanSortOverlay(
          left: left,
          top: offset.dy + size.height + 6,
          width: panelW,
          options: _sortOptions,
          selectedSort: _selectedSort,
          onDismiss: _removeSortDropdown,
          onSelect: (option) {
            _onSortChanged(option);
            _removeSortDropdown();
          },
        );
      },
    );
    Overlay.of(context).insert(_sortOverlayEntry!);
  }

  void _removeSortDropdown() {
    _sortOverlayEntry?.remove();
    _sortOverlayEntry = null;
  }

  void _openMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ZeIlanListingFilters(
          filterUiEpoch: _filterUiEpoch,
          showSheetChrome: true,
          initialType: _filterType ?? 'Konut',
          initialStatus: _filterStatus ?? 'Kiralık',
          initialCountryCode: _filterCountryCode,
          initialProvinceCode: _filterProvinceCode,
          initialDistrictCode: _filterDistrictCode,
          initialQuarterCode: _filterQuarterCode,
          initialMinPrice: _filterMinPrice,
          initialMaxPrice: _filterMaxPrice,
          initialMinArea: _filterMinArea,
          initialMaxArea: _filterMaxArea,
          onApplyFilters: (type, status, countryCode, provinceCode, districtCode,
              quarterCode, provinceName, districtName, quarterName, minPrice,
              maxPrice, minArea, maxArea) {
            _applyZeIlanFilters(
              type: type,
              status: status,
              countryCode: countryCode,
              provinceCode: provinceCode,
              districtCode: districtCode,
              quarterCode: quarterCode,
              provinceName: provinceName,
              districtName: districtName,
              quarterName: quarterName,
              minPrice: minPrice,
              maxPrice: maxPrice,
              minArea: minArea,
              maxArea: maxArea,
            );
          },
          onClearFilters: _clearZeIlanFilters,
        );
      },
    );
  }

  /// Web: kırmızı şerit — solda sıralama, sağda arama (görseldeki gibi)
  Widget _buildWebFilterToolbar() {
    return Material(
      color: _kZeIlanPrimaryRed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                key: _sortButtonKey,
                onTap: _showSortDropdown,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedSort,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_up_rounded,
                          color: _kZeIlanPrimaryRed, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'İlan başlığına göre arama..',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Icon(Icons.search, color: _kZeIlanPrimaryRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchAndSort() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'İlan başlığına göre ara...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          ),
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          key: _sortButtonKey,
          onTap: _showSortDropdown,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedSort,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15)),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kZeIlanPrimaryRed),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Role sistemine göre sidebar seçimi
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Ze-İlanlar');
        },
      ),
      appBar: AppBar(
        backgroundColor: _kZeIlanPrimaryRed,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ze-İlanlar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width < _kZeIlanWideBreakpoint)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _openMobileFilterSheet,
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kZeIlanPrimaryRed,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _kZeIlanWideBreakpoint;
          if (wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWebFilterToolbar(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: Colors.grey[100]!,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildListingsList(),
                            ],
                          ),
                        ),
                      ),
                      Material(
                        elevation: 3,
                        child: SizedBox(
                          width: 320,
                          child: ColoredBox(
                            color: Colors.white,
                            child: SingleChildScrollView(
                              child: ZeIlanListingFilters(
                                filterUiEpoch: _filterUiEpoch,
                                showSheetChrome: false,
                                initialType: _filterType ?? 'Konut',
                                initialStatus: _filterStatus ?? 'Kiralık',
                                initialCountryCode: _filterCountryCode,
                                initialProvinceCode: _filterProvinceCode,
                                initialDistrictCode: _filterDistrictCode,
                                initialQuarterCode: _filterQuarterCode,
                                initialMinPrice: _filterMinPrice,
                                initialMaxPrice: _filterMaxPrice,
                                initialMinArea: _filterMinArea,
                                initialMaxArea: _filterMaxArea,
                                onApplyFilters: (type, status, countryCode,
                                    provinceCode, districtCode, quarterCode,
                                    provinceName, districtName, quarterName,
                                    minPrice, maxPrice, minArea, maxArea) {
                                  _applyZeIlanFilters(
                                    type: type,
                                    status: status,
                                    countryCode: countryCode,
                                    provinceCode: provinceCode,
                                    districtCode: districtCode,
                                    quarterCode: quarterCode,
                                    provinceName: provinceName,
                                    districtName: districtName,
                                    quarterName: quarterName,
                                    minPrice: minPrice,
                                    maxPrice: maxPrice,
                                    minArea: minArea,
                                    maxArea: maxArea,
                                  );
                                },
                                onClearFilters: _clearZeIlanFilters,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildMobileSearchAndSort(),
              const SizedBox(height: 16),
              _buildListingsList(),
            ],
          );
        },
      ),
      // Role sistemine göre navbar seçimi
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final userRoleCodes = snapshot.data ?? [];
                print('ZeIlan Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else {
                  return const FrancahiseNavbar(currentIndex: 0);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildListingsList() {
    final visible = _visibleListings;

    if (_isLoading && _listings.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.red[700],
              ),
              SizedBox(height: 16),
              Text(
                'İlanlar yükleniyor...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _listings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadListings(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (visible.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Text(
                'İlan bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(height: 8),
                Text(
                  'Filtreyi değiştirip tekrar deneyin',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _clearZeIlanFilters,
                  child: const Text(
                    'Filtreyi Temizle',
                    style: TextStyle(
                      color: _kZeIlanPrimaryRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(
          visible.length,
          (index) => ListingCard(listing: visible[index]),
        ),
        if (_isLoading && _listings.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.red[700],
              ),
            ),
          ),
        if (_hasMoreData && !_isLoading)
          Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton(
                onPressed: () => _loadListings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: Text('Daha Fazla Yükle'),
              ),
            ),
          ),
      ],
    );
  }

}

class ListingCard extends StatelessWidget {
  final ListingApiModel listing;
  const ListingCard({required this.listing});

  /// S3'ten resim göstermek için widget builder
  Widget _buildListingImage(String? s3Id) {
    // S3 ID'si yoksa veya geçersizse "Resim Yok" göster
    if (!ImageUtils.isValidS3Id(s3Id)) {
      return Container(
        height: 140,
        color: Colors.grey[300],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 48,
        ),
      );
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 140,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Resim başarıyla yüklendi
          return child;
        }
        // Resim yükleniyor
        return Container(
          height: 140,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.red[700],
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Resim yüklenemedi
        return Container(
          height: 140,
          color: Colors.grey[300],
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 48,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = listing.id.isNotEmpty
        ? listing.id
        : (listing.slug.isNotEmpty
            ? listing.slug
            : listing.listingNo.toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: propertyId.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IlanDetailScreen(
                        propertyId: propertyId,
                      ),
                    ),
                  );
                },
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: _buildListingImage(listing.coverPicture),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    listing.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    listing.location,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.displayType,
                          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Text(listing.size, style: TextStyle(fontSize: 12)),
                      SizedBox(width: 8),
                      Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Text(listing.rooms, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    listing.fullPrice,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red[700]),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.contactTitle,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobil "Sırala" bottom sheet — arama ile süzme, seçimde üst metin + kırmızı onay
class _ZeIlanSortBottomSheet extends StatefulWidget {
  final List<String> options;
  final String selectedSort;
  final ValueChanged<String> onSelect;

  const _ZeIlanSortBottomSheet({
    required this.options,
    required this.selectedSort,
    required this.onSelect,
  });

  @override
  State<_ZeIlanSortBottomSheet> createState() => _ZeIlanSortBottomSheetState();
}

class _ZeIlanSortBottomSheetState extends State<_ZeIlanSortBottomSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _query.isEmpty ||
            o.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final sheetH = MediaQuery.of(context).size.height * 0.42;
    return Container(
      height: sheetH,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sırala',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.grey[400], size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final selected = widget.selectedSort == option;
                      return InkWell(
                        onTap: () => widget.onSelect(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? _kZeIlanPrimaryRed
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check,
                                    color: _kZeIlanPrimaryRed, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Web sıralama menüsü — arama alanı + liste (üst kırmızı şeritte kullanılır)
class _ZeIlanSortOverlay extends StatefulWidget {
  final double left;
  final double top;
  final double width;
  final List<String> options;
  final String selectedSort;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSelect;

  const _ZeIlanSortOverlay({
    required this.left,
    required this.top,
    required this.width,
    required this.options,
    required this.selectedSort,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  State<_ZeIlanSortOverlay> createState() => _ZeIlanSortOverlayState();
}

class _ZeIlanSortOverlayState extends State<_ZeIlanSortOverlay> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _search.isEmpty ||
            o.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: Container(color: Colors.black26),
          ),
        ),
        Positioned(
          left: widget.left,
          top: widget.top,
          width: widget.width,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Ara...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey[400], size: 18),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 260,
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final selected = widget.selectedSort == option;
                              return InkWell(
                                onTap: () => widget.onSelect(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: selected
                                                ? _kZeIlanPrimaryRed
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        Icon(Icons.check,
                                            color: _kZeIlanPrimaryRed,
                                            size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hem mobil bottom sheet hem web sağ panel — aynı alanlar ve il/ilçe/mahalle akışı
/// (refProvinces + ilçeler API; mahalleler ilçe nesnesinden — add_person_screen ile aynı)
class ZeIlanListingFilters extends StatefulWidget {
  final int filterUiEpoch;
  final bool showSheetChrome;
  final String initialType;
  final String initialStatus;
  final String? initialCountryCode;
  final int? initialProvinceCode;
  final int? initialDistrictCode;
  final int? initialQuarterCode;
  final int? initialMinPrice;
  final int? initialMaxPrice;
  final int? initialMinArea;
  final int? initialMaxArea;
  final ZeIlanFilterApplyCallback onApplyFilters;
  final VoidCallback onClearFilters;

  const ZeIlanListingFilters({
    super.key,
    required this.filterUiEpoch,
    required this.showSheetChrome,
    required this.initialType,
    required this.initialStatus,
    this.initialCountryCode,
    this.initialProvinceCode,
    this.initialDistrictCode,
    this.initialQuarterCode,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinArea,
    this.initialMaxArea,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<ZeIlanListingFilters> createState() => _ZeIlanListingFiltersState();
}

class _ZeIlanListingFiltersState extends State<ZeIlanListingFilters> {
  late String type;
  late String status;

  /// null = Tümü
  String? _countryCode;

  /// add_person_screen ile aynı: ContactApiRepository (refProvinces + refProvince/{kod})
  late final ContactApiRepository _contactApiRepository;

  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<QuarterModel> _quarters = [];
  bool _loadingProvinces = false;
  bool _loadingDistricts = false;

  ProvinceModel? _selectedProvince;
  DistrictModel? _selectedDistrict;
  QuarterModel? _selectedQuarter;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minAreaController = TextEditingController();
  final TextEditingController _maxAreaController = TextEditingController();

  static const List<({String code, String name})> _countryOptions = [
    (code: 'ALL', name: 'Tümü'),
    (code: 'TR', name: 'Türkiye'),
    (code: 'CT', name: 'Kıbrıs'),
  ];

  String get _countryDropdownValue {
    final code = _countryCode;
    if (code == null || code.isEmpty) return 'ALL';
    return code;
  }

  /// İl listesi için kullanılacak country_code (Tümü → TR varsayılan)
  String get _provincesCountryCode =>
      (_countryCode == null || _countryCode!.isEmpty) ? 'TR' : _countryCode!;

  String? get _countryCodeForApi =>
      (_countryCode == null || _countryCode!.isEmpty) ? null : _countryCode;

  static BoxDecoration _floatingFieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  InputDecoration _rangeFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      suffixText: '₺',
      suffixStyle: TextStyle(
        color: Colors.grey[800],
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kZeIlanPrimaryRed, width: 1.5),
      ),
    );
  }

  InputDecoration _m2FieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      suffixText: 'm²',
      suffixStyle: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kZeIlanPrimaryRed, width: 1.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _contactApiRepository = ContactApiRepository();
    _assignFromWidget();
    _loadProvinces();
  }

  @override
  void didUpdateWidget(ZeIlanListingFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterUiEpoch != oldWidget.filterUiEpoch) {
      _assignFromWidget();
      if (_provinces.isEmpty) {
        _loadProvinces();
      } else {
        _restoreLocationTree();
      }
    }
  }

  void _assignFromWidget() {
    type = widget.initialType;
    status = widget.initialStatus;
    _countryCode = widget.initialCountryCode;
    // Mobil (bottom sheet): görselde sadece Konut | İş Yeri — Arsa seçili geldiyse Konut'a düşür
    if (widget.showSheetChrome && type == 'Arsa') {
      type = 'Konut';
    }
    _minPriceController.text = widget.initialMinPrice?.toString() ?? '';
    _maxPriceController.text = widget.initialMaxPrice?.toString() ?? '';
    _minAreaController.text = widget.initialMinArea?.toString() ?? '';
    _maxAreaController.text = widget.initialMaxArea?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final result = await _contactApiRepository.getProvinces(
        countryCode: _provincesCountryCode,
      );
      result.fold(
        (failure) {
          print('❌ İller yüklenemedi: ${failure.toString()}');
          setState(() {
            _provinces = [];
            _loadingProvinces = false;
          });
        },
        (provincesModel) {
          setState(() {
            _provinces = provincesModel.provinces;
            _loadingProvinces = false;
          });
          _restoreLocationTree();
        },
      );
    } catch (e) {
      print('❌ Hata: $e');
      setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _onCountryChanged(String? selected) async {
    final code = (selected == null || selected == 'ALL') ? null : selected;
    setState(() {
      _countryCode = code;
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedQuarter = null;
      _provinces = [];
      _districts = [];
      _quarters = [];
    });
    await _loadProvinces();
  }

  Future<void> _restoreLocationTree() async {
    final pCode = widget.initialProvinceCode;
    if (pCode == null || _provinces.isEmpty) {
      setState(() {
        _selectedProvince = null;
        _selectedDistrict = null;
        _selectedQuarter = null;
        _districts = [];
        _quarters = [];
      });
      return;
    }
    try {
      final province = _provinces.firstWhere((p) => p.code == pCode);
      setState(() => _selectedProvince = province);
      await _loadDistricts(province.code, restoreDistrictCode: widget.initialDistrictCode, restoreQuarterCode: widget.initialQuarterCode);
    } catch (_) {
      setState(() {
        _selectedProvince = null;
        _selectedDistrict = null;
        _selectedQuarter = null;
        _districts = [];
        _quarters = [];
      });
    }
  }

  Future<void> _loadDistricts(
    int provinceCode, {
    int? restoreDistrictCode,
    int? restoreQuarterCode,
  }) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _quarters = [];
      _selectedDistrict = null;
      _selectedQuarter = null;
    });
    try {
      final result = await _contactApiRepository.getDistrictsByProvince(
        provinceCode,
        countryCode: _provincesCountryCode,
      );
      result.fold(
        (failure) {
          print('❌ İlçeler yüklenemedi: ${failure.toString()}');
          setState(() => _loadingDistricts = false);
        },
        (detailModel) {
          setState(() {
            _districts = detailModel.districts;
            _loadingDistricts = false;
          });
          if (restoreDistrictCode != null && _districts.isNotEmpty) {
            try {
              final district =
                  _districts.firstWhere((d) => d.code == restoreDistrictCode);
              setState(() {
                _selectedDistrict = district;
                _quarters = district.quarters;
              });
              if (restoreQuarterCode != null && _quarters.isNotEmpty) {
                try {
                  final quarter =
                      _quarters.firstWhere((q) => q.code == restoreQuarterCode);
                  setState(() => _selectedQuarter = quarter);
                } catch (_) {}
              }
            } catch (_) {}
          }
        },
      );
    } catch (e) {
      print('❌ Hata: $e');
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
    if (v != null) {
      _loadDistricts(v.code);
    }
  }

  void _onDistrictChanged(DistrictModel? v) {
    setState(() {
      _selectedDistrict = v;
      _selectedQuarter = null;
      _quarters = v?.quarters ?? [];
    });
  }

  Widget _buildFormBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSheetChrome) ...[
          _ZeIlanSegmentedPairRow(
            leftLabel: 'Konut',
            rightLabel: 'İş Yeri',
            selectedLeft: type == 'Konut',
            selectedRight: type == 'İş Yeri',
            onLeft: () => setState(() => type = 'Konut'),
            onRight: () => setState(() => type = 'İş Yeri'),
          ),
          const SizedBox(height: 12),
          _ZeIlanSegmentedPairRow(
            leftLabel: 'Kiralık',
            rightLabel: 'Satılık',
            selectedLeft: status == 'Kiralık',
            selectedRight: status == 'Satılık',
            onLeft: () => setState(() => status = 'Kiralık'),
            onRight: () => setState(() => status = 'Satılık'),
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              _FilterTab(
                text: 'Konut',
                selected: type == 'Konut',
                onTap: () => setState(() => type = 'Konut'),
              ),
              _FilterTab(
                text: 'İş Yeri',
                selected: type == 'İş Yeri',
                onTap: () => setState(() => type = 'İş Yeri'),
              ),
              _FilterTab(
                text: 'Arsa',
                selected: type == 'Arsa',
                onTap: () => setState(() => type = 'Arsa'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FilterTab(
                  text: 'Kiralık',
                  selected: status == 'Kiralık',
                  onTap: () => setState(() => status = 'Kiralık'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterTab(
                  text: 'Satılık',
                  selected: status == 'Satılık',
                  onTap: () => setState(() => status = 'Satılık'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Ülke',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        _FilterDropdown<String>(
          hint: 'Ülke Seçiniz',
          value: _countryDropdownValue,
          items: _countryOptions.map((c) => c.code).toList(),
          displayText: (code) {
            for (final c in _countryOptions) {
              if (c.code == code) return c.name;
            }
            return 'Tümü';
          },
          onChanged: _onCountryChanged,
        ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'İl Seçimi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        _loadingProvinces
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _FilterDropdown<ProvinceModel>(
                hint: 'İl Seçiniz',
                value: _selectedProvince,
                items: _provinces,
                displayText: (p) => p.name,
                onChanged: _onProvinceChanged,
              ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'İlçe Seçimi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        _loadingDistricts
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _FilterDropdown<DistrictModel>(
                hint: 'İlçe Seçiniz',
                value: _selectedDistrict,
                items: _districts,
                displayText: (d) => d.name,
                onChanged: _onDistrictChanged,
              ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mahalle Seçimi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        _FilterDropdown<QuarterModel>(
          hint: 'Mahalle Seçiniz',
          value: _selectedQuarter,
          items: _quarters,
          displayText: (q) => q.name,
          onChanged: (v) => setState(() => _selectedQuarter = v),
        ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Fiyat Aralığı',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: _floatingFieldDecoration(),
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: _rangeFieldDecoration('Min'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecoratedBox(
                decoration: _floatingFieldDecoration(),
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: _rangeFieldDecoration('Max'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'm² Aralığı',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: _floatingFieldDecoration(),
                child: TextField(
                  controller: _minAreaController,
                  keyboardType: TextInputType.number,
                  decoration: _m2FieldDecoration('Min'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecoratedBox(
                decoration: _floatingFieldDecoration(),
                child: TextField(
                  controller: _maxAreaController,
                  keyboardType: TextInputType.number,
                  decoration: _m2FieldDecoration('Max'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kZeIlanPrimaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              final minPrice = _minPriceController.text.isNotEmpty
                  ? int.tryParse(_minPriceController.text)
                  : null;
              final maxPrice = _maxPriceController.text.isNotEmpty
                  ? int.tryParse(_maxPriceController.text)
                  : null;
              final minArea = _minAreaController.text.isNotEmpty
                  ? int.tryParse(_minAreaController.text)
                  : null;
              final maxArea = _maxAreaController.text.isNotEmpty
                  ? int.tryParse(_maxAreaController.text)
                  : null;

              widget.onApplyFilters(
                type,
                status,
                _countryCodeForApi,
                _selectedProvince?.code,
                _selectedDistrict?.code,
                _selectedQuarter?.code,
                _selectedProvince?.name,
                _selectedDistrict?.name,
                _selectedQuarter?.name,
                minPrice,
                maxPrice,
                minArea,
                maxArea,
              );
              if (widget.showSheetChrome) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Uygula',
              style: TextStyle(fontSize: 17, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                type = 'Konut';
                status = 'Kiralık';
                _countryCode = null;
                _selectedProvince = null;
                _selectedDistrict = null;
                _selectedQuarter = null;
                _districts = [];
                _quarters = [];
                _minPriceController.clear();
                _maxPriceController.clear();
                _minAreaController.clear();
                _maxAreaController.clear();
              });
              widget.onClearFilters();
              _loadProvinces();
              if (widget.showSheetChrome) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Filtreyi Temizle',
              style: TextStyle(
                color: _kZeIlanPrimaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = _buildFormBody();
    if (!widget.showSheetChrome) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: form,
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                form,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobil filtre: açık pembe zemin üzerinde iki yatay segment (Konut|İş Yeri, Kiralık|Satılık)
class _ZeIlanSegmentedPairRow extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool selectedLeft;
  final bool selectedRight;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _ZeIlanSegmentedPairRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.selectedLeft,
    required this.selectedRight,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kZeIlanSegmentTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ZeIlanSegmentCell(
              label: leftLabel,
              selected: selectedLeft,
              onTap: onLeft,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ZeIlanSegmentCell(
              label: rightLabel,
              selected: selectedRight,
              onTap: onRight,
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeIlanSegmentCell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _ZeIlanSegmentCell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: _kZeIlanPrimaryRed.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _kZeIlanPrimaryRed : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _kZeIlanPrimaryRed,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// Güncellenmiş buton widget'ı
typedef FilterTabCallback = void Function();

class _FilterTab extends StatelessWidget {
  final String text;
  final bool selected;
  final FilterTabCallback? onTap;
  const _FilterTab(
      {required this.text, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kZeIlanPrimaryRed : _kZeIlanSegmentTrack,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : _kZeIlanPrimaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Güncellenmiş dropdown widget'ı
class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) displayText;
  final ValueChanged<T?>? onChanged;
  const _FilterDropdown({
    required this.hint,
    this.value,
    required this.items,
    required this.displayText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: Colors.white,
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(displayText(e)),
                  ))
              .toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
