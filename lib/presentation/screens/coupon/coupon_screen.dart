import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/coupon_cubit.dart';
import 'package:zecorner/infrastructure/coupon/coupon_api_repository.dart';
import 'package:zecorner/models/coupon/coupon_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/screens/coupon/add_coupon_screen.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_admin_guard.dart';
import 'package:zecorner/presentation/screens/coupon/edit_coupon_screen.dart';
import 'package:intl/intl.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({Key? key}) : super(key: key);

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen>
    with SingleTickerProviderStateMixin, CouponAdminGuard {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  String _selectedStatusFilter = 'Tümü';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late CouponCubit _couponCubit;

  @override
  void initState() {
    super.initState();
    _couponCubit = CouponCubit(CouponApiRepository());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkCouponAdminAccess(onAllowed: () => _couponCubit.loadCoupons());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _couponCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _couponCubit.loadMoreCoupons();
    }
  }

  void _onStatusFilterChanged(String filter) {
    setState(() {
      _selectedStatusFilter = filter;
    });
    if (filter == 'Tümü') {
      _couponCubit.clearStatusFilterOnly();
    } else {
      _couponCubit.filterByStatus(filter);
    }
  }

  void _onSearch(String _) {
    setState(() {});
  }

  /// Kartta görünen isim / başlık / tür ile eşleşme (API araması güvenilir olmadığı için istemci tarafı).
  String _normalizeCouponSearch(String s) {
    var t = s.trim();
    if (t.isEmpty) return '';
    t = t.replaceAll('İ', 'i').replaceAll('ı', 'i');
    t = t.toLowerCase();
    return t
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  List<CouponModel> _applyLocalCouponSearch(List<CouponModel> source) {
    final q = _normalizeCouponSearch(_searchController.text);
    if (q.isEmpty) return source;
    return source.where((c) {
      final haystack = _normalizeCouponSearch(
        '${c.name} ${c.title} ${c.typeText}',
      );
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _onRefresh() async {
    await _couponCubit.refreshCoupons();
  }

  Future<void> _openAddCouponScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCouponScreen(),
      ),
    );
    if (result == true && mounted) {
      _couponCubit.refreshCoupons();
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Color _getStatusColor(bool isActive) {
    return isActive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
  }

  Future<void> _openEditCoupon(CouponModel coupon) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCouponScreen(coupon: coupon),
      ),
    );
    if (result == true && mounted) {
      _couponCubit.refreshCoupons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = couponAccessGate();
    if (gate != null) return gate;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Kuponlar');
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
        title: 'Kuponlar',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      bottomNavigationBar: const AdminNavbar(currentIndex: 0),
      body: BlocBuilder<CouponCubit, CouponState>(
        bloc: _couponCubit,
        builder: (context, state) {
          return GestureDetector(
            onTap: () {
              if (_isDrawerOpen) {
                _scaffoldKey.currentState?.closeDrawer();
              }
              FocusScope.of(context).unfocus();
            },
            child: AbsorbPointer(
              absorbing: _isDrawerOpen,
              child: SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: const Color(0xFFE53935),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                      // Search & Filter
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            children: [
                              // Modern Search Bar with Kırmızı accent
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE53935).withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearch,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                    letterSpacing: -0.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Kupon ara...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.1,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFE53935).withOpacity(0.2),
                                            const Color(0xFFE53935).withOpacity(0.12),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE53935).withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE53935).withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 14),
                              
                              // Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildFilterChip('Tümü'),
                                    const SizedBox(width: 10),
                                    _buildFilterChip('Aktif'),
                                    const SizedBox(width: 10),
                                    _buildFilterChip('Pasif'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content based on state
                      if (state is CouponLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else if (state is CouponError)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Bir hata oluştu',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.failure.message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _onRefresh,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Tekrar Dene'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53935),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (state is CouponLoaded || state is CouponLoadingMore || state is CouponDeleting || state is CouponDeleteError)
                        ..._buildCouponListSlivers(state)
                      else
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                      
                      // Bottom padding — liste ile FAB çakışmasın
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 88),
                      ),
                    ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 8,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 8,
                        shadowColor: const Color(0xFFE53935).withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _openAddCouponScreen,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE53935),
                                  Color(0xFFD32F2F),
                                  Color(0xFFC62828),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 32,
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
        },
      ),
    );
  }

  /// Build coupon list slivers based on state
  List<Widget> _buildCouponListSlivers(CouponState state) {
    List<CouponModel> coupons = [];
    bool isLoadingMore = false;
    String? deletingCouponId;
    String? errorMessage;
    
    if (state is CouponLoaded) {
      coupons = state.allCoupons;
      print('📱 CouponScreen: CouponLoaded state - ${coupons.length} kupon gösterilecek');
    } else if (state is CouponLoadingMore) {
      coupons = state.currentCoupons;
      isLoadingMore = true;
      print('📱 CouponScreen: CouponLoadingMore state - ${coupons.length} kupon gösterilecek');
    } else if (state is CouponDeleting) {
      coupons = state.currentCoupons;
      deletingCouponId = state.deletingCouponId;
      print('📱 CouponScreen: CouponDeleting state - ${coupons.length} kupon, silinen: $deletingCouponId');
    } else if (state is CouponDeleteError) {
      coupons = state.currentCoupons;
      errorMessage = state.errorMessage;
      print('📱 CouponScreen: CouponDeleteError state - ${coupons.length} kupon, hata: $errorMessage');
      // Hata mesajı göster
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage ?? 'Kupon silinemedi')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }

    coupons = _applyLocalCouponSearch(coupons);
    
    if (coupons.isEmpty) {
      print('⚠️ CouponScreen: Kupon listesi boş!');
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE53935).withOpacity(0.15),
                          const Color(0xFFE53935).withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      size: 52,
                      color: const Color(0xFFE53935).withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kupon bulunamadı',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Farklı bir filtre deneyin veya\narama teriminizi değiştirin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final coupon = coupons[index];
              final isDeleting = deletingCouponId != null && coupon.id == deletingCouponId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCouponCard(coupon, isDeleting: isDeleting),
              );
            },
            childCount: coupons.length,
          ),
        ),
      ),
      if (isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
                strokeWidth: 2,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedStatusFilter == label;
    final redAccent = const Color(0xFFE53935);

    IconData chipIcon;
    if (label == 'Aktif') {
      chipIcon = Icons.check_circle_rounded;
    } else if (label == 'Pasif') {
      chipIcon = Icons.cancel_rounded;
    } else {
      chipIcon = Icons.filter_list_rounded;
    }

    return GestureDetector(
      onTap: () => _onStatusFilterChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 18,
          vertical: isSelected ? 12 : 11,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    redAccent,
                    redAccent.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? redAccent.withOpacity(0.3) : Colors.grey.shade200,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: redAccent.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: redAccent.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  chipIcon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Icon(
                chipIcon,
                size: 16,
                color: label == 'Tümü'
                    ? redAccent.withOpacity(0.7)
                    : redAccent.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : label == 'Tümü'
                        ? redAccent
                        : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon, {bool isDeleting = false}) {
    final isExpired = coupon.isExpired;
    final isActive = coupon.isActive;
    final redAccent = const Color(0xFFE53935);

    return GestureDetector(
      onTap: isDeleting ? null : () => _openEditCoupon(coupon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? redAccent.withOpacity(0.25)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? Colors.black.withOpacity(0.04)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [
                              redAccent,
                              redAccent.withOpacity(0.8),
                              redAccent.withOpacity(0.5),
                            ]
                          : [
                              Colors.grey.shade400,
                              Colors.grey.shade400.withOpacity(0.6),
                              Colors.grey.shade400.withOpacity(0.3),
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              if (!isActive)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

              if (isExpired)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              
              // Deleting overlay
              if (isDeleting)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Kupon siliniyor...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row - Icon, Title, Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFFD32F2F),
                                      Color(0xFFC62828),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade400,
                                      Colors.grey.shade500,
                                      Colors.grey.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: isActive
                                    ? const Color(0xFFE53935).withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        
                        const SizedBox(width: 14),
                        
                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with status badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      coupon.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: isActive
                                            ? const Color(0xFF1F2937)
                                            : Colors.grey.shade600,
                                        letterSpacing: -0.4,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(isActive).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _getStatusColor(isActive).withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getStatusColor(isActive).withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(isActive),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getStatusColor(isActive).withOpacity(0.2),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          coupon.statusText,
                                          style: TextStyle(
                                            color: _getStatusColor(isActive),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? redAccent.withOpacity(0.1)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? redAccent.withOpacity(0.25)
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  coupon.typeText,
                                  style: TextStyle(
                                    color: isActive
                                        ? redAccent
                                        : Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
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
                    
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildCouponMetricRow(
                            'İndirim',
                            coupon.discountText,
                          ),
                          Divider(height: 20, thickness: 1, color: Colors.grey.shade200),
                          _buildCouponMetricRow(
                            'Adet',
                            coupon.amount.toString(),
                          ),
                          Divider(height: 20, thickness: 1, color: Colors.grey.shade200),
                          _buildCouponMetricRow(
                            'Son kullanma',
                            _formatDateTime(coupon.validUntil),
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
      ),
    );
  }

  Widget _buildCouponMetricRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

