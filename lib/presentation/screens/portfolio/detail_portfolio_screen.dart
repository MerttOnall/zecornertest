import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/models/realestate/myrealestate_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'dart:math';
import 'package:zecorner/presentation/screens/portfolio/portfolio_stepper_ui.dart';

// Portfolio helper extension for RealEstateModel
extension PortfolioHelper on RealEstateModel {
  String get fullLocation {
    if (address.uavtAddress != null) {
      return '${address.uavtAddress!.provinceName} / ${address.uavtAddress!.districtName} / ${address.uavtAddress!.quarterName}';
    }
    return address.address.isNotEmpty ? address.address : 'Adres bilgisi yok';
  }

  String get displayType {
    switch (type) {
      case 'konut-daire':
        return 'Daire';
      case 'konut-mustakil-ev':
        return 'Müstakil Ev';
      case 'konut-yali-dairesi':
        return 'Yalı Dairesi';
      case 'is-yeri-apartman-dairesi':
        return 'İş Yeri';
      case 'is-yeri-plaza-kati-ofisi':
        return 'Ofis';
      case 'is-yeri-fabrika':
          return 'Fabrika';
        default:
          return type.replaceAll('-', ' ').toUpperCase();
      }
    }

    String get portfolioStatusDisplayName {
      switch (status) {
      case 0:
        return 'Pasif';
      case 1:
        return 'Aktif';
      case 2:
        return 'Beklemede';
      case 3:
        return 'Satıldı/Kiralandı';
      default:
        return 'Bilinmiyor';
    }
  }

  String get roomCountDisplay {
    final roomProperty = properties['oda-sayisi'];
    if (roomProperty?.value != null) {
      return roomProperty!.value.replaceAll('oda-sayisi-', '');
    }
    return 'Bilinmiyor';
  }

  double? get areaDisplay {
    final netProperty = properties['m2-net'];
    return netProperty?.numberValue?.toDouble();
  }

  String get thumbnailUrl {
    if (thumbnail.isNotEmpty) {
      return ImageUtils.getCoverImageUrl(thumbnail);
    }
    return 'https://picsum.photos/800/400?random=${id.hashCode}';
  }

  // Additional getters for compatibility
  String get propertyType => displayType;
  String get location => address.uavtAddress?.provinceName ?? 'Bilinmiyor';
  String get district => address.uavtAddress?.districtName ?? 'Bilinmiyor';
  String get neighborhood => address.uavtAddress?.quarterName ?? 'Bilinmiyor';
  double get area => areaDisplay ?? 0.0;
  String get rooms => roomCountDisplay;
  double get priceValue => (price ?? 0).toDouble();
  bool get isActive => status == 1;

  String get formattedPrice {
    // Önce direkt 'price' alanını kontrol et
    if (price != null && price! > 0) {
      final priceVal = price!;
      if (priceVal >= 1000000) {
        return '₺${(priceVal / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
      } else if (priceVal >= 1000) {
        return '₺${(priceVal / 1000).toStringAsFixed(0)}K';
      } else {
        return '₺$priceVal';
      }
    }
    // Eğer direkt price yoksa, properties içinde kontrol et
    final priceProperty = properties['price'];
    if (priceProperty?.numberValue != null && priceProperty!.numberValue! > 0) {
      final priceVal = priceProperty.numberValue!.toInt();
      if (priceVal >= 1000000) {
        return '₺${(priceVal / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
      } else if (priceVal >= 1000) {
        return '₺${(priceVal / 1000).toStringAsFixed(0)}K';
      } else {
        return '₺$priceVal';
      }
    }
    // Fiyat bilgisi yoksa
    return 'Fiyat Görüşülür';
  }
}

class DetailPortfolioScreen extends StatefulWidget {
  /// Görüntülenecek portföy. Verilirse doğrudan detay modunda açılır.
  /// Verilmezse [ModalRoute.settings.arguments] içinden okunur.
  final RealEstateModel? portfolio;
  final int? listingPrice;

  const DetailPortfolioScreen({
    super.key,
    this.portfolio,
    this.listingPrice,
  });

  @override
  State<DetailPortfolioScreen> createState() => _DetailPortfolioScreenState();
}

class _DetailPortfolioScreenState extends State<DetailPortfolioScreen> {
  RealEstateModel? currentPortfolio;
  bool _dataLoaded = false;
  int? _listingPriceOverride;
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _netAreaController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _aidatController = TextEditingController();
  final TextEditingController _propertyNumberController = TextEditingController();

  // Dropdown values
  String selectedType = 'Konut';
  String selectedPortfolioType = 'Daire';
  String selectedStatus = 'Satılık';
  String selectedCity = 'İstanbul';
  String selectedDistrict = 'Ataşehir';
  String selectedNeighborhood = 'Barbaros Mah.';
  String selectedBuildingAge = '1-5';
  String selectedFloor = '3';
  String selectedTotalFloors = '5';
  String selectedHeating = 'Doğalgaz';
  String selectedBathrooms = '2';
  String selectedBalcony = 'Var';
  String selectedFurnished = 'Hayır';
  bool showDaireFeatures = true;

  int _currentStep = 0;
  int _maxReachedStep = 0;

  // Sample image URL for portfolio
  String portfolioImageUrl = '';

  // State for featured properties display (removed unused variables)

  // Dynamic dropdown data
  final List<String> allCities = [
    'İstanbul', 'Ankara', 'İzmir', 'Antalya', 'Bursa', 
    'Adana', 'Trabzon', 'Bodrum', 'Muğla', 'Mersin'
  ];

  final Map<String, List<String>> cityToDistricts = {
    'İstanbul': ['Ataşehir', 'Kadıköy', 'Beşiktaş', 'Şişli', 'Beykoz', 'Üsküdar'],
    'Ankara': ['Çankaya', 'Altındağ', 'Keçiören', 'Mamak'],
    'İzmir': ['Bornova', 'Konak', 'Karşıyaka', 'Alsancak'],
    'Antalya': ['Muratpaşa', 'Konyaaltı', 'Kepez'],
    'Bursa': ['Mudanya', 'Osmangazi', 'Nilüfer'],
    'Adana': ['Seyhan', 'Yüreğir', 'Çukurova'],
    'Trabzon': ['Ortahisar', 'Akçaabat', 'Yomra'],
    'Bodrum': ['Gündoğan', 'Yalıkavak', 'Türkbükü'],
    'Muğla': ['Merkez', 'Marmaris', 'Fethiye'],
    'Mersin': ['Merkez', 'Tarsus', 'Anamur'],
  };

  final Map<String, List<String>> districtToNeighborhoods = {
    'Ataşehir': ['Barbaros Mah.', 'Küçükbakkalköy Mah.', 'Ferhatpaşa Mah.'],
    'Kadıköy': ['Fenerbahçe Mah.', 'Moda Mah.', 'Caferağa Mah.'],
    'Beşiktaş': ['Levent Mah.', 'Etiler Mah.', 'Ortaköy Mah.'],
    'Şişli': ['Nişantaşı Mah.', 'Mecidiyeköy Mah.', 'Fulya Mah.'],
    'Çankaya': ['Kızılay Mah.', 'Bahçelievler Mah.', 'Çankaya Mah.'],
    'Altındağ': ['Üniversite Mah.', 'Hacettepe Mah.', 'Merkez Mah.'],
    'Bornova': ['Erzene Mah.', 'Çamdibi Mah.', 'Merkez Mah.'],
    'Konak': ['Alsancak Mah.', 'Göztepe Mah.', 'Güzelyalı Mah.'],
    'Muratpaşa': ['Liman Mah.', 'Meltem Mah.', 'Kültür Mah.'],
    'Konyaaltı': ['Hurma Mah.', 'Arapsuyu Mah.', 'Uncalı Mah.'],
    'Mudanya': ['Zeytinbağı Mah.', 'Güzelyalı Mah.', 'Merkez Mah.'],
    'Seyhan': ['Reşatbey Mah.', 'Ziyapaşa Mah.', 'Çınarlı Mah.'],
    'Ortahisar': ['Sanayi Mah.', 'Merkez Mah.', 'Çarşı Mah.'],
    'Gündoğan': ['Sahil Mah.', 'Merkez Mah.', 'Yamaç Mah.'],
    'Beykoz': ['Çubuklu Mah.', 'Anadoluhisarı Mah.', 'Merkez Mah.'],
    'Üsküdar': ['Merkez Mah.', 'Bulgurlu Mah.', 'Çengelköy Mah.'],
    'Keçiören': ['Merkez Mah.', 'Ovacık Mah.', 'Kalaba Mah.'],
    'Mamak': ['Merkez Mah.', 'Durukan Mah.', 'Akdere Mah.'],
    'Karşıyaka': ['Merkez Mah.', 'Bostanlı Mah.', 'Mavişehir Mah.'],
    'Alsancak': ['Merkez Mah.', 'Kültür Mah.', 'Cumhuriyet Mah.'],
    'Kepez': ['Merkez Mah.', 'Santral Mah.', 'Çankaya Mah.'],
    'Osmangazi': ['Merkez Mah.', 'Çekirge Mah.', 'Dobruca Mah.'],
    'Nilüfer': ['Merkez Mah.', 'Özlüce Mah.', 'Beşevler Mah.'],
    'Yüreğir': ['Merkez Mah.', 'Köprülü Mah.', 'Yakapınar Mah.'],
    'Çukurova': ['Merkez Mah.', 'Cumhuriyet Mah.', 'Güzelyalı Mah.'],
    'Akçaabat': ['Merkez Mah.', 'Dürbinar Mah.', 'Söğütlü Mah.'],
    'Yomra': ['Merkez Mah.', 'Kalecik Mah.', 'Liman Mah.'],
    'Yalıkavak': ['Merkez Mah.', 'Tilkicik Mah.', 'Gökçebel Mah.'],
    'Türkbükü': ['Merkez Mah.', 'Gölköy Mah.', 'Dirmil Mah.'],
    'Merkez': ['Merkez Mah.', 'Cumhuriyet Mah.', 'Yeni Mah.'],
    'Marmaris': ['Merkez Mah.', 'Beldibi Mah.', 'Siteler Mah.'],
    'Fethiye': ['Merkez Mah.', 'Çalış Mah.', 'Ölüdeniz Mah.'],
    'Tarsus': ['Merkez Mah.', 'Gülek Mah.', 'Yenice Mah.'],
    'Anamur': ['Merkez Mah.', 'Ören Mah.', 'Bozyazı Mah.'],
  };

  // Get available districts for selected city
  List<String> getAvailableDistricts() {
    return cityToDistricts[selectedCity] ?? ['Merkez'];
  }

  // Get available neighborhoods for selected district
  List<String> getAvailableNeighborhoods() {
    return districtToNeighborhoods[selectedDistrict] ?? ['Merkez Mah.'];
  }

  void _ensureLocationOptionsFromPortfolio() {
    if (currentPortfolio?.address.uavtAddress == null) return;

    final uavt = currentPortfolio!.address.uavtAddress!;
    final city = uavt.provinceName.trim();
    final district = uavt.districtName.trim();
    final neighborhood = uavt.quarterName.trim();

    if (city.isNotEmpty && !allCities.contains(city)) {
      allCities.add(city);
    }

    if (city.isNotEmpty) {
      cityToDistricts.putIfAbsent(city, () => <String>[]);
      if (district.isNotEmpty && !cityToDistricts[city]!.contains(district)) {
        cityToDistricts[city]!.add(district);
      }
    }

    if (district.isNotEmpty) {
      districtToNeighborhoods.putIfAbsent(district, () => <String>[]);
      if (neighborhood.isNotEmpty &&
          !districtToNeighborhoods[district]!.contains(neighborhood)) {
        districtToNeighborhoods[district]!.add(neighborhood);
      }
    }
  }

  // Validate and fix dropdown selections
  void _validateAndFixSelections() {
    _ensureLocationOptionsFromPortfolio();

    // Validate city
    if (!allCities.contains(selectedCity)) {
      selectedCity = allCities.first;
    }

    // Validate district
    List<String> availableDistricts = getAvailableDistricts();
    if (!availableDistricts.contains(selectedDistrict)) {
      selectedDistrict = availableDistricts.first;
    }

    // Validate neighborhood
    List<String> availableNeighborhoods = getAvailableNeighborhoods();
    if (!availableNeighborhoods.contains(selectedNeighborhood)) {
      selectedNeighborhood = availableNeighborhoods.first;
    }

    // Validate portfolio type - map data values to dropdown options
    List<String> portfolioTypeOptions = [
      "Daire",
      "Rezidans", 
      "Dubleks",
      "Müstakil Ev",
      "Villa",
      "Çiftlik Evi",
      "Köşk & Konak",
      "Yalı",
      "Yalı Dairesi",
      "Yazlık"
    ];
    
    // Map common mismatches
    if (selectedPortfolioType == "Residence") {
      selectedPortfolioType = "Rezidans";
    }
    
    // If still not valid, use fallback
    if (!portfolioTypeOptions.contains(selectedPortfolioType)) {
      selectedPortfolioType = "Daire"; // Default fallback
    }

    // Validate other dropdowns
    List<String> roomOptions = ["1+0", "1+1", "2+1", "3+1", "4+1", "5+1", "6+1", "7+"];
    if (!roomOptions.contains(_roomsController.text)) {
      _roomsController.text = "3+1";
    }

    List<String> buildingAgeOptions = ["0", "1-5", "5-10", "10-15", "15-20", "20+"];
    if (!buildingAgeOptions.contains(selectedBuildingAge)) {
      selectedBuildingAge = "1-5";
    }

    List<String> floorOptions = ["Bodrum", "Zemin", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10+"];
    if (!floorOptions.contains(selectedFloor)) {
      selectedFloor = "3";
    }

    List<String> totalFloorOptions = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10+"];
    if (!totalFloorOptions.contains(selectedTotalFloors)) {
      selectedTotalFloors = "5";
    }

    List<String> heatingOptions = ["Doğalgaz", "Merkezi", "Klima", "Soba", "Yok"];
    if (!heatingOptions.contains(selectedHeating)) {
      selectedHeating = "Doğalgaz";
    }

    List<String> bathroomOptions = ["1", "2", "3", "4+"];
    if (!bathroomOptions.contains(selectedBathrooms)) {
      selectedBathrooms = "2";
    }

    List<String> balconyOptions = ["Var", "Yok"];
    if (!balconyOptions.contains(selectedBalcony)) {
      selectedBalcony = "Var";
    }

    List<String> furnishedOptions = ["Evet", "Hayır"];
    if (!furnishedOptions.contains(selectedFurnished)) {
      selectedFurnished = "Hayır";
    }
  }

  // Checkbox values for features
  Map<String, bool> directionFeatures = {
    'Batı': false,
    'Doğu': false,
    'Güney': false,
    'Kuzey': false,
  };
  
  Map<String, bool> interiorFeatures = {};
  Map<String, bool> exteriorFeatures = {};
  Map<String, bool> muhitFeatures = {};
  Map<String, bool> transportFeatures = {};
  Map<String, bool> viewFeatures = {};
  Map<String, bool> housingTypeFeatures = {};
  Map<String, bool> accessibilityFeatures = {};

  // Feature lists
  final List<String> interiorFeaturesList = [
    "ADSL", "Alarm (Yangın)", "Amerikan Mutfak", "Boyalı", "Çamaşır Makinesi", "Duvar Kağıdı",
    "Giyinme Odası", "Intercom Sistemi", "Kiler", "Marley", "Mutfak Doğalgazı", "Seramik Zemin",
    "Şömine", "Wi-Fi", "Ahşap Doğrama", "Alaturka Tuvalet", "Ankastre Fırın", "Bulaşık Makinesi",
    "Çamaşır Odası", "Ebeveyn Banyosu", "Gömme Dolap", "Isıcam", "Klima", "Mobilya",
    "Panjur/Jaluzi", "Set Üstü Ocak", "Teras", "Akıllı Ev", "Alüminyum Doğrama", "Barbekü",
    "Buzdolabı", "Çelik Kapı", "Fiber İnternet", "Görüntülü Diafon", "Jakuzi", "Küvet",
    "Mutfak (Ankastre)", "Parke Zemin", "Spot Aydınlatma", "Termosifon", "Yüz Tanıma & Parmak İzi",
    "Alarm (Hırsız)", "Amerikan Kapı", "Beyaz Eşya", "Çamaşır Kurutma Makinesi", "Duşakabin",
    "Fırın", "Hilton Banyo", "Kartonpiyer", "Laminat Zemin", "Mutfak (Laminat)", "PVC Doğrama",
    "Şofben", "Vestiyer"
  ];

  final List<String> exteriorFeaturesList = [
    "Araç Şarj İstasyonu", "Çocuk Oyun Parkı", "Jeneratör", "Müstakil Havuzlu", "Spor Alanı",
    "Yangın Merdiveni", "Apartman Görevlisi", "Kamera Sistemi", "Tenis Kortu", "Güvenlik",
    "Hamam", "Kablo TV", "Sauna", "Su Deposu", "Yüzme Havuzu (Açık)", "Hidrofor",
    "Ses Yalıtımı", "Yüzme Havuzu (Kapalı)"
  ];

  final List<String> muhitFeaturesList = [
    "Alışveriş Merkezi", "Belediye", "Cami", "Cemevi", "Denize Sıfır", "Eczane",
    "Eğlence Merkezi", "Fuar", "Göle Sıfır", "Hastane", "Havra", "İlkokul-Ortaokul",
    "İtfaiye", "Kilise", "Lise", "Market", "Park", "Plaj", "Polis Merkezi",
    "Sağlık Ocağı", "Semt Pazarı", "Spor Salonu", "Şehir Merkezi", "Üniversite"
  ];

  final List<String> transportFeaturesList = [
    "Anayol", "Deniz Otobüsü", "İskele", "Minibüs", "TEM", "Avrasya Tüneli",
    "Dolmuş", "Marmaray", "Otobüs Durağı", "Tramvay", "Boğaz Köprüleri",
    "E-5", "Metro", "Sahil", "Tren İstasyonu", "Havaalanı", "Metrobüs",
    "Teleferik", "Troleybüs"
  ];

  final List<String> viewFeaturesList = [
    "Boğaz", "Havuz", "Deniz", "Park & Yeşil Alan", "Doğa", "Göl", "Şehir"
  ];

  final List<String> housingTypeFeaturesList = [
    "Ara Kat", "Bahçeli", "Garaj / Dükkan Üstü", "Müstakil Girişli", "Ara Kat Dubleks",
    "Çatı Dubleksi", "Giriş Katı", "Ters Dubleks", "Bahçe Dubleksi", "En Üst Kat",
    "Kat Dubleksi", "Tripleks", "Bahçe Katı", "Forleks", "Loft", "Zemin Kat"
  ];

  final List<String> accessibilityFeaturesList = [
    "Araç Park Yeri", "Giriş / Rampa", "Park", "Yüzme Havuzu", "Asansör", "Merdiven",
    "Priz / Elektrik Anahtarı", "Banyo", "Mutfak", "Tutamak / Korkuluk",
    "Geniş Koridor", "Oda Kapısı", "Tuvalet"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers but don't populate data yet
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only populate once
    if (!_dataLoaded) {
      _dataLoaded = true;

      if (widget.portfolio != null) {
        currentPortfolio = widget.portfolio;
        _listingPriceOverride = widget.listingPrice;
      } else {
        // Check for portfolio data from route arguments
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args != null && args is Map) {
          final portfolioArg = args['portfolio'];
          final listingPriceArg = args['listingPrice'];
          if (portfolioArg is RealEstateModel) {
            currentPortfolio = portfolioArg;
            _listingPriceOverride = (listingPriceArg is int)
                ? listingPriceArg
                : (listingPriceArg as num?)?.toInt();
          }
        } else if (args is RealEstateModel) {
          currentPortfolio = args;
        }
      }

      if (currentPortfolio != null) {
        print('VIEWING PORTFOLIO DETAILS: ${currentPortfolio!.id}');
        _populateFormWithPortfolioData();
      } else {
        print('NO PORTFOLIO DATA - USING DEFAULT VALUES');
        _generateSampleData();
      }
    }
  }

  String _formatFullPrice(int price) {
    if (price <= 0) return 'Fiyat Görüşülür';
    return '₺${price.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]}.')}';
  }

  String _stripHtml(String? html) {
    if (html == null || html.trim().isEmpty) return '';
    return html_parser.parse(html).body?.text.trim() ?? '';
  }

  void _populateFormWithPortfolioData() {
    if (currentPortfolio == null) return;
    
    print('POPULATING DETAIL VIEW WITH PORTFOLIO DATA: ${currentPortfolio!.title}');
    
    // Set form fields with actual portfolio data
    _titleController.text = _stripHtml(currentPortfolio!.title);
    _areaController.text = currentPortfolio!.areaDisplay?.toString() ?? '0';
    _netAreaController.text = currentPortfolio!.areaDisplay?.toString() ?? '0'; // Net area from API
    _roomsController.text = currentPortfolio!.roomCountDisplay;
    final effectivePrice = _listingPriceOverride ?? currentPortfolio!.price ?? 0;
    _priceController.text = effectivePrice.toString();
    
    // Set portfolio image URL
    portfolioImageUrl = currentPortfolio!.thumbnailUrl;
    
    // Map portfolio type to main type
    if (['konut-daire', 'konut-mustakil-ev', 'konut-yali-dairesi'].contains(currentPortfolio!.type)) {
      selectedType = 'Konut';
      showDaireFeatures = true;
    } else if (currentPortfolio!.type.contains('is-yeri')) {
      selectedType = 'İş Yeri';
      showDaireFeatures = false;
    } else {
      selectedType = 'Arsa';
      showDaireFeatures = false;
    }
    
    // Map portfolio type with proper conversion
    selectedPortfolioType = currentPortfolio!.displayType;
    
    selectedStatus = currentPortfolio!.portfolioStatusDisplayName;
    
    // Address bilgilerini al
    if (currentPortfolio!.address.uavtAddress != null) {
      selectedCity = currentPortfolio!.address.uavtAddress!.provinceName;
      selectedDistrict = currentPortfolio!.address.uavtAddress!.districtName;
      selectedNeighborhood = currentPortfolio!.address.uavtAddress!.quarterName;
    } else if (currentPortfolio!.address.city != null &&
        currentPortfolio!.address.city!.isNotEmpty) {
      selectedCity = currentPortfolio!.address.city!;
      if (currentPortfolio!.address.district != null &&
          currentPortfolio!.address.district!.isNotEmpty) {
        selectedDistrict = currentPortfolio!.address.district!;
      }
    }

    _ensureLocationOptionsFromPortfolio();
    
    // Set realistic defaults for detail fields
    _setRealisticDefaults();
    
    // Validate and fix all dropdown selections to prevent errors
    _validateAndFixSelections();

    // Portföy açıklamasını API'den gelen veriyle doldur
    final plainDescription = _stripHtml(currentPortfolio!.description);
    if (plainDescription.isNotEmpty) {
      _descriptionController.text = plainDescription;
    } else {
      _descriptionController.text = '''${_stripHtml(currentPortfolio!.title)}

📍 ${currentPortfolio!.fullLocation}
📐 ${currentPortfolio!.areaDisplay?.toInt() ?? 0} m² (Net)
🚪 ${currentPortfolio!.roomCountDisplay} oda
💰 ${_formatFullPrice(effectivePrice)}

🏠 Emlak Detayları:
Bu ${currentPortfolio!.propertyType.toLowerCase()} ${currentPortfolio!.location} ${currentPortfolio!.district} bölgesinde yer almaktadır. 

• Emlak Türü: ${currentPortfolio!.propertyType}
• Durum: ${currentPortfolio!.status}
• Konum: ${currentPortfolio!.fullLocation}
• Alan: ${currentPortfolio!.area.toInt()} m² (Brüt)
• Oda: ${currentPortfolio!.rooms} oda
• Fiyat: ${_formatFullPrice(effectivePrice)}
• Portföy Durumu: ${currentPortfolio!.isActive ? 'Aktif' : 'Pasif'}

Bu ${currentPortfolio!.propertyType.toLowerCase()} modern yaşamın konforunu ${currentPortfolio!.location} ${currentPortfolio!.district} lokasyonunda sunmaktadır.''';
    }

    // Generate aidat and property number
    _aidatController.text = _generateRealisticAidat().toString();
    _propertyNumberController.text = 'P${currentPortfolio!.id.padLeft(6, '0')}';

    // Generate comprehensive feature selections based on portfolio type and characteristics
    _generateFeatureSelectionsBasedOnPortfolio();

    print('PORTFOLIO DETAIL DATA POPULATED:');
    print('ID: ${currentPortfolio!.id}');
    print('Title: ${_titleController.text}');
    print('Area: ${_areaController.text} m² (Brüt) / ${_netAreaController.text} m² (Net)');
    print('Rooms: ${_roomsController.text}');
    print('Property Type: $selectedPortfolioType');
    print('Status: $selectedStatus');
    print('Location: $selectedCity / $selectedDistrict / $selectedNeighborhood');
    print('Image URL: $portfolioImageUrl');
    
    // Force UI update
    if (mounted) {
      setState(() {
        _unlockAllSteps();
      });
    }
  }

  void _setRealisticDefaults() {
    final random = Random();
    
    // Building age based on price and property type
    final portfolioPrice = _listingPriceOverride ?? currentPortfolio!.price ?? 0;
    if (currentPortfolio!.propertyType == 'Villa' || portfolioPrice > 3000000) {
      selectedBuildingAge = ['0', '1-5'][random.nextInt(2)];
    } else {
      selectedBuildingAge = ['1-5', '5-10', '10-15'][random.nextInt(3)];
    }
    
    // Floor selection
    selectedFloor = ['1', '2', '3', '4', '5'][random.nextInt(5)];
    selectedTotalFloors = ['5', '6', '7', '8', '9', '10'][random.nextInt(6)];
    
    // Heating based on location and property type
    if (currentPortfolio!.location == 'İstanbul' || currentPortfolio!.location == 'Ankara') {
      selectedHeating = 'Doğalgaz';
    } else {
      selectedHeating = ['Doğalgaz', 'Merkezi', 'Klima'][random.nextInt(3)];
    }
    
    // Bathrooms based on rooms (parse room count from string)
    final roomCount = int.tryParse(currentPortfolio!.rooms.replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;
    selectedBathrooms = roomCount >= 4 ? '2' : '1';
    
    // Balcony and furnished status
    selectedBalcony = random.nextBool() ? 'Var' : 'Yok';
    selectedFurnished = currentPortfolio!.status == 'Kiralık' ? 
        (random.nextBool() ? 'Evet' : 'Hayır') : 'Hayır';
  }

  int _generateRealisticAidat() {
    final random = Random();
    
    if (currentPortfolio!.propertyType == 'Villa') {
      return 0; // Villas usually don't have aidat
    } else if (currentPortfolio!.propertyType == 'Penthouse' || currentPortfolio!.propertyType == 'Residence') {
      return 500 + random.nextInt(1500); // 500-2000 TL
    } else {
      return 200 + random.nextInt(800); // 200-1000 TL
    }
  }

  void _generateSampleData() {
    final random = Random();
    
    print('GENERATING SAMPLE DATA FOR DETAIL VIEW...');
    
    // Generate random values for display
    _titleController.text = '3+1 Satılık Modern Daire';
    _areaController.text = '150';
    _netAreaController.text = '128';
    _roomsController.text = '3+1';
    _priceController.text = '2500000';
    _aidatController.text = '750';
    _propertyNumberController.text = 'P000001';
    
    portfolioImageUrl = 'https://picsum.photos/800/400?random=${random.nextInt(1000)}';
    
    _descriptionController.text = '''Modern Daire - Test Data

📍 İstanbul / Ataşehir / Barbaros Mah.
📐 150 m² (Brüt) / 128 m² (Net)
🚪 3+1 oda
💰 2.5M ₺

Bu test verisi ile doldurulmuş örnek bir emlak detay sayfasıdır.''';

    _generateRandomFeatureSelections();
    
    if (mounted) {
      setState(() {
        _unlockAllSteps();
      });
    }
  }

  void _generateFeatureSelectionsBasedOnPortfolio() {
    final random = Random();
    
    // Clear all feature selections first
    interiorFeatures.clear();
    exteriorFeatures.clear();
    muhitFeatures.clear();
    transportFeatures.clear();
    viewFeatures.clear();
    housingTypeFeatures.clear();
    accessibilityFeatures.clear();

    // Generate features based on portfolio characteristics
    double featureRate = 0.3; // base rate
    
    final portfolioPrice = _listingPriceOverride ?? currentPortfolio!.price ?? 0;
    if (currentPortfolio!.propertyType == 'Villa' || currentPortfolio!.propertyType == 'Penthouse') {
      featureRate = 0.7; // Premium properties get more features
    } else if (currentPortfolio!.propertyType == 'Residence') {
      featureRate = 0.5; // Mid-range
    } else if (portfolioPrice > 2000000 && currentPortfolio!.status == 'Satılık') {
      featureRate = 0.6; // Expensive properties
    } else if (portfolioPrice > 20000 && currentPortfolio!.status == 'Kiralık') {
      featureRate = 0.5; // High rent properties
    }

    // Direction features - realistic selection
    directionFeatures['Güney'] = random.nextDouble() < 0.7; // South is preferred
    directionFeatures['Doğu'] = random.nextDouble() < 0.5;
    directionFeatures['Batı'] = random.nextDouble() < 0.4;
    directionFeatures['Kuzey'] = random.nextDouble() < 0.3;

    // Initialize interior features with smart selection
    for (String feature in interiorFeaturesList) {
      bool shouldSelect = random.nextDouble() < featureRate;
      
      // Smart feature selection based on property type
      if (currentPortfolio!.propertyType == 'Villa' && 
          ['Jakuzi', 'Şömine', 'Barbekü', 'Teras'].contains(feature)) {
        shouldSelect = random.nextDouble() < 0.8; // Higher chance for villas
      }
      
      if (currentPortfolio!.propertyType == 'Penthouse' && 
          ['Jakuzi', 'Teras', 'Görüntülü Diafon', 'Spot Aydınlatma'].contains(feature)) {
        shouldSelect = random.nextDouble() < 0.7; // Higher chance for penthouses
      }
      
      if (currentPortfolio!.propertyType == 'Residence' && 
          ['Güvenlik', 'Kamera Sistemi', 'Görüntülü Diafon'].contains(feature)) {
        shouldSelect = random.nextDouble() < 0.8; // Security features for residence
      }
      
      interiorFeatures[feature] = shouldSelect;
    }

    // Initialize other feature categories
    for (String feature in exteriorFeaturesList) {
      bool shouldSelect = random.nextDouble() < (featureRate * 0.7);
      
      // Villa specific features
      if (currentPortfolio!.propertyType == 'Villa' && 
          ['Müstakil Havuzlu', 'Spor Alanı', 'Çocuk Oyun Parkı'].contains(feature)) {
        shouldSelect = random.nextDouble() < 0.8;
      }
      
      exteriorFeatures[feature] = shouldSelect;
    }

    // Location-based features
    for (String feature in muhitFeaturesList) {
      bool shouldSelect = random.nextDouble() < (featureRate * 0.6);
      
      if (['Antalya', 'Bodrum'].contains(currentPortfolio!.location) && feature == 'Denize Sıfır') {
        shouldSelect = random.nextDouble() < 0.9; // Very high chance for coastal cities
      }
      
      muhitFeatures[feature] = shouldSelect;
    }

    // Transportation features
    for (String feature in transportFeaturesList) {
      bool shouldSelect = random.nextDouble() < (featureRate * 0.5);
      
      if (currentPortfolio!.location == 'İstanbul' && ['Metro', 'Metrobüs'].contains(feature)) {
        shouldSelect = random.nextDouble() < 0.8; // High chance for Istanbul
      }
      
      transportFeatures[feature] = shouldSelect;
    }

    // View features based on location
    for (String feature in viewFeaturesList) {
      bool shouldSelect = random.nextDouble() < (featureRate * 0.4);
      
      if (['Antalya', 'Bodrum'].contains(currentPortfolio!.location) && feature == 'Deniz') {
        shouldSelect = random.nextDouble() < 0.8; // Sea view for coastal cities
      }
      
      viewFeatures[feature] = shouldSelect;
    }

    // Housing type features
    for (String feature in housingTypeFeaturesList) {
      housingTypeFeatures[feature] = random.nextDouble() < 0.2;
    }

    // Accessibility features
    for (String feature in accessibilityFeaturesList) {
      accessibilityFeatures[feature] = random.nextDouble() < 0.15;
    }

    print('FEATURES GENERATED FOR DETAIL VIEW - PORTFOLIO TYPE: ${currentPortfolio!.propertyType}');
    print('Interior Features Selected: ${interiorFeatures.entries.where((e) => e.value).length}/${interiorFeatures.length}');
  }

  // Helper method to get all selected features (removed unused method)

  // Helper method to build the featured properties section
  // Widget _buildFeaturedPropertiesSection() {
  //   final allFeatures = _getAllSelectedFeatures();
  //   if (allFeatures.isEmpty) return const SizedBox.shrink();
    
  //   final displayFeatures = _showAllFeatures 
  //       ? allFeatures 
  //       : allFeatures.take(_maxInitialFeatures).toList();
    
  //   return ExpansionTile(
  //     title: const Text(
  //       "Öne Çıkan Özellikler",
  //       style: TextStyle(
  //         fontSize: 16,
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //     collapsedBackgroundColor: Colors.white,
  //     backgroundColor: Colors.white,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(8),
  //       side: BorderSide(color: Colors.grey[300]!),
  //     ),
  //     collapsedShape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(8),
  //       side: BorderSide(color: Colors.grey[300]!),
  //     ),
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Wrap(
  //               spacing: 8,
  //               runSpacing: 8,
  //               children: displayFeatures.map((feature) {
  //                 return Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                   decoration: BoxDecoration(
  //                     color: const Color.fromRGBO(238, 46, 36, 1).withOpacity(0.1),
  //                     borderRadius: BorderRadius.circular(20),
  //                     border: Border.all(
  //                       color: const Color.fromRGBO(238, 46, 36, 1).withOpacity(0.3),
  //                     ),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Icon(
  //                         Icons.check_circle,
  //                         size: 14,
  //                         color: const Color.fromRGBO(238, 46, 36, 1),
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Text(
  //                         feature,
  //                         style: const TextStyle(
  //                           fontSize: 12,
  //                           color: Color.fromRGBO(238, 46, 36, 1),
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             ),
  //             if (allFeatures.length > _maxInitialFeatures) ...[
  //               const SizedBox(height: 12),
  //               Center(
  //                 child: GestureDetector(
  //                   onTap: () {
  //                     setState(() {
  //                       _showAllFeatures = !_showAllFeatures;
  //                     });
  //                   },
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(20),
  //                       border: Border.all(color: const Color.fromRGBO(238, 46, 36, 1)),
  //                     ),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Text(
  //                           _showAllFeatures ? "Daha Az" : "Daha Fazla",
  //                           style: const TextStyle(
  //                             fontSize: 14,
  //                             color: Color.fromRGBO(238, 46, 36, 1),
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 4),
  //                         Icon(
  //                           _showAllFeatures ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
  //                           size: 16,
  //                           color: const Color.fromRGBO(238, 46, 36, 1),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _generateRandomFeatureSelections() {
    final random = Random();
    
    // Generate random selections for all feature categories
    directionFeatures.forEach((key, value) {
      directionFeatures[key] = random.nextDouble() < 0.4;
    });

    for (String feature in interiorFeaturesList) {
      interiorFeatures[feature] = random.nextDouble() < 0.3;
    }

    for (String feature in exteriorFeaturesList) {
      exteriorFeatures[feature] = random.nextDouble() < 0.3;
    }

    for (String feature in muhitFeaturesList) {
      muhitFeatures[feature] = random.nextDouble() < 0.3;
    }

    for (String feature in transportFeaturesList) {
      transportFeatures[feature] = random.nextDouble() < 0.3;
    }

    for (String feature in viewFeaturesList) {
      viewFeatures[feature] = random.nextDouble() < 0.3;
    }

    for (String feature in housingTypeFeaturesList) {
      housingTypeFeatures[feature] = random.nextDouble() < 0.2;
    }

    for (String feature in accessibilityFeaturesList) {
      accessibilityFeatures[feature] = random.nextDouble() < 0.2;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _netAreaController.dispose();
    _roomsController.dispose();
    _aidatController.dispose();
    _propertyNumberController.dispose();
    super.dispose();
  }

  static const _portfolioTypeOptions = [
    "Daire", "Rezidans", "Dubleks", "Müstakil Ev", "Villa",
    "Çiftlik Evi", "Köşk & Konak", "Yalı", "Yalı Dairesi", "Yazlık",
  ];

  List<String> _getStepTitles() {
    final titles = <String>[
      'Portföy Tipi',
      'Portföy Görselleri',
      'Başlık ve Açıklama',
      'Adres',
    ];
    if (showDaireFeatures) {
      titles.addAll([
        'Özellikler',
        'Cephe',
        'İç Özellikler',
        'Dış Özellikler',
        'Muhit',
        'Ulaşım',
        'Manzara',
        'Konut Tipi',
        'Engelliye ve Yaşlıya Uygun',
      ]);
    }
    return titles;
  }

  void _unlockAllSteps() {
    final last = _getStepTitles().length - 1;
    if (_maxReachedStep < last) {
      _maxReachedStep = last;
    }
  }

  void _goToStep(int step) {
    final titles = _getStepTitles();
    if (step < 0 || step >= titles.length) return;
    setState(() => _currentStep = step);
  }

  void _goToNextStep() {
    final titles = _getStepTitles();
    if (_currentStep < titles.length - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep > _maxReachedStep) {
          _maxReachedStep = _currentStep;
        }
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildCurrentStepContent(List<String> titles) {
    if (_currentStep >= titles.length) return const SizedBox.shrink();
    final title = titles[_currentStep];
    switch (title) {
      case 'Portföy Tipi':
        return _buildPortfoyTipiStepContent();
      case 'Portföy Görselleri':
        return _buildGorsellerStepContent();
      case 'Başlık ve Açıklama':
        return _buildBaslikStepContent();
      case 'Adres':
        return _buildAdresStepContent();
      case 'Özellikler':
        return _buildOzelliklerStepContent();
      case 'Cephe':
        return _buildCepheStepContent();
      case 'İç Özellikler':
        return _buildIcOzelliklerStepContent();
      case 'Dış Özellikler':
        return _buildDisOzelliklerStepContent();
      case 'Muhit':
        return _buildMuhitStepContent();
      case 'Ulaşım':
        return _buildUlasimStepContent();
      case 'Manzara':
        return _buildManzaraStepContent();
      case 'Konut Tipi':
        return _buildKonutTipiStepContent();
      case 'Engelliye ve Yaşlıya Uygun':
        return _buildEngelliStepContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.fieldLabel(label, hint: hint),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: readOnly ? const Color(0xFF64748B) : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PortfolioStepperUi.brandColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxStepContent(String title, String? subtitle, Widget rowContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle(title, subtitle: subtitle),
        const SizedBox(height: 20),
        rowContent,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = _getStepTitles();
    final safeStep = _currentStep.clamp(0, stepTitles.length - 1);
    if (safeStep != _currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentStep = safeStep);
        }
      });
    }
    _unlockAllSteps();

    return Scaffold(
      backgroundColor: PortfolioStepperUi.surfaceColor,
      appBar: AdminPanelInAppBar(
        title: "Portföy Detayı",
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            PortfolioStepperUi.stepProgressBar(
              currentStep: _currentStep,
              maxReachedStep: _maxReachedStep,
              titles: stepTitles,
              onStepTap: _goToStep,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: PortfolioStepperUi.stepCard(
                      child: _buildCurrentStepContent(stepTitles),
                    ),
                  ),
                ),
              ),
            ),
            PortfolioStepperUi.stepNavigation(
              currentStep: _currentStep,
              totalSteps: stepTitles.length,
              onPrevious: _goToPreviousStep,
              onNext: _goToNextStep,
              lastLabel: 'Sadece Görüntüleme',
              isLastStepGreen: false,
            ),
          ],
        ),
      ),
    );
  }

  // --- Step content builders ---

  Widget _buildPortfoyTipiStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle(
          'Portföy Tipi',
          subtitle: 'Portföy kategorisi ve alt tipi',
        ),
        const SizedBox(height: 20),
        PortfolioStepperUi.fieldLabel('Kategori'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildTypeOption("Konut"),
              _buildTypeOption("İş Yeri"),
              _buildTypeOption("Arsa"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PortfolioStepperUi.displayPickerTile(
          label: 'Konut Tipi',
          value: selectedPortfolioType,
          hint: 'Konut tipi seçiniz',
          icon: Icons.home_work_outlined,
        ),
      ],
    );
  }

  Widget _buildGorsellerStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle(
          'Portföy Görselleri',
          subtitle: 'Portföye ait görseller',
        ),
        const SizedBox(height: 20),
        // Portfolio image display

          if (portfolioImageUrl.isNotEmpty) ...[

            Container(

              width: double.infinity,

              height: 200,

              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: Colors.grey[300]!),

              ),

              child: ClipRRect(

                borderRadius: BorderRadius.circular(8),

                child: Image.network(

                  portfolioImageUrl,

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {

                    return Container(

                      color: Colors.grey[200],

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Icon(

                            Icons.image_not_supported,

                            size: 40,

                            color: Colors.grey[400],

                          ),

                          const SizedBox(height: 8),

                          Text(

                            "Görsel yüklenemedi",

                            style: TextStyle(

                              color: Colors.grey[400],

                              fontSize: 14,

                            ),

                          ),

                        ],

                      ),

                    );

                  },

                ),

              ),

            ),

            const SizedBox(height: 16),

          ],

          // Görsel yükleme alanı

          Container(

            width: 150,

            height: 150,

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(8),

              border: Border.all(color: Colors.grey[300]!),

            ),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Icon(

                  Icons.camera_alt_outlined,

                  size: 40,

                  color: Colors.grey[400],

                ),

                const SizedBox(height: 8),

                Text(

                  "Medya Yükleyin",

                  style: TextStyle(

                    color: Colors.grey[400],

                    fontSize: 14,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(height: 8),

          // Dosya formatı ve bilgiler

          RichText(

            text: const TextSpan(

              style: TextStyle(fontSize: 14),

              children: [

                TextSpan(

                  text:

                      "• JPEG veya PNG formatında en fazla ",

                  style: TextStyle(color: Colors.black87),

                ),

                TextSpan(

                  text: "50mb",

                  style:

                      TextStyle(color: Color(0xFFE53935)),

                ),

                TextSpan(

                  text:

                      " büyüklüğünde görsel dosyalarınızı yükleyiniz.",

                  style: TextStyle(color: Colors.black87),

                ),

              ],

            ),

          ),

          RichText(

            text: const TextSpan(

              style: TextStyle(fontSize: 14),

              children: [

                TextSpan(

                  text: "• Resimleri ",

                  style: TextStyle(color: Colors.black87),

                ),

                TextSpan(

                  text: "sürükle bırak",

                  style:

                      TextStyle(color: Color(0xFFE53935)),

                ),

                TextSpan(

                  text:

                      " yaparak sıralamasını değiştirebilirsiniz.",

                  style: TextStyle(color: Colors.black87),

                ),

              ],

            ),

          ),

          RichText(

            text: const TextSpan(

              style: TextStyle(fontSize: 14),

              children: [

                TextSpan(

                  text: "• En fazla ",

                  style: TextStyle(color: Colors.black87),

                ),

                TextSpan(

                  text: "35",

                  style:

                      TextStyle(color: Color(0xFFE53935)),

                ),

                TextSpan(

                  text: " fotoğraf yükleyebilirsiniz",

                  style: TextStyle(color: Colors.black87),

                ),

              ],

            ),

          ),

      ],
    );
  }

  Widget _buildBaslikStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle(
          'Başlık ve Açıklama',
          subtitle: 'Portföy başlığı ve açıklama metni',
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _titleController,
          label: 'Portföy Başlığı',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _descriptionController,
          label: 'Portföy Açıklaması',
          hint: 'Portföy ile alakalı açıklamalar',
          maxLines: 8,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildAdresStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle('Adres', subtitle: 'Konum bilgileri'),
        const SizedBox(height: 20),
        PortfolioStepperUi.displayPickerTile(
          label: 'İl',
          value: selectedCity,
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 16),
        PortfolioStepperUi.displayPickerTile(
          label: 'İlçe',
          value: selectedDistrict,
          icon: Icons.map_outlined,
        ),
        const SizedBox(height: 16),
        PortfolioStepperUi.displayPickerTile(
          label: 'Mahalle',
          value: selectedNeighborhood,
          icon: Icons.place_outlined,
        ),
        const SizedBox(height: 16),
        // Harita

        Container(

          height: 400,

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(8),

            border: Border.all(color: Colors.grey[300]!),

          ),

          child: Column(

            children: [

              // Harita/Uydu seçimi

              Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  border: Border(

                    bottom: BorderSide(

                        color: Colors.grey[300]!),

                  ),

                ),

                child: Row(

                  children: [

                    Container(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 12, vertical: 6),

                      decoration: BoxDecoration(

                        color: const Color(0xFFE53935),

                        borderRadius:

                            BorderRadius.circular(4),

                      ),

                      child: const Text(

                        "Harita",

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 14,

                        ),

                      ),

                    ),

                    const SizedBox(width: 8),

                    Container(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 12, vertical: 6),

                      child: Text(

                        "Uydu",

                        style: TextStyle(

                          color: Colors.grey[600],

                          fontSize: 14,

                        ),

                      ),

                    ),

                    const Spacer(),

                    // Tam ekran butonu

                    Container(

                      padding: const EdgeInsets.all(4),

                      decoration: BoxDecoration(

                        border: Border.all(

                            color: Colors.grey[300]!),

                        borderRadius:

                            BorderRadius.circular(4),

                      ),

                      child: Icon(

                        Icons.fullscreen,

                        size: 20,

                        color: Colors.grey[600],

                      ),

                    ),

                  ],

                ),

              ),

              // Harita alanı

              Expanded(

                child: Container(

                  color: Colors.grey[200],

                  child: Stack(

                    children: [

                      // Harita görüntüsü burada olacak

                      Center(

                        child: Icon(

                          Icons.map,

                          size: 100,

                          color: Colors.grey[400],

                        ),

                      ),

                      // Zoom butonları

                      Positioned(

                        right: 16,

                        bottom: 16,

                        child: Column(

                          children: [

                            Container(

                              padding:

                                  const EdgeInsets.all(8),

                              decoration: BoxDecoration(

                                color: Colors.white,

                                borderRadius:

                                    BorderRadius.circular(

                                        4),

                                boxShadow: [

                                  BoxShadow(

                                    color: Colors.black

                                        .withOpacity(0.1),

                                    blurRadius: 4,

                                  ),

                                ],

                              ),

                              child: const Icon(Icons.add,

                                  size: 20),

                            ),

                            const SizedBox(height: 4),

                            Container(

                              padding:

                                  const EdgeInsets.all(8),

                              decoration: BoxDecoration(

                                color: Colors.white,

                                borderRadius:

                                    BorderRadius.circular(

                                        4),

                                boxShadow: [

                                  BoxShadow(

                                    color: Colors.black

                                        .withOpacity(0.1),

                                    blurRadius: 4,

                                  ),

                                ],

                              ),

                              child: const Icon(

                                  Icons.remove,

                                  size: 20),

                            ),

                          ],

                        ),

                      ),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),
      ],
    );
  }

  Widget _buildOzelliklerStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortfolioStepperUi.stepTitle('Özellikler', subtitle: 'Teknik ve fiziksel özellikler'),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _areaController,
          label: 'm² (Brüt)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _netAreaController,
          label: 'm² (Net)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Oda Sayısı',
                value: _roomsController.text.isNotEmpty ? _roomsController.text : null,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Oda Sayısı',
                  options: const ["1+0", "1+1", "2+1", "3+1", "4+1", "5+1", "6+1", "7+"],
                  selected: _roomsController.text.isNotEmpty ? _roomsController.text : null,
                  onSelected: (v) => setState(() => _roomsController.text = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Bina Yaşı',
                value: selectedBuildingAge,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Bina Yaşı',
                  options: const ["0", "1-5", "5-10", "10-15", "15-20", "20+"],
                  selected: selectedBuildingAge,
                  onSelected: (v) => setState(() => selectedBuildingAge = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Bulunduğu Kat',
                value: selectedFloor,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Bulunduğu Kat',
                  options: const ["Bodrum", "Zemin", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10+"],
                  selected: selectedFloor,
                  onSelected: (v) => setState(() => selectedFloor = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Kat Sayısı',
                value: selectedTotalFloors,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Kat Sayısı',
                  options: const ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10+"],
                  selected: selectedTotalFloors,
                  onSelected: (v) => setState(() => selectedTotalFloors = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Isıtma',
                value: selectedHeating,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Isıtma',
                  options: const ["Doğalgaz", "Merkezi", "Klima", "Soba", "Yok"],
                  selected: selectedHeating,
                  onSelected: (v) => setState(() => selectedHeating = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Banyo Sayısı',
                value: selectedBathrooms,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Banyo Sayısı',
                  options: const ["1", "2", "3", "4+"],
                  selected: selectedBathrooms,
                  onSelected: (v) => setState(() => selectedBathrooms = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Balkon',
                value: selectedBalcony,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Balkon',
                  options: const ["Var", "Yok"],
                  selected: selectedBalcony,
                  onSelected: (v) => setState(() => selectedBalcony = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PortfolioStepperUi.mobilePickerTile(
                label: 'Eşyalı',
                value: selectedFurnished,
                hint: 'Seçiniz',
                onTap: () => PortfolioStepperUi.showOptionPicker(
                  context,
                  title: 'Eşyalı',
                  options: const ["Evet", "Hayır"],
                  selected: selectedFurnished,
                  onSelected: (v) => setState(() => selectedFurnished = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _aidatController,
          label: 'Aidat (TL)',
          hint: 'Aidat bilinmiyor ise 0 giriniz',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _propertyNumberController,
          label: 'Taşınmaz Numarası',
          hint: 'Maksimum 10 karakter',
          maxLength: 10,
        ),
      ],
    );
  }

  Widget _buildCepheStepContent() {
    return _buildCheckboxStepContent(
      'Cephe',
      'Portföyün cephe yönleri',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Batı"),

                _buildCheckboxItem("Doğu"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Güney"),

                _buildCheckboxItem("Kuzey"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildIcOzelliklerStepContent() {
    return _buildCheckboxStepContent(
      'İç Özellikler',
      'Portföye ait iç özellikler',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("ADSL"),

                _buildCheckboxItem("Alarm (Yangın)"),

                _buildCheckboxItem("Amerikan Mutfak"),

                _buildCheckboxItem("Boyalı"),

                _buildCheckboxItem("Çamaşır Makinesi"),

                _buildCheckboxItem("Duvar Kağıdı"),

                _buildCheckboxItem("Giyinme Odası"),

                _buildCheckboxItem("Intercom Sistemi"),

                _buildCheckboxItem("Kiler"),

                _buildCheckboxItem("Marley"),

                _buildCheckboxItem("Mutfak Doğalgazı"),

                _buildCheckboxItem("Seramik Zemin"),

                _buildCheckboxItem("Şömine"),

                _buildCheckboxItem("Wi-Fi"),

                _buildCheckboxItem("Ahşap Doğrama"),

                _buildCheckboxItem("Alaturka Tuvalet"),

                _buildCheckboxItem("Ankastre Fırın"),

                _buildCheckboxItem("Bulaşık Makinesi"),

                _buildCheckboxItem("Çamaşır Odası"),

                _buildCheckboxItem("Ebeveyn Banyosu"),

                _buildCheckboxItem("Gömme Dolap"),

                _buildCheckboxItem("Isıcam"),

                _buildCheckboxItem("Klima"),

                _buildCheckboxItem("Mobilya"),

                _buildCheckboxItem("Panjur/Jaluzi"),

                _buildCheckboxItem("Set Üstü Ocak"),

                _buildCheckboxItem("Teras"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Akıllı Ev"),

                _buildCheckboxItem("Alüminyum Doğrama"),

                _buildCheckboxItem("Barbekü"),

                _buildCheckboxItem("Buzdolabı"),

                _buildCheckboxItem("Çelik Kapı"),

                _buildCheckboxItem("Fiber İnternet"),

                _buildCheckboxItem("Görüntülü Diafon"),

                _buildCheckboxItem("Jakuzi"),

                _buildCheckboxItem("Küvet"),

                _buildCheckboxItem("Mutfak (Ankastre)"),

                _buildCheckboxItem("Parke Zemin"),

                _buildCheckboxItem("Spot Aydınlatma"),

                _buildCheckboxItem("Termosifon"),

                _buildCheckboxItem(

                    "Yüz Tanıma & Parmak İzi"),

                _buildCheckboxItem("Alarm (Hırsız)"),

                _buildCheckboxItem("Amerikan Kapı"),

                _buildCheckboxItem("Beyaz Eşya"),

                _buildCheckboxItem(

                    "Çamaşır Kurutma Makinesi"),

                _buildCheckboxItem("Duşakabin"),

                _buildCheckboxItem("Fırın"),

                _buildCheckboxItem("Hilton Banyo"),

                _buildCheckboxItem("Kartonpiyer"),

                _buildCheckboxItem("Laminat Zemin"),

                _buildCheckboxItem("Mutfak (Laminat)"),

                _buildCheckboxItem("PVC Doğrama"),

                _buildCheckboxItem("Şofben"),

                _buildCheckboxItem("Vestiyer"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildDisOzelliklerStepContent() {
    return _buildCheckboxStepContent(
      'Dış Özellikler',
      'Portföye ait dış özellikler',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Araç Şarj İstasyonu"),

                _buildCheckboxItem("Çocuk Oyun Parkı"),

                _buildCheckboxItem("Jeneratör"),

                _buildCheckboxItem("Müstakil Havuzlu"),

                _buildCheckboxItem("Spor Alanı"),

                _buildCheckboxItem("Yangın Merdiveni"),

                _buildCheckboxItem("Apartman Görevlisi"),

                _buildCheckboxItem("Kamera Sistemi"),

                _buildCheckboxItem("Tenis Kortu"),

              ],

            ),

          ),

          const SizedBox(

              width: 30), // Sütunlar arası boşluk

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Güvenlik"),

                _buildCheckboxItem("Hamam"),

                _buildCheckboxItem("Kablo TV"),

                _buildCheckboxItem("Sauna"),

                _buildCheckboxItem("Su Deposu"),

                _buildCheckboxItem("Yüzme Havuzu (Açık)"),

                _buildCheckboxItem("Hidrofor"),

                _buildCheckboxItem("Ses Yalıtımı"),

                _buildCheckboxItem(

                    "Yüzme Havuzu (Kapalı)"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildMuhitStepContent() {
    return _buildCheckboxStepContent(
      'Muhit',
      'Çevredeki olanaklar',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Alışveriş Merkezi"),

                _buildCheckboxItem("Belediye"),

                _buildCheckboxItem("Cami"),

                _buildCheckboxItem("Cemevi"),

                _buildCheckboxItem("Denize Sıfır"),

                _buildCheckboxItem("Eczane"),

                _buildCheckboxItem("Eğlence Merkezi"),

                _buildCheckboxItem("Fuar"),

                _buildCheckboxItem("Göle Sıfır"),

                _buildCheckboxItem("Hastane"),

                _buildCheckboxItem("Havra"),

                _buildCheckboxItem("İlkokul-Ortaokul"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("İtfaiye"),

                _buildCheckboxItem("Kilise"),

                _buildCheckboxItem("Lise"),

                _buildCheckboxItem("Market"),

                _buildCheckboxItem("Park"),

                _buildCheckboxItem("Plaj"),

                _buildCheckboxItem("Polis Merkezi"),

                _buildCheckboxItem("Sağlık Ocağı"),

                _buildCheckboxItem("Semt Pazarı"),

                _buildCheckboxItem("Spor Salonu"),

                _buildCheckboxItem("Şehir Merkezi"),

                _buildCheckboxItem("Üniversite"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildUlasimStepContent() {
    return _buildCheckboxStepContent(
      'Ulaşım',
      'Ulaşım imkanları',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Anayol"),

                _buildCheckboxItem("Deniz Otobüsü"),

                _buildCheckboxItem("İskele"),

                _buildCheckboxItem("Minibüs"),

                _buildCheckboxItem("TEM"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Avrasya Tüneli"),

                _buildCheckboxItem("Dolmuş"),

                _buildCheckboxItem("Marmaray"),

                _buildCheckboxItem("Otobüs Durağı"),

                _buildCheckboxItem("Tramvay"),

                _buildCheckboxItem("Boğaz Köprüleri"),

                _buildCheckboxItem("E-5"),

                _buildCheckboxItem("Metro"),

                _buildCheckboxItem("Sahil"),

                _buildCheckboxItem("Tren İstasyonu"),

                _buildCheckboxItem("Havaalanı"),

                _buildCheckboxItem("Metrobüs"),

                _buildCheckboxItem("Teleferik"),

                _buildCheckboxItem("Troleybüs"),

              ],

            ),

          ),

        ],

      ),

    );

  }

  Widget _buildManzaraStepContent() {
    return _buildCheckboxStepContent(
      'Manzara',
      'Manzara özellikleri',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Boğaz"),

                _buildCheckboxItem("Havuz"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Deniz"),

                _buildCheckboxItem("Park & Yeşil Alan"),

                _buildCheckboxItem("Doğa"),

                _buildCheckboxItem("Göl"),

                _buildCheckboxItem("Şehir"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildKonutTipiStepContent() {
    return _buildCheckboxStepContent(
      'Konut Tipi',
      'Konut tipi özellikleri',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Ara Kat"),

                _buildCheckboxItem("Bahçeli"),

                _buildCheckboxItem("Garaj / Dükkan Üstü"),

                _buildCheckboxItem("Müstakil Girişli"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Ara Kat Dubleks"),

                _buildCheckboxItem("Çatı Dubleksi"),

                _buildCheckboxItem("Giriş Katı"),

                _buildCheckboxItem("Ters Dubleks"),

                _buildCheckboxItem("Bahçe Dubleksi"),

                _buildCheckboxItem("En Üst Kat"),

                _buildCheckboxItem("Kat Dubleksi"),

                _buildCheckboxItem("Tripleks"),

                _buildCheckboxItem("Bahçe Katı"),

                _buildCheckboxItem("Forleks"),

                _buildCheckboxItem("Loft"),

                _buildCheckboxItem("Zemin Kat"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildEngelliStepContent() {
    return _buildCheckboxStepContent(
      'Engelliye ve Yaşlıya Uygun',
      'Erişilebilirlik özellikleri',
      Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Sol sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Araç Park Yeri"),

                _buildCheckboxItem("Giriş / Rampa"),

                _buildCheckboxItem("Park"),

                _buildCheckboxItem("Yüzme Havuzu"),

              ],

            ),

          ),

          const SizedBox(width: 30),

          // Sağ sütun

          Expanded(

            child: Column(

              children: [

                _buildCheckboxItem("Asansör"),

                _buildCheckboxItem("Merdiven"),

                _buildCheckboxItem(

                    "Priz / Elektrik Anahtarı"),

                _buildCheckboxItem("Banyo"),

                _buildCheckboxItem("Mutfak"),

                _buildCheckboxItem("Tutamak / Korkuluk"),

                _buildCheckboxItem("Geniş Koridor"),

                _buildCheckboxItem("Oda Kapısı"),

                _buildCheckboxItem("Tuvalet"),

              ],

            ),

          ),

        ],
      ),
    );
  }

  Widget _buildTypeOption(String type) {
    final isSelected = selectedType == type;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    PortfolioStepperUi.brandColor,
                    PortfolioStepperUi.brandColor.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: PortfolioStepperUi.brandColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildFormatButton(String text) - removed unused method

  Widget _buildCheckboxItem(String label) {
    // Get the appropriate feature map based on label
    Map<String, bool> featureMap = {};
    if (directionFeatures.containsKey(label)) {
      featureMap = directionFeatures;
    } else if (interiorFeatures.containsKey(label)) {
      featureMap = interiorFeatures;
    } else if (exteriorFeatures.containsKey(label)) {
      featureMap = exteriorFeatures;
    } else if (muhitFeatures.containsKey(label)) {
      featureMap = muhitFeatures;
    } else if (transportFeatures.containsKey(label)) {
      featureMap = transportFeatures;
    } else if (viewFeatures.containsKey(label)) {
      featureMap = viewFeatures;
    } else if (housingTypeFeatures.containsKey(label)) {
      featureMap = housingTypeFeatures;
    } else if (accessibilityFeatures.containsKey(label)) {
      featureMap = accessibilityFeatures;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: featureMap[label] ?? false,
              onChanged: (value) {
                setState(() {
                  featureMap[label] = value ?? false;
                });
              },
              activeColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
