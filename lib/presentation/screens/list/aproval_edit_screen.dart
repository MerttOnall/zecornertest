import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';

// Property model for approval
class ApprovalProperty {
  final String id;
  final String title;
  final String location;
  final String district;
  final String neighborhood;
  final String price;
  final String priceStr;
  final String type; // Satılık, Kiralık
  final String category; // Konut, İşyeri, Arsa
  final String propertyType; // Daire, Villa, etc.
  final String rooms;
  final int brutArea;
  final int netArea;
  final int floor;
  final int totalFloors;
  final int buildingAge;
  final int bathrooms;
  final bool hasBalcony;
  final bool hasParking;
  final bool hasFurnished;
  final String heating;
  final String orientation;
  final String deed;
  final bool hasCredit;
  final String deposit;
  final List<String> images;
  final String description;
  final String consultant;
  final String consultantPhone;
  final DateTime submittedDate;
  final int viewCount;
  final String status;

  ApprovalProperty({
    required this.id,
    required this.title,
    required this.location,
    required this.district,
    required this.neighborhood,
    required this.price,
    required this.priceStr,
    required this.type,
    required this.category,
    required this.propertyType,
    required this.rooms,
    required this.brutArea,
    required this.netArea,
    required this.floor,
    required this.totalFloors,
    required this.buildingAge,
    required this.bathrooms,
    required this.hasBalcony,
    required this.hasParking,
    required this.hasFurnished,
    required this.heating,
    required this.orientation,
    required this.deed,
    required this.hasCredit,
    required this.deposit,
    required this.images,
    required this.description,
    required this.consultant,
    required this.consultantPhone,
    required this.submittedDate,
    required this.viewCount,
    required this.status,
  });
}

class ApprovalEditScreen extends StatefulWidget {
  final String? listingId;
  
  const ApprovalEditScreen({
    super.key,
    this.listingId,
  });

  @override
  State<ApprovalEditScreen> createState() => _ApprovalEditScreenState();
}

class _ApprovalEditScreenState extends State<ApprovalEditScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _rejectionReasonController = TextEditingController();
  final TextEditingController _editRequestReasonController = TextEditingController();
  bool _showRejectionForm = false;
  bool _showEditRequestForm = false;
  late ApprovalProperty property;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Generate dynamic property data based on listingId
    property = _generatePropertyData(widget.listingId ?? '1');
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  // Generate dynamic property data based on listing ID
  ApprovalProperty _generatePropertyData(String listingId) {
    final propertyData = {
      'listing_0': {
        'title': '3+1 Satılık Daire',
        'location': 'İstanbul',
        'district': 'Ataşehir',
        'neighborhood': 'Barbaros Mah.',
        'price': '2.750.000',
        'priceStr': '2.750.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Daire',
        'rooms': '3+1',
        'brutArea': 150,
        'netArea': 130,
        'floor': 8,
        'totalFloors': 12,
        'buildingAge': 5,
        'bathrooms': 2,
        'hasBalcony': true,
        'hasParking': true,
        'heating': 'Kombi (Doğalgaz)',
        'orientation': 'Güney',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Mehmet Yılmaz',
        'consultantPhone': '+90 532 123 45 67',
        'viewCount': 124,
        'description': 'Şehrin merkezinde, ulaşıma yakın, modern yapı teknolojisi ile inşa edilmiş lüks daire. Geniş balkon, açık mutfak, lamel parke zemin.',
      },
      'listing_1': {
        'title': '2+1 Kiralık Daire',
        'location': 'İstanbul',
        'district': 'Kadıköy',
        'neighborhood': 'Fenerbahçe Mah.',
        'price': '8.500',
        'priceStr': '8.500 ₺',
        'type': 'Kiralık',
        'propertyType': 'Daire',
        'rooms': '2+1',
        'brutArea': 90,
        'netArea': 75,
        'floor': 4,
        'totalFloors': 8,
        'buildingAge': 8,
        'bathrooms': 1,
        'hasBalcony': true,
        'hasParking': false,
        'heating': 'Merkezi Sistem',
        'orientation': 'Kuzey',
        'deed': 'Kat İrtifaklı',
        'consultant': 'Ayşe Demir',
        'consultantPhone': '+90 535 987 65 43',
        'viewCount': 89,
        'description': 'Deniz manzaralı, metro durağına 5 dakika yürüme mesafesinde, güvenli bir semtte yer alan daire.',
      },
      'listing_2': {
        'title': '4+1 Satılık Villa',
        'location': 'Antalya',
        'district': 'Belek',
        'neighborhood': 'Acisu Mah.',
        'price': '4.250.000',
        'priceStr': '4.250.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Villa',
        'rooms': '4+1',
        'brutArea': 280,
        'netArea': 250,
        'floor': 2,
        'totalFloors': 2,
        'buildingAge': 2,
        'bathrooms': 3,
        'hasBalcony': true,
        'hasParking': true,
        'heating': 'Klima',
        'orientation': 'Güney-Batı',
        'deed': 'Arsa Tapulu',
        'consultant': 'Can Özkan',
        'consultantPhone': '+90 541 234 56 78',
        'viewCount': 203,
        'description': 'Özel havuzlu, bahçeli, denize 500m mesafede lüks villa. Tüm odalar deniz manzaralı.',
      },
      'listing_3': {
        'title': '1+1 Kiralık Stüdyo',
        'location': 'İstanbul',
        'district': 'Beşiktaş',
        'neighborhood': 'Etiler Mah.',
        'price': '12.000',
        'priceStr': '12.000 ₺',
        'type': 'Kiralık',
        'propertyType': 'Daire',
        'rooms': '1+1',
        'brutArea': 55,
        'netArea': 45,
        'floor': 15,
        'totalFloors': 20,
        'buildingAge': 1,
        'bathrooms': 1,
        'hasBalcony': false,
        'hasParking': true,
        'heating': 'VRV',
        'orientation': 'Doğu',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Elif Kaya',
        'consultantPhone': '+90 543 876 54 32',
        'viewCount': 67,
        'description': 'Modern rezidansta, şehir manzaralı, tam eşyalı lüks stüdyo daire.',
      },
      'listing_4': {
        'title': '3+1 Satılık Daire',
        'location': 'Ankara',
        'district': 'Çankaya',
        'neighborhood': 'Kızılay Mah.',
        'price': '1.850.000',
        'priceStr': '1.850.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Daire',
        'rooms': '3+1',
        'brutArea': 125,
        'netArea': 105,
        'floor': 6,
        'totalFloors': 10,
        'buildingAge': 12,
        'bathrooms': 2,
        'hasBalcony': true,
        'hasParking': true,
        'heating': 'Kalorifer (Doğalgaz)',
        'orientation': 'Güney-Doğu',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Murat Şen',
        'consultantPhone': '+90 532 456 78 90',
        'viewCount': 156,
        'description': 'Şehir merkezinde, metro ve otobüs duraklarına yakın, bakımlı bina.',
      },
      'listing_5': {
        'title': '2+1 Kiralık Daire',
        'location': 'İzmir',
        'district': 'Karşıyaka',
        'neighborhood': 'Bostanlı Mah.',
        'price': '6.200',
        'priceStr': '6.200 ₺',
        'type': 'Kiralık',
        'propertyType': 'Daire',
        'rooms': '2+1',
        'brutArea': 85,
        'netArea': 70,
        'floor': 3,
        'totalFloors': 5,
        'buildingAge': 15,
        'bathrooms': 1,
        'hasBalcony': true,
        'hasParking': false,
        'heating': 'Soba',
        'orientation': 'Batı',
        'deed': 'Kat İrtifaklı',
        'consultant': 'Zeynep Arslan',
        'consultantPhone': '+90 538 123 45 67',
        'viewCount': 92,
        'description': 'Sahile yakın, ferah ve aydınlık daire. Balkondan deniz manzarası.',
      },
      'listing_6': {
        'title': '5+2 Satılık Müstakil Ev',
        'location': 'Bursa',
        'district': 'Nilüfer',
        'neighborhood': 'Görükle Mah.',
        'price': '3.100.000',
        'priceStr': '3.100.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Müstakil Ev',
        'rooms': '5+2',
        'brutArea': 220,
        'netArea': 200,
        'floor': 2,
        'totalFloors': 2,
        'buildingAge': 7,
        'bathrooms': 3,
        'hasBalcony': false,
        'hasParking': true,
        'heating': 'Kombi (Doğalgaz)',
        'orientation': 'Güney',
        'deed': 'Arsa Tapulu',
        'consultant': 'Hasan Çelik',
        'consultantPhone': '+90 534 987 65 43',
        'viewCount': 178,
        'description': 'Bahçeli, müstakil ev. Sakin bir mahallede, ailelere uygun.',
      },
      'listing_7': {
        'title': '1+1 Satılık Daire',
        'location': 'İstanbul',
        'district': 'Şişli',
        'neighborhood': 'Mecidiyeköy Mah.',
        'price': '1.950.000',
        'priceStr': '1.950.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Daire',
        'rooms': '1+1',
        'brutArea': 65,
        'netArea': 55,
        'floor': 10,
        'totalFloors': 15,
        'buildingAge': 6,
        'bathrooms': 1,
        'hasBalcony': true,
        'hasParking': true,
        'heating': 'Kombi (Doğalgaz)',
        'orientation': 'Kuzey-Doğu',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Fatma Yıldız',
        'consultantPhone': '+90 542 345 67 89',
        'viewCount': 134,
        'description': 'İş merkezine yakın, yatırım için ideal lokasyon.',
      },
      'listing_8': {
        'title': '3+1 Kiralık Daire',
        'location': 'Adana',
        'district': 'Seyhan',
        'neighborhood': 'Reşatbey Mah.',
        'price': '4.800',
        'priceStr': '4.800 ₺',
        'type': 'Kiralık',
        'propertyType': 'Daire',
        'rooms': '3+1',
        'brutArea': 110,
        'netArea': 95,
        'floor': 2,
        'totalFloors': 4,
        'buildingAge': 20,
        'bathrooms': 2,
        'hasBalcony': true,
        'hasParking': false,
        'heating': 'Klima',
        'orientation': 'Güney',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Ali Koçak',
        'consultantPhone': '+90 537 789 12 34',
        'viewCount': 73,
        'description': 'Geniş ve ferah daire, aile için uygun, merkezi konumda.',
      },
      'listing_9': {
        'title': '2+1 Satılık Daire',
        'location': 'Trabzon',
        'district': 'Ortahisar',
        'neighborhood': 'Çarşı Mah.',
        'price': '1.450.000',
        'priceStr': '1.450.000 ₺',
        'type': 'Satılık',
        'propertyType': 'Daire',
        'rooms': '2+1',
        'brutArea': 95,
        'netArea': 80,
        'floor': 5,
        'totalFloors': 7,
        'buildingAge': 10,
        'bathrooms': 1,
        'hasBalcony': true,
        'hasParking': true,
        'heating': 'Kalorifer (Kömür)',
        'orientation': 'Doğu',
        'deed': 'Kat Mülkiyetli',
        'consultant': 'Ahmet Öz',
        'consultantPhone': '+90 539 654 32 10',
        'viewCount': 98,
        'description': 'Şehir merkezinde, deniz manzaralı, ulaşım imkanları mükemmel.',
      },
    };

    final data = propertyData[listingId] ?? propertyData['listing_0']!;
    
    return ApprovalProperty(
      id: listingId,
      title: data['title'] as String,
      location: data['location'] as String,
      district: data['district'] as String,
      neighborhood: data['neighborhood'] as String,
      price: data['price'] as String,
      priceStr: data['priceStr'] as String,
      type: data['type'] as String,
      category: 'Konut',
      propertyType: data['propertyType'] as String,
      rooms: data['rooms'] as String,
      brutArea: data['brutArea'] as int,
      netArea: data['netArea'] as int,
      floor: data['floor'] as int,
      totalFloors: data['totalFloors'] as int,
      buildingAge: data['buildingAge'] as int,
      bathrooms: data['bathrooms'] as int,
      hasBalcony: data['hasBalcony'] as bool,
      hasParking: data['hasParking'] as bool,
      hasFurnished: false,
      heating: data['heating'] as String,
      orientation: data['orientation'] as String,
      deed: data['deed'] as String,
      hasCredit: true,
      deposit: data['hasParking'] == true ? 'Kapalı Otopark' : 'Yok',
      images: [
        'https://picsum.photos/800/600?random=${listingId.hashCode % 100}',
        'https://picsum.photos/800/600?random=${(listingId.hashCode + 1) % 100}',
        'https://picsum.photos/800/600?random=${(listingId.hashCode + 2) % 100}',
        'https://picsum.photos/800/600?random=${(listingId.hashCode + 3) % 100}',
      ],
      description: data['description'] as String,
      consultant: data['consultant'] as String,
      consultantPhone: data['consultantPhone'] as String,
      submittedDate: DateTime.now().subtract(Duration(days: (listingId.hashCode % 5) + 1)),
      viewCount: data['viewCount'] as int,
      status: 'Onay Bekliyor',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rejectionReasonController.dispose();
    _editRequestReasonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text(
            'İlanı Onayla',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bu ilanı onaylamak istediğinizden emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.location} / ${property.district}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Onaylanan ilan yayına çıkacaktır.',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveProperty();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Onayla',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _approveProperty() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('İlan başarıyla onaylandı!'),
                  Text(
                    property.title,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop({'action': 'approved', 'property': property});
    });
  }

  void _rejectProperty() {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Lütfen reddetme sebebini belirtiniz.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('İlan reddedildi!'),
                  Text(
                    'Sebep: ${_rejectionReasonController.text}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop({
        'action': 'rejected', 
        'property': property,
        'reason': _rejectionReasonController.text
      });
    });
  }

  void _requestEdit() {
    if (_editRequestReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Lütfen düzenleme talebinizin sebebini belirtiniz.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.edit, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Düzenleme talebi gönderildi!'),
                  Text(
                    'Talep: ${_editRequestReasonController.text}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop({
        'action': 'edit_requested', 
        'property': property,
        'reason': _editRequestReasonController.text
      });
    });
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
            return RoleSidebar(currentPage: 'İlan Onay');
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
          title: "İlan Onaylama",
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Onay Bekliyor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${DateTime.now().difference(property.submittedDate).inDays} gün önce gönderildi',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Property Images Section - New Design
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Main large image
                            Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      property.images[_currentImageIndex],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    // Image counter overlay
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_currentImageIndex + 1}/${property.images.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Thumbnail row
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  for (int i = 0; i < property.images.length && i < 4; i++) ...[
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _currentImageIndex = i;
                                        });
                                      },
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        margin: EdgeInsets.only(
                                          right: i < 3 && i < property.images.length - 1 ? 12 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _currentImageIndex == i
                                                ? const Color(0xFFE53935)
                                                : Colors.grey[300]!,
                                            width: _currentImageIndex == i ? 2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(7),
                                          child: Image.network(
                                            property.images[i],
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (property.images.length > 4) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo_library,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+${property.images.length - 4}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Property Main Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    property.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: property.type == 'Kiralık' 
                                        ? Colors.blue 
                                        : const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    property.type,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${property.location} / ${property.district} / ${property.neighborhood}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Price Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Fiyat",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          property.priceStr,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE53935),
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
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // General Properties Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Genel Özellikler",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Property details grid
                            _buildPropertyDetailGrid(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Section
                      if (property.description.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Açıklama",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                property.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Consultant Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Danışman Bilgileri",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFFE53935),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.consultant,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Gayrimenkul Danışmanı",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            property.consultantPhone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
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
                      
                      const SizedBox(height: 24),
                      
                      // Edit Request Form (if shown)
                      if (_showEditRequestForm) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Düzenleme Talep Formu",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Lütfen hangi bilgilerin düzenlenmesi gerektiğini detaylı bir şekilde açıklayın. Bu talep danışmana iletilecektir.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _editRequestReasonController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: "Düzenleme talebinizi detaylı olarak yazın...\n\nÖrnek:\n• Fiyat bilgisi güncellensin\n• Yeni fotoğraflar eklensin\n• Özellik bilgileri düzeltilsin",
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _showEditRequestForm = false;
                                          _editRequestReasonController.clear();
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        side: BorderSide(color: Colors.grey[300]!),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "İptal",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _requestEdit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Talep Gönder",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Rejection Form (if shown)
                      if (_showRejectionForm) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "İlan Reddetme Formu",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Lütfen ilanı neden reddettiğinizi detaylı bir şekilde açıklayın. Bu bilgi danışmana iletilecektir.',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _rejectionReasonController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: "Reddetme sebebini detaylı olarak yazın...\n\nÖrnek:\n• Fotoğraflar yetersiz\n• Eksik bilgi var\n• Fiyat bilgisi hatalı",
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _showRejectionForm = false;
                                          _rejectionReasonController.clear();
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        side: BorderSide(color: Colors.grey[300]!),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "İptal",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _rejectProperty,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Reddet",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showRejectionForm = true;
                                  _showEditRequestForm = false;
                                });
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text("Reddet"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showApprovalDialog,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Onayla"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showEditRequestForm = true;
                              _showRejectionForm = false;
                            });
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text("Düzenleme Talep Et"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: AdminNavbar(
          currentIndex: 0,
          onTap: (index) {},
        ),
      ),
    );
  }

  Widget _buildPropertyDetailGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDetailItem("m² (Brüt)", "${property.brutArea}")),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("m² (Net)", "${property.netArea}")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Oda Sayısı", property.rooms)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Bina Yaşı", "${property.buildingAge}")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Bulunduğu Kat", "${property.floor}")),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Kat Sayısı", "${property.totalFloors}")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Isıtma", property.heating)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Banyo Sayısı", "${property.bathrooms}")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Balkon", property.hasBalcony ? "Var" : "Yok")),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Otopark", property.deposit)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Eşyalı", property.hasFurnished ? "Hayır" : "Hayır")),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Aidat (TL)", "Yok")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDetailItem("Cephe", property.orientation)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailItem("Krediye Uygun", property.hasCredit ? "Evet" : "Hayır")),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailItem("Tapu Durumu", property.deed),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
