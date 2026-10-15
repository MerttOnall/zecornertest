import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/infrastructure/customer/customer_api_repository.dart';
import 'package:zecorner/models/customer/customer_api_model.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';

class SaticiCustomerScreen extends StatefulWidget {
  const SaticiCustomerScreen({super.key});

  @override
  State<SaticiCustomerScreen> createState() => _SaticiCustomerScreenState();
}

class _SaticiCustomerScreenState extends State<SaticiCustomerScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  
  // API ve state yönetimi
  final CustomerApiRepository _customerRepository = CustomerApiRepository();
  List<CustomerApiModel> _customers = [];
  bool _isLoading = false;
  bool _isPaging = false;
  String _errorMessage = '';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  int _loadGeneration = 0;
  bool _matchOnCard = false;
  bool _pendingSearchReplace = false;
  int _requestLimit = 10;
  final List<CustomerApiModel> _searchHits = [];
  final Set<int> _seenContactNos = {};
  static const int _pageSize = 10;
  static const int _customerType = 202;
  
  // Arama ve sayfalama
  Timer? _searchTimer;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // API'den Satıcı müşterileri yükle
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // API: web ile aynı ?type=202&page=1&searchText=&pageSize=10
  Future<void> _loadCustomers({
    bool refresh = false,
    bool loadMore = false,
    bool keepPrevious = false,
    bool cardSearch = false,
  }) async {
    if (loadMore) {
      if (_isLoading || !_hasMore) return;
    } else if (_isLoading && !refresh) {
      return;
    }

    if (!loadMore) {
      _loadGeneration++;
      _matchOnCard = cardSearch;
      _requestLimit = cardSearch ? 100 : _pageSize;
      _seenContactNos.clear();
      _searchHits.clear();
      _pendingSearchReplace = keepPrevious;
    }
    final generation = _loadGeneration;
    final page = loadMore ? _currentPage + 1 : 1;
    final search = _searchQuery.trim();
    final limit = _requestLimit;

    setState(() {
      _isLoading = true;
      _isPaging = loadMore && !_pendingSearchReplace;
      _errorMessage = '';
      if (!loadMore) {
        _currentPage = 1;
        _totalCount = 0;
        _hasMore = true;
        if (!keepPrevious) _customers.clear();
      }
    });

    try {
      final result = await _customerRepository.getCustomers(
        page: page,
        limit: limit,
        searchText: _matchOnCard || search.isEmpty ? null : search,
        type: _customerType,
      );

      if (!mounted || generation != _loadGeneration) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _isPaging = false;
            _errorMessage = _getErrorMessage(failure);
            if (loadMore) _hasMore = false;
          });
        },
        (customersResponse) {
          if (!_matchOnCard &&
              search.isNotEmpty &&
              !loadMore &&
              customersResponse.customers.isEmpty) {
            _loadCustomers(
              refresh: true,
              keepPrevious: true,
              cardSearch: true,
            );
            return;
          }

          final filtered = customersResponse.customers
              .where((customer) => _matchesCard(customer, search))
              .toList();
          var rawNewCount = 0;
          for (final customer in customersResponse.customers) {
            if (_seenContactNos.add(customer.contactNo)) rawNewCount++;
          }

          setState(() {
            _isLoading = false;
            _isPaging = false;
            _currentPage = page;
            _totalCount = customersResponse.totalCount;
            final fetchedSoFar =
                (page - 1) * limit + customersResponse.customers.length;
            if (_totalCount > 0) {
              _hasMore = fetchedSoFar < _totalCount;
            } else if (customersResponse.totalPages > 0) {
              _hasMore = page < customersResponse.totalPages;
            } else {
              _hasMore = customersResponse.customers.length >= limit;
            }
            if (loadMore && rawNewCount == 0) _hasMore = false;

            final knownHits = _searchHits.map((c) => c.contactNo).toSet();
            _searchHits.addAll(
              filtered.where((c) => !knownHits.contains(c.contactNo)),
            );

            if (_pendingSearchReplace) {
              if (_searchHits.isNotEmpty || !_hasMore) {
                _customers = List<CustomerApiModel>.from(_searchHits);
                _pendingSearchReplace = false;
              }
            } else if (loadMore) {
              final existing = _customers.map((c) => c.contactNo).toSet();
              _customers.addAll(
                filtered.where((c) => !existing.contains(c.contactNo)),
              );
            } else {
              _customers = filtered;
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || generation != _loadGeneration) return;
            _maybeLoadMore();
          });
        },
      );
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _isPaging = false;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  void _maybeLoadMore() {
    if (_isLoading || !_hasMore) return;
    if (_pendingSearchReplace ||
        _customers.isEmpty ||
        !_scrollController.hasClients) {
      _loadCustomers(loadMore: true);
      return;
    }
    if (_scrollController.position.maxScrollExtent <= 80) {
      _loadCustomers(loadMore: true);
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

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _matchesCard(CustomerApiModel customer, String search) {
    final query = _fold(search.trim());
    if (query.isEmpty) return true;

    bool has(String? value) {
      final folded = _fold(value ?? '');
      if (folded.isEmpty || folded == 'n/a') return false;
      return folded.contains(query);
    }

    if (has(customer.fullName) ||
        has(customer.name) ||
        has(customer.surname) ||
        has(customer.title) ||
        has(customer.typeDescription) ||
        has(customer.detail.profession?.description) ||
        has(customer.eMail) ||
        has(customer.tel) ||
        has(customer.isActive ? 'Aktif' : 'Pasif')) {
      return true;
    }

    final queryDigits = _digits(search);
    if (queryDigits.length < 3) return false;
    return _digits(customer.tel).contains(queryDigits);
  }

  String _getErrorMessage(Failure failure) {
    if (failure is AuthFailure) {
      return 'Kimlik doğrulama hatası: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Ağ bağlantısı hatası: ${failure.message}';
    } else if (failure is ServerFailure) {
      return 'Sunucu hatası: ${failure.message}';
    } else {
      return 'Hata: ${failure.message}';
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _loadCustomers(refresh: true, keepPrevious: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoading || !_hasMore || _customers.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 360) {
      _loadCustomers(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Satıcılar');
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
        title: "Satıcı Müşterilerim",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
            child: Column(
              children: [
                // Search Bar Section with Add Button
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: "Ara...",
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add Customer Button - Kompakt
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFE53935),
                              const Color(0xFFD32F2F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final result = await Navigator.pushNamed(context, AppRouter.addCustomer);
                              if (result == true) {
                                // Müşteri eklendi, listeyi yenile
                                _loadCustomers(refresh: true);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Customer Table
                Expanded(
                  child: _buildCustomerTable(),
                ),
              ],
            ),
          ),
        ),
      ),
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
                
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') || 
                    userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_form_applications') || 
                    userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_sale_applications') || 
                    userRoleCodes.contains('role_sale_applications_admin')) {
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


  Widget _buildCustomerTable() {
    if (_isLoading && _customers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _customers.isEmpty) {
      return Center(
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
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCustomers(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
      return const Center(
        child: EmptyDataView(
          expanded: true,
          icon: Icons.people_outline_rounded,
          title: 'Satıcı müşteri bulunamadı',
          subtitle: 'Aradığınız kriterlere uygun satıcı kaydı yok.',
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: RefreshIndicator(
        onRefresh: () => _loadCustomers(refresh: true),
        color: const Color(0xFFE53935),
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _customers.length + (_isPaging ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _customers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                  ),
                ),
              );
            }
            return _buildCustomerCard(_customers[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerApiModel customer) {
    // Get initials for avatar
    String initials = '';
    if (customer.name.isNotEmpty) {
      initials = customer.name[0].toUpperCase();
    }
    if (customer.surname.isNotEmpty && initials.length < 2) {
      initials += customer.surname[0].toUpperCase();
    }
    if (initials.isEmpty) {
      initials = 'SM'; // Satıcı Müşteri default
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, AppRouter.editCustomer, arguments: customer);
          },
          child: Column(
            children: [
              // Header - Kırmızı kısım
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE53935),
                      const Color(0xFFD32F2F),
                      const Color(0xFFC62828),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Daire Avatar - Ultra Şık
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFB71C1C),
                            const Color(0xFFA01515),
                            const Color(0xFF8B0000),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(-1, -1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // İsim ve Tip
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.typeDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Aktif/Pasif Badge - sadece görsel (tıklanmaz)
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: customer.isActive
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                    const Color(0xFF047857),
                                  ]
                                : [
                                    Colors.grey[600]!,
                                    Colors.grey[700]!,
                                    Colors.grey[800]!,
                                  ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (customer.isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey)
                                  .withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(-1, -1),
                              spreadRadius: 0,
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              customer.isActive ? "Aktif" : "Pasif",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
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
              // Body - Beyaz kısım
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // Bilgi Grid - Ultra Şık Kutular
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFAFBFC),
                            const Color(0xFFF8F9FA),
                            const Color(0xFFF1F3F5),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey[200]!.withOpacity(0.5),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(-1, -1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Üst satır
                          Row(
                            children: [
                              Expanded(
                                child: _buildPremiumInfoBox(
                                  Icons.person_outline,
                                  "Müşteri Tipi",
                                  customer.typeDescription,
                                  const Color(0xFF6366F1),
                                  const Color(0xFF818CF8),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: _buildPremiumInfoBox(
                                  Icons.work_outline,
                                  "Meslek",
                                  customer.displayProfession,
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFFA78BFA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          // Alt satır
                          Row(
                            children: [
                              Expanded(
                                child: _buildPremiumInfoBox(
                                  Icons.phone_outlined,
                                  "Telefon No",
                                  customer.displayPhone,
                                  const Color(0xFF10B981),
                                  const Color(0xFF34D399),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: _buildPremiumInfoBox(
                                  Icons.mail_outline,
                                  "E-mail",
                                  customer.displayEmail,
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFFBBF24),
                                ),
                              ),
                            ],
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

  Widget _buildPremiumInfoBox(
    IconData icon,
    String label,
    String value,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[100]!.withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 4,
            offset: const Offset(-1, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.25),
                      secondaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.15),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.35,
              letterSpacing: 0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
