import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/router/app_router.dart';

class PortfolioApproveScreen extends StatefulWidget {
  const PortfolioApproveScreen({super.key});

  @override
  State<PortfolioApproveScreen> createState() => _PortfolioApproveScreenState();
}

class _PortfolioApproveScreenState extends State<PortfolioApproveScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  Timer? _searchTimer;

  // Search and filter variables
  final TextEditingController _searchTextController = TextEditingController();
  /// null = tümü (web radyoları gibi seçim yok)
  String? _selectedListingType;
  List<ListingPanelModel> _filteredListings = [];
  List<ListingPanelModel> _allListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  final MyListingsRepository _repository = MyListingsRepository();
  final NumberFormat _priceFormatter = NumberFormat('#,###', 'tr_TR');

  static const Color _primary = Color(0xFFE53935);
  static const Color _primaryLight = Color(0xFFFFEBEE);
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAccess());
  }

  Future<void> _guardAccess() async {
    final auth = context.read<AuthCubit>();
    final codes = await auth.getUserRoleCodes();
    if (!mounted) return;
    final allowed = codes.contains('role_office_broker') && !auth.isAdmin;
    if (!allowed) {
      Navigator.of(context).pop();
      return;
    }
    _loadListings();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _searchTextController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.getListingsPendingApproval(
        page: 1,
        pageSize: 100,
        search: _searchTextController.text.trim().isNotEmpty
            ? _searchTextController.text.trim()
            : null,
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
            _allListings = [];
            _filteredListings = [];
          });
        },
        (response) {
          setState(() {
            _isLoading = false;
            _allListings = response.listings;
            _filteredListings = response.listings;
          });
          _applyFilters();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Onay bekleyen portföyler yüklenirken hata oluştu: $e';
        _allListings = [];
        _filteredListings = [];
      });
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
    return listing.displayType;
  }

  bool _matchesSearch(ListingPanelModel listing, String query) {
    if (query.isEmpty) return true;
    final haystack = _fold(
      '${listing.title} ${listing.fullLocation} ${listing.contactTitle} '
      '${listing.connectedContactTitle} ${listing.listingNo} '
      '${_listingTypeLabel(listing)} ${listing.displayRealEstateType} '
      '${listing.area} ${listing.rooms} ${listing.price} '
      '${listing.displayState}',
    );
    return haystack.contains(query);
  }

  void _applyFilters() {
    final query = _fold(_searchTextController.text.trim());
    setState(() {
      _filteredListings = _allListings.where((listing) {
        final matchesType = _selectedListingType == null ||
            _listingTypeLabel(listing) == _selectedListingType;
        return matchesType && _matchesSearch(listing, query);
      }).toList();
    });
  }

  void _clearFilters() {
    _searchTimer?.cancel();
    setState(() {
      _selectedListingType = null;
      _searchTextController.clear();
    });
    _applyFilters();
  }

  void _onListingTypeSelected(String type) {
    setState(() {
      // Aynı tipe tekrar tıklanınca seçimi kaldır (web gibi)
      _selectedListingType =
          _selectedListingType == type ? null : type;
    });
    _applyFilters();
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _applyFilters();
    });
    setState(() {}); // clear ikonu için
  }

  String _formatPrice(ListingPanelModel listing) {
    if (listing.price == 0) return 'Fiyat Görüşülür';
    final symbol =
        listing.currency == 'TRY' || listing.currency == 'TL' ? '₺' : '';
    return '$symbol${_priceFormatter.format(listing.price)}';
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return const RoleSidebar(currentPage: 'Portföy Onay');
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
        title: "Portföy Onay",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_office_broker') || 
                          userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_form_applications') || 
                          userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_sale_applications') || 
                          userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else {
                  return const FrancahiseNavbar(currentIndex: -1);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: -1);
        },
      ),
      body: AnimatedBackgroundWidget(
        child: GestureDetector(
          onTap: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          child: AbsorbPointer(
            absorbing: _isDrawerOpen,
            child: Stack(
              children: [
                // Sağ üst animasyon
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
                // Sol alt animasyon
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
                // Orta kısım için ekstra animasyon
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 200,
                  top: MediaQuery.of(context).size.height / 2 - 200,
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * math.pi,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                  ),
                ),
                // Ana içerik
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadListings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildModernFilterBar(),
                      // Portfolio List
                      Expanded(
                        child: _filteredListings.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _primary.withOpacity(0.15),
                                              _primary.withOpacity(0.08),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _primary.withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.description_outlined,
                                          size: 64,
                                          color: _primary.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      const Text(
                                        'Onay Bekleyen Portföy Bulunamadı',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF374151),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                        ),
                                        child: Text(
                                          'Henüz kayıt yok veya sonuç bulunamadı, varsa filtrenizi değiştirerek tekrar deneyiniz.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed: _loadListings,
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Tekrar Dene',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadListings,
                                color: _primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredListings.length,
                                  itemBuilder: (context, index) {
                                    return _buildListingCard(
                                      _filteredListings[index],
                                    );
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
      ),
    );
  }

  Widget _buildModernFilterBar() {
    final hasActiveFilter = _selectedListingType != null ||
        _searchTextController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildListingTypeRadio(
                    label: 'Satılık',
                    selected: _selectedListingType == 'Satılık',
                    onTap: () => _onListingTypeSelected('Satılık'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildListingTypeRadio(
                    label: 'Kiralık',
                    selected: _selectedListingType == 'Kiralık',
                    onTap: () => _onListingTypeSelected('Kiralık'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: hasActiveFilter ? _clearFilters : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  disabledForegroundColor: _textMuted,
                  side: BorderSide(
                    color: hasActiveFilter ? _primary : _border,
                    width: 1.4,
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Filtreyi Temizle',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasActiveFilter
                      ? _primary.withOpacity(0.35)
                      : _border,
                ),
              ),
              child: TextField(
                controller: _searchTextController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Arayın...',
                  hintStyle: const TextStyle(
                    color: _textMuted,
                    fontSize: 14.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _primary,
                  ),
                  suffixIcon: _searchTextController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _textMuted,
                          ),
                          onPressed: () {
                            _searchTextController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingTypeRadio({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _primary : _border,
              width: selected ? 1.6 : 1,
            ),
            color: selected ? _primaryLight : Colors.white,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _primary : _textMuted,
                    width: 2,
                  ),
                  color: Colors.white,
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? _primary : _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(ListingPanelModel listing) {
    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.pushNamed(
          context,
          AppRouter.portfolioApproveDetail,
          arguments: {
            'listingId': listing.id,
            'contactNo': listing.contactNo,
          },
        );
        if (refreshed == true) {
          _loadListings();
        }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _listingTypeLabel(listing).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (listing.internal)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Gizli',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ClipRRect(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildListingImage(listing.coverPicture),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.fullLocation,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeature(
                      Icons.square_foot,
                      listing.area != 'N/A' ? '${listing.area} m²' : '-',
                    ),
                    const SizedBox(width: 16),
                    _buildFeature(
                      Icons.meeting_room_outlined,
                      listing.rooms != 'N/A' ? listing.rooms : '-',
                    ),
                    const Spacer(),
                    Text(
                      listing.displayRealEstateType,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatPrice(listing),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'İlan No: ${listing.listingNo}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.displayState,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.contactTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (listing.contactTypeDescription.isNotEmpty)
                        Text(
                          listing.contactTypeDescription,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(listing.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
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

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildListingImage(String? s3Id) {
    if (!ImageUtils.isValidS3Id(s3Id)) {
      return ImageUtils.getNoImageWidget(size: 50);
    }

    final imageUrl = ImageUtils.getCoverImageUrl(s3Id);

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return ImageUtils.getLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        return ImageUtils.getFailedImageWidget(size: 50);
      },
    );
  }
}
