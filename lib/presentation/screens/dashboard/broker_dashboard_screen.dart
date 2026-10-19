import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/card/broker_kisi_table.dart';
import 'package:zecorner/presentation/widgets/admin-panel/card/broker_office_table.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/core/auth/auth_session_storage.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/users/user_profile_repository.dart';
import 'package:zecorner/core/network/network_info_impl.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:zecorner/infrastructure/dashboard/dashboard_repository.dart';
import 'package:zecorner/infrastructure/potential/potential_income_repo.dart';
import 'package:zecorner/models/dashboard/office/office_totals_model.dart';
import 'package:zecorner/models/dashboard/office/office_sales_model.dart';
import 'package:zecorner/models/dashboard/office/office_top_model.dart';
import 'package:zecorner/models/dashboard/office/office_daily_model.dart';
import 'package:zecorner/models/dashboard/potential/potential_income_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_advisor_model.dart';

import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';
import 'package:zecorner/presentation/widgets/status/login_intro_loader.dart';

class BrokerDashboardScreen extends StatefulWidget {
  const BrokerDashboardScreen({super.key});

  @override
  State<BrokerDashboardScreen> createState() => _BrokerDashboardScreenState();
}

class _BrokerDashboardScreenState extends State<BrokerDashboardScreen>
    with TickerProviderStateMixin {
  static const Color _primaryRed = Color(0xFFEE2E24);
  static const Color _secondaryRed = Color(0xFFE53935);
  static const Color _pageBackground = Color(0xFFF3F4F6);
  static const Color _cardSurface = Colors.white;
  static const Color _borderLight = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late AnimationController _shimmerController;

  late final PageController _operationPageController;
  int _currentOperationPage = 0;
  Timer? _operationAutoScrollTimer;
  Timer? _operationRestartDelayTimer;

  // Universal Dashboard Repository - Role-based automatic endpoint selection
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final PotentialIncomeRepository _potentialIncomeRepo =
      PotentialIncomeRepository();
  final UserProfileRepository _userProfileRepo = UserProfileRepository(
    dio: DioClient().dio,
    networkInfo: NetworkInfoImpl(),
  );

  // Dashboard State
  bool _isLoading = false;

  // Dashboard Data
  OfficeTotalsModel? _totalsData;
  OfficeSalesModel? _salesData;
  OfficeTopModel? _topData;
  OfficeDailyModel? _dailyData;
  PotentialIncomeModel? _potentialIncomeData;
  AdminAdvisorModel? _advisorsData;
  
  // User Profile Data — connected_contact (ofis) / connected_contact_title
  String _officeTitle = '';
  int? _officeId;

  // Chart Filter State
  int? _selectedYear = DateTime.now().year;
  int? _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _operationPageController =
        PageController(initialPage: 0, viewportFraction: 1.0);
    _startOperationAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RoleSidebar.preloadSidebarData(context);
    });
    _resolveOfficeThenLoad();
  }

  void _startOperationAutoScroll() {
    _operationAutoScrollTimer?.cancel();
    _operationAutoScrollTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_operationPageController.hasClients) {
        final data = _getOperationChartData();
        if (data.isEmpty) return;
        final nextPage = (_currentOperationPage + 1) % data.length;
        _operationPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopOperationAutoScroll() {
    _operationAutoScrollTimer?.cancel();
    _operationRestartDelayTimer?.cancel();
  }

  void _restartOperationAutoScroll() {
    _stopOperationAutoScroll();
    _operationRestartDelayTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _startOperationAutoScroll();
    });
  }
  
  /// Tüm Portföyler ile aynı: ofis = get-user-info `connected_contact`.
  Future<void> _resolveOfficeThenLoad() async {
    await _loadUserProfile();
    if (!mounted) return;
    await _loadDashboardData();
  }

  /// User profile → ofis id = connected_contact, ad = connected_contact_title
  Future<void> _loadUserProfile() async {
    final generation = AuthSessionStorage.sessionGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      final personNo = int.tryParse(prefs.getString('userID')?.trim() ?? '');
      int? officeId = DashboardRepository.officeIdFromPrefs(prefs);
      var officeTitle = prefs.getString('officeTitle')?.trim() ?? '';

      final result = await _userProfileRepo.getUserProfile();
      result.fold(
        (failure) {
          print('❌ User Profile API hatası: ${failure.message}');
        },
        (userProfile) {
          if (userProfile.contactNo > 0) {
            // kişi no ofis değildir
          }
          if (userProfile.connectedContact > 0 &&
              userProfile.connectedContact != userProfile.contactNo) {
            officeId = userProfile.connectedContact;
          }
          final title = userProfile.connectedContactTitle.trim();
          if (title.isNotEmpty) officeTitle = title;
        },
      );

      if (officeId != null && personNo != null && officeId == personNo) {
        officeId = null;
      }

      final resolvedOfficeId = officeId;
      if (AuthSessionStorage.isCurrent(generation)) {
        await AuthSessionStorage.synchronized(() async {
          if (!AuthSessionStorage.isCurrent(generation)) return;
          if (resolvedOfficeId != null && resolvedOfficeId > 0) {
            await prefs.setInt('officeId', resolvedOfficeId);
          }
          if (officeTitle.isNotEmpty) {
            await prefs.setString('officeTitle', officeTitle);
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _officeId = officeId;
        _officeTitle = officeTitle;
      });
      print('✅ Broker ofis: id=$_officeId title=$_officeTitle');
    } catch (e) {
      print('❌ User Profile yükleme hatası: $e');
    }
  }

  bool _isSameOffice({int? listingOffice, String? listingOfficeTitle}) {
    final hasId = listingOffice != null && listingOffice > 0;
    final hasTitle = (listingOfficeTitle ?? '').trim().isNotEmpty;
    // Satırda ofis yoksa API'nin ofis kapsamına güven (boş ekran olmasın).
    if (!hasId && !hasTitle) return true;

    if (hasId && _officeId != null && _officeId! > 0) {
      return listingOffice == _officeId;
    }
    final title = _officeTitle.trim().toLowerCase();
    if (hasTitle && title.isNotEmpty) {
      return listingOfficeTitle!.trim().toLowerCase() == title;
    }
    return true;
  }

  AdminAdvisorModel _scopeAdvisorsToOffice(AdminAdvisorModel data) {
    if (_officeId == null && _officeTitle.trim().isEmpty) return data;
    final filtered = data.advisors.where((a) {
      return _isSameOffice(
        listingOffice: a.office,
        listingOfficeTitle: a.officeTitle,
      );
    }).toList();
    return AdminAdvisorModel(
      advisors: filtered,
      page: data.page,
      totalCount: filtered.length,
      totalPages: data.totalPages,
    );
  }

  OfficeSalesModel _scopeSalesToOffice(OfficeSalesModel data) {
    if (_officeId == null && _officeTitle.trim().isEmpty) return data;
    final filtered = data.sales.where((s) {
      return _isSameOffice(
        listingOffice: s.office,
        listingOfficeTitle: s.officeTitle,
      );
    }).toList();
    return OfficeSalesModel(
      sales: filtered,
      totalCount: filtered.length,
      totalPages: data.totalPages,
      page: data.page,
      totalRevenue: data.totalRevenue,
    );
  }

  /// Dashboard verilerini API'den yükle
  Future<void> _loadDashboardData() async {
    final generation = AuthSessionStorage.sessionGeneration;
    print('🎬 _loadDashboardData metodu başlatıldı');
    setState(() {
      _isLoading = true;
    });

    try {
      // Dashboard API çağrıları
      print('📞 Broker Dashboard Totals API çağrılıyor...');
      final totalsResult = await _dashboardRepo.getDashboardTotals();

      // Totals'taki office, prefs'te yoksa yedek olarak kaydet (connected_contact öncelikli).
      totalsResult.fold(
        (failure) => null,
        (data) {
          final office = OfficeTotalsModel.fromJson(data).office;
          if (office != 0 && (_officeId == null || _officeId == 0)) {
            _officeId = office;
          }
        },
      );

      if (_officeId != null && _officeId! > 0 && AuthSessionStorage.isCurrent(generation)) {
        final prefs = await SharedPreferences.getInstance();
        final officeId = _officeId!;
        await AuthSessionStorage.synchronized(() async {
          if (!AuthSessionStorage.isCurrent(generation)) return;
          await prefs.setInt('officeId', officeId);
        });
      }
      
      print('📞 Broker Dashboard Potential Income API çağrılıyor...');
      final potentialIncomeResult =
          await _potentialIncomeRepo.getPotentialIncome();
      final salesResult = await _dashboardRepo.getDashboardSales(page: 1);
      final topResult = await _dashboardRepo.getDashboardTop();
      final dailyResult = await _dashboardRepo.getDashboardDailyRevenue(
        year: _selectedYear,
        month: _selectedMonth,
      );
      final advisorsResult = await _dashboardRepo.getDashboardAdvisors(page: 1);

      // Totals verilerini işle
      totalsResult.fold(
        (failure) {
          print('❌ Totals API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          _totalsData = null;
        },
        (data) {
          print('🔍 Totals API RAW DATA: $data');
          _totalsData = OfficeTotalsModel.fromJson(data);
          print('✅ Totals verileri API\'den başarıyla yüklendi');
          print('📊 Office: ${_totalsData!.office}');
          print('📊 For Rent: ${_totalsData!.forRent}');
          print('📊 For Sale: ${_totalsData!.forSale}');
          print('📊 Customers: ${_totalsData!.customers}');
        },
      );

      // Sales verilerini işle
      salesResult.fold(
        (failure) {
          print('❌ Sales API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  Sales API başarısız - sales data null olacak');
          _salesData = null;
        },
        (data) {
          print('🔍 Sales API RAW DATA: $data');
          _salesData = _scopeSalesToOffice(OfficeSalesModel.fromJson(data));
          print('✅ Sales verileri yüklendi');
        },
      );

      // Top verilerini işle
      topResult.fold(
        (failure) {
          print('❌ Top API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  API başarısız - top data null olacak');
          _topData = null;
        },
        (data) {
          try {
            print('🔍 Top API RAW DATA: $data');
            _topData = OfficeTopModel.fromJson(data);
            print('✅ Top verileri API\'den başarıyla yüklendi');
            print('🔍 Week count: ${_topData?.week.length}');
            print('🔍 Month count: ${_topData?.month.length}');
            print('🔍 Year count: ${_topData?.year.length}');
            if (_topData?.week.isNotEmpty == true) {
              print(
                  '🔍 Week first: ${_topData?.week.first.advisorTitle} - ${_topData?.week.first.total}');
            }
            if (_topData?.month.isNotEmpty == true) {
              print(
                  '🔍 Month first: ${_topData?.month.first.advisorTitle} - ${_topData?.month.first.total}');
            }
            if (_topData?.year.isNotEmpty == true) {
              print(
                  '🔍 Year first: ${_topData?.year.first.advisorTitle} - ${_topData?.year.first.total}');
            }
          } catch (e) {
            print('❌ Top data parse hatası: $e');
            print('📦 Raw data: $data');
            _topData = null;
          }
        },
      );

      // Daily Revenue verilerini işle
      dailyResult.fold(
        (failure) {
          _dailyData = null;
        },
        (data) {
          try {
            _dailyData = OfficeDailyModel.fromJson(data);
            print(
                '✅ Daily Revenue verileri yüklendi - Days count: ${_dailyData!.days.length}');
            print(
                '🔍 Total Revenue: ₺${_formatPrice(_dailyData!.total.toString())}');
            // Admin dashboard'daki gibi otomatik yıl/ay seçimi
            final years = _getAvailableYears();
            if (years.isNotEmpty) {
              _selectedYear = years.first; // En güncel yıl
              final months = _getAvailableMonthsForYear(_selectedYear!);
              if (months.isNotEmpty) {
                _selectedMonth = months.first; // En güncel ay
              }
            }
          } catch (e) {
            print('❌ Daily Revenue data parse hatası: $e');
            _dailyData = null;
          }
        },
      );

      // Potential Income verilerini işle
      potentialIncomeResult.fold(
        (failure) {
          print('❌ Potential Income API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  Potential Income API başarısız - potential income data null olacak');
          setState(() {
            _potentialIncomeData = null;
          });
        },
        (data) {
          print('✅ Potential Income API başarılı - Raw Data: $data');
          print('💰 Potential Income: ${data.potentialIncome}');
          print('🏢 Office: ${data.office}');
          setState(() {
            _potentialIncomeData = data;
          });
          print('✅ Potential Income verileri başarıyla yüklendi');
        },
      );

      // Advisors verilerini işle
      advisorsResult.fold(
        (failure) {
          print('❌ Advisors API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          _advisorsData = null;
        },
        (data) {
          try {
            print('🔍 Advisors API RAW DATA: $data');
            _advisorsData = _scopeAdvisorsToOffice(
              AdminAdvisorModel.fromJson(data),
            );
            print(
                '✅ Advisors verileri yüklendi - Advisors count: ${_advisorsData!.advisors.length}');
            print('📊 Toplam Sayfa: ${_advisorsData!.totalPages}');
            print('📊 Toplam Kayıt: ${_advisorsData!.totalCount}');
          } catch (e) {
            print('❌ Advisors data parse hatası: $e');
            _advisorsData = null;
          }
        },
      );

      setState(() {
        _isLoading = false;
        // Veriler yüklendikten sonra otomatik yıl/ay seçimi (admin dashboard mantığı)
        if (_dailyData != null && _dailyData!.days.isNotEmpty) {
          final years = _getAvailableYears();
          if (years.isNotEmpty && _selectedYear == null) {
            _selectedYear = years.first;
            final months = _getAvailableMonthsForYear(_selectedYear!);
            if (months.isNotEmpty && _selectedMonth == null) {
              _selectedMonth = months.first;
            }
          }
        }
      });
    } catch (e) {
      // Genel hata durumunda null değerler
      print('❌ Genel hata: $e');
      setState(() {
        _isLoading = false;
        _totalsData = null;
        _salesData = null;
        _topData = null;
        _dailyData = null;
        _potentialIncomeData = null;
      });
    }
  }

  /// Sales verilerini belirli bir sayfa için yükle
  Future<void> _loadSalesData({int page = 1}) async {
    print('🎬 _loadSalesData metodu başlatıldı - Sayfa: $page');
    setState(() {
      _isLoading = true;
    });

    try {
      final salesResult = await _dashboardRepo.getDashboardSales(page: page);

      salesResult.fold(
        (failure) {
          print('❌ Sales API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          _salesData = null;
        },
        (data) {
          print('🔍 Sales API RAW DATA: $data');
          _salesData = _scopeSalesToOffice(OfficeSalesModel.fromJson(data));
          print('✅ Sales verileri yüklendi - Sayfa: ${_salesData!.page}');
          print('📊 Toplam Sayfa: ${_salesData!.totalPages}');
          print('📊 Toplam Kayıt: ${_salesData!.totalCount}');
        },
      );
    } catch (e) {
      print('❌ Sales verileri yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _operationAutoScrollTimer?.cancel();
    _operationRestartDelayTimer?.cancel();
    _operationPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ BrokerDashboard build metodu çağrıldı');

    // Debug için durumları kontrol et
    print('🔍 Build - _isLoading: $_isLoading');
    print('🔍 Build - _totalsData: ${_totalsData != null ? "MEVCUT" : "NULL"}');

    // Eğer veriler yüklenmemişse ve loading false ise, API çağrısı yap
    if (!_isLoading && _totalsData == null) {
      print('🔄 Build metodunda API çağrısı tetikleniyor...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDashboardData();
      });
    } else {
      print(
          '❌ API çağrısı tetiklenmedi - _isLoading: $_isLoading, _totalsData: ${_totalsData != null ? "MEVCUT" : "NULL"}');
    }

    return LoginIntroHost(
      loading: _isLoading,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _pageBackground,
        drawer: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return RoleSidebar(currentPage: 'Ana Sayfa');
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
          title: "Ana Sayfa",
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
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _primaryRed,
                          const Color(0xFFD32F2F),
                          _pageBackground.withOpacity(0),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOfficeHeader(),
                      const SizedBox(height: 14),
                      if (_isLoading)
                        _buildSkeletonLoading()
                      else if (_totalsData != null)
                        _buildModernStatsSection()
                      else
                        _buildLoadingPlaceholder(),
                      const SizedBox(height: 14),
                      _buildModernOperationSection(),
                      const SizedBox(height: 14),
                      _buildModernPotentialCard(
                        icon: Icons.attach_money_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Potansiyel Gelir Hesaplaması',
                        subtitle: _potentialIncomeData != null
                            ? _formatPrice(
                                _potentialIncomeData!.potentialIncome)
                            : '-',
                      ),
                      const SizedBox(height: 14),
                      _buildAdvisorPerformanceSection(),
                      const SizedBox(height: 14),
                      _buildIncomeChart(),
                    const SizedBox(height: 16),
                    BrokerOfficeTable(
                      salesData: _salesData,
                      totalRevenue: _totalsData?.totalRevenue,
                      selectedYear: _selectedYear,
                      selectedMonth: _selectedMonth,
                    ),
                    const SizedBox(height: 16),
                    PanelKisiCard(
                      advisorsData: _advisorsData,
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Role-based navbar ekle
        bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              final authCubit = context.read<AuthCubit>();

              return FutureBuilder<List<String>>(
                future: authCubit.getUserRoleCodes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  final userRoleCodes = snapshot.data ?? [];
                  print(
                      'Broker Dashboard Navbar - User Role Codes: $userRoleCodes');

                  // Role detection için ilk geçerli role'ü bul
                  String? detectedRoleCode;
                  if (userRoleCodes.contains('role_admin')) {
                    detectedRoleCode = 'role_admin';
                  } else if (userRoleCodes.contains('role_advisor')) {
                    detectedRoleCode = 'role_advisor';
                  } else if (userRoleCodes.contains('role_office_broker')) {
                    detectedRoleCode = 'role_office_broker';
                  } else if (userRoleCodes.contains('role_office_assistant')) {
                    detectedRoleCode = 'role_office_assistant';
                  } else if (userRoleCodes.contains('role_form_applications')) {
                    detectedRoleCode = 'role_form_applications';
                  } else if (userRoleCodes.contains('role_sale_applications')) {
                    detectedRoleCode = 'role_sale_applications';
                  }

                  print(
                      'Broker Dashboard Navbar - Detected Role Code: $detectedRoleCode');

                  // Role'e göre navbar seçimi
                  if (userRoleCodes.contains('role_admin')) {
                    return AdminNavbar(currentIndex: 0);
                  } else if (userRoleCodes.contains('role_advisor')) {
                    return DanismanNavbar(currentIndex: 0);
                  } else if (userRoleCodes.contains('role_office_broker') ||
                      userRoleCodes.contains('role_office_assistant')) {
                    return BrokerNavbar(currentIndex: 0);
                  } else if (userRoleCodes.contains('role_form_applications') ||
                      userRoleCodes.contains('role_form_applications_admin')) {
                    return BrokerNavbar(currentIndex: 0);
                  } else if (userRoleCodes.contains('role_sale_applications') ||
                      userRoleCodes.contains('role_sale_applications_admin')) {
                    return BrokerNavbar(currentIndex: 0);
                  } else {
                    return FrancahiseNavbar(currentIndex: 0);
                  }
                },
              );
            }
            return BrokerNavbar(currentIndex: 0);
          },
        ),
    ),
    );
  }

  Widget _buildDashboardSection({
    required String title,
    required IconData icon,
    required Widget child,
    EdgeInsets contentPadding = const EdgeInsets.all(16),
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderLight.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryRed.withOpacity(0.6),
                  _primaryRed.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryRed.withOpacity(0.14),
                        _primaryRed.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryRed.withOpacity(0.12)),
                  ),
                  child: Icon(icon, color: _primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: contentPadding,
            child: child,
          ),
        ],
      ),
    );
  }

  BoxDecoration _innerTileDecoration(Color accent) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.06),
          const Color(0xFFFAFAFA),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withOpacity(0.12)),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildOfficeHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryRed.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryRed, _secondaryRed],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Aktif Ofis',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _officeTitle.isNotEmpty ? _officeTitle : '—',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryRed.withOpacity(0.15)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_rounded,
                        color: _primaryRed,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Panel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryRed,
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
    );
  }

  Widget _buildLoadingPlaceholder() {
    return _buildDashboardSection(
      title: 'Genel Özet',
      icon: Icons.analytics_rounded,
      child: const EmptyDataView(
        compact: true,
        icon: Icons.analytics_outlined,
        title: 'Veri yok',
        subtitle: 'Bu dönemde gösterilecek istatistik yok',
      ),
    );
  }

  Widget _buildModernStatsSection() {
    final forRent = int.tryParse(_totalsData!.forRent) ?? 0;
    final forSale = int.tryParse(_totalsData!.forSale) ?? 0;
    final completed =
        (int.tryParse(_totalsData!.sold) ?? 0) + (int.tryParse(_totalsData!.rented) ?? 0);
    final customers = int.tryParse(_totalsData!.customers) ?? 0;
    final total = forRent + forSale + completed + customers;

    final cardData = [
      {
        'icon': Icons.vpn_key_rounded,
        'title': 'Kiralık İlan',
        'value': forRent.toString(),
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.home_rounded,
        'title': 'Satılık İlan',
        'value': forSale.toString(),
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.task_alt_rounded,
        'title': 'Tamamlanan\nSatış / Kiralama',
        'value': completed.toString(),
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Toplam Müşteri',
        'value': customers.toString(),
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return _buildDashboardSection(
      title: 'Genel Özet',
      icon: Icons.analytics_rounded,
      subtitle: 'Ofis performans göstergeleri',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: LayoutBuilder(
        builder: (context, gridConstraints) {
          final itemWidth = (gridConstraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cardData.map((data) {
              final value = int.tryParse(data['value'] as String) ?? 0;
              final percent = total > 0 ? ((value / total) * 100).round() : 0;
              return SizedBox(
                width: itemWidth,
                child: _buildModernStatGridItem(
                  icon: data['icon'] as IconData,
                  iconColor: data['color'] as Color,
                  title: data['title'] as String,
                  value: data['value'] as String,
                  percent: percent,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatIconBadge({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildPercentChip(int percent, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '%$percent',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildModernStatGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required int percent,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      decoration: _innerTileDecoration(iconColor),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildStatIconBadge(icon: icon, color: iconColor),
                    const Spacer(),
                    if (percent > 0) _buildPercentChip(percent, iconColor),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title.replaceAll('\n', ' '),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.5),
                    iconColor.withOpacity(0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLeaderCard({
    required int rank,
    required IconData icon,
    required Color accent,
    required String title,
    required String badge,
    required String amount,
  }) {
    const medalColors = [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];
    final medalColor =
        rank < medalColors.length ? medalColors[rank] : accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [medalColor, medalColor.withOpacity(0.4)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withOpacity(0.18),
                                accent.withOpacity(0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accent.withOpacity(0.2)),
                          ),
                          child: Icon(icon, color: accent, size: 24),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [medalColor, medalColor.withOpacity(0.75)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: medalColor.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${rank + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              amount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _primaryRed,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.emoji_events_rounded,
                      color: medalColor.withOpacity(0.75),
                      size: 26,
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

  Widget _buildModernOperationSection() {
    return _buildDashboardSection(
      title: 'Zecorner Ofisleri Operasyon Durumu',
      icon: Icons.pie_chart_rounded,
      subtitle: 'Kaydırarak detayları görüntüleyin',
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight.withOpacity(0.6)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildOperationGaugeCarousel(),
      ),
    );
  }

  List<Map<String, dynamic>> _getOperationChartData() {
    if (_totalsData == null) return [];

    final data = <Map<String, dynamic>>[];

    final entries = <MapEntry<String, MapEntry<int, Color>>>[
      MapEntry('Aktif', MapEntry(int.tryParse(_totalsData!.active) ?? 0, Colors.blue)),
      MapEntry('Satıldı', MapEntry(int.tryParse(_totalsData!.sold) ?? 0, Colors.green)),
      MapEntry('Kiralandı', MapEntry(int.tryParse(_totalsData!.rented) ?? 0, Colors.amber)),
      MapEntry('Reddedildi', MapEntry(int.tryParse(_totalsData!.rejected) ?? 0, Colors.red)),
      MapEntry('İptal Edildi', MapEntry(int.tryParse(_totalsData!.cancelled) ?? 0, Colors.lightBlue)),
      MapEntry('Değişiklik İsteniyor',
          MapEntry(int.tryParse(_totalsData!.changesRequired) ?? 0, Colors.teal)),
      MapEntry('Onay Bekliyor',
          MapEntry(int.tryParse(_totalsData!.waitingForApproval) ?? 0, Colors.orange)),
      MapEntry('Süresi Dolmuş', MapEntry(int.tryParse(_totalsData!.expired) ?? 0, Colors.purple)),
      MapEntry('Taslak', MapEntry(int.tryParse(_totalsData!.draft) ?? 0, Colors.pink)),
      MapEntry('Satılık İlan', MapEntry(int.tryParse(_totalsData!.forSale) ?? 0, Colors.indigo)),
      MapEntry('Kiralık İlan', MapEntry(int.tryParse(_totalsData!.forRent) ?? 0, Colors.cyan)),
    ];

    for (final entry in entries) {
      if (entry.value.key > 0) {
        data.add({
          'title': entry.key,
          'value': entry.value.key.toString(),
          'numericValue': entry.value.key.toDouble(),
          'color': entry.value.value,
        });
      }
    }

    final total = data.fold<double>(
        0, (sum, item) => sum + (item['numericValue'] as double));
    for (final item in data) {
      item['percentage'] =
          total > 0 ? ((item['numericValue'] as double) / total * 100) : 0.0;
    }

    return data;
  }

  Widget _buildOperationGaugeCarousel() {
    final data = _getOperationChartData();
    if (data.isEmpty) {
      if (_isLoading || _totalsData == null) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShimmerBox(height: 10, width: double.infinity),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Center(child: _buildShimmerCircle(size: 120)),
            ),
            const SizedBox(height: 12),
            _buildShimmerBox(height: 6, width: double.infinity),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == 0 ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return const EmptyDataView(
        compact: true,
        icon: Icons.pie_chart_outline_rounded,
        title: 'Veri yok',
        subtitle: 'Bu dönemde operasyon kaydı yok',
      );
    }

    final total = data.fold<double>(
        0, (sum, item) => sum + (item['numericValue'] as double));

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _stopOperationAutoScroll();
        } else if (notification is ScrollEndNotification) {
          _restartOperationAutoScroll();
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final fraction = total > 0
                      ? (item['numericValue'] as double) / total
                      : 0.0;
                  final isSelected = index == _currentOperationPage;
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (item['color'] as Color)
                            : (item['color'] as Color).withOpacity(0.35),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (item['color'] as Color)
                                      .withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _operationPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentOperationPage = index;
                });
              },
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final percentage = item['percentage'] as double;
                final color = item['color'] as Color;
                final title = item['title'] as String;
                final value = item['value'] as String;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 155,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _BrokerGaugePainter(
                            percentage: percentage,
                            color: color,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 62),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                    letterSpacing: -1.5,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: Colors.grey.shade100,
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.5),
                                        color,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '%${percentage.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _currentOperationPage;
              return GestureDetector(
                onTap: () {
                  _stopOperationAutoScroll();
                  _operationPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                  _restartOperationAutoScroll();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected
                        ? (item['color'] as Color)
                        : Colors.grey.shade300,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (item['color'] as Color).withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?>? onChanged,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    final isSelected = value != null;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? _primaryRed.withOpacity(0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? _primaryRed.withOpacity(0.28)
              : _borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 17,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          selectedItemBuilder: (context) {
            return items
                .map(
                  (item) => Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 17,
                        color: _primaryRed,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: item.child),
                    ],
                  ),
                )
                .toList();
          },
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isSelected ? _primaryRed : _textSecondary,
            size: 22,
          ),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorPerformanceSection() {
    final cards = _buildTopAdvisorCards();
    return _buildDashboardSection(
      title: 'Danışman Performans Durumu',
      icon: Icons.emoji_events_rounded,
      subtitle: 'Haftalık, aylık ve yıllık liderler',
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: cards.isEmpty
          ? const EmptyDataView(
              compact: true,
              icon: Icons.emoji_events_outlined,
              title: 'Veri yok',
              subtitle: 'Henüz danışman performans kaydı yok',
            )
          : SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.78,
                    child: cards[index],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildIncomeChart() {
    // Yıl ve aya göre günleri al
    List<DayModel> displayDays = [];
    if (_dailyData != null && _dailyData!.days.isNotEmpty) {
      // Tarihe göre sırala (en yeni en son)
      final sortedDays = List<DayModel>.from(_dailyData!.days)
        ..sort(
            (a, b) => DateTime.parse(a.day).compareTo(DateTime.parse(b.day)));
      
      // Yıl ve ay seçilmişse filtrele
      if (_selectedYear != null && _selectedMonth != null) {
        displayDays = sortedDays.where((day) {
          final dayDate = DateTime.parse(day.day);
          return dayDate.year == _selectedYear && dayDate.month == _selectedMonth;
        }).toList();
      } else if (_selectedYear != null) {
        // Sadece yıl seçilmişse
        displayDays = sortedDays.where((day) {
          final dayDate = DateTime.parse(day.day);
          return dayDate.year == _selectedYear;
        }).toList();
      } else {
        // Varsayılan: son 4 gün
        if (sortedDays.length > 4) {
          displayDays = sortedDays.sublist(sortedDays.length - 4);
        } else {
          displayDays = sortedDays;
        }
      }
      
      // Maksimum 4 gün göster
      if (displayDays.length > 4) {
        displayDays = displayDays.sublist(displayDays.length - 4);
      }
    }

    final availableYears = _getAvailableYears();
    final availableMonths = _selectedYear != null
        ? _getAvailableMonthsForYear(_selectedYear!)
        : <int>[];

    return _buildDashboardSection(
      title: 'Ofis Gelir Grafiği',
      icon: Icons.show_chart_rounded,
      subtitle: 'Günlük gelir trendi',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    hint: 'Yıl',
                    value: _selectedYear,
                    margin: const EdgeInsets.only(right: 6),
                    items: availableYears
                        .map(
                          (year) => DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: availableYears.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _selectedYear = value;
                              _selectedMonth ??= DateTime.now().month;
                            });
                            _reloadChart();
                          },
                  ),
                ),
                Expanded(
                  child: _buildFilterDropdown(
                    hint: 'Ay',
                    value: _selectedMonth,
                    margin: const EdgeInsets.only(left: 6),
                    items: availableMonths
                        .map(
                          (month) => DropdownMenuItem<int>(
                            value: month,
                            child: Text(_getMonthName(month)),
                          ),
                        )
                        .toList(),
                    onChanged: (_selectedYear == null || availableMonths.isEmpty)
                        ? null
                        : (value) {
                            setState(() {
                              _selectedMonth = value;
                            });
                            _reloadChart();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = DateTime.now().year;
                  _selectedMonth = DateTime.now().month;
                });
                _reloadChart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Filtreyi Temizle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight.withOpacity(0.9)),
              ),
              child: SizedBox(
              height: math.min(
                MediaQuery.of(context).size.height * 0.28,
                230,
              ),
              child: displayDays.isNotEmpty
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxRevenueForDays(displayDays),
                        backgroundColor: Colors.transparent,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => _primaryRed,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipRoundedRadius: 10,
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                _formatPrice(rod.toY.toStringAsFixed(0)),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < displayDays.length) {
                                  final date =
                                      DateTime.parse(displayDays[index].day);
                                  return _buildChartAxisDateLabel(date, meta);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final maxRevenue =
                                    _getMaxRevenueForDays(displayDays);
                                if (value == maxRevenue) {
                                  String formattedValue;
                                  if (maxRevenue >= 1000000) {
                                    formattedValue =
                                        '₺${(maxRevenue / 1000000).toStringAsFixed(1)}M';
                                  } else if (maxRevenue >= 1000) {
                                    formattedValue =
                                        '₺${(maxRevenue / 1000).toStringAsFixed(0)}K';
                                  } else {
                                    formattedValue = _formatPrice(
                                        maxRevenue.toStringAsFixed(0));
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 0.0, left: 0.0),
                                    child: Text(
                                      formattedValue,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryRed,
                                        letterSpacing: 0.2,
                                        height: 1,
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 0,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          drawHorizontalLine: true,
                          getDrawingHorizontalLine: (value) {
                            final maxRevenue =
                                _getMaxRevenueForDays(displayDays);
                            if (value == maxRevenue) {
                              return FlLine(
                                color: _primaryRed.withOpacity(0.35),
                                strokeWidth: 1.5,
                                dashArray: [5, 4],
                              );
                            }
                            return const FlLine(
                              color: Colors.transparent,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        barGroups: List.generate(
                          displayDays.length,
                          (index) {
                            final maxY = _getMaxRevenueForDays(displayDays);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: displayDays[index].revenue,
                                  width: displayDays.length <= 4 ? 36 : 26,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0xFFC62828),
                                      Color(0xFFEE2E24),
                                      Color(0xFFFF6B63),
                                    ],
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: const Color(0xFFEEF0F3),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    )
                  : _isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    color: _textSecondary, size: 42),
                                SizedBox(height: 12),
                                Text(
                                  'Gelir verileri yükleniyor...',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const EmptyDataView(
                          compact: true,
                          icon: Icons.show_chart_rounded,
                          title: 'Veri yok',
                          subtitle:
                              'Bu dönemde gösterilecek gelir kaydı yok',
                        ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam Net Kazanç',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    displayDays.isNotEmpty
                        ? _formatPrice(
                            _calculateTotalForDays(displayDays).toString())
                        : '₺0',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
      ),
    );
  }

  Widget _buildAwardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String price,
    int rank = 0,
  }) {
    return _buildPremiumLeaderCard(
      rank: rank,
      icon: icon,
      accent: iconColor,
      title: title,
      badge: subtitle,
      amount: price,
    );
  }

  Widget _buildModernPotentialCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    const accentGreen = Color(0xFF10B981);
    return GestureDetector(
      onTap: () {
        _showPotentialDetailsDialog(
          context: context,
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF9),
              Color(0xFFFFFFFF),
            ],
          ),
          border: Border.all(color: accentGreen.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: accentGreen.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentGreen, Color(0xFF059669)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentGreen.withOpacity(0.2),
                              accentGreen.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accentGreen.withOpacity(0.2)),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: accentGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: _textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _primaryRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: _primaryRed,
                          size: 20,
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
    );
  }

  void _showPotentialDetailsDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final forRent = int.tryParse(_totalsData?.forRent ?? '0') ?? 0;
    final forSale = int.tryParse(_totalsData?.forSale ?? '0') ?? 0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(dialogContext).size.width - 40,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Potansiyel Gelir Bilgilendirmesi',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _primaryRed,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_potentialIncomeData != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryRed.withOpacity(0.1),
                              _primaryRed.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryRed.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money_rounded,
                                  color: _primaryRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Güncel Potansiyel Gelir',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatPrice(
                                    _potentialIncomeData!.potentialIncome),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryRed,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Potansiyel gelir, yayında olan satılık ve kiralık ilanlarınızın satış veya kiralanması durumunda elde edilecek tahmini geliri göstermektedir. Kiralık ilanlar için bir aylık kira bedeli, satılık ilanlar için ise %2 alıcıdan ve %2 satıcıdan olmak üzere toplam %4 komisyon üzerinden hesaplama yapılır.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hesaplama Detayları',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDialogDetailRow(
                            'Kiralık İlanlar',
                            '$forRent adet',
                          ),
                          const SizedBox(height: 6),
                          _buildDialogDetailRow(
                            'Satılık İlanlar',
                            '$forSale adet',
                          ),
                          const SizedBox(height: 6),
                          _buildDialogDetailRow(
                            'Toplam İlan',
                            '${forRent + forSale} adet',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tamam',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _primaryRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  /// Para formatı için yardımcı metot - Web formatı: ₺743.000,00
  String _formatPrice(String priceString) {
    try {
      final price = double.tryParse(priceString.replaceAll(',', '.')) ?? 0.0;
      final parts = price.toStringAsFixed(2).split('.');
      final formattedInteger = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
      return '₺$formattedInteger,${parts[1]}';
    } catch (e) {
      return "₺0,00";
    }
  }

  /// Belirli günler için maksimum gelir değerini hesapla
  double _getMaxRevenueForDays(List<DayModel> days) {
    if (days.isEmpty) return 1000000;

    double maxRevenue = 0;
    for (var day in days) {
      if (day.revenue > maxRevenue) {
        maxRevenue = day.revenue;
      }
    }
    return maxRevenue * 1.1; // %10 margin ekle
  }

  /// Belirli günler için toplam gelir hesapla
  double _calculateTotalForDays(List<DayModel> days) {
    if (days.isEmpty) return 0;

    double total = 0;
    for (var day in days) {
      total += day.revenue;
    }
    return total;
  }

  /// Grafik X ekseni: ay üstte, gün altta
  Widget _buildChartAxisDateLabel(DateTime date, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getMonthName(date.month),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
              height: 1.05,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Ay adını döndür
  String _getMonthName(int month) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month];
  }

  /// Web ile aynı: 2024’ten bu yıla, en yeni yıl üstte.
  List<int> _getAvailableYears() => DashboardRepository.chartFilterYears();

  /// Web ile aynı: seçilen yıl için 12 ay.
  List<int> _getAvailableMonthsForYear(int year) {
    if (year <= 0) return const [];
    return DashboardRepository.chartFilterMonths();
  }

  Future<void> _reloadChart() async {
    final year = _selectedYear ?? DateTime.now().year;
    final month = _selectedMonth ?? DateTime.now().month;
    final result = await _dashboardRepo.getDashboardDailyRevenue(
      year: year,
      month: month,
    );
    if (!mounted) return;
    result.fold((_) {}, (data) {
      try {
        setState(() => _dailyData = OfficeDailyModel.fromJson(data));
      } catch (e) {
        print('⚠️ Grafik yenilenemedi: $e');
      }
    });
  }

  /// Top advisor kartları oluştur - OfficeTopModel kullanarak
  List<Widget> _buildTopAdvisorCards() {
    print('🚀 _buildTopAdvisorCards çağrıldı');

    List<Widget> cards = [];

    if (_topData != null && _topData!.week.isNotEmpty) {
      final weekAdvisor = _topData!.week.first;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.blue,
        title: weekAdvisor.advisorTitle,
        subtitle: "Haftanın Yıldızı",
        price: _formatPrice(weekAdvisor.total),
        rank: 0,
      ));
    }

    if (_topData != null && _topData!.month.isNotEmpty) {
      final monthAdvisor = _topData!.month.first;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.amber,
        title: monthAdvisor.advisorTitle,
        subtitle: "Ayın Yıldızı",
        price: _formatPrice(monthAdvisor.total),
        rank: 1,
      ));
    }

    if (_topData != null && _topData!.year.isNotEmpty) {
      final yearAdvisor = _topData!.year.first;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.green,
        title: yearAdvisor.advisorTitle,
        subtitle: "Yılın Yıldızı",
        price: _formatPrice(yearAdvisor.total),
        rank: 2,
      ));
    }

    print('🎯 Final advisor cards count: ${cards.length}');
    return cards;
  }

  /// Modern Skeleton Loading Widget
  Widget _buildSkeletonLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSkeletonSectionCard(
          child: _buildShimmerBox(height: 56, width: double.infinity),
        ),
        const SizedBox(height: 16),
        _buildSkeletonSectionCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(
                  4,
                  (_) => SizedBox(
                    width: itemWidth,
                    height: 118,
                    child: _buildSkeletonStatItem(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildShimmerBox(height: 36, width: 36),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildShimmerBox(height: 18, width: double.infinity)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSkeletonStatItem() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderLight),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildShimmerBox(height: 36, width: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(height: 22, width: 40),
              const SizedBox(height: 6),
              _buildShimmerBox(height: 10, width: double.infinity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double height,
    required double width,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final t = _shimmerController.value;
        final base = Colors.grey.shade200;
        final highlight = Colors.grey.shade100;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: height,
            width: width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + t * 2, 0),
                  end: Alignment(0.0 + t * 2, 0),
                  colors: [base, highlight, base],
                  stops: const [0.25, 0.5, 0.75],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle({required double size}) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _buildShimmerBox(height: size, width: size),
      ),
    );
  }
}

class _BrokerGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _BrokerGaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.80);
    final radius = math.min(size.width * 0.35, size.height * 0.54);
    const strokeWidth = 24.0;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final clampedPercent = (percentage / 100).clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final filledSweep = sweepAngle * clampedPercent;
    if (filledSweep > 0.01) {
      final lighterColor = Color.lerp(Colors.white, color, 0.45)!;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        filledSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            center: Alignment.center,
            startAngle: startAngle,
            endAngle: startAngle + sweepAngle,
            colors: [lighterColor, color, color],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );

      final endAngle = startAngle + filledSweep;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      canvas.drawCircle(
          dotCenter, 16, Paint()..color = color.withOpacity(0.12));
      canvas.drawCircle(
          dotCenter, 11, Paint()..color = color.withOpacity(0.08));
      canvas.drawCircle(dotCenter, 8, Paint()..color = Colors.white);
      canvas.drawCircle(dotCenter, 5.5, Paint()..color = color);
    }

    final edgeLabels = [
      {'pos': 0.0, 'text': '0%'},
      {'pos': 1.0, 'text': '100%'},
    ];

    for (final label in edgeLabels) {
      final angle = startAngle + sweepAngle * (label['pos'] as double);
      final textSpan = TextSpan(
        text: label['text'] as String,
        style: const TextStyle(
          color: Color(0xFFADB5BD),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();
      final labelR = radius + strokeWidth / 2 + 14;
      tp.paint(
        canvas,
        Offset(
          center.dx + labelR * math.cos(angle) - tp.width / 2,
          center.dy + labelR * math.sin(angle) - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrokerGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
