import 'package:flutter/material.dart';
import 'dart:async';
import 'package:zecorner/presentation/screens/office/add_office_screen.dart';
import 'package:zecorner/presentation/screens/office/edit_office_screen.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/models/office/office_api_model.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/utils/image_utils.dart';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;

  // API ve state yönetimi
  final OfficeApiRepository _officeRepository = OfficeApiRepository();
  List<OfficeApiModel> _offices = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';
  int _currentPage = 1;
  int _loadRequestId = 0;
  final Set<int> _statusUpdatingIds = <int>{};

  static const int _pageSize = 200;
  static const List<String> _statusOptions = ['Tümü', 'Aktif', 'Pasif'];
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

    // API'den ofisleri yükle
    _loadOffices();
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

  bool _matchesStatus(OfficeApiModel office, String status) {
    switch (status) {
      case 'Aktif':
        return office.isActive;
      case 'Pasif':
        return !office.isActive;
      default:
        return true;
    }
  }

  List<OfficeApiModel> get _visibleOffices => _offices
      .where((office) => _matchesStatus(office, _selectedStatus))
      .toList();

  int get _activeFilterCount => _selectedStatus == 'Tümü' ? 0 : 1;

  // API çağrıları
  Future<void> _loadOffices({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    final requestId = ++_loadRequestId;
    final page = refresh ? 1 : _currentPage;
    final search = _searchQuery.trim();
    final status = _selectedStatus;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _offices = [];
      }
    });

    try {
      final result = await _officeRepository.getOffices(
        page: page,
        limit: _pageSize,
        search: search.isNotEmpty ? search : null,
        status: status,
        types: [101, 102], // Zecorner Ofis ve Broker Ofis
      );

      if (!mounted || requestId != _loadRequestId) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = _getErrorMessage(failure);
            if (refresh) _offices = [];
          });
        },
        (officesResponse) {
          final incoming = officesResponse.offices
              .where((office) => _matchesStatus(office, status))
              .toList();
          final reportedPages = officesResponse.totalPages;
          final reachedEnd = officesResponse.offices.isEmpty ||
              officesResponse.offices.length < _pageSize ||
              (reportedPages > 0 && page >= reportedPages);

          setState(() {
            _isLoading = false;
            _hasMore = !reachedEnd;
            _currentPage = page;
            if (refresh || page == 1) {
              _offices = incoming;
            } else {
              final ids = _offices.map((office) => office.contactNo).toSet();
              _offices = [
                ..._offices,
                ...incoming.where((office) => !ids.contains(office.contactNo)),
              ];
            }
          });
        },
      );
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  OfficeApiModel _copyOfficeWithStatus(OfficeApiModel office, int newStatus) {
    return OfficeApiModel(
      contactNo: office.contactNo,
      title: office.title,
      name: office.name,
      surname: office.surname,
      type: office.type,
      tcIdNumber: office.tcIdNumber,
      taxNo: office.taxNo,
      taxOffice: office.taxOffice,
      nationality: office.nationality,
      sex: office.sex,
      eMail: office.eMail,
      tel: office.tel,
      status: newStatus,
      updatedAt: DateTime.now().toIso8601String(),
      createdAt: office.createdAt,
      source: office.source,
      typeDescription: office.typeDescription,
      isCompany: office.isCompany,
      isEmployee: office.isEmployee,
      isAgency: office.isAgency,
      birthday: office.birthday,
      professionCode: office.professionCode,
      professionDescription: office.professionDescription,
      educationCode: office.educationCode,
      educationDescription: office.educationDescription,
      whereYouHeardUs: office.whereYouHeardUs,
      sectoralExperience: office.sectoralExperience,
      picture: office.picture,
      marketingCommunicationPermission: office.marketingCommunicationPermission,
      address: office.address,
      district: office.district,
      postCode: office.postCode,
      city: office.city,
      country: office.country,
      addressSource: office.addressSource,
      provinceCode: office.provinceCode,
      provinceName: office.provinceName,
      districtCode: office.districtCode,
      districtName: office.districtName,
      quarterCode: office.quarterCode,
      quarterName: office.quarterName,
      connectedContact: office.connectedContact,
      connectedContactTitle: office.connectedContactTitle,
      connectedContactType: office.connectedContactType,
      connectedContactDescription: office.connectedContactDescription,
      isCustomer: office.isCustomer,
      slug: office.slug,
      tradeName: office.tradeName,
      detailRef: office.detailRef,
    );
  }

  Future<void> _updateOfficeStatus(OfficeApiModel office) async {
    if (_statusUpdatingIds.contains(office.contactNo)) return;
    setState(() {
      _statusUpdatingIds.add(office.contactNo);
    });

    final result = await _officeRepository.toggleOfficeStatus(
      office.contactNo,
      currentIsActive: office.isActive,
    );
    if (!mounted) return;

    setState(() {
      _statusUpdatingIds.remove(office.contactNo);
    });

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${office.title}: ${_getErrorMessage(failure)}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        if (!success) return;
        final newStatus = office.isActive ? 0 : 1;
        setState(() {
          final index = _offices.indexWhere((o) => o.contactNo == office.contactNo);
          if (index != -1) {
            _offices[index] = _copyOfficeWithStatus(_offices[index], newStatus);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${office.title} ${newStatus == 1 ? "aktif" : "pasif"} yapıldı'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
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

    // Önceki timer'ı iptal et
    _searchTimer?.cancel();

    // 300ms debounce
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _loadOffices(refresh: true);
    });
  }

  // Sonsuz kaydırma: sona yaklaşınca yeni sayfayı yükle
  void _onScroll() {
    if (_isLoading || !_hasMore || _offices.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadNextPage();
    }
  }

  void _onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    _loadOffices(refresh: true);
  }

  void _showFilterSheet() {
    var draftStatus = _selectedStatus;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtreler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D2E),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                        color: Color(0xFF6B7280),
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Durum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._statusOptions.map((status) {
                    final selected = draftStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setSheetState(() => draftStatus = status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFE53935).withOpacity(0.4)
                                    : const Color(0xFFE5E7EB),
                              ),
                              color: selected
                                  ? const Color(0xFFFFEBEE)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  status == 'Aktif'
                                      ? Icons.check_circle_outline_rounded
                                      : status == 'Pasif'
                                          ? Icons.pause_circle_outline_rounded
                                          : Icons.business_outlined,
                                  color: selected
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF1A1D2E),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFFE53935),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _onStatusChanged('Tümü');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE53935),
                            side: const BorderSide(
                              color: Color(0xFFE53935),
                              width: 1.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Temizle',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _onStatusChanged(draftStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Uygula',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadNextPage() async {
    if (_isLoading) return;
    setState(() {
      _currentPage++;
    });
    await _loadOffices();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackgroundWidget(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'Ofisler');
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
          title: "Ofisler",
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: GestureDetector(
          onTap: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          child: AbsorbPointer(
            absorbing: _isDrawerOpen,
            child: Column(
              children: [
                // Premium Search Section
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                      decoration: BoxDecoration(
                  color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                          decoration: InputDecoration(
                          hintText: "Ofis ara (isim, email, telefon)...",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFFE53935).withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                            suffixIcon: _searchController.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
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
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                            ),
                            ),
                            const SizedBox(width: 10),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Material(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    onTap: _showFilterSheet,
                                    borderRadius: BorderRadius.circular(14),
                                    child: const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_activeFilterCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE53935),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (_selectedStatus != 'Tümü') ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              label: Text(
                                _selectedStatus,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              avatar: Icon(
                                _selectedStatus == 'Aktif'
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_filled_rounded,
                                size: 16,
                                color: const Color(0xFFE53935),
                              ),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFFE53935),
                              ),
                              onDeleted: () => _onStatusChanged('Tümü'),
                              backgroundColor: const Color(0xFFFFEBEE),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Office List
                Expanded(
                  child: _buildOfficeList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddOfficeScreen()),
            );
            if (!mounted) return;
            if (added == true) {
              _loadOffices(refresh: true);
            }
          },
          backgroundColor: const Color(0xFFE53935),
          elevation: 6,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AdminNavbar(
          currentIndex: -1,
          onTap: (index) {},
        ),
      ),
    );
  }

  Widget _buildOfficeList() {
    final visible = _visibleOffices;

    if (_isLoading && _offices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _offices.isEmpty) {
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
              onPressed: () => _loadOffices(refresh: true),
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

    if (visible.isEmpty) {
      final filtered = _searchQuery.trim().isNotEmpty || _selectedStatus != 'Tümü';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ofis bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (filtered) ...[
              const SizedBox(height: 6),
              Text(
                'Filtreyi değiştirip tekrar deneyin',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOffices(refresh: true),
      color: const Color(0xFFE53935),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: visible.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                ),
              ),
            );
          }
          return _buildMobileOfficeCard(visible[index]);
        },
      ),
    );
  }

  Widget _buildMobileOfficeCard(OfficeApiModel office) {
    final isStatusUpdating = _statusUpdatingIds.contains(office.contactNo);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Office data to OfficePerson conversion
            OfficePerson officeData = OfficePerson(
              id: office.contactNo.toString(),
              firstName: office.title.split(' ').first,
              lastName: office.title.split(' ').skip(1).join(' '),
              email: office.eMail,
              office: office.title,
              personNo: office.contactNo.toString(),
              userType: office.typeDescription,
              status: office.isActive ? 'Aktif' : 'Pasif',
              registrationDate: office.updatedAt?.split('T').first ?? DateTime.now().toString().split(' ').first,
              personCount: '1',
              isActive: office.isActive,
              address: office.address,
              city: office.provinceName,
              district: office.districtName,
              tradeName: office.tradeName,
              detailRef: office.detailRef,
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditOfficeScreen(),
                settings: RouteSettings(arguments: officeData),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row with Red Accent
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildOfficeAvatar(office.picture),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              office.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              office.displayEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: isStatusUpdating ? null : () => _updateOfficeStatus(office),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isStatusUpdating)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                                ),
                              )
                            else ...[
                              Container(
                                width: 6,
                                height: 6,
                                  decoration: BoxDecoration(
                                    color: office.isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                                Text(
                                  office.isActive ? "Aktif" : "Pasif",
                                style: TextStyle(
                                    color: office.isActive ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info Grid - Clean White Background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.location_on_outlined,
                              "Konum",
                              office.displayLocation,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.phone_outlined,
                              "İletişim",
                              office.displayPhone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.business_center_outlined,
                              "Kullanıcı Tipi",
                              office.typeDescription,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.calendar_today_outlined,
                              "Kayıt",
                              office.formattedCreatedDate,
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
        ),
      ),
    );
  }

  Widget _buildCleanInfoCard(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// S3'ten ofis profil fotoğrafını yükle
  Widget _buildOfficeAvatar(String? pictureId) {
    // Picture yoksa default icon göster
    if (!ImageUtils.isValidS3Id(pictureId)) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.business,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // S3 URL'ini oluştur
    final imageUrl = ImageUtils.getProfileImageUrl(pictureId);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: 36,
            height: 36,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              // Loading state
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Error state - default icon göster
              return const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              );
            },
          ),
        ),
      ),
    );
  }
}