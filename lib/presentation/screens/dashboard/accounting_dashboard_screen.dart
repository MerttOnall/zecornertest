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

import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/admin-panel/card/panel_office_table.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class AccountingDashboardScreen extends StatefulWidget {
  const AccountingDashboardScreen({super.key});

  @override
  State<AccountingDashboardScreen> createState() => _AccountingDashboardScreenState();
}

class _AccountingDashboardScreenState extends State<AccountingDashboardScreen>
    with TickerProviderStateMixin {
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
  int? _selectedYear = DateTime.now().year;
  int? _selectedMonth = DateTime.now().month;
  
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

  @override
  void initState() {
    print('🎯 Muhasebe Dashboard initState başlatıldı');
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
    
    // Otomatik kaydırma timer'ını başlat
    _startAutoScroll();

      // Dashboard verilerini yükle - frame tamamlandıktan sonra
      print('🎬 _loadDashboardData çağrılıyor...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎬 PostFrameCallback ile _loadDashboardData çağrılıyor...');
        // Sidebar verilerini önceden yükle
        RoleSidebar.preloadSidebarData(context);
        _loadDashboardData();
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

    /// Dashboard verilerini API'den yükle - Muhasebe rolüne göre
    Future<void> _loadDashboardData() async {
      print('🎬 Muhasebe Dashboard - _loadDashboardData metodu başlatıldı');
      
      setState(() {
        _isLoading = true;
      });

      try {
        print('🚀 Muhasebe Dashboard API çağrıları başlıyor...');
        
        // Muhasebe Dashboard - Admin endpoint'lerini kullan (muhasebe için özel endpoint yoksa)
        print('📞 Muhasebe Dashboard Totals API çağrılıyor...');
        late Either totalsResult;
        try {
          // Muhasebe rolü için dashboard totals - role-based otomatik seçim
          totalsResult = await _dashboardRepo.getDashboardTotals();
          print('✅ Muhasebe Totals API çağrısı tamamlandı');
        } catch (e) {
          print('❌ Muhasebe Totals API çağrısında hata: $e');
          totalsResult = left(UnknownFailure(message: "Totals API hatası: $e"));
        }
        
        print('📞 Muhasebe Dashboard Offices API çağrılıyor...');
        late Either officeResult;
        try {
          officeResult = await _dashboardRepo.getAdminOffices();
          print('✅ Offices API çağrısı tamamlandı');
        } catch (e) {
          print('❌ Offices API çağrısında hata: $e');
          officeResult = left(UnknownFailure(message: "Offices API hatası: $e"));
        }

        print('📞 Muhasebe Dashboard Advisors API çağrılıyor...');
        late Either advisorResult;
        try {
          advisorResult = await _dashboardRepo.getAdminAdvisors();
          print('✅ Advisors API çağrısı tamamlandı');
        } catch (e) {
          print('❌ Advisors API çağrısında hata: $e');
          advisorResult = left(UnknownFailure(message: "Advisors API hatası: $e"));
        }
        

        
        print('📞 Muhasebe Dashboard Top API çağrılıyor...');
        late Either topResult;
        try {
          topResult = await _dashboardRepo.getAdminTop();
          print('✅ Top API çağrısı tamamlandı');
        } catch (e) {
          print('❌ Top API çağrısında hata: $e');
          topResult = left(UnknownFailure(message: "Top API hatası: $e"));
        }
        
        print('📞 Muhasebe Dashboard Daily Revenue API çağrılıyor...');
        late Either dailyResult;
        try {
          dailyResult = await _dashboardRepo.getDashboardDailyRevenue(
            year: _selectedYear,
            month: _selectedMonth,
          );
          print('✅ Daily Revenue API çağrısı tamamlandı');
        } catch (e) {
          print('❌ Daily Revenue API çağrısında hata: $e');
          dailyResult = left(UnknownFailure(message: "Daily Revenue API hatası: $e"));
        }
        
        print('✅ Tüm Muhasebe Dashboard API çağrıları tamamlandı');

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
            print('📦 API Raw Data - active: ${data['active']}, for_rent: ${data['for_rent']}, for_sale: ${data['for_sale']}, customers: ${data['customers']}');
            _totalsData = AdminTotalsModel.fromJson(data);
            print('✅ Totals verileri API\'den başarıyla yüklendi');
            print('📊 Parsed Data - active: ${_totalsData!.active}, forRent: ${_totalsData!.forRent}, forSale: ${_totalsData!.forSale}, sold: ${_totalsData!.sold}, rented: ${_totalsData!.rented}, customers: ${_totalsData!.customers}');
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
            _officeData = AdminOfficeModel.fromJson(data);
            print('✅ Office verileri yüklendi - Offices count: ${_officeData!.offices.length}');
            print('🔍 Office of the week: ${_officeData!.officeOfTheWeek?.officeTitle} - Revenue: ${_officeData!.officeOfTheWeek?.revenue}');
            print('🔍 Office of the month: ${_officeData!.officeOfTheMonth?.officeTitle} - Revenue: ${_officeData!.officeOfTheMonth?.revenue}');
            print('🔍 Office of the year: ${_officeData!.officeOfTheYear?.officeTitle} - Revenue: ${_officeData!.officeOfTheYear?.revenue}');
            print('🔍 Top offices: ${_officeData!.topOffices.length}');
          },
        );

        // Advisor verilerini işle
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
            print('✅ Advisor verileri yüklendi - Advisors count: ${_advisorData!.advisors.length}');
            print('🔍 Top advisors: ${_advisorData!.topAdvisors.length}');
          },
        );

        // Top verilerini işle - API başarısızsa totals data'dan mock oluştur
        topResult.fold(
          (failure) {
            print('❌ Top API hatası: ${failure.message}');
            print('📊 HTTP Status Code: ${failure.statusCode}');
            print('⚠️  API başarısız - totals data\'dan mock top data oluşturuluyor...');
            
            // Totals data varsa mock top data oluştur
            if (_totalsData != null || _officeData != null) {
              print('🔧 Totals ve Office data\'dan mock AdminTopModel oluşturuluyor...');
              
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
                  ..sort((a, b) => (double.tryParse(b.revenue) ?? 0).compareTo(double.tryParse(a.revenue) ?? 0));
                
                print('🏢 Tüm ofisler (gelire göre sıralı):');
                for (var office in sortedOffices) {
                  print('  - ${office.officeTitle}: ₺${office.revenue}');
                }
                
                if (sortedOffices.length >= 3) {
                  // En iyi 3 ofisi farklı dönemler için kullan
                  bestOfficeYear = sortedOffices[0].officeTitle;    // En yüksek gelirli - Yıl
                  bestOfficeMonth = sortedOffices[1].officeTitle;   // İkinci en yüksek - Ay
                  bestOfficeWeek = sortedOffices[2].officeTitle;    // Üçüncü en yüksek - Hafta
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
                  print('🏢 Tek ofis kullanılıyor: ${topOffice.officeTitle} - ₺${topOffice.revenue}');
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
              final officeMonthTitle = (_topData?.officeMonth?.isNotEmpty ?? false) 
                  ? _topData!.officeMonth![0].officeTitle 
                  : "Boş";
              final officeYearTitle = (_topData?.officeYear?.isNotEmpty ?? false) 
                  ? _topData!.officeYear![0].officeTitle 
                  : "Boş";
              print('🔍 Top Data - Office Week: $officeWeekTitle');
              print('🔍 Top Data - Office Month: $officeMonthTitle');
              print('🔍 Top Data - Office Year: $officeYearTitle');
              print('🔍 Office Week Count: ${_topData?.officeWeek?.length ?? 0}');
              print('🔍 Office Month Count: ${_topData?.officeMonth?.length ?? 0}');
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
              print('✅ Daily Revenue verileri yüklendi - Days count: ${_dailyData!.days.length}');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoginIntroHost(
      loading: _isLoading,
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Muhasebe Dashboard');
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
        title: "Muhasebe Dashboard",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBackgroundWidget(
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
                      // Modern Animasyonlu Arka Plan Desenleri
                      Positioned(
                        top: -100,
                        right: -100,
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red.withOpacity(0.1),
                                  Colors.red.withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(150),
                            ),
                          ),
                        ),
                      ),
                      // Yüzen Daire
                      Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.3,
                        left: -150,
                        child: AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * _floatingAnimation.value),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red.withOpacity(0.05),
                                  Colors.red.withOpacity(0.01),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      // Küçük Yüzen Şekiller
                      ...List.generate(5, (index) {
                        final random = math.Random();
                        final size = random.nextDouble() * 50 + 20;
                        final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
                        final initialY = random.nextDouble() * MediaQuery.of(context).size.height;

                        return Positioned(
                          left: initialX,
                          top: initialY,
                          child: AnimatedBuilder(
                            animation: _floatingAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  10 * math.sin((index + 1) * _floatingAnimation.value * math.pi),
                                  15 * math.cos((index + 1) * _floatingAnimation.value * math.pi),
                                ),
                                child: Transform.rotate(
                                  angle: _rotationController.value * math.pi * (index + 1),
                                  child: Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.withOpacity(0.05),
                                          Colors.red.withOpacity(0.02),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(index.isEven ? size / 2 : 5),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      // Eski animasyonlu arka plan elementleri
                      Positioned(
                        right: -100,
                        top: -100,
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_rotationController, _scaleAnimation]),
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(200),
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE53935).withOpacity(0.1),
                                  const Color(0xFFE53935).withOpacity(0.15),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -100,
                        bottom: -100,
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_rotationController, _scaleAnimation]),
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: -_rotationController.value * 2 * math.pi,
                              child: Transform.scale(
                                scale: _scaleAnimation.value * 0.8,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(200),
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE53935).withOpacity(0.3),
                                  const Color(0xFFE53935).withOpacity(0.15),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: MediaQuery.of(context).size.width / 2 - 200,
                        top: MediaQuery.of(context).size.height / 2 - 200,
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_rotationController, _scaleAnimation]),
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * math.pi,
                              child: Transform.scale(
                                scale: _scaleAnimation.value * 0.9,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(200),
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFE53935).withOpacity(0.25),
                                  const Color(0xFFE53935).withOpacity(0.1),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // İçerik
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                              // Modern Skeleton Loading
                              if (_isLoading)
                                _buildSkeletonLoading()
                              else if (_totalsData != null)
                                _buildCarouselCard()
                              else
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
                                        'İstatistik verileri yükleniyor...',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Zecorner Ofisleri Operasyon Durumu",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 200,
                                        child: PieChart(
                                          PieChartData(
                                            sectionsSpace: 0,
                                            centerSpaceRadius: 50,
                                            sections: _buildPieChartSections(),
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event,
                                                  pieTouchResponse) {
                                                if (event is FlTapUpEvent) {
                                                  final sectionIndex =
                                                      pieTouchResponse?.touchedSection
                                                          ?.touchedSectionIndex;
                                                  if (sectionIndex != null) {
                                                    setState(() {
                                                      // Broker dashboard'daki gibi sabit titles array kullan
                                                      final titles = _getPieSectionTitles();
                                                      if (sectionIndex < titles.length) {
                                                        _selectedPieSection = titles[sectionIndex];
                                                        _textAnimationController.reset();
                                                        _textAnimationController.forward();
                                                      }
                                                    });
                                                  }
                                                }
                                              },
                                            ),
                                            centerSpaceColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (_selectedPieSection != null)
                                        ScaleTransition(
                                          scale: _textScaleAnimation,
                                          child: FadeTransition(
                                            opacity: _textAnimationController,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _selectedPieSection!,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (_getSelectedSectionValue(_selectedPieSection!) != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      _getSelectedSectionValue(_selectedPieSection!)!,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            // TEST: API Debug Butonu
                            // Container(
                            //   width: double.infinity,
                            //   padding: const EdgeInsets.symmetric(horizontal: 16),
                            //   child: ElevatedButton.icon(
                            //     onPressed: () {
                            //       print('🧪 TEST: Manual API çağrısı başlatılıyor (Tamamen gerçek API verileri)...');
                            //       _loadDashboardData();
                            //     },
                            //     icon: const Icon(Icons.refresh, color: Colors.white),
                            //     label: const Text('API Yenile (Tamamen Gerçek Veriler)', 
                            //       style: TextStyle(color: Colors.white)),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.orange,
                            //       padding: const EdgeInsets.symmetric(vertical: 12),
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(height: 20),
                            // Ofis Performans Durumu
                            const Text(
                              "Ofis Performans Durumu",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(238, 46, 36, 1),
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _buildTopOfficeCards(),
                            ),
                            SizedBox(height: 30),
                            // Danışman Performans Durumu  
                            const Text(
                              "Danışman Performans Durumu",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(238, 46, 36, 1),
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _buildTopAdvisorCards(),
                            ),
                            SizedBox(height: 36),
                            _buildIncomeChart(),
                            const SizedBox(height: 45),
                            PanelOfficeTable(officeData: _officeData),
                            const SizedBox(height: 0),
                            PanelDanismanCard(
                              advisorData: _advisorData,
                            ),
                            SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Muhasebe Navbar - role_accountant için
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
                    print('Muhasebe Dashboard - Bottom Navbar - User Role Codes: $userRoleCodes');
                    
                    // Web sitesindeki mantığa göre navbar seçimi - Muhasebe rolü için
                    if (userRoleCodes.contains('role_accountant')) {
                      // Muhasebe rolü için admin navbar kullan (veya özel muhasebe navbar'ı eklenebilir)
                      return const AdminNavbar(currentIndex: 0);
                    } else if (userRoleCodes.contains('role_admin')) {
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
        ],
      ),
    ),
    );
  }





  /// Para formatı için yardımcı metot
  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString.replaceAll(',', '.')) ?? 0.0;
    final parts = price.toStringAsFixed(2).split('.');
    final formattedInteger = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '₺$formattedInteger,${parts[1]}';
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
    final result = await _dashboardRepo.getDashboardDailyRevenue(
      year: year,
      month: month,
    );
    if (!mounted) return;
    result.fold((_) {}, (data) {
      try {
        setState(() => _dailyData = AdminDailyModel.fromJson(data));
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

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Zecorner Ofisleri Gelir Grafiği",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
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
                                              color: Colors.white.withOpacity(0.3),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    itemCount: years.length,
                                    itemBuilder: (context, index) {
                                      final year = years[index];
                                      final isSelected = _selectedYear == year;
                                      return InkWell(
                                        onTap: () => Navigator.pop(context, year),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                                    colors: [
                                                      const Color(0xFFE53935).withOpacity(0.15),
                                                      const Color(0xFFE53935).withOpacity(0.08),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            color: isSelected ? null : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFE53935).withOpacity(0.4)
                                                  : Colors.grey[200]!,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFFE53935).withOpacity(0.15),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    margin: const EdgeInsets.only(right: 16),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(0xFFE53935)
                                                          : Colors.grey[300],
                                                      shape: BoxShape.circle,
                                                      border: isSelected
                                                          ? Border.all(
                                                              color: const Color(0xFFE53935).withOpacity(0.3),
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
                                                          ? const Color(0xFFE53935)
                                                          : Colors.black87,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFE53935),
                                                        Color(0xFFC62828),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFE53935).withOpacity(0.4),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
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
                                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                              ],
                            ),
                          ),
                        );
                        
                        if (selectedYear != null) {
                          setState(() {
                            _selectedYear = selectedYear;
                            _selectedMonth ??= DateTime.now().month;
                          });
                          _reloadChart();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _selectedYear != null 
                                    ? '$_selectedYear'
                                    : 'Yıl',
                                style: TextStyle(
                                  color: _selectedYear != null ? Colors.black : Colors.grey,
                                  fontWeight: _selectedYear != null ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: _selectedYear == null ? 0.5 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: GestureDetector(
                        onTap: _selectedYear == null ? null : () async {
                        // Seçili yıldaki mevcut ayları göster
                        final availableMonths = _getAvailableMonthsForYear(_selectedYear!);
                        
                        if (availableMonths.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bu yıl için veri bulunmuyor'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        const monthNames = [
                          'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                          'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                        ];
                        
                        final selectedMonth = await showModalBottomSheet<int>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => Container(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
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
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    itemCount: availableMonths.length,
                                    itemBuilder: (context, index) {
                                      final month = availableMonths[index];
                                      final isSelected = _selectedMonth == month;
                                      return InkWell(
                                        onTap: () => Navigator.pop(context, month),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                                    colors: [
                                                      const Color(0xFFE53935).withOpacity(0.15),
                                                      const Color(0xFFE53935).withOpacity(0.08),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            color: isSelected ? null : Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFE53935).withOpacity(0.4)
                                                  : Colors.grey[200]!,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFFE53935).withOpacity(0.15),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    margin: const EdgeInsets.only(right: 16),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(0xFFE53935)
                                                          : Colors.grey[300],
                                                      shape: BoxShape.circle,
                                                      border: isSelected
                                                          ? Border.all(
                                                              color: const Color(0xFFE53935).withOpacity(0.3),
                                                              width: 3,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                  Text(
                                                    monthNames[month - 1],
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: isSelected 
                                                          ? FontWeight.bold 
                                                          : FontWeight.w500,
                                                      color: isSelected 
                                                          ? const Color(0xFFE53935)
                                                          : Colors.black87,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFE53935),
                                                        Color(0xFFC62828),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFE53935).withOpacity(0.4),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
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
                                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                              ],
                            ),
                          ),
                        );
                        
                        if (selectedMonth != null) {
                          setState(() {
                            _selectedMonth = selectedMonth;
                          });
                          _reloadChart();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _selectedMonth != null 
                                    ? _getMonthName(_selectedMonth!)
                                    : 'Ay',
                                style: TextStyle(
                                  color: _selectedYear == null 
                                      ? Colors.grey[400] 
                                      : (_selectedMonth != null ? Colors.black : Colors.grey),
                                  fontWeight: _selectedMonth != null ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _selectedYear == null ? Colors.grey[400] : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                    ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = DateTime.now().year;
                  _selectedMonth = DateTime.now().month;
                  _selectedMetric = "Gelir";
                });
                _reloadChart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Filtreyi Temizle",
                style: TextStyle(color: Colors.white,fontSize: 17),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
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
                                _formatPrice(rod.toY.toStringAsFixed(0)),
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
                                    '${date.day} ${_getMonthName(date.month)}',
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
                                  String formattedValue;
                                  if (maxRevenue >= 1000000) {
                                    formattedValue = '₺${(maxRevenue / 1000000).toStringAsFixed(1)}M';
                                  } else if (maxRevenue >= 1000) {
                                    formattedValue = '₺${(maxRevenue / 1000).toStringAsFixed(0)}K';
                                  } else {
                                    formattedValue = _formatPrice(maxRevenue.toStringAsFixed(0));
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 0.0, left: 0.0),
                                    child: Text(
                                      formattedValue,
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
                                color: const Color(0xFFE53935),
                                width: displayDays.length <= 4 ? 45 : 30,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
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
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color.fromRGBO(229, 57, 53, 1).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Toplam Net Kazanç:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          const Color.fromRGBO(229, 57, 53, 1).withOpacity(1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayDays.isNotEmpty 
                          ? _formatPrice(_calculateTotalForDays(displayDays).toString())
                          : "₺0",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
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
    
    final changesRequiredValue = double.tryParse(_totalsData!.changesRequired) ?? 0;
    if (changesRequiredValue > 0) titles.add('Değişiklik İsteniyor');
    
    final waitingForApprovalValue = double.tryParse(_totalsData!.waitingForApproval) ?? 0;
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
        PieChartSectionData(value: 30, color: Colors.blue, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 10, color: Colors.green, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 25, color: Colors.amber, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 15, color: Colors.red, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 12, color: Colors.lightBlue, title: '', radius: 60, showTitle: false),
        PieChartSectionData(value: 8, color: Colors.teal, title: '', radius: 60, showTitle: false),
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
    
    final changesRequiredValue = double.tryParse(_totalsData!.changesRequired) ?? 0;
    if (changesRequiredValue > 0) {
      sections.add(PieChartSectionData(
        value: changesRequiredValue,
        color: Colors.teal,
        title: '',
        radius: 60,
        showTitle: false,
      ));
    }
    
    final waitingForApprovalValue = double.tryParse(_totalsData!.waitingForApproval) ?? 0;
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
        iconColor: Colors.blue,
        title: weekOffice.officeTitle,
        subtitle: "Haftanın Ofisi",
        price: _formatPrice(weekOffice.total),
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print('✅ Haftanın Ofisi eklendi: ${weekOffice.officeTitle} - ${weekOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: Colors.blue,
        title: "-",
        subtitle: "Haftanın Ofisi",
        price: "-",
        onTap: null,
      ));
      print('⚠️ Haftanın Ofisi verisi yok - "-" gösteriliyor');
    }

    // Ayın Ofisi - office_month array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.officeMonth != null && _topData!.officeMonth!.isNotEmpty) {
      final monthOffice = _topData!.officeMonth![0];
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: Colors.amber,
        title: monthOffice.officeTitle,
        subtitle: "Ayın Ofisi",
        price: _formatPrice(monthOffice.total),
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print('✅ Ayın Ofisi eklendi: ${monthOffice.officeTitle} - ${monthOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: Colors.amber,
        title: "-",
        subtitle: "Ayın Ofisi",
        price: "-",
        onTap: null,
      ));
      print('⚠️ Ayın Ofisi verisi yok - "-" gösteriliyor');
    }

    // Yılın Ofisi - office_year array'inden ilk elemanı al, yoksa "-" göster
    if (_topData!.officeYear != null && _topData!.officeYear!.isNotEmpty) {
      final yearOffice = _topData!.officeYear![0];
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: Colors.green,
        title: yearOffice.officeTitle,
        subtitle: "Yılın Ofisi",
        price: _formatPrice(yearOffice.total),
        onTap: () => Navigator.pushNamed(context, '/broker-dashboard'),
      ));
      print('✅ Yılın Ofisi eklendi: ${yearOffice.officeTitle} - ${yearOffice.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.apartment,
        iconColor: Colors.green,
        title: "-",
        subtitle: "Yılın Ofisi",
        price: "-",
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
      ));
      print('✅ Haftanın Danışmanı eklendi: ${weekAdvisor.advisorTitle} - ${weekAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.blue,
        title: "-",
        subtitle: "Haftanın Yıldızı",
        price: "-",
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
      ));
      print('✅ Ayın Danışmanı eklendi: ${monthAdvisor.advisorTitle} - ${monthAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.amber,
        title: "-",
        subtitle: "Ayın Yıldızı",
        price: "-",
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
      ));
      print('✅ Yılın Danışmanı eklendi: ${yearAdvisor.advisorTitle} - ${yearAdvisor.total}');
    } else {
      // Veri yoksa "-" göster
      cards.add(_buildAwardCard(
        icon: Icons.person,
        iconColor: Colors.green,
        title: "-",
        subtitle: "Yılın Yıldızı",
        price: "-",
      ));
      print('⚠️ Yılın Danışmanı verisi yok - "-" gösteriliyor');
    }

    print('🎯 Final advisor cards count: ${cards.length}');
    return cards;
  }

  /// Yatay carousel kart widget'ı
  Widget _buildCarouselCard() {
    final List<Map<String, dynamic>> cardData = [
      {
        'icon': Icons.key,
        'iconColor': const Color(0xFFF59E0B),
        'title': 'Kiralık İlan',
        'value': _totalsData!.forRent.toString(),
      },
      {
        'icon': Icons.home,
        'iconColor': const Color(0xFF2563EB),
        'title': 'Satılık İlan',
        'value': _totalsData!.forSale.toString(),
      },
      {
        'icon': Icons.check_circle,
        'iconColor': const Color(0xFF10B981),
        'title': 'Tamamlanan Satış / Kiralama',
        'value': ((int.tryParse(_totalsData!.sold) ?? 0) + (int.tryParse(_totalsData!.rented) ?? 0)).toString(),
      },
      {
        'icon': Icons.people,
        'iconColor': const Color(0xFF7C3AED),
        'title': 'Toplam Müşteri',
        'value': _totalsData!.customers.toString(),
      },
    ];

    return SizedBox(
      height: 165,
      child: ClipRect(
        child: PageView.builder(
          controller: _pageController,
          clipBehavior: Clip.hardEdge,
          physics: const PageScrollPhysics(),
          onPageChanged: (index) {
            _currentPage = index;
            _restartAutoScroll();
          },
          itemCount: cardData.length,
          itemBuilder: (context, index) {
            final data = cardData[index];
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildHorizontalStatCard(
                  icon: data['icon'] as IconData,
                  iconColor: data['iconColor'] as Color,
                  title: data['title'] as String,
                  value: data['value'] as String,
                ),
              ),
            );
          },
        ),
      ),
    );
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
    final animationValue = (_entranceAnimation.value - delay).clamp(0.0, 1.0) / (1.0 - delay);
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
                  color: Colors.black.withOpacity(0.05 + (0.03 * animation.value)),
                  blurRadius: 10 + (5 * animation.value),
                  spreadRadius: 0,
                  offset: Offset(0, 2 + (2 * animation.value)),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03 + (0.02 * animation.value)),
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
}