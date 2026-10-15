import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/users/users_model.dart';
import '../../models/list/listing_model.dart';
import '../../infrastructure/advisor/advisor_repository.dart';
import '../../infrastructure/list/listing_repository.dart';
import '../../router/app_router.dart';
import '../../core/utils/image_utils.dart';
import '../widgets/status/app_status_view.dart';

class HomeDanismanScreen extends StatefulWidget {
  const HomeDanismanScreen({Key? key}) : super(key: key);

  @override
  State<HomeDanismanScreen> createState() => _HomeDanismanScreenState();
}

class _HomeDanismanScreenState extends State<HomeDanismanScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0;
  late TabController _tabController;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Repository
  final AdvisorRepository _advisorRepository = AdvisorRepository();
  final ListingRepository _listingRepository = ListingRepository();
  
  // Dynamic data
  List<ListingModel> _listings = []; // Filtrelenmiş ilanlar (gösterilecek)
  List<ListingModel> _allListings = []; // Tüm ilanlar (sayılar için)
  UserModel? _advisor;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  // Advisor info - dinamik olacak (detay sayfasından gelince route args ile dolar)
  String _advisorId = '';
  String _advisorName = 'Danışman Yükleniyor...';
  String _advisorRole = '';
  String _advisorEmail = '';
  String _advisorPhone = '';
  String? _advisorPicture; // Danışman fotoğrafı (S3 ID)
  String _advisorOffice = ''; // Bağlı ofis (connected_contact_title)
  String _advisorAbout = ''; // Hakkımda / ön yazı
  String? _advisorInstagram;
  String? _advisorFacebook;
  String? _advisorTwitter;
  String? _advisorLinkedIn;
  String? _advisorYouTube;
  int _contactNo = 0;
  int _satilikCount = 0;
  int _kiralikCount = 0;
  int _satildiCount = 0;
  int _kiralandiCount = 0;
  int _selectedTabIndex = 0; // 0 = Portföyüm, 1 = Geçmiş İlanlar
  /// Detay sayfasından "Danışmanı Ziyaret Et" ile gelindiyse route bilgileri öncelikli, API ile ezilmesin
  bool _fromListingDetail = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;





  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
          _listings = _getDisplayedListings();
        });
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    
    // Route arguments'tan advisor bilgilerini al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getRouteArguments();
      _loadAdvisorData();
    });
  }

  void _getRouteArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    print('📋 Route arguments: $arguments');
    
    if (arguments != null && arguments is Map<String, dynamic>) {
      setState(() {
        _fromListingDetail = true; // Detay sayfasından gelen bilgileri koru, API ile ezme
        // Consultant ID - slug veya isimden oluşturulmuş ID
        _advisorId = arguments['consultantId']?.toString() ?? 'unknown';
        
        // Consultant Name - contact_title
        _advisorName = arguments['consultantName']?.toString() ?? 'Danışman';
        
        // Consultant Title/Role - contact_type_description
        _advisorRole = arguments['consultantTitle']?.toString() ?? 'Emlak Danışmanı';
        
        // Consultant Email - contact_email
        _advisorEmail = arguments['consultantEmail']?.toString() ?? '';
        
        // Consultant Phone - contact_tel (JSON'dan gelen telefon numarası)
        _advisorPhone = arguments['consultantPhone']?.toString() ?? '';
        
        // Consultant Picture - contact_picture (JSON'dan gelen fotoğraf S3 ID)
        _advisorPicture = arguments['consultantPicture']?.toString();
        
        _advisorOffice = arguments['consultantOffice']?.toString() ?? '';
        _advisorAbout = arguments['consultantAbout']?.toString() ?? '';
        _advisorInstagram = arguments['consultantInstagram']?.toString();
        _advisorFacebook = arguments['consultantFacebook']?.toString();
        _advisorTwitter = arguments['consultantTwitter']?.toString();
        _advisorLinkedIn = arguments['consultantLinkedIn']?.toString();
        _advisorYouTube = arguments['consultantYouTube']?.toString();
        
        // Contact No - contact_no (JSON'dan gelen ID numarası)
        if (arguments['consultantContactNo'] != null) {
          if (arguments['consultantContactNo'] is int) {
            _contactNo = arguments['consultantContactNo'] as int;
          } else if (arguments['consultantContactNo'] is String) {
            _contactNo = int.tryParse(arguments['consultantContactNo'] as String) ?? 0;
          }
        }
      });
      print('🔄 Route arguments alındı (detay sayfasından - öncelikli kullanılacak):');
      print('👤 Advisor ID: $_advisorId');
      print('👤 Advisor Name: $_advisorName');
      print('👤 Advisor Role: $_advisorRole');
      print('👤 Advisor Email: $_advisorEmail');
      print('👤 Advisor Phone: $_advisorPhone');
      print('👤 Advisor Picture: $_advisorPicture');
      print('👤 Contact No: $_contactNo');
    } else {
      print('❌ Route arguments bulunamadı veya geçersiz format');
      _fromListingDetail = false;
      setState(() {
        _advisorId = 'sukru-portakal';
        _contactNo = 40;
        _advisorName = "Şükrü Portakal";
        _advisorEmail = "sukru.portakal@zecorner.com";
      });
      print('🧪 Fallback danışman kullanılıyor: $_advisorName');
    }
  }

  Future<void> _loadAdvisorData() async {
    await _loadAdvisorInfo();
    await _loadListings();
  }

  Future<void> _loadAdvisorInfo() async {
    try {
      // Detay sayfasından gelindiyse route'taki bilgiler zaten set edildi, API ile ezme
      if (_fromListingDetail) {
        print('📌 Detay sayfasından gelindi - danışman bilgileri route argümanlarından kullanılıyor');
        return;
      }
      if (_advisorId.isEmpty) return;
      final result = await _advisorRepository.getAdvisorInfo(_advisorId);
      
      result.fold(
        (failure) {
          print('❌ Danışman bilgisi hatası: ${failure.message}');
        },
        (advisorUser) {
          if (advisorUser != null) {
            setState(() {
              _advisor = advisorUser;
              _advisorName = advisorUser.title;
              _advisorRole = advisorUser.roleDescription;
              _advisorEmail = advisorUser.email;
              _advisorPhone = advisorUser.tel;
              _advisorPicture = advisorUser.picture;
              _contactNo = advisorUser.contactNo;
            });
            print('✅ Danışman bilgileri API\'den yüklendi: ${advisorUser.title} (${advisorUser.contactNo})');
          } else {
            print('⚠️ Danışman bulunamadı, mevcut/fallback bilgiler kullanılıyor');
          }
        },
      );
    } catch (e) {
      print('💥 Danışman bilgisi beklenmeyen hata: $e');
    }
  }

  Future<void> _loadListings({bool isRefresh = false}) async {
    print('🔄 Listings yükleniyor - Advisor ID: $_advisorId');
    
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _listings.clear();
        _allListings.clear(); // Tüm ilanları da temizle
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
      print('🔄 Refresh mode - sayfa 1\'den başlıyor');
    }

    if (_isLoadingMore || (!_hasMoreData && !isRefresh)) {
      print('⏹️ Loading durdu - isLoadingMore: $_isLoadingMore, hasMoreData: $_hasMoreData');
      return;
    }

    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      print('🎯 Tab: $_selectedTabIndex, Filter: $_selectedFilter');
      print('📄 Sayfa: $_currentPage');

      // Listing API'sinden ilanları al (state/tip filtresi client-side yapılacak)
      final result = await _listingRepository.getListings(
        page: _currentPage,
        limit: 50,
      );

      result.fold(
        (failure) {
          print('❌ Listings API hatası: ${failure.message}');
          print('❌ Status Code: ${failure.statusCode}');
          setState(() {
            _hasError = true;
            _errorMessage = failure.message;
            _isLoading = false;
            _isLoadingMore = false;
          });
        },
        (response) {
          print('✅ ${response.listings.length} ilan alındı');
          print('📊 Total Count: ${response.totalCount}');
          
          // Debug: İlan contact bilgilerini göster
          print('📋 İlk 3 ilanın contact bilgileri:');
          for (int i = 0; i < response.listings.length && i < 3; i++) {
            final listing = response.listings[i];
            print('   İlan ${i+1}: contact_no=${listing.contactNo}, title="${listing.contactTitle}", email="${listing.contactEmail}"');
          }
          
          // Client-side filtreleme - contact_no ile
          List<ListingModel> filteredListings = response.listings;
          
          print('🎯 Danışman Contact No: $_contactNo');
          print('🎯 Danışman Name: $_advisorName');
          print('🎯 Danışman Email: $_advisorEmail');
          
          // 1. Adım: Danışman ile filtreleme
          if (_contactNo > 0) {
            // Danışman contact_no'su ile filtreleme yap
            filteredListings = response.listings.where((listing) {
              final isMatch = listing.contactNo == _contactNo;
              if (isMatch) {
                print('✅ Eşleşen ilan: ${listing.title} (contact_no: ${listing.contactNo}, tip: ${listing.type})');
              }
              return isMatch;
            }).toList();
            
            print('🔍 Contact No ($_contactNo) ile filtreleme: ${filteredListings.length} ilan kaldı');
          } else if (_advisorEmail.isNotEmpty) {
            // Email ile de dene
            filteredListings = response.listings.where((listing) {
              final isMatch = listing.contactEmail.toLowerCase() == _advisorEmail.toLowerCase();
              if (isMatch) {
                print('✅ Email ile eşleşen ilan: ${listing.title} (email: ${listing.contactEmail}, tip: ${listing.type})');
              }
              return isMatch;
            }).toList();
            
            print('🔍 Email ($_advisorEmail) ile filtreleme: ${filteredListings.length} ilan kaldı');
          } else if (_advisorName.isNotEmpty && _advisorName != 'Danışman Yükleniyor...') {
            // İsim ile de dene
            filteredListings = response.listings.where((listing) {
              final isMatch = listing.contactTitle.toLowerCase().contains(_advisorName.toLowerCase());
              if (isMatch) {
                print('✅ İsim ile eşleşen ilan: ${listing.title} (contact: ${listing.contactTitle}, tip: ${listing.type})');
              }
              return isMatch;
            }).toList();
            
            print('🔍 İsim ($_advisorName) ile filtreleme: ${filteredListings.length} ilan kaldı');
          } else {
            print('⚠️ Hiçbir filtreleme kriteri bulunamadı, tüm ilanlar gösteriliyor');
            print('⚠️ Contact No: $_contactNo, Email: "$_advisorEmail", Name: "$_advisorName"');
          }

          // Danışman ile filtrelenmiş ilanları bul (filtreleme yapmadan önce)
          List<ListingModel> allAdvisorListings = response.listings;
          
          if (_contactNo > 0) {
            allAdvisorListings = response.listings.where((listing) => listing.contactNo == _contactNo).toList();
          } else if (_advisorEmail.isNotEmpty) {
            allAdvisorListings = response.listings.where((listing) => listing.contactEmail.toLowerCase() == _advisorEmail.toLowerCase()).toList();
          } else if (_advisorName.isNotEmpty && _advisorName != 'Danışman Yükleniyor...') {
            allAdvisorListings = response.listings.where((listing) => listing.contactTitle.toLowerCase().contains(_advisorName.toLowerCase())).toList();
          }
          
          // Tüm danışman ilanlarını _allListings'e ekle
          if (_currentPage == 1) {
            _allListings = List<ListingModel>.from(allAdvisorListings);
            print('📊 Danışman ilanları (LIVE): ${_allListings.length}');
            // Ofis adı route'tan gelmediyse ilanlardan al (bulunduğu ofis)
            if (_advisorOffice.isEmpty && _allListings.isNotEmpty) {
              for (var l in _allListings) {
                if (l.connectedContactTitle.isNotEmpty) {
                  _advisorOffice = l.connectedContactTitle;
                  print('🏢 Ofis adı ilanlardan alındı: $_advisorOffice');
                  break;
                }
              }
            }
            // Hemen sayıları güncelle ki Satılık/Kiralık (0) olmasın
            _updateCounts();
            // İlk sayfada Satıldı/Kiralandı ilanlarını da arka planda çek ve ekle
            _loadPastListingsAndMerge(contactNo: _contactNo, advisorEmail: _advisorEmail, advisorName: _advisorName);
          } else {
            _allListings.addAll(allAdvisorListings);
            _updateCounts();
            print('📊 Tüm ilanlara eklendi - Toplam: ${_allListings.length} ilan');
          }

          setState(() {
            _listings = _getDisplayedListings();
            if (_currentPage == 1) {
              print('🔄 İlk sayfa - gösterilen: ${_listings.length} (tab: $_selectedTabIndex)');
            } else {
              print('➕ Sayfa eklendi - gösterilen: ${_listings.length}');
            }
            _hasMoreData = filteredListings.length >= 10;
            _currentPage++;
            _isLoading = false;
            _isLoadingMore = false;
            _hasError = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      print('💥 Listings beklenmeyen hata: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Satıldı ve Kiralandı ilanlarını get-advisor-listings endpoint'i ile çeker (web ile aynı: ?state=SOLD / ?state=RENTED)
  Future<void> _loadPastListingsAndMerge({
    required int contactNo,
    required String advisorEmail,
    required String advisorName,
  }) async {
    if (contactNo <= 0) {
      print('⚠️ Geçmiş ilanlar: contact_no yok, atlanıyor');
      return;
    }
    final existingIds = _allListings.map((e) => e.id).toSet();
    for (final state in ['SOLD', 'RENTED']) {
      try {
        final result = await _listingRepository.getAdvisorListingsByState(
          contactNo: contactNo,
          page: 1,
          pageSize: 50,
          state: state,
        );
        result.fold(
          (failure) {
            print('⚠️ Geçmiş ilanlar ($state) API hatası: ${failure.message}');
          },
          (response) {
            print('📡 Geçmiş ilanlar ($state) get-advisor-listings: totalCount=${response.totalCount}, listings.length=${response.listings.length}');
            for (final l in response.listings) {
              if (!existingIds.contains(l.id)) {
                _allListings.add(l);
                existingIds.add(l.id);
                if (_advisorOffice.isEmpty && l.connectedContactTitle.isNotEmpty) {
                  _advisorOffice = l.connectedContactTitle;
                  print('🏢 Ofis adı geçmiş ilanlardan alındı: $_advisorOffice');
                }
              }
            }
            print('📊 Geçmiş ilanlar ($state): ${response.listings.length} ilan eklendi');
            if (mounted) setState(() {});
          },
        );
      } catch (e) {
        print('⚠️ Geçmiş ilanlar ($state) yüklenemedi: $e');
      }
    }
    _updateCounts();
    if (mounted) setState(() => _listings = _getDisplayedListings());
  }

  /// Sosyal medya URL'ini normalize et (tam URL, kullanıcı adı veya boş)
  String _normalizeSocialUrl(String? value, String defaultUrl, String domain) {
    if (value == null || value.trim().isEmpty) return defaultUrl;
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.contains(domain)) return 'https://$v';
    final username = v.replaceAll('@', '').trim();
    if (domain == 'instagram.com') return 'https://www.instagram.com/$username/';
    if (domain == 'facebook.com') return 'https://www.facebook.com/$username';
    if (domain == 'x.com') return 'https://x.com/$username';
    if (domain == 'linkedin.com') return 'https://www.linkedin.com/in/$username';
    if (domain == 'youtube.com') return username.startsWith('@') ? 'https://www.youtube.com/$username' : 'https://www.youtube.com/@$username';
    return defaultUrl;
  }

  /// Tek bir sosyal medya ikonu - tıklanınca link açar, marka rengiyle
  Widget _socialIcon({required Widget icon, required Color backgroundColor, required String url}) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link açılamadı')),
            );
          }
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  /// Sosyal medya ikonu - gradient arka plan (Instagram vb.)
  Widget _socialIconGradient({required Widget icon, required Gradient gradient, required String url}) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link açılamadı')),
            );
          }
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  /// Danışman profil fotoğrafı yoksa veya yüklenemezse: yuvarlak avatar (amblem/placeholder)
  Widget _buildAdvisorAvatarPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: 48, color: Colors.grey[600]),
    );
  }

  void _updateCounts() {
    final liveListings = _allListings.where((l) => l.state.toUpperCase() == 'LIVE').toList();
    final pastListings = _allListings.where((l) {
      final s = l.state.toUpperCase();
      return s == 'SOLD' || s == 'RENTED';
    }).toList();

    _satilikCount = liveListings.where((listing) {
      final type = listing.type.toLowerCase();
      return type.contains('satı') || type.contains('sat') || type == 'satilik';
    }).length;
    _kiralikCount = liveListings.where((listing) {
      final type = listing.type.toLowerCase();
      return type.contains('kira') || type == 'kiralik';
    }).length;
    _satildiCount = pastListings.where((l) => l.state.toUpperCase() == 'SOLD').length;
    _kiralandiCount = pastListings.where((l) => l.state.toUpperCase() == 'RENTED').length;

    print('📊 Sayılar güncellendi: Portföy Satılık=$_satilikCount Kiralık=$_kiralikCount | Geçmiş Satıldı=$_satildiCount Kiralandı=$_kiralandiCount');
  }

  /// Gösterilecek ilan listesi: seçili sekmeye ve filtreye göre _allListings'den türetilir
  List<ListingModel> _getDisplayedListings() {
    if (_selectedTabIndex == 0) {
      // Portföyüm: sadece LIVE
      var list = _allListings.where((l) => l.state.toUpperCase() == 'LIVE').toList();
      if (_selectedFilter == 1) {
        list = list.where((l) {
          final t = l.type.toLowerCase();
          return t.contains('satı') || t.contains('sat') || t == 'satilik';
        }).toList();
      } else if (_selectedFilter == 2) {
        list = list.where((l) => l.type.toLowerCase().contains('kira') || l.type.toLowerCase() == 'kiralik').toList();
      }
      return list;
    } else {
      // Geçmiş İlanlar: SOLD ve RENTED
      var list = _allListings.where((l) {
        final s = l.state.toUpperCase();
        return s == 'SOLD' || s == 'RENTED';
      }).toList();
      if (_selectedFilter == 1) list = list.where((l) => l.state.toUpperCase() == 'SOLD').toList();
      if (_selectedFilter == 2) list = list.where((l) => l.state.toUpperCase() == 'RENTED').toList();
      return list;
    }
  }

  void _shareConsultant() {
    final lines = <String>[
      '🏠 $_advisorName',
      '$_advisorRole${_advisorOffice.isNotEmpty ? ' · $_advisorOffice' : ''}',
      '',
      if (_advisorEmail.isNotEmpty) '📧 $_advisorEmail',
      if (_advisorPhone.isNotEmpty) '📞 $_advisorPhone',
      '',
      'Zecorner üzerinden iletişime geçebilirsiniz.',
    ];
    Share.share(
      lines.join('\n'),
      subject: '$_advisorName - Emlak Danışmanı',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: null,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Üst Profil ve Logo
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      image: DecorationImage(
                        image: AssetImage('assets/images/istanbul_bg.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5), BlendMode.darken),
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: _shareConsultant,
                                icon: Icon(Icons.share, color: Colors.white, size: 25),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ClipOval(
                                child: _advisorPicture != null && ImageUtils.isValidS3Id(_advisorPicture!)
                                    ? Image.network(
                                        ImageUtils.getProfileImageUrl(_advisorPicture!),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return _buildAdvisorAvatarPlaceholder();
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildAdvisorAvatarPlaceholder();
                                        },
                                      )
                                    : _buildAdvisorAvatarPlaceholder(),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _advisorName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _advisorRole,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _advisorOffice.isNotEmpty ? _advisorOffice : 'Zecorner',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Portföy Sayıları
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text('$_satilikCount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 22)),
                            const SizedBox(height: 2),
                            Text('Satılık Portföy',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Column(
                          children: [
                            Text('$_kiralikCount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 22)),
                            const SizedBox(height: 2),
                            Text('Kiralık Portföy',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Hakkımda
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hakkımda',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _advisorAbout.isNotEmpty ? _advisorAbout : 'Ön yazı',
                          style: TextStyle(
                            fontSize: 14,
                            color: _advisorAbout.isNotEmpty ? Colors.black54 : Colors.black38,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // İletişim butonları
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final email = _advisorEmail.isNotEmpty ? _advisorEmail : 'info@zecorner.com';
                              final Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: email,
                                query: 'subject=İlan Hakkında Bilgi',
                              );
                              if (await canLaunchUrl(emailUri)) {
                                await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                              } else {
                                // Eğer mail uygulaması yoksa, kullanıcıya bilgi ver
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('E-posta uygulaması bulunamadı'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.email, color: Colors.white),
                            label: Text(
                              _advisorEmail.isNotEmpty ? _advisorEmail : 'info@zecorner.com',
                              style: TextStyle(fontSize: 13, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(238, 46, 36, 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_advisorPhone.isEmpty || _advisorPhone == '0') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Telefon numarası bulunamadı'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              
                              // Telefon numarasını temizle
                              String cleanPhone = _advisorPhone
                                  .replaceAll(' ', '')
                                  .replaceAll('(', '')
                                  .replaceAll(')', '')
                                  .replaceAll('-', '')
                                  .replaceAll('+', '');
                              
                              // Eğer +90 ile başlamıyorsa ekle
                              if (!cleanPhone.startsWith('90') && !cleanPhone.startsWith('0')) {
                                cleanPhone = '90$cleanPhone';
                              }
                              
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: '+$cleanPhone',
                              );
                              
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Telefon uygulaması bulunamadı'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.phone, color: Colors.white),
                            label: Text(
                              _advisorPhone.isNotEmpty && _advisorPhone != '0'
                                  ? _advisorPhone
                                  : 'Telefon numarası bulunamadı',
                              style: TextStyle(fontSize: 13, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(238, 46, 36, 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sosyal Medya - marka renkleri ve çalışan linkler
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sosyal Medya Hesaplarım',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _socialIcon(
                              icon: Text('f', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                              backgroundColor: const Color(0xFF1877F2), // Facebook mavi
                              url: _normalizeSocialUrl(_advisorFacebook, 'https://www.facebook.com/zecornertr', 'facebook.com'),
                            ),
                            const SizedBox(width: 12),
                            _socialIconGradient(
                              icon: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                              ),
                              url: _normalizeSocialUrl(_advisorInstagram, 'https://www.instagram.com/zecornertr/', 'instagram.com'),
                            ),
                            const SizedBox(width: 12),
                            _socialIcon(
                              icon: Text('X', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.black, // X (Twitter) siyah
                              url: _normalizeSocialUrl(_advisorTwitter, 'https://x.com/zecornertr', 'x.com'),
                            ),
                            const SizedBox(width: 12),
                            _socialIcon(
                              icon: Text('in', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF0A66C2), // LinkedIn mavi
                              url: _normalizeSocialUrl(_advisorLinkedIn, 'https://www.linkedin.com/company/zecorner', 'linkedin.com'),
                            ),
                            const SizedBox(width: 12),
                            _socialIcon(
                              icon: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              backgroundColor: const Color(0xFFFF0000), // YouTube kırmızı
                              url: _normalizeSocialUrl(_advisorYouTube, 'https://www.youtube.com/@zecorner', 'youtube.com'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Sekmeli Portföy/Geçmiş İlanlar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      color: Colors.grey[200],
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.black,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black54,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                              child: Text('Portföyüm',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Tab(
                              child: Text('Geçmiş İlanlar',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        onTap: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                            _listings = _getDisplayedListings();
                          });
                        },
                      ),
                    ),
                  ),
                  // Filtre Tabları
                  _buildFilterTabs(),
                  // İlan Listesi - Dinamik
                  _buildListingsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 3, // 3. sekme seçili
        onTap: (index) {
          // Sayfa geçişi veya setState ile index değişimi eklenebilir
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    final labels = _selectedTabIndex == 0
        ? ['Tümü', 'Satılık ($_satilikCount)', 'Kiralık ($_kiralikCount)']
        : ['Tümü', 'Satıldı ($_satildiCount)', 'Kiralandı ($_kiralandiCount)'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 244, 244, 244),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(3, (index) {
            final isSelected = _selectedFilter == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = index;
                    _listings = _getDisplayedListings();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Color(0xFFE53935) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Daha küçük font
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildListingsSection() {
    if (_isLoading && _listings.isEmpty) {
      return const AppStatusView.loading(
        title: 'İlanlar hazırlanıyor.',
        message: 'Danışman ilanları yüklenirken lütfen bekleyin.',
      );
    }

    if (_hasError && _listings.isEmpty) {
      return AppStatusView.error(
        title: 'Hata oluştu',
        message: _errorMessage ?? 'İlanlar yüklenemedi.',
        onRetry: () => _loadListings(isRefresh: true),
      );
    }

    if (_listings.isEmpty) {
      final isPastTab = _selectedTabIndex == 1;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(238, 46, 36, 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPastTab ? Icons.history_rounded : Icons.home_rounded,
                    size: 48,
                    color: const Color.fromRGBO(238, 46, 36, 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isPastTab
                    ? 'Satılan ya da kiralanan ilanlar burada listelenir.'
                    : (_contactNo > 0 ? 'Bu danışmanın henüz ilanı yok' : 'Henüz ilan yok'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isPastTab) const SizedBox(height: 8),
                if (!isPastTab)
                Text(
                  'Yeni ilanlar eklendiğinde burada görünecektir.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _hasMoreData && !_isLoadingMore) {
          _loadListings();
        }
        return false;
      },
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _listings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    // Named route ile detay sayfasına git
                    Navigator.pushNamed(
                      context,
                      AppRouter.homeIlanDetail,
                      arguments: _listings[index].id,
                    );
                  },
                  child: _buildDynamicListingCard(_listings[index]),
                ),
              );
            },
          ),
          // Load more indicator
          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                ),
              ),
            ),
          // No more data indicator
          if (!_hasMoreData && _listings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Tüm ilanlar gösterildi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicListingCard(ListingModel listing) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // S3 resim gösterimi
              Container(
                width: 110,
                height: 130,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: ImageUtils.isValidS3Id(listing.coverPicture)
                    ? Image.network(
                        ImageUtils.getCoverImageUrl(listing.coverPicture),
                    width: 110,
                    height: 130,
                    fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.home_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.home_outlined,
                          size: 40,
                          color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title.isNotEmpty ? listing.title : 'İlan Başlığı',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${listing.districtName}, ${listing.provinceName}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoIcon(Icons.meeting_room, _formatOdaSayisi(listing.properties['oda-sayisi']?.value)),
                              const SizedBox(width: 10),
                              _infoIcon(Icons.square_foot, '${listing.properties['m2-brut']?.numberValue ?? listing.properties['m2-net']?.numberValue ?? '-'} m²'),
                              const SizedBox(width: 10),
                              _infoIcon(Icons.layers, _formatKat(listing.properties['bulundugu-kat']?.value)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        listing.price > 0 
                          ? '${listing.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ${listing.currency}'
                          : 'Fiyat Görüşülür',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(238, 46, 36, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Satılık / Kiralık veya Satıldı / Kiralandı rozeti - sağ alt
          Positioned(
            bottom: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(238, 46, 36, 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getListingBadgeLabel(listing),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Kart rozeti: Geçmiş ilanlarda Satıldı/Kiralandı, portföyde Satılık/Kiralık
  String _getListingBadgeLabel(ListingModel listing) {
    final s = listing.state.toUpperCase();
    if (s == 'SOLD') return 'Satıldı';
    if (s == 'RENTED') return 'Kiralandı';
    return _formatListingType(listing.type);
  }

  /// İlan tipini formatla (örn: "satilik" -> "Satılık", "kiralik" -> "Kiralık")
  String _formatListingType(String type) {
    if (type.isEmpty) return type;
    
    final typeLower = type.toLowerCase();
    
    if (typeLower.contains('satı') || typeLower == 'satilik' || typeLower == 'satilik') {
      return 'Satılık';
    } else if (typeLower.contains('kira') || typeLower == 'kiralik') {
      return 'Kiralık';
    }
    
    // Kebab-case'i Title Case'e çevir
    return type.split('-').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatOdaSayisi(String? odaSayisi) {
    if (odaSayisi == null || odaSayisi.isEmpty || odaSayisi == '-' || odaSayisi == 'oda-sayisi' ||
        odaSayisi.toLowerCase().contains('undefined') || odaSayisi.toLowerCase().contains('null')) {
      return '-';
    }
    if (odaSayisi.contains('oda-sayisi-')) {
      final number = odaSayisi.replaceAll('oda-sayisi-', '');
      if (number.isEmpty || number == '0' || number == '00') return '-';
      if (number.length > 2) return '-';
      if (number.length == 2 && RegExp(r'^\d{2}$').hasMatch(number)) {
        final odaNum = int.tryParse(number[0]) ?? 0;
        final salonNum = int.tryParse(number[1]) ?? 0;
        if (odaNum > 6 || salonNum > 5) return '-';
        return '${number[0]}+${number[1]}';
      }
      if (number.length == 1 && RegExp(r'^\d$').hasMatch(number)) {
        final n = int.tryParse(number) ?? 0;
        if (n == 0 || n > 5) return '-';
        return '$number+1';
      }
      return '-';
    }
    if (odaSayisi.contains('+')) return odaSayisi;
    if (RegExp(r'^\d+$').hasMatch(odaSayisi)) {
      if (odaSayisi == '0') return '-';
      return '$odaSayisi+1';
    }
    return odaSayisi;
  }

  String _formatKat(String? kat) {
    if (kat == null || kat.isEmpty || kat == '-' || kat == 'bulundugu-kat' ||
        kat.toLowerCase().contains('undefined') || kat.toLowerCase().contains('null')) {
      return '-';
    }
    final katLower = kat.toLowerCase().trim();
    if (katLower.contains('giris') || katLower.contains('giriş')) {
      final parts = kat.split('-');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].toLowerCase() == 'kot' && i + 1 < parts.length) {
          return 'Giriş Katı Kot ${parts[i + 1]}';
        }
      }
      return 'Giriş Katı';
    }
    if (katLower.contains('bulundugu-kat-')) {
      final number = kat.replaceAll(RegExp(r'bulundugu-kat-', caseSensitive: false), '');
      if (number.isEmpty || number == '0') return 'Zemin Kat';
      if (RegExp(r'^\d+$').hasMatch(number)) return '$number. Kat';
      return number;
    }
    if (katLower == 'bulundugu-kat') return '-';
    final katMatch = RegExp(r'kat\s*(\d+)', caseSensitive: false).firstMatch(kat);
    if (katMatch != null) return '${katMatch.group(1)}. Kat';
    if (RegExp(r'^\d+$').hasMatch(kat)) {
      if (kat == '0') return 'Zemin Kat';
      return '$kat. Kat';
    }
    if (katLower == 'zemin' || katLower == '0') return 'Zemin Kat';
    if (katLower == 'bodrum' || katLower == '-1') return 'Bodrum Kat';
    return kat;
  }

  Widget _infoIcon(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: const Color.fromRGBO(238, 46, 36, 1)),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      );
}