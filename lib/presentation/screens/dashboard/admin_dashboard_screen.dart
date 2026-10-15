import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/card/panel_danisman_card.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/status/login_intro_loader.dart';
import 'dart:math' as math;
import 'dart:async';

// Dashboard Repository Import - Universal
import 'package:zecorner/infrastructure/dashboard/dashboard_repository.dart';
import 'package:zecorner/models/dashboard/admin /admin_totals_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_office_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_advisor_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_top_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_daily_model.dart';

import 'package:zecorner/presentation/widgets/admin-panel/card/panel_office_table.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
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
  late final AnimationController _rotationController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;
  String? _selectedPieSection;
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;

  // Operation Gauge Carousel
  late final PageController _operationPageController;
  int _currentOperationPage = 0;
  Timer? _operationAutoScrollTimer;
  Timer? _operationRestartDelayTimer;
  late AnimationController _shimmerController;

  // Universal Dashboard Repository - Role-based automatic endpoint selection
  final DashboardRepository _dashboardRepo = DashboardRepository();

  // Dashboard State
  bool _isLoading = true;

  // Dashboard Data
  AdminTotalsModel? _totalsData;
  AdminOfficeModel? _officeData;
  AdminAdvisorModel? _advisorData;
  AdminTopModel? _topData;
  AdminDailyModel? _dailyData;

  // Chart Filter State
  String _selectedMetric = "Gelir";
  int? _selectedYear;
  int? _selectedMonth;

  // Card Expansion State
  final Map<String, bool> _cardExpanded = {
    'rental': false,
    'sale': false,
    'completed': false,
    'customers': false,
  };

  // Card Animation Controllers
  late final AnimationController _rentalCardController;
  late final AnimationController _saleCardController;
  late final AnimationController _completedCardController;
  late final AnimationController _customersCardController;

  // Card Animations
  late final Animation<double> _rentalCardAnimation;
  late final Animation<double> _saleCardAnimation;
  late final Animation<double> _completedCardAnimation;
  late final Animation<double> _customersCardAnimation;

  // Entrance Animation Controllers (staggered entrance)
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  // Carousel için PageController ve Timer
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  // Kırmızı alana girince yazı/ikon beyaz olsun
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _redZoneKey = GlobalKey();
  final GlobalKey _ofisHeaderKey = GlobalKey();
  final GlobalKey _danismanHeaderKey = GlobalKey();
  final GlobalKey _tumunuGorKey = GlobalKey();
  bool _ofisHeaderInRedZone = false;
  bool _danismanHeaderInRedZone = false;
  bool _tumunuGorInRedZone = false;

  void _updateRedZoneVisibility() {
    final redBox = _redZoneKey.currentContext?.findRenderObject() as RenderBox?;
    final ofisBox =
        _ofisHeaderKey.currentContext?.findRenderObject() as RenderBox?;
    final danismanBox =
        _danismanHeaderKey.currentContext?.findRenderObject() as RenderBox?;
    final tumunuGorBox =
        _tumunuGorKey.currentContext?.findRenderObject() as RenderBox?;
    double redZoneBottom = 160;
    if (redBox != null && redBox.hasSize) {
      final redPos = redBox.localToGlobal(Offset.zero);
      redZoneBottom = redPos.dy + redBox.size.height;
    }
    bool ofisInRed = false;
    bool danismanInRed = false;
    bool tumunuGorInRed = false;
    if (ofisBox != null && ofisBox.hasSize) {
      final pos = ofisBox.localToGlobal(Offset.zero);
      if (pos.dy < redZoneBottom) ofisInRed = true;
    }
    if (danismanBox != null && danismanBox.hasSize) {
      final pos = danismanBox.localToGlobal(Offset.zero);
      if (pos.dy < redZoneBottom) danismanInRed = true;
    }
    if (tumunuGorBox != null && tumunuGorBox.hasSize) {
      final pos = tumunuGorBox.localToGlobal(Offset.zero);
      if (pos.dy < redZoneBottom) tumunuGorInRed = true;
    }
    if (ofisInRed != _ofisHeaderInRedZone ||
        danismanInRed != _danismanHeaderInRedZone ||
        tumunuGorInRed != _tumunuGorInRedZone) {
      if (mounted) {
        setState(() {
          _ofisHeaderInRedZone = ofisInRed;
          _danismanHeaderInRedZone = danismanInRed;
          _tumunuGorInRedZone = tumunuGorInRed;
        });
      }
    }
  }

  @override
  void initState() {
    print('🎯 AdminDashboard initState başlatıldı');
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );

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

    // Card Animation Controllers
    _rentalCardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _saleCardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _completedCardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _customersCardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Card Animations
    _rentalCardAnimation = CurvedAnimation(
      parent: _rentalCardController,
      curve: Curves.easeInOutCubic,
    );
    _saleCardAnimation = CurvedAnimation(
      parent: _saleCardController,
      curve: Curves.easeInOutCubic,
    );
    _completedCardAnimation = CurvedAnimation(
      parent: _completedCardController,
      curve: Curves.easeInOutCubic,
    );
    _customersCardAnimation = CurvedAnimation(
      parent: _customersCardController,
      curve: Curves.easeInOutCubic,
    );

    // Entrance Animation Controller
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Entrance animasyonunu başlat
    _entranceController.forward();

    // PageController başlat
    _pageController = PageController(initialPage: 0);
    _operationPageController =
        PageController(initialPage: 0, viewportFraction: 1.0);
    _startOperationAutoScroll();

    // Otomatik kaydırma timer'ını başlat
    _startAutoScroll();

    // Dashboard verilerini yükle - frame tamamlandıktan sonra
    print('🎬 _loadDashboardData çağrılıyor...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🎬 PostFrameCallback ile _loadDashboardData çağrılıyor...');
      RoleSidebar.preloadSidebarData(context);
      _loadDashboardData();
      _updateRedZoneVisibility();
    });
  }

  // Otomatik kaydırma timer'ını başlat
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < 3) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // Timer'ı durdur (kullanıcı dokunduğunda)
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  // Timer'ı yeniden başlat
  void _restartAutoScroll() {
    _stopAutoScroll();
    _startAutoScroll();
  }

  // Operation Gauge Carousel Auto-Scroll
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

  DateTime get _officeYearStart {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  DateTime get _officeToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _loadAdminOfficesForRange(DateTime start, DateTime end) async {
    final result = await _dashboardRepo.getAdminOffices(
      startDate: start,
      endDate: end,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        print('❌ Office API hatası: ${failure.message}');
        setState(() => _officeData = null);
      },
      (data) {
        setState(() => _officeData = AdminOfficeModel.fromJson(data));
      },
    );
  }

  /// Dashboard verilerini API'den yükle - Role-based automatic
  Future<void> _loadDashboardData() async {
    print('🎬 _loadDashboardData metodu başlatıldı');

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Dashboard API çağrıları başlıyor - Role-based system...');

      // Admin Dashboard - Kesinlikle admin endpoint'ini kullan
      print('📞 Admin Dashboard Totals API çağrılıyor (admin endpoint)...');
      late Either totalsResult;
      try {
        // Admin dashboard'da direkt admin endpoint'ini kullan
        totalsResult = await _dashboardRepo.getAdminTotals();
        print('✅ Admin Totals API çağrısı tamamlandı');
      } catch (e) {
        print('❌ Admin Totals API çağrısında hata: $e');
        totalsResult = left(UnknownFailure(message: "Totals API hatası: $e"));
      }

      print('📞 Dashboard Admin Offices API çağrılıyor...');
      late Either officeResult;
      try {
        officeResult = await _dashboardRepo.getAdminOffices(
          startDate: _officeYearStart,
          endDate: _officeToday,
        );
        print('✅ Offices API çağrısı tamamlandı');
      } catch (e) {
        print('❌ Offices API çağrısında hata: $e');
        officeResult = left(UnknownFailure(message: "Offices API hatası: $e"));
      }

      print('📞 Admin Dashboard Advisors API çağrılıyor...');
      late Either advisorResult;
      try {
        // Admin dashboard'da direkt admin advisors endpoint'ini kullan
        advisorResult = await _dashboardRepo.getAdminAdvisors();
        print('✅ Admin Advisors API çağrısı tamamlandı');
      } catch (e) {
        print('❌ Admin Advisors API çağrısında hata: $e');
        advisorResult =
            left(UnknownFailure(message: "Advisors API hatası: $e"));
      }

      print('📞 Admin Dashboard Top API çağrılıyor (admin endpoint)...');
      late Either topResult;
      try {
        // Admin dashboard'da direkt admin endpoint'ini kullan
        topResult = await _dashboardRepo.getAdminTop();
        print('✅ Admin Top API çağrısı tamamlandı');
      } catch (e) {
        print('❌ Admin Top API çağrısında hata: $e');
        topResult = left(UnknownFailure(message: "Top API hatası: $e"));
      }

      print(
          '📞 Admin Dashboard Daily Revenue API çağrılıyor (admin endpoint)...');
      late Either dailyResult;
      try {
        // Admin dashboard'da direkt admin endpoint'ini kullan
        dailyResult = await _dashboardRepo.getAdminDailyRevenue();
        print('✅ Admin Daily Revenue API çağrısı tamamlandı');
      } catch (e) {
        print('❌ Admin Daily Revenue API çağrısında hata: $e');
        dailyResult =
            left(UnknownFailure(message: "Daily Revenue API hatası: $e"));
      }

      print('✅ Tüm API çağrıları tamamlandı - Role-based system');

      // Totals verilerini işle
      totalsResult.fold(
        (failure) {
          print('❌ Totals API hatası: ${failure.message}');
          _totalsData = null;
        },
        (data) {
          print('📦 API Raw Data: $data');
          print('📦 API Raw Data Type: ${data.runtimeType}');
          print('📦 API Raw Data Keys: ${data.keys}');
          print(
              '📦 API Raw Data - active: ${data['active']}, for_rent: ${data['for_rent']}, for_sale: ${data['for_sale']}, customers: ${data['customers']}');
          _totalsData = AdminTotalsModel.fromJson(data);
          print('✅ Totals verileri API\'den başarıyla yüklendi');
          print(
              '📊 Parsed Data - active: ${_totalsData!.active}, forRent: ${_totalsData!.forRent}, forSale: ${_totalsData!.forSale}, sold: ${_totalsData!.sold}, rented: ${_totalsData!.rented}, customers: ${_totalsData!.customers}');
          print('📊 Full Model: $_totalsData');
        },
      );

      // Office verilerini işle
      officeResult.fold(
        (failure) {
          print('❌ Office API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  Office API başarısız - office data null olacak');
          _officeData = null;
        },
        (data) {
          print('🔍 Office API RAW DATA: $data');
          // getAdminOffices API cevabı -> ofis kartlarındaki Son İşlem Tarihi bu veriye bağlı
          _officeData = AdminOfficeModel.fromJson(data);
          print(
              '✅ Office verileri yüklendi - Offices count: ${_officeData!.offices.length}');
          // Son işlem tarihi: API'de her ofiste last_transaction (veya last_transaction_date) olmalı
          for (final o in _officeData!.offices) {
            print('  📌 Ofis: id=${o.office} "${o.officeTitle}" lastTransaction=${o.lastTransaction ?? "NULL"}');
          }
          print(
              '🔍 Office of the week: ${_officeData!.officeOfTheWeek?.officeTitle} - Revenue: ${_officeData!.officeOfTheWeek?.revenue}');
          print(
              '🔍 Office of the month: ${_officeData!.officeOfTheMonth?.officeTitle} - Revenue: ${_officeData!.officeOfTheMonth?.revenue}');
          print(
              '🔍 Office of the year: ${_officeData!.officeOfTheYear?.officeTitle} - Revenue: ${_officeData!.officeOfTheYear?.revenue}');
          print('🔍 Top offices: ${_officeData!.topOffices.length}');
        },
      );

      // Advisor verilerini işle (ofis kartındaki Son İşlem Tarihi, ofiste yoksa danışmanlardan doldurulur)
      advisorResult.fold(
        (failure) {
          print('❌ Advisor API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  Advisor API başarısız - advisor data null olacak');
          _advisorData = null;
        },
        (data) {
          print('🔍 Advisor API RAW DATA: $data');
          _advisorData = AdminAdvisorModel.fromJson(data);
          print(
              '✅ Advisor verileri yüklendi - Advisors count: ${_advisorData!.advisors.length}');
          // Son işlem tarihi debug: danışmanlarda office + last_transaction yoksa ofis kartında N/A kalır
          for (final a in _advisorData!.advisors.take(10)) {
            print('  📌 Danışman: advisor=${a.advisor} office=${a.office} lastTransaction=${a.lastTransaction ?? "NULL"}');
          }
          print('🔍 Top advisors: ${_advisorData!.topAdvisors.length}');
        },
      );

      // Top verilerini işle - API başarısızsa totals data'dan mock oluştur
      topResult.fold(
        (failure) {
          print('❌ Top API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print(
              '⚠️  API başarısız - totals data\'dan mock top data oluşturuluyor...');

          // Totals data varsa mock top data oluştur
          if (_totalsData != null || _officeData != null) {
            print(
                '🔧 Totals ve Office data\'dan mock AdminTopModel oluşturuluyor...');

            // Office data'dan gerçek ofis bilgilerini al
            String bestOfficeWeek = "En İyi Ofis (Bu Hafta)";
            String bestOfficeMonth = "En İyi Ofis (Bu Ay)";
            String bestOfficeYear = "En İyi Ofis (Bu Yıl)";
            String weekRevenue = "50000";
            String monthRevenue = "150000";
            String yearRevenue = "500000";

            if (_officeData != null && _officeData!.offices.isNotEmpty) {
              // En yüksek gelirli ofisleri bul ve sırala
              final sortedOffices = List.from(_officeData!.offices)
                ..sort((a, b) => (double.tryParse(b.revenue) ?? 0)
                    .compareTo(double.tryParse(a.revenue) ?? 0));

              print('🏢 Tüm ofisler (gelire göre sıralı):');
              for (var office in sortedOffices) {
                print('  - ${office.officeTitle}: ₺${office.revenue}');
              }

              if (sortedOffices.length >= 3) {
                // En iyi 3 ofisi farklı dönemler için kullan
                bestOfficeYear =
                    sortedOffices[0].officeTitle; // En yüksek gelirli - Yıl
                bestOfficeMonth =
                    sortedOffices[1].officeTitle; // İkinci en yüksek - Ay
                bestOfficeWeek =
                    sortedOffices[2].officeTitle; // Üçüncü en yüksek - Hafta
                yearRevenue = sortedOffices[0].revenue;
                monthRevenue = sortedOffices[1].revenue;
                weekRevenue = sortedOffices[2].revenue;

                print('🏆 Yılın Ofisi: $bestOfficeYear - ₺$yearRevenue');
                print('🏆 Ayın Ofisi: $bestOfficeMonth - ₺$monthRevenue');
                print('🏆 Haftanın Ofisi: $bestOfficeWeek - ₺$weekRevenue');
              } else if (sortedOffices.isNotEmpty) {
                // Az ofis varsa aynı ofisi kullan
                final topOffice = sortedOffices.first;
                bestOfficeWeek = topOffice.officeTitle;
                bestOfficeMonth = topOffice.officeTitle;
                bestOfficeYear = topOffice.officeTitle;
                weekRevenue = topOffice.revenue;
                monthRevenue = topOffice.revenue;
                yearRevenue = topOffice.revenue;
                print(
                    '🏢 Tek ofis kullanılıyor: ${topOffice.officeTitle} - ₺${topOffice.revenue}');
              }
            }

            _topData = AdminTopModel.fromJson({
              "week": {
                "advisor_title": "En İyi Danışman (Bu Hafta)",
                "total": "25000",
                "revenue": "25000"
              },
              "month": {
                "advisor_title": "En İyi Danışman (Bu Ay)",
                "total": "75000",
                "revenue": "75000"
              },
              "year": {
                "advisor_title": "En İyi Danışman (Bu Yıl)",
                "total": "250000",
                "revenue": "250000"
              },
              "office_week": [
                {
                  "office": 0,
                  "office_title": bestOfficeWeek,
                  "total": weekRevenue,
                  "revenue": weekRevenue
                }
              ],
              "office_month": [
                {
                  "office": 0,
                  "office_title": bestOfficeMonth,
                  "total": monthRevenue,
                  "revenue": monthRevenue
                }
              ],
              "office_year": [
                {
                  "office": 0,
                  "office_title": bestOfficeYear,
                  "total": yearRevenue,
                  "revenue": yearRevenue
                }
              ]
            });
            print('✅ Mock top data oluşturuldu - gerçek office data ile');
            print('🏢 Office Week: $bestOfficeWeek - ₺$weekRevenue');
            print('🏢 Office Month: $bestOfficeMonth - ₺$monthRevenue');
            print('🏢 Office Year: $bestOfficeYear - ₺$yearRevenue');
          } else {
            _topData = null;
          }
        },
        (data) {
          try {
            _topData = AdminTopModel.fromJson(data);
            print('✅ Top verileri API\'den başarıyla yüklendi');
            print('🔍 Raw API Data: $data');
            print('🔍 Top Data - Week: ${_topData?.week?.advisorTitle}');
            print('🔍 Top Data - Month: ${_topData?.month?.advisorTitle}');
            print('🔍 Top Data - Year: ${_topData?.year?.advisorTitle}');
            final officeWeekTitle = (_topData?.officeWeek?.isNotEmpty ?? false)
                ? _topData!.officeWeek![0].officeTitle
                : "Boş";
            final officeMonthTitle =
                (_topData?.officeMonth?.isNotEmpty ?? false)
                    ? _topData!.officeMonth![0].officeTitle
                    : "Boş";
            final officeYearTitle = (_topData?.officeYear?.isNotEmpty ?? false)
                ? _topData!.officeYear![0].officeTitle
                : "Boş";
            print('🔍 Top Data - Office Week: $officeWeekTitle');
            print('🔍 Top Data - Office Month: $officeMonthTitle');
            print('🔍 Top Data - Office Year: $officeYearTitle');
            print('🔍 Office Week Count: ${_topData?.officeWeek?.length ?? 0}');
            print(
                '🔍 Office Month Count: ${_topData?.officeMonth?.length ?? 0}');
            print('🔍 Office Year Count: ${_topData?.officeYear?.length ?? 0}');
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
          print('❌ Daily Revenue API hatası: ${failure.message}');
          print('📊 HTTP Status Code: ${failure.statusCode}');
          print('⚠️  Daily Revenue API başarısız - daily data null olacak');
          _dailyData = null;
        },
        (data) {
          try {
            print('🔍 Daily Revenue API RAW DATA: $data');
            _dailyData = AdminDailyModel.fromJson(data);
            print(
                '✅ Daily Revenue verileri yüklendi - Days count: ${_dailyData!.days.length}');
            print('🔍 Total Revenue: ₺${_dailyData!.total}');
            print('🔍 Sample Days:');
            for (var i = 0; i < math.min(5, _dailyData!.days.length); i++) {
              final day = _dailyData!.days[i];
              print('  - ${day.day}: ₺${day.revenue}');
            }
          } catch (e) {
            print('❌ Daily Revenue data parse hatası: $e');
            print('📦 Raw data: $data');
            _dailyData = null;
          }
        },
      );

      setState(() {
        _isLoading = false;
        // Gelir grafiği varsayılan: en son ay, en güncel 4 gelir
        if (_dailyData != null &&
            _dailyData!.days.isNotEmpty &&
            _selectedYear == null &&
            _selectedMonth == null) {
          final sorted = List<DayModel>.from(_dailyData!.days)
            ..sort((a, b) =>
                DateTime.parse(a.day).compareTo(DateTime.parse(b.day)));
          final last = DateTime.parse(sorted.last.day);
          _selectedYear = last.year;
          _selectedMonth = last.month;
        }
      });
    } catch (e) {
      // Genel hata durumunda null değerler
      print('❌ Genel hata: $e');
      setState(() {
        _isLoading = false;
        _totalsData = null;
        _officeData = null;
        _advisorData = null;
        _topData = null;
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    _textAnimationController.dispose();
    _shimmerController.dispose();
    _rentalCardController.dispose();
    _saleCardController.dispose();
    _completedCardController.dispose();
    _customersCardController.dispose();
    _entranceController.dispose();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _operationAutoScrollTimer?.cancel();
    _operationRestartDelayTimer?.cancel();
    _operationPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginIntroHost(
      loading: _isLoading,
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBackground,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
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
      body: Column(
        children: [
          Expanded(
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
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 220,
                      child: DecoratedBox(
                        key: _redZoneKey,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _primaryRed,
                              _secondaryRed,
                              _pageBackground.withOpacity(0),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    NotificationListener<ScrollNotification>(
                      onNotification: (_) {
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _updateRedZoneVisibility());
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _isLoading
                                ? _buildSkeletonStatsCard()
                                : _totalsData != null
                                    ? _buildModernStatsCard()
                                    : _buildLoadingPlaceholder(),
                            const SizedBox(height: 14),
                            _buildModernOperationSection(),
                            const SizedBox(height: 14),
                            _buildOfficePerformanceSection(),
                            const SizedBox(height: 14),
                            _buildAdvisorPerformanceSection(),
                            const SizedBox(height: 14),
                            _buildIncomeChart(),
                            const SizedBox(height: 16),
                            PanelOfficeTable(
                              officeData: _officeData,
                              advisorData: _advisorData,
                              tumunuGorKey: _tumunuGorKey,
                              tumunuGorInRedZone: _tumunuGorInRedZone,
                              initialStartDate: _officeYearStart,
                              initialEndDate: DateTime.now(),
                              onDateRangeChanged: (start, end) {
                                _loadAdminOfficesForRange(start, end);
                              },
                            ),
                            const SizedBox(height: 16),
                            PanelDanismanCard(
                              advisorData: _advisorData,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Admin Navbar
          BlocBuilder<AuthCubit, AuthState>(
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
                    print(
                        'Admin Dashboard - Bottom Navbar - User Role Codes: $userRoleCodes');

                    // Web sitesindeki mantığa göre navbar seçimi
                    if (userRoleCodes.contains('role_admin')) {
                      return const AdminNavbar(currentIndex: 0);
                    } else if (userRoleCodes.contains('role_advisor')) {
                      return const DanismanNavbar(currentIndex: 0);
                    } else if (userRoleCodes.contains('role_office_broker') ||
                        userRoleCodes.contains('role_office_assistant')) {
                      return const BrokerNavbar(currentIndex: 0);
                    } else if (userRoleCodes
                            .contains('role_form_applications') ||
                        userRoleCodes
                            .contains('role_form_applications_admin')) {
                      return const BrokerNavbar(currentIndex: 0);
                    } else if (userRoleCodes
                            .contains('role_sale_applications') ||
                        userRoleCodes
                            .contains('role_sale_applications_admin')) {
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
        ],
      ),
    ),
    );
  }

  /// Para formatı için yardımcı metot
  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString) ?? 0.0;
    return "₺${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}";
  }

  /// Maksimum gelir değerini hesapla
  double _getMaxRevenue() {
    if (_dailyData == null || _dailyData!.days.isEmpty) return 1000000;

    double maxRevenue = 0;
    for (var day in _dailyData!.days) {
      if (day.revenue > maxRevenue) {
        maxRevenue = day.revenue;
      }
    }
    return maxRevenue * 1.1; // %10 margin ekle
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

  /// Grafik X ekseni: ay üstte, gün altta (yan yana sığmama sorununu çözer)
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

  /// API'den gelen verilerdeki yılları döndür
  List<int> _getAvailableYears() {
    if (_dailyData == null || _dailyData!.days.isEmpty) {
      return [];
    }

    final years = <int>{};
    for (var day in _dailyData!.days) {
      try {
        final dayDate = DateTime.parse(day.day);
        years.add(dayDate.year);
      } catch (e) {
        print('⚠️ Tarih parse hatası: ${day.day} - $e');
      }
    }

    final sortedYears = years.toList()
      ..sort((a, b) => b.compareTo(a)); // Yeni yıldan eskiye
    return sortedYears;
  }

  /// Seçili yıldaki mevcut ayları döndür
  List<int> _getAvailableMonthsForYear(int year) {
    if (_dailyData == null || _dailyData!.days.isEmpty) {
      return [];
    }

    final months = <int>{};
    for (var day in _dailyData!.days) {
      try {
        final dayDate = DateTime.parse(day.day);
        if (dayDate.year == year) {
          months.add(dayDate.month);
        }
      } catch (e) {
        print('⚠️ Tarih parse hatası: ${day.day} - $e');
      }
    }

    final sortedMonths = months.toList()
      ..sort((a, b) => b.compareTo(a)); // Yeni aydan eskiye
    return sortedMonths;
  }

  Widget _buildIncomeChart() {
    // Yıl ve aya göre günleri al; varsayılan: en son ay, en güncel 4 gelir
    List<DayModel> displayDays = [];
    if (_dailyData != null && _dailyData!.days.isNotEmpty) {
      // Tarihe göre sırala (eskiden yeniye)
      final sortedDays = List<DayModel>.from(_dailyData!.days)
        ..sort(
            (a, b) => DateTime.parse(a.day).compareTo(DateTime.parse(b.day)));

      if (_selectedYear != null && _selectedMonth != null) {
        displayDays = sortedDays.where((day) {
          final dayDate = DateTime.parse(day.day);
          return dayDate.year == _selectedYear &&
              dayDate.month == _selectedMonth;
        }).toList();
      } else if (_selectedYear != null) {
        displayDays = sortedDays.where((day) {
          final dayDate = DateTime.parse(day.day);
          return dayDate.year == _selectedYear;
        }).toList();
      } else {
        // Varsayılan: en son aydaki işlemler, en güncel 4 gelir
        final lastDay = DateTime.parse(sortedDays.last.day);
        final lastYear = lastDay.year;
        final lastMonth = lastDay.month;
        final lastMonthDays = sortedDays.where((day) {
          final d = DateTime.parse(day.day);
          return d.year == lastYear && d.month == lastMonth;
        }).toList();
        if (lastMonthDays.length > 4) {
          displayDays = lastMonthDays.sublist(lastMonthDays.length - 4);
        } else {
          displayDays = lastMonthDays;
        }
      }

      // Grafikte en fazla 4 gün (en güncel 4)
      if (displayDays.length > 4) {
        displayDays = displayDays.sublist(displayDays.length - 4);
      }
    }

    return _buildDashboardSection(
      title: 'Zecorner Ofisleri Gelir Grafiği',
      icon: Icons.show_chart_rounded,
      subtitle: 'Günlük gelir trendi',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedYear != null
                        ? _primaryRed.withOpacity(0.04)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedYear != null
                          ? _primaryRed.withOpacity(0.28)
                          : _borderLight,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      // Sadece verilerin olduğu yılları göster
                      final years = _getAvailableYears();

                      if (years.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Henüz veri bulunmuyor'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      final selectedYear = await showModalBottomSheet<int>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Modern drag handle area - kırmızı arka plan (tek renk)
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              // Header with red background (tek renk) - dikey ortalanmış
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 22),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Text(
                                          'Yıl Seçin',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Year list with red-themed design
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  itemCount: years.length,
                                  itemBuilder: (context, index) {
                                    final year = years[index];
                                    final isSelected = _selectedYear == year;
                                    return InkWell(
                                      onTap: () => Navigator.pop(context, year),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 20),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  colors: [
                                                    const Color(0xFFE53935)
                                                        .withOpacity(0.15),
                                                    const Color(0xFFE53935)
                                                        .withOpacity(0.08),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFE53935)
                                                    .withOpacity(0.4)
                                                : Colors.grey[200]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFE53935)
                                                            .withOpacity(0.15),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  margin: const EdgeInsets.only(
                                                      right: 16),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFE53935)
                                                        : Colors.grey[300],
                                                    shape: BoxShape.circle,
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: const Color(
                                                                    0xFFE53935)
                                                                .withOpacity(
                                                                    0.3),
                                                            width: 3,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                Text(
                                                  '$year',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFE53935)
                                                        : Colors.black87,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Color(0xFFE53935),
                                                      Color(0xFFC62828),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFFE53935)
                                                          .withOpacity(0.4),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          16),
                            ],
                          ),
                        ),
                      );

                      if (selectedYear != null) {
                        setState(() {
                          _selectedYear = selectedYear;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 17,
                              color: _selectedYear != null
                                  ? _primaryRed
                                  : _textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedYear != null ? '$_selectedYear' : 'Yıl',
                              style: TextStyle(
                                color: _selectedYear != null
                                    ? _textPrimary
                                    : _textSecondary,
                                fontWeight: _selectedYear != null
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _selectedYear != null
                              ? _primaryRed
                              : _textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: _selectedYear == null ? 0.5 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedMonth != null
                          ? _primaryRed.withOpacity(0.04)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedMonth != null
                            ? _primaryRed.withOpacity(0.28)
                            : _borderLight,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _selectedYear == null
                          ? null
                          : () async {
                              // Seçili yıldaki mevcut ayları göster
                              final availableMonths =
                                  _getAvailableMonthsForYear(_selectedYear!);

                              if (availableMonths.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Bu yıl için veri bulunmuyor'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              const monthNames = [
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

                              final selectedMonth =
                                  await showModalBottomSheet<int>(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => Container(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(28)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE53935)
                                            .withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, -5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Modern drag handle area - kırmızı arka plan (tek renk)
                                      Container(
                                        padding: const EdgeInsets.only(
                                            top: 12, bottom: 8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE53935),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(28),
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 50,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Header with red background (tek renk) - dikey ortalanmış
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 22),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE53935),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.25),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.calendar_month,
                                                    color: Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                const Text(
                                                  'Ay Seçin',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Month list with red-themed design - sadece mevcut ayları göster
                                      Flexible(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          itemCount: availableMonths.length,
                                          itemBuilder: (context, index) {
                                            final month =
                                                availableMonths[index];
                                            final isSelected =
                                                _selectedMonth == month;
                                            return InkWell(
                                              onTap: () =>
                                                  Navigator.pop(context, month),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 20),
                                                decoration: BoxDecoration(
                                                  gradient: isSelected
                                                      ? LinearGradient(
                                                          colors: [
                                                            const Color(
                                                                    0xFFE53935)
                                                                .withOpacity(
                                                                    0.15),
                                                            const Color(
                                                                    0xFFE53935)
                                                                .withOpacity(
                                                                    0.08),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        )
                                                      : null,
                                                  color: isSelected
                                                      ? null
                                                      : Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(
                                                                0xFFE53935)
                                                            .withOpacity(0.4)
                                                        : Colors.grey[200]!,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFFE53935)
                                                                .withOpacity(
                                                                    0.15),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 12,
                                                          height: 12,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 16),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFFE53935)
                                                                : Colors
                                                                    .grey[300],
                                                            shape:
                                                                BoxShape.circle,
                                                            border: isSelected
                                                                ? Border.all(
                                                                    color: const Color(
                                                                            0xFFE53935)
                                                                        .withOpacity(
                                                                            0.3),
                                                                    width: 3,
                                                                  )
                                                                : null,
                                                          ),
                                                        ),
                                                        Text(
                                                          monthNames[month - 1],
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                isSelected
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .w500,
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFFE53935)
                                                                : Colors
                                                                    .black87,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              const LinearGradient(
                                                            colors: [
                                                              Color(0xFFE53935),
                                                              Color(0xFFC62828),
                                                            ],
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(
                                                                      0xFFE53935)
                                                                  .withOpacity(
                                                                      0.4),
                                                              blurRadius: 6,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom +
                                              16),
                                    ],
                                  ),
                                ),
                              );

                              if (selectedMonth != null) {
                                setState(() {
                                  _selectedMonth = selectedMonth;
                                });
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 17,
                                color: _selectedYear == null
                                    ? Colors.grey[400]
                                    : (_selectedMonth != null
                                        ? _primaryRed
                                        : _textSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedMonth != null
                                    ? _getMonthName(_selectedMonth!)
                                    : 'Ay',
                                style: TextStyle(
                                  color: _selectedYear == null
                                      ? Colors.grey[400]
                                      : (_selectedMonth != null
                                          ? _textPrimary
                                          : _textSecondary),
                                  fontWeight: _selectedMonth != null
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _selectedYear == null
                                ? Colors.grey[400]
                                : (_selectedMonth != null
                                    ? _primaryRed
                                    : _textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  _selectedYear = null;
                  _selectedMonth = null;
                  _selectedMetric = "Gelir";
                });
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
                "Filtreyi Temizle",
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
                  : Container(
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
                  "Toplam Net Kazanç",
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
                      : "₺0",
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
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
  }

  BoxDecoration _innerTileDecoration(Color accent) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withOpacity(0.06), const Color(0xFFFAFAFA)],
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

  Widget _buildStatIconBadge({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
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

  Widget _buildOfficePerformanceSection() {
    final cards = _buildTopOfficeCards();
    return _buildDashboardSection(
      title: 'Ofis Performans Durumu',
      icon: Icons.apartment_rounded,
      subtitle: 'Dönemsel lider ofisler',
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 10 : 0),
              child: cards[i],
            ),
        ],
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
      child: SizedBox(
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

  Widget _buildPremiumLeaderCard({
    required int rank,
    required IconData icon,
    required Color accent,
    required String title,
    required String badge,
    required String amount,
    VoidCallback? onTap,
  }) {
    const medalColors = [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];
    final medalColor =
        rank < medalColors.length ? medalColors[rank] : accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                                colors: [
                                  accent.withOpacity(0.18),
                                  accent.withOpacity(0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: accent.withOpacity(0.2)),
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
                                  colors: [
                                    medalColor,
                                    medalColor.withOpacity(0.75),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
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
      ),
    );
  }

  Widget _buildAwardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String price,
    VoidCallback? onTap,
    int rank = 0,
  }) {
    return _buildPremiumLeaderCard(
      rank: rank,
      icon: icon,
      accent: iconColor,
      title: title,
      badge: subtitle,
      amount: price,
      onTap: onTap,
    );
  }

  /// Seçilen bölümün değerini döndür
  String? _getSelectedSectionValue(String sectionName) {
    if (_totalsData == null) return null;

    switch (sectionName) {
      case 'Aktif':
        return _totalsData!.active;
      case 'Satıldı':
        return _totalsData!.sold;
      case 'Kiralandı':
        return _totalsData!.rented;
      case 'Reddedildi':
        return _totalsData!.rejected;
      case 'İptal Edildi':
        return _totalsData!.cancelled;
      case 'Değişiklik İsteniyor':
        return _totalsData!.changesRequired;
      case 'Onay Bekliyor':
        return _totalsData!.waitingForApproval;
      case 'Süresi Dolmuş':
        return _totalsData!.expired;
      case 'Taslak':
        return _totalsData!.draft;
      case 'Satılık İlan':
        return _totalsData!.forSale;
      case 'Kiralık İlan':
        return _totalsData!.forRent;
      default:
        return null;
    }
  }

  /// Operasyon verileri - gauge carousel için yapılandırılmış veri listesi
  List<Map<String, dynamic>> _getOperationChartData() {
    if (_totalsData == null) {
      return [];
    }

    List<Map<String, dynamic>> data = [];

    final entries = <MapEntry<String, MapEntry<String, Color>>>[
      MapEntry('Aktif', MapEntry(_totalsData!.active, Colors.blue)),
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
      MapEntry('Satılık İlan', MapEntry(_totalsData!.forSale, Colors.indigo)),
      MapEntry('Kiralık İlan', MapEntry(_totalsData!.forRent, Colors.cyan)),
    ];

    for (final entry in entries) {
      final numVal = double.tryParse(entry.value.key) ?? 0;
      if (numVal > 0) {
        data.add({
          'title': entry.key,
          'value': entry.value.key,
          'numericValue': numVal,
          'color': entry.value.value,
        });
      }
    }

    // Toplam hesapla ve yüzde ekle
    final total = data.fold<double>(
        0, (sum, item) => sum + (item['numericValue'] as double));
    for (final item in data) {
      item['percentage'] =
          total > 0 ? ((item['numericValue'] as double) / total * 100) : 0.0;
    }

    return data;
  }

  /// Pie chart section title'larını döndür (sadece 0'dan büyük değerler için)
  List<String> _getPieSectionTitles() {
    if (_totalsData == null) return [];

    List<String> titles = [];

    // Sections ile aynı sırada - sadece 0'dan büyük değerleri ekle
    final activeValue = double.tryParse(_totalsData!.active) ?? 0;
    if (activeValue > 0) titles.add('Aktif');

    final soldValue = double.tryParse(_totalsData!.sold) ?? 0;
    if (soldValue > 0) titles.add('Satıldı');

    final rentedValue = double.tryParse(_totalsData!.rented) ?? 0;
    if (rentedValue > 0) titles.add('Kiralandı');

    final rejectedValue = double.tryParse(_totalsData!.rejected) ?? 0;
    if (rejectedValue > 0) titles.add('Reddedildi');

    final cancelledValue = double.tryParse(_totalsData!.cancelled) ?? 0;
    if (cancelledValue > 0) titles.add('İptal Edildi');

    final changesRequiredValue =
        double.tryParse(_totalsData!.changesRequired) ?? 0;
    if (changesRequiredValue > 0) titles.add('Değişiklik İsteniyor');

    final waitingForApprovalValue =
        double.tryParse(_totalsData!.waitingForApproval) ?? 0;
    if (waitingForApprovalValue > 0) titles.add('Onay Bekliyor');

    final expiredValue = double.tryParse(_totalsData!.expired) ?? 0;
    if (expiredValue > 0) titles.add('Süresi Dolmuş');

    final draftValue = double.tryParse(_totalsData!.draft) ?? 0;
    if (draftValue > 0) titles.add('Taslak');

    final forSaleValue = double.tryParse(_totalsData!.forSale) ?? 0;
    if (forSaleValue > 0) titles.add('Satılık İlan');

    final forRentValue = double.tryParse(_totalsData!.forRent) ?? 0;
    if (forRentValue > 0) titles.add('Kiralık İlan');

    return titles;
  }

  /// Pie chart sections oluştur - AdminTotalsModel'den TÜM verilerle
  List<PieChartSectionData> _buildPieChartSections() {
    if (_totalsData == null) {
      // Default sections - veri yoksa
      return [
        PieChartSectionData(
            value: 30,
            color: Colors.blue,
            title: '',
            radius: 60,
            showTitle: false),
        PieChartSectionData(
            value: 10,
            color: Colors.green,
            title: '',
            radius: 60,
            showTitle: false),
        PieChartSectionData(
            value: 25,
            color: Colors.amber,
            title: '',
            radius: 60,
            showTitle: false),
        PieChartSectionData(
            value: 15,
            color: Colors.red,
            title: '',
            radius: 60,
            showTitle: false),
        PieChartSectionData(
            value: 12,
            color: Colors.lightBlue,
            title: '',
            radius: 60,
            showTitle: false),
        PieChartSectionData(
            value: 8,
            color: Colors.teal,
            title: '',
            radius: 60,
            showTitle: false),
      ];
    }

    // AdminTotalsModel'den gelen TÜM verilerle dinamik sections
    List<PieChartSectionData> sections = [];

    // Sadece 0'dan büyük değerleri ekle (title listesi _getPieSectionTitles()'da oluşturuluyor)
    final activeValue = double.tryParse(_totalsData!.active) ?? 0;
    if (activeValue > 0) {
      sections.add(PieChartSectionData(
        value: activeValue,
        color: Colors.blue,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final soldValue = double.tryParse(_totalsData!.sold) ?? 0;
    if (soldValue > 0) {
      sections.add(PieChartSectionData(
        value: soldValue,
        color: Colors.green,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final rentedValue = double.tryParse(_totalsData!.rented) ?? 0;
    if (rentedValue > 0) {
      sections.add(PieChartSectionData(
        value: rentedValue,
        color: Colors.amber,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final rejectedValue = double.tryParse(_totalsData!.rejected) ?? 0;
    if (rejectedValue > 0) {
      sections.add(PieChartSectionData(
        value: rejectedValue,
        color: Colors.red,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final cancelledValue = double.tryParse(_totalsData!.cancelled) ?? 0;
    if (cancelledValue > 0) {
      sections.add(PieChartSectionData(
        value: cancelledValue,
        color: Colors.lightBlue,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final changesRequiredValue =
        double.tryParse(_totalsData!.changesRequired) ?? 0;
    if (changesRequiredValue > 0) {
      sections.add(PieChartSectionData(
        value: changesRequiredValue,
        color: Colors.teal,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final waitingForApprovalValue =
        double.tryParse(_totalsData!.waitingForApproval) ?? 0;
    if (waitingForApprovalValue > 0) {
      sections.add(PieChartSectionData(
        value: waitingForApprovalValue,
        color: Colors.orange,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final expiredValue = double.tryParse(_totalsData!.expired) ?? 0;
    if (expiredValue > 0) {
      sections.add(PieChartSectionData(
        value: expiredValue,
        color: Colors.purple,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final draftValue = double.tryParse(_totalsData!.draft) ?? 0;
    if (draftValue > 0) {
      sections.add(PieChartSectionData(
        value: draftValue,
        color: Colors.pink,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final forSaleValue = double.tryParse(_totalsData!.forSale) ?? 0;
    if (forSaleValue > 0) {
      sections.add(PieChartSectionData(
        value: forSaleValue,
        color: Colors.indigo,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    final forRentValue = double.tryParse(_totalsData!.forRent) ?? 0;
    if (forRentValue > 0) {
      sections.add(PieChartSectionData(
        value: forRentValue,
        color: Colors.cyan,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }

    return sections;
  }

  /// Top office kartları oluştur - AdminTopModel kullanarak
  List<Widget> _buildTopOfficeCards() {
    print('🚀 _buildTopOfficeCards çağrıldı');

    if (_topData == null) {
      print('❌ AdminTopModel verisi null - API\'den veri gelmemiş');
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Ofis performans verileri yükleniyor...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ];
    }

    print('✅ AdminTopModel verisi mevcut');
    List<Widget> cards = [];

    // Haftanın Ofisi - office_week array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.officeWeek != null && _topData!.officeWeek!.isNotEmpty) {
      final weekOffice = _topData!.officeWeek![0];
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: weekOffice.officeTitle,
        subtitle: "Haftanın Ofisi",
        price: _formatPrice(weekOffice.total),
        rank: 0,
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print(
          '✅ Haftanın Ofisi eklendi: ${weekOffice.officeTitle} - ${weekOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: "-",
        subtitle: "Haftanın Ofisi",
        price: "-",
        rank: 0,
        onTap: null,
      ));
      print('⚠️ Haftanın Ofisi verisi yok - "-" gösteriliyor');
    }

    // Ayın Ofisi - office_month array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.officeMonth != null && _topData!.officeMonth!.isNotEmpty) {
      final monthOffice = _topData!.officeMonth![0];
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: monthOffice.officeTitle,
        subtitle: "Ayın Ofisi",
        price: _formatPrice(monthOffice.total),
        rank: 1,
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print(
          '✅ Ayın Ofisi eklendi: ${monthOffice.officeTitle} - ${monthOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: "-",
        subtitle: "Ayın Ofisi",
        price: "-",
        rank: 1,
        onTap: null,
      ));
      print('⚠️ Ayın Ofisi verisi yok - "-" gösteriliyor');
    }

    // Yılın Ofisi - office_year array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.officeYear != null && _topData!.officeYear!.isNotEmpty) {
      final yearOffice = _topData!.officeYear![0];
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: yearOffice.officeTitle,
        subtitle: "Yılın Ofisi",
        price: _formatPrice(yearOffice.total),
        rank: 2,
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print(
          '✅ Yılın Ofisi eklendi: ${yearOffice.officeTitle} - ${yearOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: const Color(0xFF10B981),
        title: "-",
        subtitle: "Yılın Ofisi",
        price: "-",
        rank: 2,
        onTap: null,
      ));
      print('⚠️ Yılın Ofisi verisi yok - "-" gösteriliyor');
    }

    print('🎯 Final office cards count: ${cards.length}');
    return cards;
  }

  /// Top advisor kartları oluştur - AdminTopModel kullanarak
  List<Widget> _buildTopAdvisorCards() {
    print('🚀 _buildTopAdvisorCards çağrıldı');

    if (_topData == null) {
      print('❌ AdminTopModel verisi null - API\'den veri gelmemiş');
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 32),
              SizedBox(height: 8),
              Text(
                'Danışman performans verileri yükleniyor...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ];
    }

    print('✅ AdminTopModel verisi mevcut');
    List<Widget> cards = [];

    // Haftanın Danışmanı - week array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.week != null) {
      final weekAdvisor = _topData!.week!;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.blue,
        title: weekAdvisor.advisorTitle ?? "-",
        subtitle: "Haftanın Yıldızı",
        price: weekAdvisor.total.isNotEmpty
            ? _formatPrice(weekAdvisor.total)
            : "-",
        rank: 0,
      ));
      print(
          '✅ Haftanın Danışmanı eklendi: ${weekAdvisor.advisorTitle} - ${weekAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.blue,
        title: "-",
        subtitle: "Haftanın Yıldızı",
        price: "-",
        rank: 0,
      ));
      print('⚠️ Haftanın Danışmanı verisi yok - "-" gösteriliyor');
    }

    // Ayın Danışmanı - month array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.month != null) {
      final monthAdvisor = _topData!.month!;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.amber,
        title: monthAdvisor.advisorTitle ?? "-",
        subtitle: "Ayın Yıldızı",
        price: monthAdvisor.total.isNotEmpty
            ? _formatPrice(monthAdvisor.total)
            : "-",
        rank: 1,
      ));
      print(
          '✅ Ayın Danışmanı eklendi: ${monthAdvisor.advisorTitle} - ${monthAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.amber,
        title: "-",
        subtitle: "Ayın Yıldızı",
        price: "-",
        rank: 1,
      ));
      print('⚠️ Ayın Danışmanı verisi yok - "-" gösteriliyor');
    }

    // Yılın Danışmanı - year array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.year != null) {
      final yearAdvisor = _topData!.year!;
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.green,
        title: yearAdvisor.advisorTitle ?? "-",
        subtitle: "Yılın Yıldızı",
        price: yearAdvisor.total.isNotEmpty
            ? _formatPrice(yearAdvisor.total)
            : "-",
        rank: 2,
      ));
      print(
          '✅ Yılın Danışmanı eklendi: ${yearAdvisor.advisorTitle} - ${yearAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.green,
        title: "-",
        subtitle: "Yılın Yıldızı",
        price: "-",
        rank: 2,
      ));
      print('⚠️ Yılın Danışmanı verisi yok - "-" gösteriliyor');
    }

    print('🎯 Final advisor cards count: ${cards.length}');
    return cards;
  }

  /// Modern istatistik kartı
  Widget _buildModernStatsCard() {
    final forRent = int.tryParse(_totalsData!.forRent) ?? 0;
    final forSale = int.tryParse(_totalsData!.forSale) ?? 0;
    final completed = (int.tryParse(_totalsData!.sold) ?? 0) +
        (int.tryParse(_totalsData!.rented) ?? 0);
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
      subtitle: 'Tüm ofisler performans göstergeleri',
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
                  title,
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

  Widget _buildSkeletonStatsCard() {
    return _buildDashboardSection(
      title: 'Genel Özet',
      icon: Icons.analytics_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (_) => SizedBox(
                width: itemWidth,
                child: _buildSkeletonStatItem(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonStatItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerCircle(size: 40),
              _buildShimmerBox(height: 16, width: 40),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(height: 24, width: 60),
              const SizedBox(height: 8),
              _buildShimmerBox(height: 14, width: double.infinity),
            ],
          ),
        ],
      ),
    );
  }

  /// Yatay carousel kart widget'ı (yedek - navbar vb. hala kullanıyor olabilir)
  Widget _buildCarouselCard() {
    return _buildModernStatsCard();
  }

  /// Yatay stat kart widget'ı - kırmızı ağırlıklı, şık ve animasyonlu
  Widget _buildHorizontalStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sol taraf - İkon (göze çarpan)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.2),
                      iconColor.withOpacity(0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: iconColor.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Sağ taraf - Başlık ve değer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık - belirgin ve modern
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Büyük değer - belirgin ve modern
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[900],
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  /// Staggered entrance animasyonu için wrapper widget
  Widget _buildAnimatedCard({
    required double delay,
    required Widget child,
  }) {
    final animationValue =
        (_entranceAnimation.value - delay).clamp(0.0, 1.0) / (1.0 - delay);
    final opacity = Curves.easeOutCubic.transform(animationValue);
    final scale = 0.95 + (0.05 * Curves.easeOutCubic.transform(animationValue));
    final offset = 10 * (1 - Curves.easeOutCubic.transform(animationValue));

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Transform.translate(
          offset: Offset(0, offset),
          child: child,
        ),
      ),
    );
  }

  Widget buildFlexibleStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String cardKey,
    double height = 130,
    double width = double.infinity,
    double borderRadius = 12,
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE0E0E0),
    bool showShadow = false,
  }) {
    final isExpanded = _cardExpanded[cardKey] ?? false;
    AnimationController controller;
    Animation<double> animation;

    // Her kart için doğru controller'ı seç
    switch (cardKey) {
      case 'rental':
        controller = _rentalCardController;
        animation = _rentalCardAnimation;
        break;
      case 'sale':
        controller = _saleCardController;
        animation = _saleCardAnimation;
        break;
      case 'completed':
        controller = _completedCardController;
        animation = _completedCardAnimation;
        break;
      case 'customers':
        controller = _customersCardController;
        animation = _customersCardAnimation;
        break;
      default:
        controller = _rentalCardController;
        animation = _rentalCardAnimation;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _cardExpanded[cardKey] = !isExpanded;
            if (_cardExpanded[cardKey]!) {
              controller.forward();
            } else {
              controller.reverse();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.grey.withOpacity(0.05),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05 + (0.03 * animation.value)),
                    blurRadius: 10 + (5 * animation.value),
                    spreadRadius: 0,
                    offset: Offset(0, 2 + (2 * animation.value)),
                  ),
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.03 + (0.02 * animation.value)),
                    blurRadius: 6 + (3 * animation.value),
                    spreadRadius: 0,
                    offset: Offset(0, 1 + (1 * animation.value)),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // İkon ve değer üstte
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // İkon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: iconColor.withOpacity(0.15),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        // Değer sağda - daha belirgin
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.8,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Başlık altta - daha belirgin
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Modern Skeleton Loading Widget
  Widget _buildSkeletonLoading() {
    return Column(
      children: [
        // Tek yatay kart skeleton
        _buildSkeletonCard(
          height: 165,
          width: double.infinity,
        ),
        const SizedBox(height: 30),
        // Chart Card Skeleton
        _buildSkeletonCard(
          height: 280,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(height: 20, width: 200),
              const SizedBox(height: 24),
              Center(
                child: _buildShimmerCircle(size: 200),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Section Title Skeleton
        _buildShimmerBox(height: 24, width: 250),
        const SizedBox(height: 16),
        // Top Cards Skeleton
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(3, (index) {
            return _buildSkeletonCard(
              height: 120,
              width: 350,
            );
          }),
        ),
        const SizedBox(height: 30),
        // Section Title Skeleton
        _buildShimmerBox(height: 24, width: 280),
        const SizedBox(height: 16),
        // Top Cards Skeleton
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(3, (index) {
            return _buildSkeletonCard(
              height: 120,
              width: 350,
            );
          }),
        ),
        const SizedBox(height: 30),
        // Chart Card Skeleton
        _buildSkeletonCard(
          height: 400,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(height: 20, width: 250),
              const SizedBox(height: 24),
              _buildShimmerBox(height: 200, width: double.infinity),
              const SizedBox(height: 16),
              _buildShimmerBox(height: 40, width: double.infinity),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
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
      child: child ??
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShimmerCircle(size: 48),
                  _buildShimmerBox(height: 30, width: 60),
                ],
              ),
              const SizedBox(height: 8),
              _buildShimmerBox(height: 16, width: double.infinity),
            ],
          ),
    );
  }

  /// Shimmer Box Widget
  Widget _buildShimmerBox({
    required double height,
    required double width,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
            gradient: LinearGradient(
              begin: Alignment(-1.5 + shimmerValue * 3, 0),
              end: Alignment(0.5 + shimmerValue * 3, 0),
              colors: [
                Colors.grey[200]!,
                Colors.grey[200]!,
                Colors.grey[50]!,
                Colors.grey[200]!,
                Colors.grey[200]!,
              ],
              stops: const [
                0.0,
                0.4,
                0.5,
                0.6,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shimmer Circle Widget
  Widget _buildShimmerCircle({required double size}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            gradient: LinearGradient(
              begin: Alignment(-1.5 + shimmerValue * 3, 0),
              end: Alignment(0.5 + shimmerValue * 3, 0),
              colors: [
                Colors.grey[200]!,
                Colors.grey[200]!,
                Colors.grey[50]!,
                Colors.grey[200]!,
                Colors.grey[200]!,
              ],
              stops: const [
                0.0,
                0.4,
                0.5,
                0.6,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Operasyon Durumu - Modern Gauge Carousel Widget
  Widget _buildOperationGaugeCarousel() {
    final data = _getOperationChartData();
    if (data.isEmpty) {
      // Yükleniyor shimmer
      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final shimmerValue = _shimmerController.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shimmer renk barı
              Container(
                height: 10,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment(-1.5 + shimmerValue * 3, 0),
                    end: Alignment(0.5 + shimmerValue * 3, 0),
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ],
                  ),
                ),
              ),
              // Shimmer gauge
              SizedBox(
                height: 155,
                child: Center(
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(100)),
                      gradient: LinearGradient(
                        begin: Alignment(-1.5 + shimmerValue * 3, 0),
                        end: Alignment(0.5 + shimmerValue * 3, 0),
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[100]!,
                          Colors.grey[200]!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Shimmer bar
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    begin: Alignment(-1.5 + shimmerValue * 3, 0),
                    end: Alignment(0.5 + shimmerValue * 3, 0),
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer dots
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
                            color: Colors.grey[200],
                          ),
                        )),
              ),
            ],
          );
        },
      );
    }

    final total = data.fold<double>(
        0, (sum, item) => sum + (item['numericValue'] as double));

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          // Kullanıcı elle kaydırmaya başladı
          _stopOperationAutoScroll();
        } else if (notification is ScrollEndNotification) {
          // Kaydırma bitti, 6 saniye sonra otomatik kaydırmayı yeniden başlat
          _restartOperationAutoScroll();
        }
        return false;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üstte yatay renk barı - tüm segmentlerin oranını gösterir
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
                                    offset: const Offset(0, 1))
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Gauge PageView
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
                          painter: _GaugePainter(
                            percentage: percentage,
                            color: color,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 62),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Değer - büyük ve bold
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
                                // Başlık pill
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
                      // Yüzdelik bar
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
          // Modern dot indicators - pill style
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
}

/// Modern Gauge CustomPainter - Minimal yarım daire, iğnesiz
class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.80);
    final radius = math.min(size.width * 0.35, size.height * 0.54);
    const strokeWidth = 24.0;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final clampedPercent = (percentage / 100).clamp(0.0, 1.0);

    // Arka plan yayı - ince çizgili track
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

    // Renkli dolum yayı
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

      // Uç noktada parlak dot gösterge
      final endAngle = startAngle + filledSweep;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      // Dış glow
      canvas.drawCircle(
          dotCenter, 16, Paint()..color = color.withOpacity(0.12));
      canvas.drawCircle(
          dotCenter, 11, Paint()..color = color.withOpacity(0.08));
      // Beyaz halka
      canvas.drawCircle(dotCenter, 8, Paint()..color = Colors.white);
      // İç renkli dot
      canvas.drawCircle(dotCenter, 5.5, Paint()..color = color);
    }

    // Sadece uçlarda 0% ve 100% etiketi
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
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
