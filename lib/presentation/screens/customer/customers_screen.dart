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
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;

  // API ve state yönetimi
  final CustomerApiRepository _customerRepository = CustomerApiRepository();
  List<CustomerApiModel> _customers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';
  String _selectedCustomerType = 'Hepsi';
  int _currentPage = 1;
  int _totalCount = 0;
  int _totalPages = 0;
  bool _hasMore = true;
  int _loadGeneration = 0;
  static const int _pageSize = 10;

  static const List<String> _customerTypeLabels = [
    'Hepsi',
    'Alıcı',
    'Satıcı',
    'Potansiyel',
    'Potansiyel Alıcı',
    'Potansiyel Satıcı',
    'Alıcı & Satıcı',
  ];

  int? _getCustomerTypeCode() {
    if (_selectedCustomerType == 'Hepsi') return null;
    return CustomerApiModel.typeCodeForLabel(_selectedCustomerType);
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
  // Arama ve sayfalama
  Timer? _searchTimer;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Scroll listener
    _scrollController.addListener(_onScroll);


    // API'den müşterileri yükle
    _loadCustomers();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomers({bool refresh = false, bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoading || !_hasMore) return;
    } else if (_isLoading && !refresh) {
      return;
    }

    if (!loadMore) {
      _loadGeneration++;
    }
    final generation = _loadGeneration;
    final page = loadMore ? _currentPage + 1 : 1;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (!loadMore) {
        _currentPage = 1;
        _totalCount = 0;
        _totalPages = 0;
        _hasMore = true;
        _customers.clear();
      }
    });

    final search = _searchQuery.trim();
    final status = _selectedStatus;
    final typeLabel = _selectedCustomerType;
    final typeCode = _getCustomerTypeCode();

    try {
      final result = await _customerRepository.getCustomers(
        page: page,
        limit: _pageSize,
        searchText: search.isNotEmpty ? search : null,
        status: status,
        type: typeCode,
      );

      if (!mounted || generation != _loadGeneration) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = _getErrorMessage(failure);
            if (loadMore) _hasMore = false;
          });
        },
        (customersResponse) {
          final filteredCustomers = _applyLocalFilters(
            customersResponse.customers,
            status: status,
            typeLabel: typeLabel,
            typeCode: typeCode,
            search: search,
          );
          final existingIds = _customers.map((c) => c.contactNo).toSet();
          final rawNewCount = customersResponse.customers
              .where((c) => !existingIds.contains(c.contactNo))
              .length;
          setState(() {
            _isLoading = false;
            _currentPage = page;
            _totalCount = customersResponse.totalCount;
            _totalPages = customersResponse.totalPages;
            if (loadMore) {
              _customers.addAll(
                filteredCustomers.where((c) => !existingIds.contains(c.contactNo)),
              );
            } else {
              _customers = filteredCustomers;
            }
            final fetchedSoFar =
                (page - 1) * _pageSize + customersResponse.customers.length;
            if (_totalCount > 0) {
              _hasMore = fetchedSoFar < _totalCount;
            } else if (_totalPages > 0) {
              _hasMore = page < _totalPages;
            } else {
              _hasMore = customersResponse.customers.length >= _pageSize;
            }
            if (loadMore && rawNewCount == 0) _hasMore = false;
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
        _errorMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  void _maybeLoadMore() {
    if (_isLoading || !_hasMore) return;
    if (_customers.isEmpty || !_scrollController.hasClients) {
      _loadCustomers(loadMore: true);
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 80) {
      _loadCustomers(loadMore: true);
    }
  }

  bool _matchesType(
    CustomerApiModel customer, {
    required String typeLabel,
    required int? typeCode,
  }) {
    if (typeLabel == 'Hepsi' || typeCode == null) return true;

    final description = _fold(customer.typeDescription);
    final wanted = _fold(typeLabel);
    if (description.isNotEmpty && description == wanted) return true;
    if (customer.type != typeCode) return false;
    if (typeCode != 203) return true;

    const specific = {'potansiyel alici', 'potansiyel satici'};
    if (wanted == 'potansiyel') {
      return description.isEmpty || !specific.contains(description);
    }
    return false;
  }

  bool _matchesSearch(CustomerApiModel customer, String search) {
    final query = _fold(search);
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
        has(customer.isActive ? 'Aktif' : 'Pasif') ||
        customer.tags.any(has) ||
        customer.contactNo.toString().contains(query)) {
      return true;
    }

    final queryDigits = _digits(search);
    if (queryDigits.length < 3) return false;
    return _digits(customer.tel).contains(queryDigits);
  }

  List<CustomerApiModel> _applyLocalFilters(
    List<CustomerApiModel> customers, {
    required String status,
    required String typeLabel,
    required int? typeCode,
    required String search,
  }) {
    return customers.where((customer) {
      if (!_matchesType(customer, typeLabel: typeLabel, typeCode: typeCode)) {
        return false;
      }
      if (status == 'Aktif' && !customer.isActive) return false;
      if (status == 'Pasif' && customer.isActive) return false;
      return _matchesSearch(customer, search);
    }).toList();
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
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _loadCustomers(refresh: true);
    });
  }

  void _onStatusChanged(String? status) {
    if (status == null || status == _selectedStatus) return;
    setState(() => _selectedStatus = status);
    _loadCustomers(refresh: true);
  }

  void _onCustomerTypeChanged(String? type) {
    if (type == null || type == _selectedCustomerType) return;
    setState(() => _selectedCustomerType = type);
    _loadCustomers(refresh: true);
  }

  Future<void> _showCustomerTypePicker() async {
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerTypeBottomSheet(
        options: _customerTypeLabels,
        selected: _selectedCustomerType,
        onSelected: (value) {
          _onCustomerTypeChanged(value);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _clearFilters() {
    _searchTimer?.cancel();
    setState(() {
      _selectedCustomerType = 'Hepsi';
      _selectedStatus = 'Tümü';
      _searchController.clear();
      _searchQuery = '';
    });
    _loadCustomers(refresh: true);
  }

  /// Mobil segmented control: Tümü | Aktif | Pasif (tek satır, eşit genişlik)
  Widget _buildStatusSegmented() {
    const labels = ['Tümü', 'Aktif', 'Pasif'];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: labels.map((label) {
          final isSelected = _selectedStatus == label;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onStatusChanged(label),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFFE53935) : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoading || !_hasMore || _customers.isEmpty) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadCustomers(loadMore: true);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 360) {
      _loadCustomers(loadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
        backgroundColor: Colors.white,
        // Role sistemine göre sidebar seçimi
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'Müşteriler');
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
          title: "Müşteriler",
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
              child: RefreshIndicator(
              onRefresh: () => _loadCustomers(refresh: true),
              color: const Color(0xFFE53935),
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arama - tam genişlik
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "Müşteri Ara",
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Müşteri Tipi + Ekle (taşma olmaması için Expanded + minWidth: 0)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Müşteri Tipi",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Material(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: _showCustomerTypePicker,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 0),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedCustomerType,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.grey[600],
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(context, AppRouter.addCustomer);
                                  if (result == true) _loadCustomers(refresh: true);
                                },
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Durum - mobil segmented control (Tümü | Aktif | Pasif)
                        _buildStatusSegmented(),
                        const SizedBox(height: 12),
                        // Filtreyi Temizle - mobil: ince text buton
                        Center(
                          child: TextButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.refresh_rounded, size: 18, color: Colors.grey[600]),
                            label: Text(
                              "Filtreyi Temizle",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                      ),
                    ),
                    ..._buildCustomerSlivers(),
                  ],
                ),
              ),
            ),
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

  List<Widget> _buildCustomerSlivers() {
    if (_isLoading && _customers.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView.loading(
            title: 'Müşteriler hazırlanıyor.',
            message: 'Müşteri listesi yüklenirken lütfen bekleyin.',
          ),
        ),
      ];
    }

    if (_errorMessage.isNotEmpty && _customers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView.error(
            message: _errorMessage,
            onRetry: () => _loadCustomers(refresh: true),
          ),
        ),
      ];
    }

    if (_customers.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView.missing(
            title: 'Müşteri bulunamadı',
            message: 'Aradığınız kriterlere uygun müşteri kaydı yok.',
            icon: Icons.people_outline_rounded,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _customers.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    ),
                  ),
                );
              }
              return _buildCustomerCard(_customers[index]);
            },
            childCount: _customers.length + (_isLoading && _hasMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }

  Widget _buildCustomerCard(CustomerApiModel customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              AppRouter.editCustomer,
              arguments: customer,
            );
            if (result == true) _loadCustomers(refresh: true);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık: gradient + isim + tip + durum (sadece görsel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
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
                    // Durum - sadece bilgi (mobil: küçük, tıklanmaz)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: customer.isActive
                                ? const Color(0xFF4ADE80)
                                : Colors.white.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          customer.isActive ? "Aktif" : "Pasif",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bilgi alanları - sade grid
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanInfoCard(
                            Icons.person_outline_rounded,
                            "Müşteri Tipi",
                            customer.typeDescription,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCleanInfoCard(
                            Icons.work_outline_rounded,
                            "Meslek",
                            customer.displayProfession,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanInfoCard(
                            Icons.phone_outlined,
                            "Telefon",
                            customer.displayPhone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCleanInfoCard(
                            Icons.mail_outline_rounded,
                            "E-mail",
                            customer.displayEmail,
                          ),
                        ),
                      ],
                    ),
                    if (customer.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: customer.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFE53935)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Müşteri Tipi seçimi için projedeki modern bottom sheet stili
class _CustomerTypeBottomSheet extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CustomerTypeBottomSheet({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.5;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Müşteri Tipi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, i) {
                  final option = options[i];
                  final isSelected = selected == option;
                  return Material(
                    color: isSelected ? const Color(0xFFE53935).withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onSelected(option),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFFE53935) : const Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded, color: Color(0xFFE53935), size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}