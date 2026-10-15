import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/events/portfolio_change_notifier.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/services/portfolio_service.dart';

String _formatListingPrice(int? price, {String currency = 'TRY'}) {
  if (price == null || price <= 0) return 'Fiyat Belirtilmemiş';
  final symbol = switch (currency.toUpperCase()) {
    'USD' => '\$',
    'EUR' => '€',
    _ => '₺',
  };
  return '$symbol${NumberFormat('#,###', 'tr_TR').format(price)}';
}

enum _LoadState { idle, loading, loaded, error }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const _brand = Color(0xFFE53935);
  static const _muted = Color(0xFF64748B);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;

  final TextEditingController _searchTextController = TextEditingController();
  String _selectedDurum = 'Tümü';
  String _selectedListingType = 'Tümü';
  String _selectedRealEstateType = 'Tümü';

  // myListings data source
  final List<ListingPanelModel> _allListings = [];
  List<ListingPanelModel> _filteredListings = [];
  _LoadState _loadState = _LoadState.idle;
  String _errorMessage = '';
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _fetchedAll = false;
  bool _fillingList = false;
  int _loadGeneration = 0;
  bool _isOpeningEdit = false;
  final PortfolioService _portfolioService = PortfolioService();

  static const int _pageSize = 10;

  static const List<String> _durumOptions = [
    'Tümü',
    'Yayında',
    'Taslak',
    'Onay Bekliyor',
    'Süresi Dolmuş',
    'Kiralandı',
    'Değişiklik İsteniyor',
    'Satıldı',
    'İptal Edildi',
    'Reddedildi',
    'Kapama Onayı Bekliyor',
  ];

  static const List<String> _listingTypeOptions = [
    'Tümü',
    'Satılık',
    'Kiralık',
  ];

  static const List<String> _realEstateTypeOptions = [
    'Tümü',
    'Konut',
    'İş Yeri',
    'Arsa',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchTextController.addListener(() {
      if (mounted) setState(() {});
    });
    // Portföy eklendi/güncellendi → liste elle refresh beklemeden yenilensin.
    PortfolioChangeNotifier.version.addListener(_onPortfolioChanged);
    _loadListings();
  }

  @override
  void dispose() {
    PortfolioChangeNotifier.version.removeListener(_onPortfolioChanged);
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onPortfolioChanged() {
    if (!mounted) return;
    _loadListings(refresh: true);
  }

  /// Kart → düzenleme ekranı. Portföyüm listesi *ilan* kayıtlarıdır;
  /// düzenleme ekranı ise *portföy* (real_estate) id'siyle çalışır. İlan
  /// yanıtında `real_estate` yoksa ilan detayından çözümlenir.
  Future<void> _openEditPortfolio(ListingPanelModel listing) async {
    if (_isOpeningEdit) return;
    _isOpeningEdit = true;
    try {
      String? realEstateId = listing.realEstate;
      if (realEstateId == null || realEstateId.isEmpty) {
        realEstateId =
            await _portfolioService.fetchListingRealEstateId(listing.id);
      }
      if (realEstateId == null || realEstateId.isEmpty) {
        debugPrint(
          '⚠️ Portföy id bulunamadı, ilan id ile açılıyor: ${listing.id}',
        );
      }
      if (!mounted) return;

      final portfolio = listing.toRealEstateModel(realEstateId: realEstateId);
      debugPrint(
        '✏️ Düzenleme açılıyor → listing=${listing.id} portfolio=${portfolio.id}',
      );
      await Navigator.pushNamed(
        context,
        AppRouter.editPortfolio,
        arguments: {
          'portfolio': portfolio,
          'listingPrice': listing.price,
          'listingType': listing.type,
          'listingId': listing.id,
        },
      );
    } finally {
      _isOpeningEdit = false;
    }
  }


  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 360 && !_isLoadingMore) {
      _loadMore();
    }
  }

  String? get _apiStateQuery {
    switch (_selectedDurum) {
      case 'Satıldı':
        return 'SOLD';
      case 'Kiralandı':
        return 'RENTED';
      case 'Yayında':
        return 'LIVE';
      default:
        return null;
    }
  }

  bool get _needsFullList {
    if (_searchTextController.text.trim().isNotEmpty) return true;
    if (_selectedListingType != 'Tümü') return true;
    if (_selectedRealEstateType != 'Tümü') return true;
    if (_selectedDurum != 'Tümü' && _apiStateQuery == null) return true;
    return false;
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (_loadState == _LoadState.loading && !refresh) return;
    final generation = ++_loadGeneration;
    final keepVisible = _filteredListings.isNotEmpty;

    setState(() {
      _errorMessage = '';
      _fetchedAll = false;
      _fillingList = false;
      _isLoadingMore = false;
      if (!keepVisible) _loadState = _LoadState.loading;
      if (refresh && !keepVisible) {
        _allListings.clear();
        _filteredListings.clear();
        _currentPage = 1;
        _totalPages = 1;
      }
    });
    if (keepVisible) _applyFilters();

    final repo = MyListingsRepository();
    final contact = await MyListingsRepository.contactQueryForSession();
    final result = await repo.getMyListings(
      page: 1,
      pageSize: _pageSize,
      state: _apiStateQuery,
      contact: contact,
      office: '',
    );

    if (!mounted || generation != _loadGeneration) return;

    var failed = false;
    result.fold(
      (failure) {
        failed = true;
        setState(() {
          if (_allListings.isEmpty) {
            _loadState = _LoadState.error;
            _errorMessage = failure.message;
          } else {
            _loadState = _LoadState.loaded;
          }
        });
      },
      (response) {
        final listings = MyListingsRepository.keepSessionListings(
          response.listings,
          contact,
        );
        setState(() {
          _allListings
            ..clear()
            ..addAll(listings);
          _totalPages = response.totalPages <= 0 ? 1 : response.totalPages;
          _currentPage = response.page <= 0 ? 1 : response.page;
          _fetchedAll = _currentPage >= _totalPages;
          _loadState = _LoadState.loaded;
        });
        _applyFilters();
      },
    );

    if (failed || !mounted || generation != _loadGeneration) return;
    if (_needsFullList && _currentPage < _totalPages) {
      if (mounted) setState(() => _fillingList = true);
      while (mounted &&
          generation == _loadGeneration &&
          _currentPage < _totalPages) {
        await _loadMore(generation: generation);
      }
      if (mounted && generation == _loadGeneration) {
        setState(() => _fillingList = false);
      }
    }
    if (mounted && generation == _loadGeneration) _applyFilters();
  }

  Future<void> _loadMore({int? generation}) async {
    final gen = generation ?? _loadGeneration;
    if (_isLoadingMore) return;
    if (_currentPage >= _totalPages) {
      _fetchedAll = true;
      return;
    }
    setState(() => _isLoadingMore = true);

    final repo = MyListingsRepository();
    final contact = await MyListingsRepository.contactQueryForSession();
    final nextPage = _currentPage + 1;
    final result = await repo.getMyListings(
      page: nextPage,
      pageSize: _pageSize,
      state: _apiStateQuery,
      contact: contact,
      office: '',
    );

    if (!mounted || gen != _loadGeneration) {
      if (mounted && gen == _loadGeneration) {
        setState(() => _isLoadingMore = false);
      }
      return;
    }

    result.fold(
      (failure) {
        setState(() => _isLoadingMore = false);
      },
      (response) {
        final existingIds = _allListings.map((e) => e.id).toSet();
        final newItems = MyListingsRepository.keepSessionListings(
          response.listings,
          contact,
        ).where((e) => !existingIds.contains(e.id)).toList();
        setState(() {
          _allListings.addAll(newItems);
          _currentPage = nextPage;
          _totalPages = response.totalPages <= 0
              ? (newItems.isEmpty ? _currentPage : _currentPage + 1)
              : response.totalPages;
          if (newItems.isEmpty) _totalPages = _currentPage;
          _fetchedAll = _currentPage >= _totalPages;
          _isLoadingMore = false;
        });
        _applyFilters();
      },
    );
  }

  String _durumFromState(String state) {
    switch (state.toUpperCase()) {
      case 'LIVE':
        return 'Yayında';
      case 'DRAFT':
        return 'Taslak';
      case 'PENDING':
      case 'WAITING_FOR_APPROVAL':
        return 'Onay Bekliyor';
      case 'EXPIRED':
        return 'Süresi Dolmuş';
      case 'RENTED':
        return 'Kiralandı';
      case 'CHANGE_REQUIRED':
        return 'Değişiklik İsteniyor';
      case 'SOLD':
        return 'Satıldı';
      case 'CANCELLED':
        return 'İptal Edildi';
      case 'REJECTED':
        return 'Reddedildi';
      case 'CLOSURE_APPROVAL':
      case 'WAITING_FOR_CLOSE_APPROVAL':
        return 'Kapama Onayı Bekliyor';
      default:
        return state;
    }
  }

  String _fold(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  String _listingTypeLabel(ListingPanelModel listing) {
    final raw = _fold(listing.type);
    if (raw.contains('kiral') || raw == 'rent') return 'Kiralık';
    if (raw.contains('satil') || raw == 'sale') return 'Satılık';
    if (listing.displayType == 'Satılık' || listing.displayType == 'Kiralık') {
      return listing.displayType;
    }
    return listing.displayType.isEmpty ? listing.type : listing.displayType;
  }

  String _realEstateCategory(ListingPanelModel listing) {
    final compact = _fold(listing.realEstateType).replaceAll(RegExp(r'[\s_-]'), '');
    if (compact.contains('isyeri') ||
        compact.contains('ofis') ||
        compact.contains('dukkan')) {
      return 'İş Yeri';
    }
    if (compact.contains('arsa')) return 'Arsa';
    if (compact.contains('konut') ||
        compact.contains('daire') ||
        compact.contains('villa') ||
        compact.contains('residence') ||
        compact.contains('mustakil')) {
      return 'Konut';
    }
    return '';
  }

  bool _matchesSearch(ListingPanelModel listing, String query) {
    if (query.isEmpty) return true;
    final room = listing.propertiesShortList
        .where((p) => p.code == 'oda-sayisi')
        .map((p) => p.value.replaceAll('oda-sayisi-', ''))
        .join(' ');
    final haystack = _fold(
      '${listing.title} ${listing.listingNo} ${listing.provinceName} '
      '${listing.districtName} ${listing.quarterName} '
      '${listing.realEstateType} ${listing.displayRealEstateType} '
      '${_listingTypeLabel(listing)} ${_realEstateCategory(listing)} '
      '${_durumFromState(listing.state)} ${listing.price} ${listing.formattedPrice} '
      '$room',
    );
    return haystack.contains(query);
  }

  void _applyFilters() {
    final search = _fold(_searchTextController.text.trim());
    setState(() {
      _filteredListings = _allListings.where((listing) {
        if (!_matchesSearch(listing, search)) return false;
        if (_selectedDurum != 'Tümü' &&
            _durumFromState(listing.state) != _selectedDurum) {
          return false;
        }
        if (_selectedListingType != 'Tümü' &&
            _listingTypeLabel(listing) != _selectedListingType) {
          return false;
        }
        if (_selectedRealEstateType != 'Tümü' &&
            _realEstateCategory(listing) != _selectedRealEstateType) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    _searchTimer?.cancel();
    _searchTextController.clear();
    setState(() {
      _selectedDurum = 'Tümü';
      _selectedListingType = 'Tümü';
      _selectedRealEstateType = 'Tümü';
    });
    _loadListings(refresh: true);
  }

  bool get _hasActiveFilters =>
      _searchTextController.text.isNotEmpty ||
      _selectedDurum != 'Tümü' ||
      _selectedListingType != 'Tümü' ||
      _selectedRealEstateType != 'Tümü';

  int get _activeFilterCount {
    int c = 0;
    if (_selectedDurum != 'Tümü') c++;
    if (_selectedListingType != 'Tümü') c++;
    if (_selectedRealEstateType != 'Tümü') c++;
    return c;
  }

  void _openFilterSheet() {
    String tmpDurum = _selectedDurum;
    String tmpListingType = _selectedListingType;
    String tmpRealEstateType = _selectedRealEstateType;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, color: _brand),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Filtrele',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tmpDurum = 'Tümü';
                                  tmpListingType = 'Tümü';
                                  tmpRealEstateType = 'Tümü';
                                });
                              },
                              child: const Text(
                                'Temizle',
                                style: TextStyle(
                                  color: _brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FilterField(
                          label: 'Emlak Tipi',
                          value: tmpRealEstateType,
                          options: _realEstateTypeOptions,
                          icon: Icons.home_work_rounded,
                          onChanged: (v) =>
                              setModalState(() => tmpRealEstateType = v),
                        ),
                        const SizedBox(height: 12),
                        _FilterField(
                          label: 'Durum',
                          value: tmpDurum,
                          options: _durumOptions,
                          icon: Icons.verified_rounded,
                          onChanged: (v) => setModalState(() => tmpDurum = v),
                        ),
                        const SizedBox(height: 12),
                        _FilterField(
                          label: 'İlan Tipi',
                          value: tmpListingType,
                          options: _listingTypeOptions,
                          icon: Icons.sell_rounded,
                          onChanged: (v) =>
                              setModalState(() => tmpListingType = v),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                final previousState = _apiStateQuery;
                                _searchTimer?.cancel();
                                setState(() {
                                  _selectedDurum = tmpDurum;
                                  _selectedListingType = tmpListingType;
                                  _selectedRealEstateType = tmpRealEstateType;
                                });
                                Navigator.pop(context);
                                final stateChanged = _apiStateQuery != previousState;
                                if (stateChanged ||
                                    (_needsFullList && !_fetchedAll)) {
                                  _loadListings(refresh: true);
                                } else {
                                  _applyFilters();
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Uygula',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Portföyüm');
        },
      ),
      appBar: AdminPanelInAppBar(
        title: 'Portföyüm',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.addPortfolio);
        },
        backgroundColor: _brand,
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        label: const Text(
          'Portföy Ekle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 56);
                }
                final userRoleCodes = snapshot.data ?? [];
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_office_broker') ||
                    userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else {
                  return const FrancahiseNavbar(currentIndex: -1);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern Stats Header
          SliverToBoxAdapter(
            child: _buildStatsHeader(),
          ),

          // Sticky search bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _PortfolioSearchBarDelegate(
              searchController: _searchTextController,
              onSearchChanged: (value) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(seconds: 1), () {
                  if (!mounted) return;
                  if (_needsFullList && !_fetchedAll) {
                    _loadListings(refresh: true);
                  } else {
                    _applyFilters();
                  }
                });
              },
              onFilterPressed: _openFilterSheet,
              hasActiveFilters: _hasActiveFilters,
              activeFilterCount: _activeFilterCount,
            ),
          ),

          // Body
          _buildSliverBody(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final isLoading =
        _loadState == _LoadState.idle || _loadState == _LoadState.loading;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portföyünüz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Satılık ve kiralık ilanlarınızı buradan yönetin',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLoading ? null : () => _loadListings(refresh: true),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverBody() {
    if ((_loadState == _LoadState.idle || _loadState == _LoadState.loading) &&
        _filteredListings.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonCard(),
            childCount: 4,
          ),
        ),
      );
    }

    if (_loadState == _LoadState.error) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline,
                      size: 64, color: Colors.red[400]),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bir Hata Oluştu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey[600], height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => _loadListings(refresh: true),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Tekrar Dene',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredListings.isEmpty && (_fillingList || _isLoadingMore)) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonCard(),
            childCount: 3,
          ),
        ),
      );
    }

    if (_filteredListings.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.grey[100]!, Colors.grey[200]!]),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.home_work, size: 72, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                const Text(
                  'İlan Bulunamadı',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aradığınız kriterlere uygun ilan bulunamadı.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[600], height: 1.5),
                  textAlign: TextAlign.center,
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Filtreleri Temizle'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final hasMore = _currentPage < _totalPages;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _filteredListings.length) {
              return _buildLoadMoreFooter();
            }
            return _buildListingCard(_filteredListings[index]);
          },
          childCount:
              _filteredListings.length + (hasMore || _isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _brand,
                ),
              )
            : TextButton(
                onPressed: _loadMore,
                child: const Text(
                  'Daha fazla yükle',
                  style: TextStyle(color: _brand, fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Yayında':
        return const Color(0xFF10B981);
      case 'Onay Bekliyor':
      case 'Değişiklik İsteniyor':
        return const Color(0xFFF59E0B);
      case 'Satıldı':
        return _brand;
      case 'Kiralandı':
        return const Color(0xFF3B82F6);
      case 'Süresi Dolmuş':
      case 'İptal Edildi':
      case 'Reddedildi':
        return Colors.grey.shade500;
      default:
        return const Color(0xFF475569);
    }
  }

  Widget _buildStatusChip(String statusText, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(ListingPanelModel listing) {
    final durum = _durumFromState(listing.state);
    final statusClr = _statusColor(durum);
    final typeLabel = _listingTypeLabel(listing);
    final isForSale = typeLabel == 'Satılık';

    // m2 from properties
    final m2 = listing.propertiesShortList
        .where((p) => p.code == 'm2-net' || p.code == 'm2-brut' || p.code == 'm2')
        .map((p) => p.numberValue)
        .where((v) => v != null && v > 0)
        .firstOrNull;

    // oda sayisi
    final odaSayisi = listing.propertiesShortList
        .where((p) => p.code == 'oda-sayisi')
        .map((p) => p.value.replaceAll('oda-sayisi-', ''))
        .where((v) => v.isNotEmpty && v != 'oda-sayisi')
        .firstOrNull;

    final imageId = listing.coverPicture?.isNotEmpty == true
        ? listing.coverPicture
        : listing.picture;

    return InkWell(
      onTap: () => _openEditPortfolio(listing),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _buildImage(imageId),
                  ),
                ),
                // Type badge top-left
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isForSale ? _brand : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isForSale ? _brand : const Color(0xFF3B82F6))
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          typeLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip
                  _buildStatusChip(durum, statusClr),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${listing.provinceName} / ${listing.districtName} / ${listing.quarterName}',
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Area + Room chips
                  Row(
                    children: [
                      if (m2 != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _brand.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.straighten,
                                    color: _brand, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '$m2 m²',
                                  style: const TextStyle(
                                    color: _brand,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (m2 != null && odaSayisi != null)
                        const SizedBox(width: 12),
                      if (odaSayisi != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _brand.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hotel,
                                    color: _brand, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  odaSayisi,
                                  style: const TextStyle(
                                    color: _brand,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price - direkt listing.price'dan alıyoruz
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _brand.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fiyat',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        Flexible(
                          child: Text(
                            _formatListingPrice(
                              listing.price,
                              currency: listing.currency,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey[200], thickness: 1, height: 0),
            ),

            // Agent footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.contactTitle,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.connectedContactTitle,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: _muted, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? s3Id) {
    if (s3Id == null || s3Id.isEmpty || !ImageUtils.isValidS3Id(s3Id)) {
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_work, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Resim Yok',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 220,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 220,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_brand),
              strokeWidth: 3,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 220,
          color: Colors.grey[200],
          child: Center(
            child: Icon(Icons.broken_image,
                size: 60, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: _shimmerBox(height: 220, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(height: 14, width: 80),
                const SizedBox(height: 10),
                _shimmerBox(height: 18, width: double.infinity),
                const SizedBox(height: 8),
                _shimmerBox(height: 13, width: 160),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _shimmerBox(height: 40, width: double.infinity)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _shimmerBox(height: 40, width: double.infinity)),
                ]),
                const SizedBox(height: 14),
                _shimmerBox(height: 48, width: double.infinity),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Divider(color: Colors.grey[200], thickness: 1, height: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _shimmerBox(height: 44, width: 44, radius: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(height: 14, width: 120),
                      const SizedBox(height: 6),
                      _shimmerBox(height: 11, width: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
      {required double height, required double width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Search Bar Delegate ───────────────────────────────────────────────────────
class _PortfolioSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;
  final int activeFilterCount;

  _PortfolioSearchBarDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.hasActiveFilters,
    required this.activeFilterCount,
  });

  @override
  double get minExtent => 76.0;
  @override
  double get maxExtent => 76.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 76.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey[50]!],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: searchController,
                builder: (context, _) {
                  return TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Portföy ara (konum, başlık...)...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFFE53935).withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFE53935),
                                    size: 16,
                                  ),
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              onPressed: onFilterPressed,
              hasActiveFilters: hasActiveFilters,
              activeFilterCount: activeFilterCount,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PortfolioSearchBarDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.hasActiveFilters != hasActiveFilters ||
        oldDelegate.activeFilterCount != activeFilterCount;
  }
}

// ─── Filter Button ─────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool hasActiveFilters;
  final int activeFilterCount;

  const _FilterButton({
    required this.onPressed,
    required this.hasActiveFilters,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasActiveFilters
                ? const Color(0xFFE53935).withOpacity(0.12)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasActiveFilters
                  ? const Color(0xFFE53935).withOpacity(0.25)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: hasActiveFilters
                        ? const Color(0xFFE53935)
                        : const Color(0xFF6B7280),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                'Filtre',
                style: TextStyle(
                  color: hasActiveFilters
                      ? const Color(0xFFE53935)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Field Dropdown ──────────────────────────────────────────────────────
class _FilterField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _FilterField({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.white),
          child: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: options
                .map(
                  (v) => DropdownMenuItem<String>(
                    value: v,
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: const Color(0xFFE53935)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            v,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
            hint: Text(
              label,
              style: TextStyle(
                  color: Colors.grey[500], fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
