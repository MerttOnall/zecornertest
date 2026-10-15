import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/screens/list/edit_listing_screen.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'dart:math' as math;
import 'package:zecorner/presentation/screens/list/add_listing_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/models/list/media_model.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

// Listing model
class Listing {
  final String id;
  final String title;
  final String location;
  final String district;
  final String neighborhood;
  final String price;
  final String calender;
  final String type;
  final String status;
  final String consultant;
  final String area;
  final String rooms;
  final int viewCount;
  final String imageUrl;
  final bool isActive;
  final String? coverPicture; // Yeni eklenen alan
  final String? picture; // API'den gelen picture
  final List<MediaModel> medias; // Medias listesi

  Listing({
    required this.id,
    required this.title,
    required this.location,
    required this.district,
    required this.neighborhood,
    required this.price,
    required this.calender,
    required this.type,
    required this.status,
    required this.consultant,
    required this.area,
    required this.rooms,
    required this.viewCount,
    required this.imageUrl,
    required this.isActive,
    this.coverPicture, // Yeni eklenen alan
    this.picture, // API'den gelen picture
    required this.medias, // Medias listesi
  });

  String get fullLocation => '$location / $district / $neighborhood';

  // Create a copy with updated fields
  Listing copyWith({
    String? id,
    String? title,
    String? location,
    String? district,
    String? neighborhood,
    String? price,
    String? calender,
    String? type,
    String? status,
    String? consultant,
    String? area,
    String? rooms,
    int? viewCount,
    String? imageUrl,
    bool? isActive,
    String? coverPicture, // Yeni eklenen alan
    String? picture, // API'den gelen picture
    List<MediaModel>? medias, // Medias listesi
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      price: price ?? this.price,
      calender: calender ?? this.calender,
      type: type ?? this.type,
      status: status ?? this.status,
      consultant: consultant ?? this.consultant,
      area: area ?? this.area,
      rooms: rooms ?? this.rooms,
      viewCount: viewCount ?? this.viewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      coverPicture: coverPicture ?? this.coverPicture, // Yeni eklenen alan
      picture: picture ?? this.picture, // API'den gelen picture
      medias: medias ?? this.medias, // Medias listesi
    );
  }
}

// Global state manager for listings
class ListingsState extends ChangeNotifier {
  static final ListingsState _instance = ListingsState._internal();
  factory ListingsState() => _instance;
  ListingsState._internal();

  // API Repository
  final MyListingsRepository _myListingsRepo = MyListingsRepository();
  
  // State variables
  List<Listing> _listings = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalCount = 0;
  static const int _pageSize = 10;

  // Mock data for fallback
  
  List<Listing> get listings => List.unmodifiable(_listings);

  // Get listing by ID
  Listing? getListingById(String id) {
    try {
      return _listings.firstWhere((listing) => listing.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update a listing
  void updateListing(String id, Listing updatedListing) {
    final index = _listings.indexWhere((listing) => listing.id == id);
    if (index != -1) {
      _listings[index] = updatedListing;
      notifyListeners();
      
      // Show success message - this could be enhanced with a snackbar service
      print('✅ İlan güncellendi: ${updatedListing.title}');
    }
  }

  // Delete a listing
  void deleteListing(String id) {
    final listingTitle = getListingById(id)?.title ?? 'Bilinmeyen İlan';
    _listings.removeWhere((listing) => listing.id == id);
    notifyListeners();
    
    print('🗑️ İlan silindi: $listingTitle');
  }

  // Add a new listing
  void addListing(Listing listing) {
    _listings.add(listing);
    notifyListeners();
    
    print('➕ Yeni ilan eklendi: ${listing.title}');
  }

  // Simulate API call delay
  Future<void> _simulateApiDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // API-ready methods (will be easy to replace with actual API calls)
  Future<Listing?> fetchListingById(String id) async {
    await _simulateApiDelay();
    return getListingById(id);
  }

  Future<void> saveListingChanges(String id, Listing updatedListing) async {
    await _simulateApiDelay();
    updateListing(id, updatedListing);
  }

  Future<void> removeListingById(String id) async {
    await _simulateApiDelay();
    deleteListing(id);
  }

  // API Methods
  Future<void> loadListingsFromAPI({
    int page = 1,
    bool refresh = false,
    String? state,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final safePage = page < 1 ? 1 : page;
      final result = await _myListingsRepo.getMyListings(
        page: safePage,
        pageSize: _pageSize,
        state: state,
        contact: 'all',
        office: '',
      );

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          // Mock data fallback'i tamamen kaldırıldı
          if (refresh || safePage <= 1) {
            _listings = [];
          }
          notifyListeners();
          print('❌ API Error: ${failure.message}');
        },
        (listingResponse) {
          if (refresh || safePage <= 1) {
            _listings = _convertApiListingsToLocal(listingResponse.listings);
          } else {
            _listings.addAll(_convertApiListingsToLocal(listingResponse.listings));
          }
          _currentPage = listingResponse.page;
          _totalPages = listingResponse.totalPages;
          _totalCount = listingResponse.totalCount;
          _isLoading = false;
          notifyListeners();
          print('✅ API Success: ${listingResponse.listings.length} listings loaded');
          print('📊 Total Count: ${listingResponse.totalCount}');
          print('📄 Total Pages: ${listingResponse.totalPages}');
        },
      );
    } catch (e) {
      _errorMessage = 'Beklenmeyen hata: $e';
      _isLoading = false;
      // Mock data fallback'i tamamen kaldırıldı
      if (refresh || page <= 1) {
        _listings = [];
      }
      notifyListeners();
      print('❌ Unexpected Error: $e');
    }
  }

  /// Fiyatı tam formatına çevirir (örn: 2500000 → "₺2.500.000")
  String _formatFullPrice(int price) {
    if (price == 0) return 'Fiyat Görüşülür';
    return '₺${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Convert API ListingPanelModel to local Listing
  List<Listing> _convertApiListingsToLocal(List<ListingPanelModel> apiListings) {
    return apiListings.map((apiListing) => Listing(
      id: apiListing.id,
      title: apiListing.title,
      location: apiListing.provinceName,
      district: apiListing.districtName,
      neighborhood: apiListing.quarterName,
      price: _formatFullPrice(apiListing.price), // Tam format kullan
      calender: apiListing.formattedDate,
      type: apiListing.displayType,
      status: apiListing.displayState,
      consultant: apiListing.contactTitle,
      area: apiListing.area,
      rooms: apiListing.rooms,
      viewCount: apiListing.viewCount,
      imageUrl: apiListing.imageUrl,
      isActive: apiListing.state == 'LIVE',
      coverPicture: apiListing.coverPicture, // Yeni eklenen alan
      picture: apiListing.picture, // API'den picture verisi geçiriliyor
      medias: apiListing.medias, // API'den medias verisi geçiriliyor
    )).toList();
  }

  // Getters for state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
}

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _searchController;
  late final Animation<double> _floatingAnimation;
  late final Animation<double> _searchExpandAnimation;
  Timer? _searchTimer;

  // Search and filter variables
  bool _isSearchExpanded = false;
  final TextEditingController _searchTextController = TextEditingController();
  String _selectedStatus = 'Tümü';
  List<Listing> _filteredListings = [];

  // State manager instance
  final ListingsState _listingsState = ListingsState();

  @override
  void initState() {
    super.initState();
    
    // Listen to listings state changes
    _listingsState.addListener(_onListingsChanged);
    _scrollController.addListener(_onListingsScroll);
    
    // Initialize filtered listings
    _filteredListings = _listingsState.listings;

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );

    _searchExpandAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    );

    _searchController.addListener(() {
      _filterListings();
    });

    // Load initial data from API - WidgetsBinding ile sararak setState hatasını önlüyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listingsState.loadListingsFromAPI(refresh: true);
    });
  }

  @override
  void dispose() {
    _listingsState.removeListener(_onListingsChanged);
    _scrollController.dispose();
    _rotationController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onListingsChanged() {
    _filterListings();
  }

  void _onListingsScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 360) return;
    final hasMore = _listingsState.totalCount > 0
        ? _listingsState.listings.length < _listingsState.totalCount
        : _listingsState.currentPage + 1 < _listingsState.totalPages;
    if (!_listingsState.isLoading && hasMore) {
      _listingsState.loadListingsFromAPI(
        page: _listingsState.currentPage + 1,
        state: _listingsApiState,
      );
    }
  }

  String? get _listingsApiState {
    switch (_selectedStatus) {
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

  Future<void> _reloadListingsForStatus() async {
    await _listingsState.loadListingsFromAPI(
      refresh: true,
      state: _listingsApiState,
    );
    if (mounted) _filterListings();
  }

  void _filterListings() {
    setState(() {
      _filteredListings = _listingsState.listings.where((listing) {
        bool matchesSearch = true;
        bool matchesStatus = true;

        // Search filter
        if (_searchTextController.text.isNotEmpty) {
          String searchTerm = _searchTextController.text.toLowerCase();
          matchesSearch = listing.title.toLowerCase().contains(searchTerm) ||
              listing.location.toLowerCase().contains(searchTerm) ||
              listing.district.toLowerCase().contains(searchTerm) ||
              listing.neighborhood.toLowerCase().contains(searchTerm) ||
              listing.consultant.toLowerCase().contains(searchTerm) ||
              listing.type.toLowerCase().contains(searchTerm);
        }

        // Status filter (Satıldı/Kiralandı/Yayında API'den gelir)
        if (_selectedStatus != 'Tümü' && _listingsApiState == null) {
          matchesStatus = listing.status == _selectedStatus;
        }

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchController.forward();
      } else {
        _searchController.reverse();
        _searchTextController.clear();
        _filterListings();
      }
    });
  }

  // Navigate directly to edit listing screen
  void _navigateToEditListing(String listingId) async {
    // Get the listing data from state
    final listing = _listingsState.getListingById(listingId);
    
    if (listing != null) {
      // Navigate to edit screen with listing data
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditListingScreen(
            listing: listing,
            onListingUpdated: (updatedListing) {
              // Update the listing in state
              _listingsState.updateListing(listingId, updatedListing);
              _showUpdateMessage('İlan başarıyla güncellendi!');
            },
            onListingDeleted: (deletedListingId) {
              // Remove the listing from state
              _listingsState.deleteListing(deletedListingId);
              _showUpdateMessage('İlan başarıyla silindi!');
            },
          ),
        ),
      );

      // Handle any result from edit screen if needed
      if (result != null && result is Map<String, dynamic>) {
        if (result['action'] == 'updated') {
          _showUpdateMessage('İlan başarıyla güncellendi!');
        } else if (result['action'] == 'deleted') {
          _showUpdateMessage('İlan başarıyla silindi!');
        }
      }
    } else {
      // Show error if listing not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan bulunamadı!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBackgroundWidget(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        // Role sistemine göre sidebar seçimi
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'İlanlarım');
          },
        ),
        onDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
        },
        drawerScrimColor: Colors.black54,
        drawerEdgeDragWidth: 0,
        appBar: AdminPanelAppBar(
          title: "İlanlar",
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -10 * _floatingAnimation.value),
              child: child,
            );
          },
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddListingScreen(),
                ),
              );

              // Handle result from add screen
              if (result != null && result['action'] == 'created') {
                _showUpdateMessage('İlan başarıyla oluşturuldu!');
              }
            },
            backgroundColor: const Color(0xFFE53935),
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            label: const Text(
              "İlan Ekle",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          child: AbsorbPointer(
            absorbing: _isDrawerOpen,
            child: Stack(
              children: [
                // Arka plan animasyonları
                Positioned(
                  right: -100,
                  top: -100,
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -100,
                  bottom: -100,
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                  ),
                ),
                // Ana içerik
                Column(
                  children: [
                    // Modern Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top Row with status dropdown and search icon
                          Row(
                            children: [
                              // Status Dropdown
                              Expanded(
                                child: Container(
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedStatus != 'Tümü'
                                          ? const Color(0xFFE53935)
                                              .withOpacity(0.3)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: _selectedStatus != 'Tümü'
                                            ? const Color(0xFFE53935)
                                            : Colors.grey[600],
                                      ),
                                      items: [
                                        "Tümü",
                                        "İptal",
                                        "Süresi Doldu",
                                        "Yayında",
                                        "Taslak",
                                        "Onay Bekliyor",
                                        "Düzenleme İsteniyor",
                                        "Onaylanmadı",
                                        "Kiralandı",
                                        "Satıldı"
                                      ]
                                          .map((e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  style: TextStyle(
                                                    color: e != 'Tümü'
                                                        ? Colors.black87
                                                        : Colors.grey[600],
                                                    fontWeight:
                                                        e == _selectedStatus
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedStatus = value!;
                                        });
                                        _reloadListingsForStatus();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Search Toggle Button
                              Container(
                                height: 45,
                                width: 45,
                                decoration: BoxDecoration(
                                  color: _isSearchExpanded
                                      ? const Color(0xFFE53935)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSearchExpanded
                                        ? const Color(0xFFE53935)
                                        : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _toggleSearch,
                                    child: Icon(
                                      _isSearchExpanded
                                          ? Icons.close
                                          : Icons.search,
                                      color: _isSearchExpanded
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Expandable Search Field
                          AnimatedBuilder(
                            animation: _searchExpandAnimation,
                            builder: (context, child) {
                              return Container(
                                height: _searchExpandAnimation.value * 60,
                                child: _searchExpandAnimation.value > 0.1
                                    ? Opacity(
                                        opacity: _searchExpandAnimation.value,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: TextField(
                                            controller: _searchTextController,
                                            onChanged: (value) {
                                              // 300ms debounce
                                              _searchTimer?.cancel();
                                              _searchTimer = Timer(const Duration(milliseconds: 300), _filterListings);
                                            },
                                            decoration: InputDecoration(
                                              hintText:
                                                  "İlan başlığı, konum, danışman ile arayın...",
                                              hintStyle: TextStyle(
                                                  color: Colors.grey[500]),
                                              prefixIcon: Icon(
                                                Icons.search_outlined,
                                                color: const Color(0xFFE53935),
                                                size: 22,
                                              ),
                                              suffixIcon: _searchTextController
                                                      .text.isNotEmpty
                                                  ? IconButton(
                                                      icon: Icon(
                                                        Icons.clear,
                                                        color: Colors.grey[500],
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _searchTextController
                                                            .clear();
                                                        _filterListings();
                                                      },
                                                    )
                                                  : null,
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE53935),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              );
                            },
                          ),
                          // Results Counter
                          if (_searchTextController.text.isNotEmpty ||
                              _selectedStatus != 'Tümü')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${_filteredListings.length} ilan bulundu",
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_searchTextController.text.isNotEmpty ||
                                      _selectedStatus != 'Tümü')
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchTextController.clear();
                                          _selectedStatus = 'Tümü';
                                        });
                                        _reloadListingsForStatus();
                                      },
                                      icon: const Icon(
                                        Icons.clear_all,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      label: const Text(
                                        "Temizle",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Error Message
                    if (_listingsState.errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _listingsState.errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red[600], size: 20),
                              onPressed: () {
                                // Error will be cleared on next API call
                              },
                            ),
                          ],
                        ),
                      ),
                    // Loading Indicator
                    if (_listingsState.isLoading && _filteredListings.isEmpty)
                      const Expanded(
                        child: AppStatusView.loading(
                          title: 'İlanlar hazırlanıyor.',
                          message: 'İlan listeniz yüklenirken lütfen bekleyin.',
                        ),
                      )
                    else
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFFE53935),
                          onRefresh: () async {
                            await _reloadListingsForStatus();
                          },
                          child: _filteredListings.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.62,
                                    child: AppStatusView.missing(
                                      title: 'İlan bulunamadı',
                                      message:
                                          'Arama kriterlerinize uygun ilan yok. Filtreleri değiştirerek tekrar deneyin.',
                                      icon: Icons.home_work_outlined,
                                      retryLabel: 'Filtreleri Temizle',
                                      onRetry: () {
                                        setState(() {
                                          _searchTextController.clear();
                                          _selectedStatus = 'Tümü';
                                        });
                                        _reloadListingsForStatus();
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredListings.length +
                                    ((_listingsState.totalCount > 0 &&
                                            _listingsState.listings.length <
                                                _listingsState.totalCount) ||
                                            _listingsState.isLoading
                                        ? 1
                                        : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredListings.length) {
                                    return _buildLoadMoreButton();
                                  }
                                  return _buildListingCard(
                                      _filteredListings[index]);
                                },
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
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
                  print('Listings Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                  
                  // Web sitesindeki mantığa göre navbar seçimi
                  if (userRoleCodes.contains('role_admin')) {
                    return const AdminNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  } else if (userRoleCodes.contains('role_advisor')) {
                    return const DanismanNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                    return const BrokerNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                    return const BrokerNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                    return const BrokerNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  } else {
                    return const FrancahiseNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
                  }
                },
              );
            }
            return const AdminNavbar(currentIndex: 3); // Listings is the 4th tab (index 3)
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Center(
        child: _listingsState.isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFE53935),
                ),
              )
            : TextButton(
                onPressed: () => _listingsState.loadListingsFromAPI(
                  page: _listingsState.currentPage + 1,
                  state: _listingsApiState,
                ),
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

  Widget _buildListingCard(Listing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToEditListing(listing.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        _buildListingImage(listing.coverPicture ?? listing.imageUrl),
                        if (!listing.isActive)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(
                                child: Text(
                                  "PASİF",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          listing.type == 'Kiralık' ? Colors.blue : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      listing.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.fullLocation,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      children: [
                        _buildFeature(Icons.square_foot, "${listing.area} m²"),
                        _buildFeature(
                            Icons.meeting_room_outlined, listing.rooms),
                        _buildFeature(Icons.remove_red_eye_outlined,
                            "${listing.viewCount} Görüntülenme"),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Eklenme Tarihi",
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    listing.calender,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                listing.price,
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(71, 85, 105, 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.consultant,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          "Gayrimenkul Danışmanı",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(listing.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Yayında':
        return Colors.green;
      case 'Taslak':
        return Colors.orange;
      case 'Onay Bekliyor':
        return Colors.blue;
      case 'Kiralandı':
      case 'Satıldı':
        return Colors.purple;
      case 'İptal':
      case 'Süresi Doldu':
      case 'Onaylanmadı':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFeature(IconData icon, String text) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// S3'ten resim göstermek için widget builder
  Widget _buildListingImage(String? s3Id) {
    // S3 ID'si yoksa veya geçersizse "Resim Yok" göster
    if (!ImageUtils.isValidS3Id(s3Id)) {
      print('⚠️ Resim ID yok veya geçersiz: $s3Id');
      return ImageUtils.getNoImageWidget(size: 40);
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);
    print('🖼️ Resim yükleniyor: ${s3Id?.substring(0, 8)}...');

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
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
        return ImageUtils.getFailedImageWidget(size: 40);
      },
    );
  }
}