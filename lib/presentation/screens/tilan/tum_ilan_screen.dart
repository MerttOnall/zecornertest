import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/admin-panel/admin_panel_in_appbar.dart';
import '../../widgets/role-sidebar/role_sidebar.dart';
import '../../widgets/navbar/admin_navbar.dart';
import '../../widgets/navbar/danisman_navbar.dart';
import '../../widgets/navbar/broker_navbar.dart';
import '../../widgets/navbar/francahise_navbar.dart';
import '../../../core/cubit/auth_cubit.dart';
import '../../../core/cubit/user_profile_cubit.dart';
import '../../../core/cubit/user_profile_state.dart';
import '../../../models/tilan/tum_ilan_model.dart';
import '../../../models/office_persons/office_persons_api_model.dart';
import '../../../infrastructure/tilan/tum_ilan_api_repository.dart';
import '../../../infrastructure/office_persons/office_persons_api_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/image_utils.dart';
import 'tum_ilan_detail_screen.dart';

class TumIlanScreen extends StatefulWidget {
  const TumIlanScreen({super.key});

  @override
  State<TumIlanScreen> createState() => _TumIlanScreenState();
}

class _TumIlanScreenState extends State<TumIlanScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TumIlanApiRepository _apiRepository = TumIlanApiRepository();
  final OfficePersonsApiRepository _officePersonsRepository =
      OfficePersonsApiRepository();
  final ScrollController _scrollController = ScrollController();
  
  List<TumIlanModel> _ilanlar = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _totalCount = 0;
  int _page = 1;
  int _totalPages = 1;
  int _lastFetchedCount = 0;
  bool _hasMoreFromApi = false;
  static const int _pageSize = 10;
  static const int _allPortfoliosPageSize = 9999;

  // Filtreler (web'deki gibi: Durum + Kişi + Ofis)
  String _selectedStatusFilter = 'Tümü';
  String _selectedOfficeFilter = 'Tümü';
  String _selectedContactLabel = 'Tümü';
  int? _selectedContactNo;
  List<String> _availableOffices = const [];
  List<OfficePersonsApiModel> _officePersons = const [];
  /// Kişi filtresi: tüm portföy (ofis kapsamı), 10'luk sayfa değil.
  List<TumIlanModel> _allPortfoliosCache = const [];
  bool _allPortfoliosCacheReady = false;

  /// Ofis filtresi yalnızca admin kullanıcılar için.
  bool _isAdmin = false;
  /// Broker/asistan: ilan `connected_contact` (ofis), kişi `contact_no` değil.
  int? _userOfficeId;
  String? _userOfficeTitle;
  int? _userContactNo;
  bool _identityReady = false;

  // Arama
  final TextEditingController _searchTextController = TextEditingController();
  Timer? _searchTimer;
  String _searchQuery = '';
  List<TumIlanModel> _filteredIlanlar = [];
  static const Duration _searchDebounceDuration = Duration(seconds: 1);
  /// Arama/filtre yenilemesinde artar; eski HTTP cevapları yoksayılır.
  int _loadGeneration = 0;
  static const double _scrollToTopThreshold = 420;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // Scroll position'ı en üste ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _scrollController.addListener(_onIlanScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolveIdentityThenLoad();
    });
  }

  /// API'ye office gönderme: office=113 BAMMA'da yalnızca yayındakileri döndürüyor.
  /// Broker ofis süzgeci istemcide `connected_contact` ile yapılır.
  String get _apiOfficeQuery => '';

  bool get _shouldScopeToOffice => !_isAdmin;

  bool get _hasOfficeScope =>
      (_userOfficeId != null && _userOfficeId! > 0) ||
      (_userOfficeTitle != null && _userOfficeTitle!.trim().isNotEmpty);

  bool _isListingInUserOffice(TumIlanModel ilan) {
    if (_userOfficeId != null &&
        _userOfficeId! > 0 &&
        ilan.connectedContact == _userOfficeId) {
      return true;
    }
    final title = _userOfficeTitle?.trim().toLowerCase();
    if (title != null &&
        title.isNotEmpty &&
        ilan.connectedContactTitle.trim().toLowerCase() == title) {
      return true;
    }
    // Ofis henüz çözülemediyse en azından kendi ilanlarını göster (boş ekran olmasın).
    if (!_hasOfficeScope &&
        _userContactNo != null &&
        _userContactNo! > 0 &&
        ilan.contactNo == _userContactNo) {
      return true;
    }
    return false;
  }

  void _inferOfficeFromListings(List<TumIlanModel> listings) {
    if (_isAdmin || _hasOfficeScope) return;
    if (_userContactNo == null || _userContactNo! <= 0) return;
    for (final ilan in listings) {
      if (ilan.contactNo == _userContactNo && ilan.connectedContact > 0) {
        _userOfficeId = ilan.connectedContact;
        if (ilan.connectedContactTitle.trim().isNotEmpty) {
          _userOfficeTitle = ilan.connectedContactTitle.trim();
        }
        return;
      }
    }
  }

  List<TumIlanModel> _scopeToUserOffice(List<TumIlanModel> listings) {
    if (!_shouldScopeToOffice) {
      return List<TumIlanModel>.from(listings);
    }
    return listings.where(_isListingInUserOffice).toList();
  }

  Future<void> _resolveIdentityThenLoad() async {
    await _loadUserIdentity();
    if (!mounted) return;
    unawaited(_loadOfficePersons());
    await _loadFirstPage();
  }

  Future<void> _loadOfficePersons() async {
    final result = await _officePersonsRepository.getOfficePersons(
      page: 1,
      limit: 9999,
      types: const [],
    );
    if (!mounted) return;
    result.fold(
      (_) {},
      (response) {
        var contacts = List<OfficePersonsApiModel>.from(response.contacts);
        if (!_isAdmin && _userOfficeId != null && _userOfficeId! > 0) {
          contacts = contacts
              .where((c) => c.connectedContact == _userOfficeId)
              .toList();
        }
        contacts.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        setState(() {
          _officePersons = contacts;
          if (_selectedContactNo != null &&
              !contacts.any((c) => c.contactNo == _selectedContactNo)) {
            _selectedContactNo = null;
            _selectedContactLabel = 'Tümü';
          }
        });
        _applyFilters();
      },
    );
  }

  String _personBaseTitle(OfficePersonsApiModel person) {
    final title = person.title.trim();
    if (title.isNotEmpty) return title;
    final name = '${person.name ?? ''} ${person.surname ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return 'Kişi ${person.contactNo}';
  }

  Map<int, String> get _personLabelByContactNo {
    final titleCounts = <String, int>{};
    for (final person in _officePersons) {
      final title = _personBaseTitle(person);
      titleCounts[title] = (titleCounts[title] ?? 0) + 1;
    }
    final map = <int, String>{};
    for (final person in _officePersons) {
      final title = _personBaseTitle(person);
      map[person.contactNo] = titleCounts[title]! > 1
          ? '$title (${person.contactNo})'
          : title;
    }
    return map;
  }

  List<String> get _personFilterOptions {
    final labels = _personLabelByContactNo;
    return [
      'Tümü',
      ..._officePersons.map((p) => labels[p.contactNo] ?? _personBaseTitle(p)),
    ];
  }

  int? _contactNoForLabel(String label) {
    if (label == 'Tümü') return null;
    final labels = _personLabelByContactNo;
    for (final person in _officePersons) {
      if (labels[person.contactNo] == label) return person.contactNo;
    }
    final match = RegExp(r'\((\d+)\)$').firstMatch(label);
    if (match != null) return int.tryParse(match.group(1)!);
    for (final person in _officePersons) {
      if (_personBaseTitle(person) == label) return person.contactNo;
    }
    return null;
  }

  OfficePersonsApiModel? _personByContactNo(int? contactNo) {
    if (contactNo == null || contactNo <= 0) return null;
    for (final person in _officePersons) {
      if (person.contactNo == contactNo) return person;
    }
    return null;
  }

  bool _isListingOfSelectedPerson(TumIlanModel ilan) {
    final selectedNo = _selectedContactNo;
    if (selectedNo == null || selectedNo <= 0) return true;
    if (ilan.contactNo == selectedNo) return true;

    final person = _personByContactNo(selectedNo);
    if (person == null) return false;

    String norm(String value) =>
        _fold(value).replaceAll(RegExp(r'\s+'), ' ').trim();

    final personTitle = norm(_personBaseTitle(person));
    if (personTitle.isNotEmpty && norm(ilan.contactTitle) == personTitle) {
      return true;
    }
    final slug = person.slug?.trim();
    if (slug != null &&
        slug.isNotEmpty &&
        ilan.contactSlug.trim() == slug) {
      return true;
    }
    return false;
  }

  Future<void> _loadUserIdentity() async {
    try {
      final authCubit = context.read<AuthCubit>();
      UserProfileCubit? profileCubit;
      try {
        profileCubit = context.read<UserProfileCubit>();
      } catch (_) {
        profileCubit = null;
      }

      final roleCodes = await authCubit.getUserRoleCodes();
      var isAdmin = roleCodes.contains('role_admin') ||
          roleCodes.any((c) => c == 'role_admin');

      int? officeId;
      String? officeTitle;
      int? personContactNo;

      final pref = await SharedPreferences.getInstance();
      personContactNo = int.tryParse(pref.getString('userID')?.trim() ?? '');
      officeTitle = pref.getString('officeTitle')?.trim();
      if (officeTitle != null && officeTitle.isEmpty) officeTitle = null;

      if (profileCubit != null) {
        try {
          if (profileCubit.state is! UserProfileLoaded) {
            await profileCubit.loadUserProfile();
          }
          if (profileCubit.state is UserProfileLoaded) {
            final profile =
                (profileCubit.state as UserProfileLoaded).userProfile;
            isAdmin = isAdmin ||
                profile.isAdmin ||
                profile.roles.any(
                  (r) => r.code == 'role_admin' || r.isAdmin,
                );
            if (profile.contactNo > 0) {
              personContactNo = profile.contactNo;
            }
            // Her broker için ofis = get-user-info connected_contact.
            if (profile.connectedContact > 0 &&
                profile.connectedContact != profile.contactNo) {
              officeId = profile.connectedContact;
            }
            final title = profile.connectedContactTitle.trim();
            if (title.isNotEmpty) officeTitle = title;
          }
        } catch (_) {
          // Profil yoksa prefs ile devam
        }
      }

      officeId ??= pref.getInt('officeId');
      officeId ??= await authCubit.getStoredOfficeId();
      officeId ??= await authCubit.getOfficeId();
      if (officeId != null &&
          personContactNo != null &&
          officeId == personContactNo) {
        officeId = null;
      }
      if (officeId != null && officeId <= 0) officeId = null;

      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _userOfficeId = officeId;
        _userOfficeTitle = officeTitle;
        _userContactNo = personContactNo;
        _identityReady = true;
        if (!isAdmin) {
          _selectedOfficeFilter = 'Tümü';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _userOfficeId = null;
        _userOfficeTitle = null;
        _userContactNo = null;
        _identityReady = true;
        _selectedOfficeFilter = 'Tümü';
      });
    }
  }

  bool get _hasMoreIlanlar => _hasMoreFromApi;

  void _sortNewestFirst(List<TumIlanModel> items) {
    items.sort(
      (a, b) => b.createdAtDateTime.compareTo(a.createdAtDateTime),
    );
  }

  void _onIlanScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final shouldShow = offset > _scrollToTopThreshold;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }

    if (_searchTimer?.isActive == true) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadMoreIlanlar();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildScrollToTopButton() {
    return IgnorePointer(
      ignoring: !_showScrollToTop,
      child: AnimatedOpacity(
        opacity: _showScrollToTop ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedScale(
          scale: _showScrollToTop ? 1 : 0.85,
          duration: const Duration(milliseconds: 200),
          child: Material(
            elevation: 6,
            shadowColor: const Color(0xFFE53935).withValues(alpha: 0.35),
            shape: const CircleBorder(),
            color: const Color(0xFFE53935),
            child: InkWell(
              onTap: _scrollToTop,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _needsFullList =>
      _searchQuery.trim().isNotEmpty ||
      (_selectedContactNo != null && _selectedContactNo! > 0) ||
      (_isAdmin && _selectedOfficeFilter != 'Tümü');

  /// Tümü: state gönderilmez — web gibi tüm durumlar (satıldı/kiralandı dahil) gelir.
  String? get _apiStateQuery {
    switch (_selectedStatusFilter) {
      case 'Satıldı':
        return 'SOLD';
      case 'Kiralandı':
        return 'RENTED';
      case 'Yayında':
        return 'LIVE';
      case 'Taslak':
        return 'DRAFT';
      case 'Onay Bekliyor':
        return 'WAITING_FOR_APPROVAL';
      case 'Süresi Dolmuş':
        return 'EXPIRED';
      case 'Değişiklik İsteniyor':
        return 'CHANGE_REQUIRED';
      case 'İptal Edildi':
        return 'CANCELLED';
      case 'Reddedildi':
        return 'REJECTED';
      case 'Kapama Onayı Bekliyor':
        return 'WAITING_FOR_CLOSE_APPROVAL';
      default:
        return null;
    }
  }

  Future<void> _loadAllIlanlarAutomatically() =>
      _loadFirstPage(refreshCache: true);

  Future<void> _loadFirstPage({bool refreshCache = false}) async {
    if (!_identityReady) return;

    if (refreshCache) {
      _allPortfoliosCache = const [];
      _allPortfoliosCacheReady = false;
    }

    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _page = 1;
      _lastFetchedCount = 0;
      _hasMoreFromApi = false;
      _isLoadingMore = false;
    });

    if (_needsFullList) {
      await _loadFromFullCache(generation);
      return;
    }

    final result = await _apiRepository.getTumIlanlar(
      page: 1,
      limit: _pageSize,
      state: _apiStateQuery,
      sortBy: 'created_at',
      sortOrder: 'asc',
      office: _apiOfficeQuery,
      contact: 'all',
    );

    if (!mounted || generation != _loadGeneration) return;
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getErrorMessage(failure);
        });
      },
      (response) {
        final unscoped = List<TumIlanModel>.from(response.listings);
        _inferOfficeFromListings(unscoped);
        var listings = _scopeToUserOffice(unscoped);
        _sortNewestFirst(listings);
        setState(() {
          _ilanlar = listings;
          _totalCount = _shouldScopeToOffice
              ? listings.length
              : response.totalCount;
          _totalPages = response.totalPages <= 0
              ? (response.totalCount > 0
                  ? (response.totalCount / _pageSize).ceil()
                  : 1)
              : response.totalPages;
          _page = response.page <= 0 ? 1 : response.page;
          _lastFetchedCount = listings.length;
          _hasMoreFromApi = response.hasMore;
          if (_shouldScopeToOffice && !_hasOfficeScope) {
            _hasMoreFromApi = false;
          }
          _isLoading = false;
          _availableOffices = _computeAvailableOffices(
            _isAdmin ? unscoped : listings,
          );
        });
        _applyFilters();
      },
    );

    if (mounted &&
        generation == _loadGeneration &&
        _shouldScopeToOffice &&
        _hasOfficeScope &&
        _hasMoreFromApi &&
        _ilanlar.length < _pageSize) {
      await _loadMoreUntilBrokerFilled(generation);
    }
  }

  Future<void> _loadFromFullCache(int generation) async {
    final all = await _fetchAllPortfolios(generation);
    if (!mounted || generation != _loadGeneration) return;

    if (all == null) {
      setState(() {
        _isLoading = false;
        if (_filteredIlanlar.isEmpty) {
          _hasError = true;
          _errorMessage = 'Portföyler alınamadı.';
        }
      });
      return;
    }

    setState(() {
      _ilanlar = List<TumIlanModel>.from(all);
      _totalCount = all.length;
      _totalPages = 1;
      _page = 1;
      _lastFetchedCount = all.length;
      _hasMoreFromApi = false;
      _isLoading = false;
      _hasError = false;
      _availableOffices = _computeAvailableOffices(all);
    });
    _applyFilters();
  }

  Future<List<TumIlanModel>?> _fetchAllPortfolios(int generation) async {
    if (_allPortfoliosCacheReady) {
      return List<TumIlanModel>.from(_allPortfoliosCache);
    }

    final byId = <String, TumIlanModel>{};
    var page = 1;
    var hasMore = true;
    var guard = 0;

    while (hasMore && guard < 40) {
      if (!mounted || generation != _loadGeneration) return null;
      guard++;

      final result = await _apiRepository.getTumIlanlar(
        page: page,
        limit: _allPortfoliosPageSize,
        state: null,
        sortBy: 'created_at',
        sortOrder: 'asc',
        office: _apiOfficeQuery,
        contact: 'all',
      );

      final response = result.fold<TumIlanResponse?>((_) => null, (r) => r);
      if (response == null) {
        if (byId.isNotEmpty) break;
        return null;
      }

      _inferOfficeFromListings(response.listings);
      final before = byId.length;
      for (final listing in response.listings) {
        if (listing.id.isNotEmpty) {
          byId[listing.id] = listing;
        }
      }

      final gotNew = byId.length > before;
      hasMore = gotNew &&
          response.hasMore &&
          response.listings.isNotEmpty;
      page += 1;
    }

    final all = _scopeToUserOffice(byId.values.toList());
    _sortNewestFirst(all);
    _allPortfoliosCache = all;
    _allPortfoliosCacheReady = true;
    return List<TumIlanModel>.from(all);
  }

  Future<void> _loadMoreUntilBrokerFilled(int generation) async {
    var guard = 0;
    while (mounted &&
        generation == _loadGeneration &&
        _shouldScopeToOffice &&
        _hasOfficeScope &&
        _hasMoreFromApi &&
        _ilanlar.length < _pageSize &&
        guard < 8) {
      guard++;
      await _loadMoreIlanlar();
    }
  }

  Future<void> _loadMoreIlanlar() async {
    if (!_identityReady) return;
    if (_needsFullList) return;
    if (_isLoading || _isLoadingMore || !_hasMoreIlanlar) return;
    if (_searchTimer?.isActive == true) return;

    final generation = _loadGeneration;
    setState(() => _isLoadingMore = true);

    final nextPage = _page + 1;
    final result = await _apiRepository.getTumIlanlar(
      page: nextPage,
      limit: _pageSize,
      state: _apiStateQuery,
      sortBy: 'created_at',
      sortOrder: 'asc',
      office: _apiOfficeQuery,
      contact: 'all',
    );

    if (!mounted || generation != _loadGeneration) return;
    result.fold(
      (failure) {
        setState(() => _isLoadingMore = false);
      },
      (response) {
        _inferOfficeFromListings(response.listings);
        final existingIds = _ilanlar.map((e) => e.id).toSet();
        final appended = _scopeToUserOffice(response.listings)
            .where((item) => !existingIds.contains(item.id))
            .toList();
        final merged = [..._ilanlar, ...appended];
        _sortNewestFirst(merged);
        setState(() {
          _ilanlar
            ..clear()
            ..addAll(merged);
          if (_shouldScopeToOffice) {
            _totalCount = merged.length;
          } else {
            _totalCount = response.totalCount > 0
                ? response.totalCount
                : _totalCount;
          }
          _lastFetchedCount = appended.isEmpty ? 0 : appended.length;
          _hasMoreFromApi = response.hasMore &&
              (_hasOfficeScope || appended.isNotEmpty) &&
              (appended.isNotEmpty || _shouldScopeToOffice);
          if (!_hasOfficeScope && _shouldScopeToOffice) {
            _hasMoreFromApi = false;
          }
          if (appended.isEmpty && !_shouldScopeToOffice) {
            _totalPages = _page;
          } else {
            _page = response.page <= 0 ? nextPage : response.page;
            _totalPages = response.totalPages > 0
                ? response.totalPages
                : (_totalCount > 0
                    ? (_totalCount / _pageSize).ceil()
                    : nextPage + 1);
          }
          _isLoadingMore = false;
          if (_isAdmin) {
            _availableOffices = _computeAvailableOffices([
              ..._ilanlar,
              ...response.listings,
            ]);
          } else {
            _availableOffices = _computeAvailableOffices(_ilanlar);
          }
        });
        _applyFilters();
      },
    );
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (failure is ServerFailure) {
      return failure.message;
    } else {
      return 'Beklenmeyen bir hata oluştu.';
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

  bool _matchesSearch(TumIlanModel ilan, String query) {
    if (query.isEmpty) return true;

    bool has(String? value) {
      final folded = _fold(value ?? '');
      if (folded.isEmpty ||
          folded == 'bilinmiyor' ||
          folded == 'n/a' ||
          folded == '-') {
        return false;
      }
      return folded.contains(query);
    }

    return has(ilan.title) ||
        has(ilan.location) ||
        has(ilan.typeText) ||
        has(ilan.realEstateType) ||
        has(ilan.contactTitle) ||
        has(ilan.connectedContactTitle) ||
        has(ilan.listingNo.toString()) ||
        has(ilan.price.toString()) ||
        has(ilan.formattedPrice) ||
        has(ilan.areaInfo) ||
        has(ilan.roomInfo) ||
        has(_getStatusText(ilan.state));
  }

  void _applyFilters() {
    final query = _fold(_searchQuery.trim());
    final officeQuery = _fold(_selectedOfficeFilter.trim());
    setState(() {
      Iterable<TumIlanModel> items = _ilanlar;

      if (_shouldScopeToOffice) {
        items = items.where(_isListingInUserOffice);
      }

      if (_selectedStatusFilter != 'Tümü') {
        items = items.where(
          (ilan) => _getStatusText(ilan.state) == _selectedStatusFilter,
        );
      }

      if (_isAdmin && _selectedOfficeFilter != 'Tümü') {
        items = items.where(
          (ilan) => _fold(ilan.connectedContactTitle.trim()) == officeQuery,
        );
      }

      if (_selectedContactNo != null && _selectedContactNo! > 0) {
        items = items.where(_isListingOfSelectedPerson);
      }

      if (query.isNotEmpty) {
        items = items.where((ilan) => _matchesSearch(ilan, query));
      }

      _filteredIlanlar = items.toList();
      _sortNewestFirst(_filteredIlanlar);
    });
  }

  void _applySearchFromField({bool immediate = false}) {
    _searchTimer?.cancel();
    void runSearch() {
      if (!mounted) return;
      final nextQuery = _searchTextController.text.trim();
      final changed = nextQuery != _searchQuery.trim();
      if (!changed && !_needsFullList) return;

      if (changed && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _searchQuery = nextQuery;
      });
      if (_needsFullList) {
        if (_allPortfoliosCacheReady) {
          _ilanlar = List<TumIlanModel>.from(_allPortfoliosCache);
          _hasMoreFromApi = false;
          _applyFilters();
        } else {
          _loadFirstPage();
        }
      } else {
        _applyFilters();
      }
    }

    if (immediate) {
      runSearch();
      return;
    }

    _searchTimer = Timer(_searchDebounceDuration, runSearch);
  }

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      _applySearchFromField(immediate: true);
      return;
    }
    _applySearchFromField();
  }


  /// İlan durumunu Türkçe'ye çevir
  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
        return 'Yayında';
      case 'DRAFT':
        return 'Taslak';
      case 'WAITING_FOR_APPROVAL':
      case 'PENDING':
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
      case 'WAITING_FOR_CLOSE_APPROVAL':
      case 'CLOSURE_APPROVAL':
        return 'Kapama Onayı Bekliyor';
      default:
        return status;
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedStatusFilter != 'Tümü' ||
      _selectedContactNo != null ||
      (_isAdmin && _selectedOfficeFilter != 'Tümü');

  int get _activeFilterCount {
    int c = 0;
    if (_searchQuery.trim().isNotEmpty) c += 1;
    if (_selectedStatusFilter != 'Tümü') c += 1;
    if (_selectedContactNo != null) c += 1;
    if (_isAdmin && _selectedOfficeFilter != 'Tümü') c += 1;
    return c;
  }

  // Durum chip'i - renkli rozet
  Widget _buildStatusChip(String statusCode) {
    final statusText = _getStatusText(statusCode);

    Color bgColor;

    switch (statusText) {
      case 'Yayında':
        bgColor = const Color(0xFF10B981); // yeşil
        break;
      case 'Satıldı':
        bgColor = const Color(0xFFEF4444); // kırmızı
        break;
      case 'Kiralandı':
        bgColor = const Color(0xFF3B82F6); // mavi
        break;
      case 'Onay Bekliyor':
        bgColor = const Color(0xFFF59E0B); // turuncu
        break;
      default:
        bgColor = Colors.grey.shade500;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bgColor.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: bgColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1),
      ),
      child: const Text(
        'Gizli',
        style: TextStyle(
          color: Color(0xFF374151),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  List<String> _computeAvailableOffices(List<TumIlanModel> ilanlar) {
    final set = <String>{};
    for (final ilan in ilanlar) {
      final t = ilan.connectedContactTitle.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return ['Tümü', ...list];
  }

  void _openFilterSheet() {
    String tmpStatus = _selectedStatusFilter;
    String tmpOffice = _selectedOfficeFilter;
    String tmpPerson = _personFilterOptions.contains(_selectedContactLabel)
        ? _selectedContactLabel
        : 'Tümü';
    int? tmpPersonNo = _selectedContactNo;

    const statusOptions = <String>[
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
    final officeOptions =
        _availableOffices.isEmpty ? const <String>['Tümü'] : _availableOffices;

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
                            const Icon(Icons.tune_rounded,
                                color: Color(0xFFE53935)),
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
                                  tmpStatus = 'Tümü';
                                  tmpPerson = 'Tümü';
                                  tmpPersonNo = null;
                                  if (_isAdmin) {
                                    tmpOffice = 'Tümü';
                                  }
                                });
                              },
                              child: const Text(
                                'Temizle',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FilterField(
                          label: 'Durum',
                          value: tmpStatus,
                          options: statusOptions,
                          icon: Icons.verified_rounded,
                          onChanged: (v) => setModalState(() => tmpStatus = v),
                        ),
                        const SizedBox(height: 12),
                        _PersonFilterField(
                          label: 'Kişi',
                          value: tmpPerson,
                          persons: _officePersons,
                          labelForPerson: (p) =>
                              _personLabelByContactNo[p.contactNo] ??
                              _personBaseTitle(p),
                          onChanged: (pick) => setModalState(() {
                            tmpPerson = pick.label;
                            tmpPersonNo = pick.contactNo;
                          }),
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(height: 12),
                          _FilterField(
                            label: 'Ofis Seçiniz',
                            value: tmpOffice,
                            options: officeOptions,
                            icon: Icons.apartment_rounded,
                            onChanged: (v) => setModalState(() => tmpOffice = v),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE53935),
                                  Color(0xFFD32F2F)
                                ],
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
                                setState(() {
                                  _selectedStatusFilter = tmpStatus;
                                  _selectedContactLabel = tmpPerson;
                                  _selectedContactNo = tmpPersonNo ??
                                      _contactNoForLabel(tmpPerson);
                                  if (_isAdmin) {
                                    _selectedOfficeFilter = tmpOffice;
                                  } else {
                                    _selectedOfficeFilter = 'Tümü';
                                  }
                                });
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                                _loadFirstPage();
                                Navigator.pop(context);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white),
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

  /// Durum rengini getir - listings_screen.dart'daki gibi
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: 'Tüm Portföyler',
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Tüm İlanlar');
        },
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader()),

              // Modern Search Bar - Sticky
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarDelegate(
                  searchController: _searchTextController,
                  onSearchChanged: _onSearchChanged,
                  onFilterPressed: _openFilterSheet,
                  hasActiveFilters: _hasActiveFilters,
                  activeFilterCount: _activeFilterCount,
                ),
              ),

              // İlanlar Listesi
              _buildSliverIlanlarList(),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 72),
              child: _buildScrollToTopButton(),
            ),
          ),
        ],
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
                // print('TumIlanScreen - Bottom Navbar - User Role Codes: $userRoleCodes');
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 3);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 3);
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 3);
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 3);
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 3);
                } else {
                  return const FrancahiseNavbar(currentIndex: 3);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 3);
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
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
            color: const Color(0xFFE53935).withValues(alpha: 0.28),
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
                  'Tüm Portföyler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ofis portföylerini keşfedin ve filtreleyin',
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
            onTap: _isLoading
                ? null
                : () => _loadFirstPage(refreshCache: true),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
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

  /// Sliver version of ilanlar list
  Widget _buildSliverIlanlarList() {
    if (_isLoading && _filteredIlanlar.isEmpty) {
      // Modern Skeleton Loading
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonCard(),
            childCount: 4, // 4 skeleton card göster
          ),
        ),
      );
    }

    if (_hasError && _filteredIlanlar.isEmpty) {
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
                  child: Icon(
              Icons.error_outline,
              size: 64,
                    color: Colors.red[400],
                  ),
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
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _loadAllIlanlarAutomatically(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tekrar Dene',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
            ),
          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredIlanlar.isEmpty) {
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
                      colors: [
                        Colors.grey[100]!,
                        Colors.grey[200]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_work,
                    size: 72,
                    color: Colors.grey[400],
            ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Henüz Portföy Bulunmuyor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
            Text(
                  'Aradığınız kriterlere uygun ilan bulunamadı.\nDaha sonra tekrar kontrol edin.',
              style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
              ),
                  textAlign: TextAlign.center,
            ),
          ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
          padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _filteredIlanlar.length) {
              if (_hasMoreIlanlar || _isLoadingMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFE53935),
                            ),
                          )
                        : TextButton(
                            onPressed: _loadMoreIlanlar,
                            child: const Text(
                              'Daha fazla yükle',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                );
              }
              return _buildEndOfList();
            }

            final ilan = _filteredIlanlar[index];
            return _buildIlanCard(ilan);
          },
          childCount: _filteredIlanlar.length + 1,
        ),
      ),
    );
  }

  Widget _buildIlanCard(TumIlanModel ilan) {
    return InkWell(
      onTap: () {
        // Detayları alt sayfa (bottom sheet) olarak göster
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return _PortfolioDetailBottomSheet(
              ilan: ilan,
              onOpenDetail: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TumIlanDetailScreen(
                      // Diğer ekranlarda olduğu gibi doğrudan listing id kullan
                      propertyId: ilan.id,
                      listingFromList: null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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
          // Resim Bölümü - Modern ve Yüksek
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  ),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                child: Stack(
                    fit: StackFit.expand,
                  children: [
                      _buildListingImage(ilan.coverImageS3Id),
                      // Gradient overlay for better badge visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 1.0],
                          ),
                        ),
                    ),
                      // Pasif overlay (satıldı/kiralandı PASİF değil)
                    if (ilan.showPassiveOverlay)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "PASİF Portföy",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                ),
                              ),
                              ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ),
              // Modern Badge - Top Left (Satılık/Kiralık) - metin padding (16) ile hizalı
              Positioned(
                top: 14,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ilan.typeText.toUpperCase(),
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
              if (ilan.internal)
                Positioned(
                  top: 14,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Gizli',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // İlan Detayları - Modern Spacing
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tarih ve Görüntülenme
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                Text(
                  ilan.formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                    fontSize: 12,
                        fontWeight: FontWeight.w500,
                  ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.visibility,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ilan.viewCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Portföy Durum Bilgisi (Aktif / Satıldı / Kiralandı / Onay Bekliyor)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildStatusChip(ilan.state),
                      if (ilan.internal) _buildInternalChip(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Başlık - Bold ve Modern
                Text(
                  ilan.title,
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
                
                // Konum - Icon ile birlikte
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                  ilan.location,
                        style: TextStyle(
                          color: Colors.grey[700],
                    fontSize: 14,
                          fontWeight: FontWeight.w500,
                  ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Metrekare ve Oda - Modern Chips
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.2),
                            width: 1,
                          ),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                              Icons.straighten,
                            color: Color(0xFFE53935),
                              size: 18,
                          ),
                            const SizedBox(width: 8),
                          Text(
                            ilan.areaInfo,
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.2),
                            width: 1,
                          ),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                              Icons.hotel,
                            color: Color(0xFFE53935),
                              size: 18,
                          ),
                            const SizedBox(width: 8),
                          Text(
                            ilan.roomInfo,
                            style: const TextStyle(
                              color: Color(0xFFE53935),
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
                
                // Fiyat - Vurgulu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.3),
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
                          fontWeight: FontWeight.w500,
                        ),
            ),
                      Flexible(
            child: Text(
                          ilan.formattedPrice,
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
            child: Divider(
              color: Colors.grey[200],
              thickness: 1,
              height: 0,
            ),
          ),
          
          // Emlakçı Bilgileri - Modern Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
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
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                // Emlakçı Bilgileri
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ilan.contactTitle,
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
                        ilan.contactTypeDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ilan.connectedContactTitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                      Text(
                        ilan.connectedContactTitle,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                        ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                      ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Contact Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone,
                      color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// S3'ten resim göstermek için widget builder
  Widget _buildListingImage(String? s3Id) {
    // S3 ID'si yoksa veya geçersizse "Resim Yok" göster
    if (!ImageUtils.isValidS3Id(s3Id)) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Resim Yok',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 240,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Resim başarıyla yüklendi
          return child;
        }
        // Resim yükleniyor - Modern shimmer
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Yükleniyor...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Resim yüklenemedi
    return Container(
          color: Colors.grey[200],
          child: Center(
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Icon(
                  Icons.broken_image,
                  size: 60,
                  color: Colors.grey[400],
            ),
                const SizedBox(height: 8),
            Text(
                  'Resim Yüklenemedi',
              style: TextStyle(
                    color: Colors.grey[500],
                fontSize: 14,
                    fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  /// Pagination loading widget - Modern Design
  /// Modern Skeleton Loading Card
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
          // Skeleton Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: _buildShimmerBox(height: 240, width: double.infinity),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and views skeleton
                Row(
                  children: [
                    _buildShimmerBox(height: 12, width: 80),
                    const Spacer(),
                    _buildShimmerBox(height: 12, width: 40),
                  ],
            ),
                const SizedBox(height: 12),
                
                // Title skeleton
                _buildShimmerBox(height: 18, width: double.infinity),
                const SizedBox(height: 8),
                _buildShimmerBox(height: 18, width: 200),
                const SizedBox(height: 8),
                
                // Location skeleton
                _buildShimmerBox(height: 14, width: 150),
                const SizedBox(height: 12),
                
                // Area and room skeleton
                Row(
                  children: [
                    Expanded(child: _buildShimmerBox(height: 40, width: double.infinity)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildShimmerBox(height: 40, width: double.infinity)),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Price skeleton
                _buildShimmerBox(height: 48, width: double.infinity),
              ],
            ),
          ),
          
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[200], thickness: 1, height: 0),
          ),
          
          // Agent info skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildShimmerBox(height: 44, width: 44, radius: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(height: 14, width: 120),
                      const SizedBox(height: 6),
                      _buildShimmerBox(height: 11, width: 80),
                    ],
                  ),
                ),
                _buildShimmerBox(height: 44, width: 44, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Box Widget with Animation
  Widget _buildShimmerBox({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[100]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                0.35,
                0.5,
                0.65,
                1.0,
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  /// End of list widget - Modern Design
  Widget _buildEndOfList() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Success Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 44,
            ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Tüm Portföyler Yüklendi! 🎉',
              style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Toplam ${_filteredIlanlar.length} ilan görüntüleniyor',
            style: const TextStyle(
              color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          // Scroll to Top Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
              'Başa dönmek için yukarı kaydırın',
              style: TextStyle(
                    color: Colors.white,
                fontSize: 12,
                    fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

}

/// Search Bar Delegate - Sticky header for search bar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;
  final int activeFilterCount;

  _SearchBarDelegate({
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 76.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
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
                      hintText: 'Portföy ara (konum, başlık, tür, danışman)...',
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
                                    color: const Color(0xFFE53935).withOpacity(0.1),
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
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.hasActiveFilters != hasActiveFilters ||
        oldDelegate.activeFilterCount != activeFilterCount;
  }
}

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
                    color: hasActiveFilters ? const Color(0xFFE53935) : const Color(0xFF6B7280),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  color: hasActiveFilters ? const Color(0xFFE53935) : const Color(0xFF6B7280),
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
          // Dropdown menüsünün arka planını beyaz zorla
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
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonPick {
  final String label;
  final int? contactNo;

  const _PersonPick({required this.label, this.contactNo});
}

class _PersonFilterField extends StatelessWidget {
  final String label;
  final String value;
  final List<OfficePersonsApiModel> persons;
  final String Function(OfficePersonsApiModel person) labelForPerson;
  final ValueChanged<_PersonPick> onChanged;

  const _PersonFilterField({
    required this.label,
    required this.value,
    required this.persons,
    required this.labelForPerson,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<_PersonPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PersonPickerSheet(
          label: label,
          selected: value,
          persons: persons,
          labelForPerson: labelForPerson,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
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
          child: Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 18, color: Color(0xFFE53935)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonPickerSheet extends StatefulWidget {
  final String label;
  final String selected;
  final List<OfficePersonsApiModel> persons;
  final String Function(OfficePersonsApiModel person) labelForPerson;

  const _PersonPickerSheet({
    required this.label,
    required this.selected,
    required this.persons,
    required this.labelForPerson,
  });

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_PersonPick> get _allOptions {
    return [
      const _PersonPick(label: 'Tümü'),
      ...widget.persons.map(
        (p) => _PersonPick(
          label: widget.labelForPerson(p),
          contactNo: p.contactNo,
        ),
      ),
    ];
  }

  List<_PersonPick> get _filtered {
    final q = _query.trim().toLowerCase();
    final options = _allOptions;
    if (q.isEmpty) return options;
    return options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Color(0xFFE53935)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _PersonPick(label: 'Tümü'),
                      ),
                      child: const Text(
                        'Tümü',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Kişi bulunamadı',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final selected = option.label == widget.selected;
                          return ListTile(
                            leading: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.person_outline_rounded,
                              color: selected
                                  ? const Color(0xFFE53935)
                                  : Colors.grey[400],
                            ),
                            title: Text(
                              option.label,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            onTap: () => Navigator.pop(context, option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  final String? s3Id;

  const _DetailImage({required this.s3Id});

  @override
  Widget build(BuildContext context) {
    // S3 ID'si yoksa karttaki placeholder mantığına benzer basit bir alan göster
    if (s3Id == null || !ImageUtils.isValidS3Id(s3Id)) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.home_work,
            size: 60,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    final imageUrl = ImageUtils.getCoverImageUrl(s3Id!);

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              strokeWidth: 3,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioDetailBottomSheet extends StatefulWidget {
  final TumIlanModel ilan;
  final VoidCallback onOpenDetail;

  const _PortfolioDetailBottomSheet({
    required this.ilan,
    required this.onOpenDetail,
  });

  @override
  State<_PortfolioDetailBottomSheet> createState() =>
      _PortfolioDetailBottomSheetState();
}

class _PortfolioDetailBottomSheetState
    extends State<_PortfolioDetailBottomSheet> {
  late final PageController _pageController;
  late final List<String> _imageIds;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final ids = <String?>[
      widget.ilan.coverImageS3Id,
      widget.ilan.pictureS3Id,
    ]
        .where((id) => id != null && ImageUtils.isValidS3Id(id))
        .cast<String>()
        .toList();

    _imageIds = ids;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ilan = widget.ilan;
    final statusText = _getStatusTextStatic(ilan.state);

    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fotoğraf galerisi - sağa/sola kaydırılabilir
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _imageIds.isEmpty
                          ? _DetailImage(s3Id: widget.ilan.coverImageS3Id)
                          : Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: _imageIds.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (context, index) =>
                                      _DetailImage(s3Id: _imageIds[index]),
                                ),
                                // Sayfa göstergesi
                                if (_imageIds.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _imageIds.length,
                                        (index) => Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _currentPage == index
                                                ? Colors.white
                                                : Colors.white
                                                    .withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ilan.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatusChipStatic(statusText),
                      if (ilan.internal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Gizli',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Önemli kısa bilgiler (m² ve oda)
                  _buildDetailRow(
                    icon: Icons.straighten,
                    label: 'Brüt / Net',
                    value: ilan.areaInfo,
                  ),
                  _buildDetailRow(
                    icon: Icons.meeting_room_outlined,
                    label: 'Oda',
                    value: ilan.roomInfo,
                  ),
                  _buildDetailRow(
                    icon: Icons.tag,
                    label: 'İlan No',
                    value: ilan.listingNo.toString(),
                  ),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Konum',
                    value: ilan.location,
                  ),
                  _buildDetailRow(
                    icon: Icons.sell_outlined,
                    label: 'Tür',
                    value: ilan.typeText,
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Fiyat',
                    value: ilan.formattedPrice,
                  ),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Danışman',
                    value: ilan.contactTitle,
                  ),
                  if (ilan.connectedContactTitle.isNotEmpty)
                    _buildDetailRow(
                      icon: Icons.apartment_rounded,
                      label: 'Ofis',
                      value: ilan.connectedContactTitle,
                    ),
                  const SizedBox(height: 16),
                  // Detay sayfasına git butonu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onOpenDetail,
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Color(0xFFE53935)),
                      label: const Text(
                        'Detay Sayfasına Git',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _getStatusTextStatic(String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
        return 'Yayında';
      case 'DRAFT':
        return 'Taslak';
      case 'WAITING_FOR_APPROVAL':
      case 'PENDING':
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
      case 'WAITING_FOR_CLOSE_APPROVAL':
      case 'CLOSURE_APPROVAL':
        return 'Kapama Onayı Bekliyor';
      default:
        return status;
    }
  }

  static Widget _buildStatusChipStatic(String statusText) {
    Color bgColor;
    switch (statusText) {
      case 'Yayında':
        bgColor = const Color(0xFF10B981);
        break;
      case 'Satıldı':
        bgColor = const Color(0xFFEF4444);
        break;
      case 'Kiralandı':
        bgColor = const Color(0xFF3B82F6);
        break;
      case 'Onay Bekliyor':
        bgColor = const Color(0xFFF59E0B);
        break;
      default:
        bgColor = Colors.grey.shade500;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: bgColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

