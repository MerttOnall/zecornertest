import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/card/danisman_kisi_table.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/status/login_intro_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:zecorner/infrastructure/dashboard/dashboard_repository.dart';
import 'package:zecorner/models/dashboard/advisor/advisor_totals_model.dart';
import 'package:zecorner/models/dashboard/advisor/advisor_daily_model.dart';
import 'package:zecorner/models/dashboard/potential/potential_income_model.dart';
import 'package:zecorner/infrastructure/potential/potential_income_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';

class _PieItem {
  final String label;
  final double value;
  final Color color;
  const _PieItem(this.label, this.value, this.color);
}

class DanismanDashboardScreen extends StatefulWidget {
  const DanismanDashboardScreen({super.key});

  @override
  State<DanismanDashboardScreen> createState() =>
      _DanismanDashboardScreenState();
}

class _DanismanDashboardScreenState extends State<DanismanDashboardScreen>
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
  static bool _drawerOpenedOnce = false;
  String? _selectedPieSection;
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;
  late AnimationController _shimmerController;

  // Universal Dashboard Repository - Role-based automatic endpoint selection
  final DashboardRepository _dashboardRepo = DashboardRepository();
  final PotentialIncomeRepository _potentialIncomeRepo = PotentialIncomeRepository();

  // Dashboard State
  bool _isLoading = false;
  
  // Dashboard Data
  AdvisorTotalsModel? _totalsData;
  PotentialIncomeModel? _potentialIncomeData;
  AdvisorDailyModel? _dailyData;
  
  // Chart Filter State
  int? _selectedYear = DateTime.now().year;
  int? _selectedMonth = DateTime.now().month;

  // Operation Gauge Carousel
  late final PageController _operationPageController;
  int _currentOperationPage = 0;
  Timer? _operationAutoScrollTimer;
  Timer? _operationRestartDelayTimer;

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _textScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutBack,
    ));

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
    _loadDashboardData();
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

  @override
  void dispose() {
    _textAnimationController.dispose();
    _shimmerController.dispose();
    _operationAutoScrollTimer?.cancel();
    _operationRestartDelayTimer?.cancel();
    _operationPageController.dispose();
    super.dispose();
  }

  /// Dashboard verilerini API'den yükle
  Future<void> _loadDashboardData() async {
    print('🎯 DanismanDashboard - _loadDashboardData başlatıldı');
    setState(() {
      _isLoading = true;
    });

    try {
      // Dashboard API çağrıları
      print('🎯 API çağrıları yapılıyor...');
      final totalsResult = await _dashboardRepo.getDashboardTotals();
      final potentialResult = await _potentialIncomeRepo.getPotentialIncome();
      // Danışman dashboard için direkt advisor daily revenue endpoint'ini kullan
      final dailyResult = await _dashboardRepo.getAdvisorDailyRevenue(
        year: _selectedYear,
        month: _selectedMonth,
      );

      // Totals verilerini işle
      totalsResult.fold(
        (failure) {
          print('❌ Totals API Hatası: ${failure.message}');
          print('❌ Status Code: ${failure.statusCode}');
          _totalsData = null;
        },
        (data) {
          print('✅ Totals API Başarılı - Raw Data: $data');
          _totalsData = AdvisorTotalsModel.fromJson(data);
          print('✅ Totals Model oluşturuldu: ${_totalsData.toString()}');
          print('✅ Totals API verisi başarıyla yüklendi');
        },
      );

      // Potential Income verilerini işle
      potentialResult.fold(
        (failure) {
          print('❌ Potential Income API Hatası: ${failure.message}');
          print('❌ Status Code: ${failure.statusCode}');
          _potentialIncomeData = null;
        },
        (data) {
          print('✅ Potential Income API Başarılı - Raw Data: $data');
          _potentialIncomeData = data;
          print('✅ Potential Income Model oluşturuldu: ${_potentialIncomeData.toString()}');
          print('✅ Potential Income API verisi başarıyla yüklendi');
        },
      );

      // Daily Revenue verilerini işle
      dailyResult.fold(
        (failure) {
          print('❌ Daily Revenue API Hatası: ${failure.message}');
          print('❌ Status Code: ${failure.statusCode}');
          _dailyData = null;
        },
        (data) {
          try {
            print('🔍 Daily Revenue API RAW DATA: $data');
            _dailyData = AdvisorDailyModel.fromJson(data);
            print('✅ Daily Revenue verileri yüklendi - Days count: ${_dailyData!.days.length}');
            print('🔍 Total Revenue: ₺${_dailyData!.total}');
            print('🔍 Sample Days:');
            for (var i = 0; i < math.min(5, _dailyData!.days.length); i++) {
              final day = _dailyData!.days[i];
              print('  - ${day.day}: ₺${day.revenue}');
            }
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
            print('📦 Raw data: $data');
            _dailyData = null;
          }
        },
      );
      
      // Eğer repo çağrısı başarısız olduysa, danışman dashboard'a özel doğrudan çağrı yap
      if (_totalsData == null) {
        print('🔄 Repo başarısız oldu, danışman dashboard için doğrudan API çağrısı deneniyor...');
        final directData = await _fetchAdvisorTotalsDirect();
        if (directData != null) {
          _totalsData = directData;
          print('✅ Doğrudan çağrı ile veriler alındı.');
        }
      }

      // Pie chart için veri kontrolü
      if (_totalsData != null) {
        print('🎯 Pie chart için veri kontrolü yapılıyor...');
        print('📊 Active: ${_totalsData!.active}');
        print('📊 Sold: ${_totalsData!.sold}');
        print('📊 Rented: ${_totalsData!.rented}');
        print('📊 ForRent: ${_totalsData!.forRent}');
        print('📊 Progress - Level: ${_totalsData!.progress.level}');
        print('📊 Progress - Treshold: ${_totalsData!.progress.treshold}');
        print('📊 Progress - Remaining Try: ${_totalsData!.progress.remainingTry}');
      }

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
      print('❌ Genel Hata: $e');
      setState(() {
        _isLoading = false;
        _totalsData = null;
        _dailyData = null;
      });
    }
  }

  // Danışman dashboard için doğrudan API çağrısı
  Future<AdvisorTotalsModel?> _fetchAdvisorTotalsDirect() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');

      if (token == null || token.isEmpty) {
        print('❌ Doğrudan çağrı: Token yok');
        return null;
      }

      final String baseUrl = dotenv.env["BASE_URL"] ?? '${EnvApi.origin}';
      final String apiKey = dotenv.env["X_API_KEY"] ?? 'ed017c68-24ca-4239-ae68-0fa041391855';
      final String appId = dotenv.env["X_APP_ID"] ?? 'zecorner';

      final headers = {
        'Authorization': 'Bearer $token',
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'X-SESSION': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final url = "$baseUrl/api/zecorner/dashboard/advisor/totals";
      print('🌐 Doğrudan Advisor Totals URL: $url');

      final dio = DioClient().dio;
      final response = await dio.get(url, options: Options(headers: headers));
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return AdvisorTotalsModel.fromJson(data);
      }
    } on DioException catch (e) {
      print('❌ Doğrudan çağrı DioException: ${e.message} - ${e.response?.data}');
    } catch (e) {
      print('❌ Doğrudan çağrı genel hata: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ DanismanDashboard build çağrıldı - _isLoading: $_isLoading, _totalsData: ${_totalsData != null ? "MEVCUT" : "NULL"}');
    if (_totalsData != null) {
      print('📊 Build - Active: ${_totalsData!.active}');
      print('📊 Build - Sold: ${_totalsData!.sold}');
      print('📊 Build - Rented: ${_totalsData!.rented}');
      print('📊 Build - ForRent: ${_totalsData!.forRent}');
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
                    _buildAdvisorHeader(),
                    const SizedBox(height: 14),
                    _isLoading
                        ? _buildSkeletonLoading()
                        : _totalsData != null
                            ? Column(
                                children: [
                                  _buildModernPerformanceSection(),
                                  const SizedBox(height: 14),
                                  _buildModernStatsSection(),
                                ],
                              )
                            : _buildLoadingPlaceholder(),
                    const SizedBox(height: 14),
                    _buildModernPotentialCard(
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      title: 'Potansiyel Gelir Hesaplaması',
                      subtitle: _getPotentialIncome(),
                    ),
                    const SizedBox(height: 14),
                    _buildModernOperationSection(),
                    const SizedBox(height: 14),
                    _buildIncomeChart(),
                    const SizedBox(height: 16),
                    const DanismanKisiTable(),
                  ],
                ),
              ),
            ],
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
                  print('Danisman Dashboard - Bottom Navbar - User Role Codes: $userRoleCodes');
                  
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
            return const DanismanNavbar(currentIndex: 0);
          },
        ),
    ),
    );
  }

  /// Ana bölüm kartı — ince kırmızı çizgi, yumuşak gölge
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

  Widget _buildAdvisorHeader() {
    final name =
        context.read<AuthCubit>().currentUser?.fullName.trim() ?? '';
    final greeting = name.isNotEmpty ? name : 'Danışman Paneli';

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
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
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
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoş geldiniz',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 18,
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
                  child: const Text(
                    'Danışman',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPerformanceSection() {
    return _buildDashboardSection(
      title: 'Performans Özeti',
      icon: Icons.trending_up_rounded,
      subtitle: 'Yıllık hedef ve seviye',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _buildProgressCard(
            currentAmount: _totalsData!.progress.yearTotal,
            targetAmount: _totalsData!.progress.treshold,
            remainingTry: _totalsData!.progress.remainingTry,
            consultantName: 'Kalan Tutar',
          ),
          const SizedBox(height: 12),
          _buildLevelCard(
            level: _totalsData!.progress.level,
            levelName: 'Seviye',
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsSection() {
    final forRent = _totalsData!.forRent;
    final forSale = _totalsData!.forSale;
    final completed = _totalsData!.sold + _totalsData!.rented;
    final customers = _totalsData!.customers;
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
        'title': 'Tamamlanan Satış / Kiralama',
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
      subtitle: 'Portföy ve müşteri göstergeleri',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: LayoutBuilder(
        builder: (context, gridConstraints) {
          final itemWidth = (gridConstraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cardData.map((data) {
              final value = int.tryParse(data['value'] as String) ?? 0;
              final percent =
                  total > 0 ? ((value / total) * 100).round() : 0;
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                  title,
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildModernOperationSection() {
    return _buildDashboardSection(
      title: 'Danışman Operasyon Durumu',
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

  /// Operasyon verileri - gauge carousel (admin dashboard ile aynı görünüm)
  List<Map<String, dynamic>> _getOperationChartData() {
    if (_totalsData == null) return [];

    final data = <Map<String, dynamic>>[];

    final entries = <MapEntry<String, MapEntry<int, Color>>>[
      MapEntry('Yayında', MapEntry(_totalsData!.active, Colors.blue)),
      MapEntry('Satıldı', MapEntry(_totalsData!.sold, Colors.green)),
      MapEntry('Kiralandı', MapEntry(_totalsData!.rented, Colors.amber)),
      MapEntry('Reddedildi', MapEntry(_totalsData!.rejected, Colors.red)),
      MapEntry(
          'İptal Edildi', MapEntry(_totalsData!.cancelled, Colors.lightBlue)),
      MapEntry('Değişiklik İsteniyor',
          MapEntry(_totalsData!.changesRequired, Colors.teal)),
      MapEntry('Onay Bekliyor',
          MapEntry(_totalsData!.waitingForApproval, Colors.orange)),
      MapEntry('Süresi Dolmuş', MapEntry(_totalsData!.expired, Colors.purple)),
      MapEntry('Taslak', MapEntry(_totalsData!.draft, Colors.pink)),
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

  /// Operasyon Durumu - Modern Gauge Carousel (admin ile aynı)
  Widget _buildOperationGaugeCarousel() {
    final data = _getOperationChartData();
    if (data.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShimmerBox(
            height: 10,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Center(
              child: _buildShimmerCircle(size: 120),
            ),
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
                          painter: _DanismanGaugePainter(
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

  Widget _buildLoadingPlaceholder() {
    return _buildDashboardSection(
      title: 'Genel Özet',
      icon: Icons.analytics_rounded,
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 40),
          SizedBox(height: 12),
          Text(
            'İstatistik verileri yükleniyor...',
            style: TextStyle(color: Colors.grey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.white,
                ],
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.red : Colors.red.shade300,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.red : Colors.red.shade900,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
        hoverColor: Colors.red.shade50,
        selectedTileColor: Colors.red.shade50,
        selected: isSelected,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  List<_PieItem> _getPieItems() {
    final totals = _totalsData;
    if (totals == null) {
      return [
        _PieItem('Yayında', 30, Colors.blue),
        _PieItem('Satıldı', 10, Colors.green),
        _PieItem('Kiralandı', 25, Colors.amber),
        _PieItem('Reddedildi', 15, Colors.red),
        _PieItem('İptal Edildi', 12, Colors.lightBlue),
        _PieItem('Değişiklik İsteniyor', 8, Colors.teal),
        _PieItem('Onay Bekliyor', 0, Colors.orange),
        _PieItem('Süresi Dolmuş', 0, Colors.purple),
        _PieItem('Taslak', 0, Colors.pink),
      ];
    }
    return [
      _PieItem('Yayında', totals.active.toDouble(), Colors.blue),
      _PieItem('Satıldı', totals.sold.toDouble(), Colors.green),
      _PieItem('Kiralandı', totals.rented.toDouble(), Colors.amber),
      _PieItem('Reddedildi', totals.rejected.toDouble(), Colors.red),
      _PieItem('İptal Edildi', totals.cancelled.toDouble(), Colors.lightBlue),
      _PieItem('Değişiklik İsteniyor', totals.changesRequired.toDouble(), Colors.teal),
      _PieItem('Onay Bekliyor', totals.waitingForApproval.toDouble(), Colors.orange),
      _PieItem('Süresi Dolmuş', totals.expired.toDouble(), Colors.purple),
      _PieItem('Taslak', totals.draft.toDouble(), Colors.pink),
    ].where((e) => e.value > 0).toList();
  }

  /// Seçilen bölümün değerini döndür
  String? _getSelectedSectionValue(String sectionName) {
    if (_totalsData == null) return null;
    
    switch (sectionName) {
      case 'Yayında':
        return _totalsData!.active.toString();
      case 'Satıldı':
        return _totalsData!.sold.toString();
      case 'Kiralandı':
        return _totalsData!.rented.toString();
      case 'Reddedildi':
        return _totalsData!.rejected.toString();
      case 'İptal Edildi':
        return _totalsData!.cancelled.toString();
      case 'Değişiklik İsteniyor':
        return _totalsData!.changesRequired.toString();
      case 'Onay Bekliyor':
        return _totalsData!.waitingForApproval.toString();
      case 'Süresi Dolmuş':
        return _totalsData!.expired.toString();
      case 'Taslak':
        return _totalsData!.draft.toString();
      default:
        return null;
    }
  }

  /// Pie chart section title'larını döndür (sadece 0'dan büyük değerler için)
  List<String> _getPieSectionTitles() {
    if (_totalsData == null) return [];
    
    List<String> titles = [];
    
    // Sections ile aynı sırada - sadece 0'dan büyük değerleri ekle
    if (_totalsData!.active > 0) titles.add('Yayında');
    if (_totalsData!.sold > 0) titles.add('Satıldı');
    if (_totalsData!.rented > 0) titles.add('Kiralandı');
    if (_totalsData!.rejected > 0) titles.add('Reddedildi');
    if (_totalsData!.cancelled > 0) titles.add('İptal Edildi');
    if (_totalsData!.changesRequired > 0) titles.add('Değişiklik İsteniyor');
    if (_totalsData!.waitingForApproval > 0) titles.add('Onay Bekliyor');
    if (_totalsData!.expired > 0) titles.add('Süresi Dolmuş');
    if (_totalsData!.draft > 0) titles.add('Taslak');
    
    return titles;
  }

  /// Pie chart sections oluştur - Web ile aynı 9 statü
  List<PieChartSectionData> _buildPieChartSections() {
    print('🎯 _buildPieChartSections çağrıldı');
    print('🎯 _totalsData: ${_totalsData != null ? "MEVCUT" : "NULL"}');
    
    if (_totalsData == null) {
      print('⚠️ _totalsData null - default sections döndürülüyor');
      // Default sections - veri yoksa
      return [
        PieChartSectionData(value: 30, color: Colors.blue, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 10, color: Colors.green, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 25, color: Colors.amber, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 15, color: Colors.red, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 12, color: Colors.lightBlue, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 8, color: Colors.teal, title: '', radius: 60, showTitle: false),
      ];
    }

    print('✅ _totalsData mevcut - API verileri kullanılıyor');
    print('📊 Active: ${_totalsData!.active}');
    print('📊 Sold: ${_totalsData!.sold}');
    print('📊 Rented: ${_totalsData!.rented}');
    print('📊 ForSale: ${_totalsData!.forSale}');
    print('📊 ForRent: ${_totalsData!.forRent}');
    print('📊 Rejected: ${_totalsData!.rejected}');
    print('📊 Cancelled: ${_totalsData!.cancelled}');
    print('📊 ChangesRequired: ${_totalsData!.changesRequired}');
    print('📊 WaitingForApproval: ${_totalsData!.waitingForApproval}');
    print('📊 Expired: ${_totalsData!.expired}');
    print('📊 Draft: ${_totalsData!.draft}');

    // Webdeki 9 statüye göre dinamik sections
    final items = _getPieItems();
    List<PieChartSectionData> sections = [];
    
    print('🎯 Sections oluşturuluyor...');
    
    // Sadece 0'dan büyük değerleri ekle
    for (final item in items) {
      sections.add(PieChartSectionData(
        value: item.value,
        color: item.color,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }
    
    // Not: Web grafiğinde "Satılık/Kiralık ilan" yer almıyor, bu ikisini legend'dan ve datasından çıkardık
    
    print('🎯 Toplam ${sections.length} section oluşturuldu');
    print('🎯 Sections: $sections');
    
    // Eğer hiç section yoksa, üç örnek dilim göster
    if (sections.isEmpty) {
      print('⚠️ Hiç section yok, örnek dilimler ekleniyor');
      for (final item in _getPieItems().take(3)) {
        sections.add(PieChartSectionData(
          value: item.value,
          color: item.color,
          title: '',
          radius: 60,
          showTitle: false,
        ));
      }
      print('✅ Örnek sections eklendi: ${sections.length}');
    }
    
    return sections;
  }

  /// Para formatı için yardımcı metot
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

  /// Mobil format için para formatı - Binlik ve ondalık ayırıcı nokta: ₺841.473.946.77
  String _formatPriceMobile(double price) {
    try {
      // Negatif işareti kontrolü
      final isNegative = price < 0;
      final absPrice = price.abs();
      
      // Ondalık kısmı al (2 basamak)
      final priceString = absPrice.toStringAsFixed(2);
      final parts = priceString.split('.');
      final integerPart = int.parse(parts[0]);
      final decimalString = parts[1];
      
      // Binlik ayırıcı ekle (nokta ile)
      final integerString = integerPart.toString();
      final formattedInteger = integerString.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
        (match) => '${match[1]}.'
      );
      
      final sign = isNegative ? '-' : '';
      return "$sign₺$formattedInteger.$decimalString";
    } catch (e) {
      return "₺0.00";
    }
  }

  /// Potansiyel gelir değerini güvenli şekilde al
  String _getPotentialIncome() {
    try {
      if (_potentialIncomeData != null) {
        return _formatPrice(_potentialIncomeData!.potentialIncome);
      }
      return "₺1.640.000";
    } catch (e) {
      return "₺1.640.000";
    }
  }

  /// Maksimum gelir değerini hesapla
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

  /// Ay adını döndür
  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
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
    final result = await _dashboardRepo.getAdvisorDailyRevenue(
      year: year,
      month: month,
    );
    if (!mounted) return;
    result.fold((_) {}, (data) {
      try {
        setState(() => _dailyData = AdvisorDailyModel.fromJson(data));
      } catch (e) {
        print('⚠️ Grafik yenilenemedi: $e');
      }
    });
  }

  Widget _buildIncomeChart() {
    // Yıl ve aya göre günleri al
    List<DayModel> displayDays = [];
    if (_dailyData != null && _dailyData!.days.isNotEmpty) {
      // Tarihe göre sırala (en yeni en son)
      final sortedDays = List<DayModel>.from(_dailyData!.days)
        ..sort((a, b) => DateTime.parse(a.day).compareTo(DateTime.parse(b.day)));
      
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
      title: 'Danışman Gelir Grafiği',
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
                            getTooltipColor: (group) => const Color.fromRGBO(238, 46, 36, 1),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '₺${rod.toY.toStringAsFixed(0)}',
                                const TextStyle(
                                  color: Color.fromARGB(255, 252, 252, 252),
                                  fontWeight: FontWeight.bold,
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
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < displayDays.length) {
                                  final day = displayDays[value.toInt()];
                                  final date = DateTime.parse(day.day);
                                  return Text(
                                    '${date.day} ${_getMonthName(date.month)} ${date.year}',
                                    style: TextStyle(
                                      fontSize: displayDays.length <= 4 ? 15 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final maxRevenue = _getMaxRevenueForDays(displayDays);
                                if (value == maxRevenue) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 0.0, left: 0.0),
                                    child: Text(
                                      '₺${(maxRevenue / 1000000).toStringAsFixed(1)}M',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD32F2F),
                                        letterSpacing: 0.5,
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
                          drawHorizontalLine: true,
                          getDrawingHorizontalLine: (value) {
                            final maxRevenue = _getMaxRevenueForDays(displayDays);
                            if (value == maxRevenue) {
                              return FlLine(
                                color: const Color(0xFFE53935),
                                strokeWidth: 2,
                                dashArray: [6, 4],
                              );
                            }
                            return FlLine(
                              color: Colors.transparent,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        barGroups: List.generate(
                          displayDays.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: displayDays[index].revenue,
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFFEE2E24),
                                    Color(0xFFFF6B63),
                                  ],
                                ),
                                width: displayDays.length <= 4 ? 28 : 18,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bar_chart, color: Colors.grey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Gelir verileri yükleniyor...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
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
                  const Flexible(
                    child: Text(
                      'Toplam Net Kazanç',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayDays.isNotEmpty
                          ? _formatPrice(
                              _calculateTotalForDays(displayDays).toString())
                          : '₺0,00',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
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
          color: isSelected ? _primaryRed.withOpacity(0.28) : _borderLight,
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
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isSelected ? _primaryRed : _textSecondary,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAwardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.13),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, color: iconColor, size: 28),
                radius: 22,
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color.fromRGBO(238, 46, 36, 1),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
                          border:
                              Border.all(color: accentGreen.withOpacity(0.2)),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi kartı
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Bilgilendirme",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(238, 46, 36, 1),
                                ),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "Potansiyel gelir, yayında olan satılık ve kiralık ilanlarınızın satış veya kiralanması durumunda elde edilecek tahmini geliri göstermektedir. Kiralık ilanlar için bir aylık kira bedeli, satılık ilanlar için ise %2 alıcıdan ve %2 satıcıdan olmak üzere toplam %4 komisyon üzerinden hesaplama yapılır.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
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
        );
      },
    );
  }

  Widget buildFlexibleStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    double height = 60,
    double width = double.infinity,
    double borderRadius = 12,
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE0E0E0),
    bool showShadow = false,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required double currentAmount,
    required double targetAmount,
    required double remainingTry,
    required String consultantName,
  }) {
    final progressPercentage =
        targetAmount > 0 ? currentAmount / targetAmount : 0.0;
    final isCompleted = progressPercentage >= 1.0;
    const accentBlue = Color(0xFF3B82F6);
    const accentGreen = Color(0xFF10B981);
    final accent = isCompleted ? accentGreen : accentBlue;
    final progressFactor =
        isCompleted ? 1.0 : progressPercentage.clamp(0.0, 1.0);
    final progressPercent = (progressFactor * 100).round();

    return Container(
      decoration: _innerTileDecoration(accent),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatIconBadge(
                  icon: Icons.show_chart_rounded,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yıllık Performans',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isCompleted
                            ? 'Hedef tamamlandı'
                            : 'Hedefe kalan ${_formatPriceMobile(remainingTry)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildPercentChip(progressPercent, accent),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isCompleted
                    ? 'Tebrikler'
                    : _formatPriceMobile(currentAmount),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted
                  ? 'Hedef başarıyla tamamlandı'
                  : consultantName == 'Kalan Tutar'
                      ? 'Bu yıl gerçekleşen ciro'
                      : consultantName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: accent.withOpacity(0.12)),
                    FractionallySizedBox(
                      widthFactor: progressFactor,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [
                                    const Color(0xFF34D399),
                                    accentGreen,
                                  ]
                                : [
                                    const Color(0xFF60A5FA),
                                    accentBlue,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hedef ${_formatPriceMobile(targetAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
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
    );
  }

  Widget _buildLevelCard({
    required int level,
    required String levelName,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLevelInfoDialog(context, level, levelName),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: _innerTileDecoration(_primaryRed),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryRed, _secondaryRed],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      level.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Danışman Seviyeniz',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _primaryRed,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLevelInfoDialog(BuildContext context, int level, String levelName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basit header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Seviye Bilgilendirme",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seviye gösterimi
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              level.toString(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Şu anki seviyeniz: Seviye $level",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${level + 1}. seviyeye ulaşmak için 100.000TL ile 200.000TL arasında bir tutar yapınız.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Kapat butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Tamam",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Modern Skeleton Loading Widget
  Widget _buildSkeletonLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSkeletonSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShimmerBox(height: 88, width: double.infinity),
              const SizedBox(height: 12),
              _buildShimmerBox(height: 64, width: double.infinity),
            ],
          ),
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
              Expanded(child: _buildShimmerBox(height: 18, width: double.infinity)),
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

  /// Skeleton Card Widget
  Widget _buildSkeletonCard({
    required double height,
    required double width,
    Widget? child,
  }) {
    return Container(
      height: height,
      width: width,
      padding: EdgeInsets.all(height < 100 ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child != null
          ? ClipRect(
              child: child,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final circleSize = availableHeight < 80 ? 36.0 : 48.0;
                final boxHeight = availableHeight < 80 ? 24.0 : 30.0;
                final bottomBoxHeight = availableHeight < 80 ? 12.0 : 16.0;
                final spacing = availableHeight < 80 ? 6.0 : 8.0;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShimmerCircle(size: circleSize),
                        _buildShimmerBox(height: boxHeight, width: 60),
                      ],
                    ),
                    SizedBox(height: spacing),
                    _buildShimmerBox(height: bottomBoxHeight, width: double.infinity),
                  ],
                );
              },
            ),
    );
  }

  /// Shimmer Box Widget — taşma ve piksel artefaktı olmadan
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

  /// Shimmer Circle Widget
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

/// Modern Gauge CustomPainter - admin dashboard ile aynı
class _DanismanGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _DanismanGaugePainter({required this.percentage, required this.color});

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
  bool shouldRepaint(covariant _DanismanGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}