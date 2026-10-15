class OfficeResponseModel {
  final List<OfficeModel> offices;
  final int totalCount;
  final int totalPages;
  final int page;

  OfficeResponseModel({
    required this.offices,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory OfficeResponseModel.fromJson(Map<String, dynamic> json) {
    return OfficeResponseModel(
      offices: json['offices'] != null
          ? (json['offices'] as List).map((e) => OfficeModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offices': offices.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

class OfficeModel {
  final int officeId;
  final String officeTitle;
  final String officeEmail;
  final String officePhone;
  final String? officeLogo;
  final String officeAddress;
  final int districtCode;
  final String officeSlug;
  final List<OfficeMemberModel> officeMembers;
  final String city;

  OfficeModel({
    required this.officeId,
    required this.officeTitle,
    required this.officeEmail,
    required this.officePhone,
    this.officeLogo,
    required this.officeAddress,
    required this.districtCode,
    required this.officeSlug,
    required this.officeMembers,
    required this.city,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    String officeAddress = json['office_address'] ?? '';
    
    // Web'deki adres formatı "İzmir, Urla, Yen..." şeklinde virgülle ayrılmış
    // Bunu "İzmir / Urla / Yen..." formatına çeviriyoruz
    if (officeAddress.contains(',')) {
      officeAddress = officeAddress.split(',').map((e) => e.trim()).join(' / ');
    }
    
    // city field'ı yoksa office_address'ten parse et
    String city = json['city'] ?? '';
    if (city.isEmpty && officeAddress.isNotEmpty) {
      // "İzmir / Urla / Yen..." formatından ilk kısmı al
      final addressParts = officeAddress.split(' / ');
      if (addressParts.isNotEmpty) {
        city = addressParts[0].trim();
      }
    }
    
    return OfficeModel(
      officeId: json['office_id'] ?? 0,
      officeTitle: json['office_title'] ?? '',
      officeEmail: json['office_e_mail'] ?? '',
      officePhone: json['office_phone'] ?? '',
      officeLogo: json['office_logo'],
      officeAddress: officeAddress,
      districtCode: json['district_code'] ?? 0,
      officeSlug: json['office_slug'] ?? '',
      officeMembers: json['office_members'] != null
          ? (json['office_members'] as List).map((e) => OfficeMemberModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      city: city,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office_id': officeId,
      'office_title': officeTitle,
      'office_e_mail': officeEmail,
      'office_phone': officePhone,
      'office_logo': officeLogo,
      'office_address': officeAddress,
      'district_code': districtCode,
      'office_slug': officeSlug,
      'office_members': officeMembers.map((e) => e.toJson()).toList(),
      'city': city,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeModel && other.officeId == officeId;
  }

  @override
  int get hashCode => officeId.hashCode;

  @override
  String toString() => 'OfficeModel(id: $officeId, title: $officeTitle)';
}

class OfficeMemberModel {
  final int memberId;
  final String memberSlug;
  final String memberTitle;
  final String? memberPicture;
  final String memberTypeDescription;

  OfficeMemberModel({
    required this.memberId,
    required this.memberSlug,
    required this.memberTitle,
    this.memberPicture,
    required this.memberTypeDescription,
  });

  factory OfficeMemberModel.fromJson(Map<String, dynamic> json) {
    return OfficeMemberModel(
      memberId: json['member_id'] ?? 0,
      memberSlug: json['member_slug'] ?? '',
      memberTitle: json['member_title'] ?? '',
      memberPicture: json['member_picture'],
      memberTypeDescription: json['member_type_description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'member_slug': memberSlug,
      'member_title': memberTitle,
      'member_picture': memberPicture,
      'member_type_description': memberTypeDescription,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeMemberModel && other.memberId == memberId;
  }

  @override
  int get hashCode => memberId.hashCode;

  @override
  String toString() => 'OfficeMemberModel(id: $memberId, title: $memberTitle)';
}

// Helper Extension for OfficeModel
extension OfficeModelHelpers on OfficeModel {
  /// Ofis türü (ZeCorner mı özel mi?)
  String get officeType {
    if (officeTitle.toLowerCase().contains('zecorner')) return 'ZeCorner Ofis';
    if (officeTitle.toLowerCase().contains('prestige')) return 'Prestige Ofis';
    return 'Partner Ofis';
  }

  /// Ofis kategorisi
  String get officeCategory {
    if (officeTitle.contains('Merkez')) return 'Merkez Ofis';
    if (officeTitle.contains('Prestige')) return 'Prestige';
    if (officeTitle.contains('Cadde')) return 'Cadde Ofis';
    if (officeTitle.contains('Deneme')) return 'Test Ofis';
    if (officeType == 'ZeCorner Ofis') return 'ZeCorner Şube';
    return 'Partner Şube';
  }

  /// Şehir adı (il plaka kodundan)
  String get cityName {
    switch (city) {
      case '1': return 'Adana';
      case '6': return 'Ankara';
      case '7': return 'Antalya';
      case '16': return 'Bursa';
      case '34': return 'İstanbul';
      case '35': return 'İzmir';
      case '42': return 'Konya';
      case '48': return 'Muğla';
      case '61': return 'Trabzon';
      default: return 'Bilinmiyor';
    }
  }

  /// Adres parçaları
  List<String> get addressParts {
    return officeAddress.split(', ').where((part) => part.isNotEmpty).toList();
  }

  /// İlçe adı (adres'ten)
  String get district {
    final parts = addressParts;
    return parts.length >= 2 ? parts[1] : '';
  }

  /// Mahalle adı (adres'ten)
  String get neighborhood {
    final parts = addressParts;
    return parts.length >= 3 ? parts[2] : '';
  }

  /// Kısa adres
  String get shortAddress {
    final parts = addressParts;
    if (parts.length >= 2) {
      return '${parts[1]}, $cityName';
    }
    return cityName;
  }

  /// Tam adres formatı
  String get fullAddress {
    return '$officeAddress, $cityName';
  }

  /// Toplam üye sayısı
  int get totalMembers => officeMembers.length;

  /// Broker sayısı
  int get brokerCount {
    return officeMembers.where((member) => member.isBroker).length;
  }

  /// Danışman sayısı
  int get advisorCount {
    return officeMembers.where((member) => member.isAdvisor).length;
  }

  /// Takım lideri sayısı
  int get teamLeaderCount {
    return officeMembers.where((member) => member.isTeamLeader).length;
  }

  /// Asistan sayısı
  int get assistantCount {
    return officeMembers.where((member) => member.isAssistant).length;
  }

  /// Admin sayısı
  int get adminCount {
    return officeMembers.where((member) => member.isAdmin).length;
  }

  /// Diğer üye sayısı
  int get otherMemberCount {
    return officeMembers.where((member) => member.isOtherType).length;
  }

  /// Üye tip dağılımı
  Map<String, int> get memberTypeDistribution {
    return {
      'Broker': brokerCount,
      'Danışman': advisorCount,
      'Takım Lideri': teamLeaderCount,
      'Asistan': assistantCount,
      'Admin': adminCount,
      'Diğer': otherMemberCount,
    };
  }

  /// Fotoğrafı olan üye sayısı
  int get membersWithPhotoCount {
    return officeMembers.where((member) => member.hasPicture).length;
  }

  /// Fotoğrafı olmayan üye sayısı
  int get membersWithoutPhotoCount {
    return officeMembers.where((member) => !member.hasPicture).length;
  }

  /// Logo'su var mı?
  bool get hasLogo => officeLogo != null && officeLogo!.isNotEmpty;

  /// Telefon numarası var mı?
  bool get hasPhone => officePhone != '0' && officePhone.isNotEmpty;

  /// Geçerli email var mı?
  bool get hasValidEmail {
    return officeEmail.isNotEmpty && 
           officeEmail.contains('@') && 
           officeEmail.contains('.');
  }

  /// Ofis büyüklük kategorisi
  String get sizeCategory {
    if (totalMembers >= 20) return 'Çok Büyük';
    if (totalMembers >= 10) return 'Büyük';
    if (totalMembers >= 5) return 'Orta';
    if (totalMembers >= 2) return 'Küçük';
    return 'Bireysel';
  }

  /// Ofis emoji'si
  String get officeEmoji {
    if (officeCategory == 'Merkez Ofis') return '🏛️';
    if (officeCategory == 'Prestige') return '💎';
    if (officeCategory == 'Cadde Ofis') return '🏢';
    if (officeCategory == 'Test Ofis') return '🧪';
    if (officeType == 'ZeCorner Ofis') return '🏬';
    return '🏪';
  }

  /// Ofis renk kodu
  String get officeColor {
    switch (officeCategory) {
      case 'Merkez Ofis':
        return '#e74c3c'; // Kırmızı
      case 'Prestige':
        return '#9b59b6'; // Mor
      case 'Cadde Ofis':
        return '#3498db'; // Mavi
      case 'ZeCorner Şube':
        return '#f39c12'; // Turuncu
      case 'Test Ofis':
        return '#95a5a6'; // Gri
      default:
        return '#27ae60'; // Yeşil
    }
  }

  /// Ofis istatistik özeti
  String get memberStatsSummary {
    final brokers = brokerCount > 0 ? '${brokerCount}B' : '';
    final advisors = advisorCount > 0 ? '${advisorCount}D' : '';
    final leaders = teamLeaderCount > 0 ? '${teamLeaderCount}L' : '';
    final assistants = assistantCount > 0 ? '${assistantCount}A' : '';
    
    final parts = [brokers, advisors, leaders, assistants].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' • ') : '${totalMembers} Üye';
  }

  /// Ofis durumu
  String get officeStatus {
    if (totalMembers == 0) return 'Boş';
    if (brokerCount == 0) return 'Broker Aranıyor';
    if (totalMembers == 1) return 'Yeni Açıldı';
    if (totalMembers >= 15) return 'Tam Kapasite';
    if (totalMembers >= 10) return 'Aktif';
    return 'Gelişiyor';
  }

  /// Ofis kalite skoru (1-100)
  int get qualityScore {
    int score = 0;
    
    // Logo varsa +15
    if (hasLogo) score += 15;
    
    // Geçerli telefon varsa +10
    if (hasPhone) score += 10;
    
    // Geçerli email varsa +10
    if (hasValidEmail) score += 10;
    
    // Üye sayısına göre puan (max 30)
    score += (totalMembers * 3).clamp(0, 30);
    
    // Broker varsa +15
    if (brokerCount > 0) score += 15;
    
    // Danışman varsa +10
    if (advisorCount > 0) score += 10;
    
    // Fotoğrafı olan üye oranına göre puan (max 10)
    if (totalMembers > 0) {
      final photoRatio = membersWithPhotoCount / totalMembers;
      score += (photoRatio * 10).round();
    }
    
    return score.clamp(0, 100);
  }

  /// Kalite kategorisi
  String get qualityCategory {
    final score = qualityScore;
    if (score >= 80) return 'Mükemmel';
    if (score >= 60) return 'İyi';
    if (score >= 40) return 'Orta';
    if (score >= 20) return 'Zayıf';
    return 'Çok Zayıf';
  }

  /// Broker listesi
  List<OfficeMemberModel> get brokers {
    return officeMembers.where((member) => member.isBroker).toList();
  }

  /// Danışman listesi
  List<OfficeMemberModel> get advisors {
    return officeMembers.where((member) => member.isAdvisor).toList();
  }

  /// Yönetici listesi (Broker + Takım Lideri)
  List<OfficeMemberModel> get managers {
    return officeMembers.where((member) => member.isBroker || member.isTeamLeader).toList();
  }

  /// Fotoğrafı olan üyeler
  List<OfficeMemberModel> get membersWithPhoto {
    return officeMembers.where((member) => member.hasPicture).toList();
  }

  /// En deneyimli üye (ID'ye göre - düşük ID daha eski)
  OfficeMemberModel? get seniorMember {
    if (officeMembers.isEmpty) return null;
    return officeMembers.reduce((a, b) => a.memberId < b.memberId ? a : b);
  }

  /// En yeni üye (ID'ye göre - yüksek ID daha yeni)
  OfficeMemberModel? get newestMember {
    if (officeMembers.isEmpty) return null;
    return officeMembers.reduce((a, b) => a.memberId > b.memberId ? a : b);
  }

  /// Ofis performans tahmini
  String get performanceEstimate {
    if (brokerCount >= 2 && advisorCount >= 5) return 'Yüksek Performans';
    if (brokerCount >= 1 && advisorCount >= 3) return 'İyi Performans';
    if (brokerCount >= 1 && advisorCount >= 1) return 'Orta Performans';
    if (totalMembers >= 2) return 'Başlangıç Seviyesi';
    return 'Yetersiz Kadro';
  }

  /// İletişim bilgileri tam mı?
  bool get hasCompleteContactInfo {
    return hasValidEmail && hasPhone;
  }

  /// Ofis web URL'i
  String get officeWebUrl {
    return 'https://zecorner.com/ofis/$officeSlug';
  }

  /// Ofis profil tamamlanma yüzdesi
  double get profileCompleteness {
    double total = 0;
    double completed = 0;
    
    // Temel bilgiler (40%)
    total += 40;
    if (officeTitle.isNotEmpty) completed += 10;
    if (officeAddress.isNotEmpty) completed += 10;
    if (hasValidEmail) completed += 10;
    if (hasPhone) completed += 10;
    
    // Logo (20%)
    total += 20;
    if (hasLogo) completed += 20;
    
    // Üyeler (40%)
    total += 40;
    if (totalMembers > 0) completed += 20;
    if (brokerCount > 0) completed += 20;
    
    return (completed / total) * 100;
  }

  /// Ofis bilgi özeti
  Map<String, dynamic> get officeInfo {
    return {
      'id': officeId,
      'title': officeTitle,
      'type': officeType,
      'category': officeCategory,
      'city': cityName,
      'district': district,
      'short_address': shortAddress,
      'full_address': fullAddress,
      'member_count': totalMembers,
      'member_distribution': memberTypeDistribution,
      'size_category': sizeCategory,
      'status': officeStatus,
      'quality_score': qualityScore,
      'quality_category': qualityCategory,
      'performance_estimate': performanceEstimate,
      'profile_completeness': profileCompleteness,
      'emoji': officeEmoji,
      'color': officeColor,
      'flags': {
        'has_logo': hasLogo,
        'has_phone': hasPhone,
        'has_valid_email': hasValidEmail,
        'has_complete_contact': hasCompleteContactInfo,
      },
    };
  }
}

// Helper Extension for OfficeMemberModel
extension OfficeMemberModelHelpers on OfficeMemberModel {
  /// Üye tipi kontrolleri
  bool get isBroker => memberTypeDescription.toLowerCase().contains('broker');
  bool get isAdvisor => memberTypeDescription.toLowerCase().contains('danışman');
  bool get isTeamLeader => memberTypeDescription.toLowerCase().contains('takım lideri');
  bool get isAssistant => memberTypeDescription.toLowerCase().contains('asistan');
  bool get isAdmin => memberTypeDescription.toLowerCase().contains('admin');
  bool get isDirector => memberTypeDescription.toLowerCase().contains('direktör');
  bool get isFranchise => memberTypeDescription.toLowerCase().contains('franchise');
  
  /// Diğer tipler
  bool get isOtherType => !isBroker && !isAdvisor && !isTeamLeader && !isAssistant && !isAdmin;

  /// Fotoğrafı var mı?
  bool get hasPicture => memberPicture != null && memberPicture!.isNotEmpty;

  /// Yönetici mi? (Broker, Takım Lideri, Direktör)
  bool get isManager => isBroker || isTeamLeader || isDirector;

  /// Satış ekibi mi? (Broker, Danışman, Takım Lideri)
  bool get isSalesTeam => isBroker || isAdvisor || isTeamLeader;

  /// Üye kategorisi
  String get memberCategory {
    if (isAdmin) return 'Yönetim';
    if (isBroker) return 'Broker';
    if (isTeamLeader) return 'Takım Lideri';
    if (isAdvisor) return 'Danışman';
    if (isAssistant) return 'Destek';
    if (isFranchise) return 'Franchise';
    return 'Diğer';
  }

  /// Üye seviyesi (1-5)
  int get memberLevel {
    if (isDirector) return 5;
    if (isBroker) return 4;
    if (isTeamLeader) return 3;
    if (isAdvisor) return 2;
    return 1;
  }

  /// Üye emoji'si
  String get memberEmoji {
    if (isAdmin) return '👑';
    if (isDirector) return '🎯';
    if (isBroker) return '🏢';
    if (isTeamLeader) return '👥';
    if (isAdvisor) return '💼';
    if (isAssistant) return '📝';
    if (isFranchise) return '🏪';
    return '👤';
  }

  /// Üye renk kodu
  String get memberColor {
    switch (memberCategory) {
      case 'Yönetim':
        return '#e74c3c'; // Kırmızı
      case 'Broker':
        return '#f39c12'; // Turuncu
      case 'Takım Lideri':
        return '#3498db'; // Mavi
      case 'Danışman':
        return '#27ae60'; // Yeşil
      case 'Destek':
        return '#9b59b6'; // Mor
      case 'Franchise':
        return '#1abc9c'; // Turkuaz
      default:
        return '#95a5a6'; // Gri
    }
  }

  /// İsim formatları
  String get firstName {
    final parts = memberTitle.split(' ');
    return parts.isNotEmpty ? parts.first : memberTitle;
  }

  String get lastName {
    final parts = memberTitle.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : '';
  }

  String get initials {
    final parts = memberTitle.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  /// Title case formatı
  String get formattedName {
    return memberTitle.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Kısa tip açıklaması
  String get shortTypeDescription {
    if (memberTypeDescription.length <= 15) return memberTypeDescription;
    
    // Kısaltmalar
    String short = memberTypeDescription
        .replaceAll('Gayrimenkul', 'GYM')
        .replaceAll('Danışmanı', 'Danışman')
        .replaceAll('Franchise', 'FR')
        .replaceAll('Direktörü', 'Dir.')
        .replaceAll('Yöneticisi', 'Yön.')
        .replaceAll('Asistanı', 'Asist.')
        .replaceAll('Takım Lideri', 'T.Lideri');
    
    return short.length <= 15 ? short : '${short.substring(0, 12)}...';
  }

  /// Üye profil URL'i
  String get memberProfileUrl {
    return 'https://zecorner.com/uye/$memberSlug';
  }

  /// Üye bilgi özeti
  Map<String, dynamic> get memberInfo {
    return {
      'id': memberId,
      'name': formattedName,
      'first_name': firstName,
      'last_name': lastName,
      'initials': initials,
      'type': memberTypeDescription,
      'short_type': shortTypeDescription,
      'category': memberCategory,
      'level': memberLevel,
      'emoji': memberEmoji,
      'color': memberColor,
      'flags': {
        'has_picture': hasPicture,
        'is_broker': isBroker,
        'is_advisor': isAdvisor,
        'is_manager': isManager,
        'is_sales_team': isSalesTeam,
      },
    };
  }
}

// Helper Extension for OfficeResponseModel
extension OfficeResponseModelHelpers on OfficeResponseModel {
  /// Toplam ofis sayısı
  int get totalOffices => offices.length;

  /// Boş mu?
  bool get isEmpty => offices.isEmpty;

  /// Dolu mu?
  bool get isNotEmpty => offices.isNotEmpty;

  /// Sayfalama bilgisi var mı?
  bool get hasPagination => totalPages > 1;

  /// Daha fazla sayfa var mı?
  bool get hasMorePages => page < totalPages;

  /// İlk sayfa mı?
  bool get isFirstPage => page == 1;

  /// Son sayfa mı?
  bool get isLastPage => page >= totalPages;

  /// Ofis ID'sine göre bul
  OfficeModel? getOfficeById(int officeId) {
    try {
      return offices.firstWhere((office) => office.officeId == officeId);
    } catch (e) {
      return null;
    }
  }

  /// Ofis slug'ına göre bul
  OfficeModel? getOfficeBySlug(String slug) {
    try {
      return offices.firstWhere((office) => office.officeSlug == slug);
    } catch (e) {
      return null;
    }
  }

  /// Arama fonksiyonu
  List<OfficeModel> searchOffices(String query) {
    if (query.isEmpty) return offices;
    
    final lowerQuery = query.toLowerCase();
    return offices.where((office) {
      return office.officeTitle.toLowerCase().contains(lowerQuery) ||
             office.officeAddress.toLowerCase().contains(lowerQuery) ||
             office.cityName.toLowerCase().contains(lowerQuery) ||
             office.district.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Şehre göre filtrele
  List<OfficeModel> getOfficesByCity(String cityCode) {
    return offices.where((office) => office.city == cityCode).toList();
  }

  /// Şehir adına göre filtrele
  List<OfficeModel> getOfficesByCityName(String cityName) {
    return offices.where((office) => office.cityName.toLowerCase() == cityName.toLowerCase()).toList();
  }

  /// Ofis tipine göre filtrele
  List<OfficeModel> getOfficesByType(String officeType) {
    return offices.where((office) => office.officeType == officeType).toList();
  }

  /// Ofis kategorisine göre filtrele
  List<OfficeModel> getOfficesByCategory(String category) {
    return offices.where((office) => office.officeCategory == category).toList();
  }

  /// ZeCorner ofisleri
  List<OfficeModel> get zeCornerOffices {
    return offices.where((office) => office.officeType == 'ZeCorner Ofis').toList();
  }

  /// Partner ofisleri
  List<OfficeModel> get partnerOffices {
    return offices.where((office) => office.officeType == 'Partner Ofis').toList();
  }

  /// Prestige ofisleri
  List<OfficeModel> get prestigeOffices {
    return offices.where((office) => office.officeCategory == 'Prestige').toList();
  }

  /// Test ofisleri
  List<OfficeModel> get testOffices {
    return offices.where((office) => office.officeCategory == 'Test Ofis').toList();
  }

  /// Büyüklüğe göre filtrele
  List<OfficeModel> getOfficesBySize(String sizeCategory) {
    return offices.where((office) => office.sizeCategory == sizeCategory).toList();
  }

  /// Kalite skoruna göre filtrele
  List<OfficeModel> getOfficesByQuality(String qualityCategory) {
    return offices.where((office) => office.qualityCategory == qualityCategory).toList();
  }

  /// Şehirlere göre grupla
  Map<String, List<OfficeModel>> get groupedByCity {
    final Map<String, List<OfficeModel>> grouped = {};
    
    for (final office in offices) {
      final city = office.cityName;
      grouped[city] = (grouped[city] ?? [])..add(office);
    }
    
    return grouped;
  }

  /// Ofis tipine göre grupla
  Map<String, List<OfficeModel>> get groupedByType {
    final Map<String, List<OfficeModel>> grouped = {};
    
    for (final office in offices) {
      final type = office.officeType;
      grouped[type] = (grouped[type] ?? [])..add(office);
    }
    
    return grouped;
  }

  /// Büyüklüğe göre grupla
  Map<String, List<OfficeModel>> get groupedBySize {
    final Map<String, List<OfficeModel>> grouped = {};
    
    for (final office in offices) {
      final size = office.sizeCategory;
      grouped[size] = (grouped[size] ?? [])..add(office);
    }
    
    return grouped;
  }

  /// Kaliteye göre grupla
  Map<String, List<OfficeModel>> get groupedByQuality {
    final Map<String, List<OfficeModel>> grouped = {};
    
    for (final office in offices) {
      final quality = office.qualityCategory;
      grouped[quality] = (grouped[quality] ?? [])..add(office);
    }
    
    return grouped;
  }

  /// Sıralamalar
  List<OfficeModel> get sortedByName {
    final sorted = List<OfficeModel>.from(offices);
    sorted.sort((a, b) => a.officeTitle.compareTo(b.officeTitle));
    return sorted;
  }

  List<OfficeModel> get sortedByMemberCount {
    final sorted = List<OfficeModel>.from(offices);
    sorted.sort((a, b) => b.totalMembers.compareTo(a.totalMembers));
    return sorted;
  }

  List<OfficeModel> get sortedByQualityScore {
    final sorted = List<OfficeModel>.from(offices);
    sorted.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    return sorted;
  }

  List<OfficeModel> get sortedByCity {
    final sorted = List<OfficeModel>.from(offices);
    sorted.sort((a, b) => a.cityName.compareTo(b.cityName));
    return sorted;
  }

  /// İstatistikler
  Map<String, int> get cityStatistics {
    final stats = <String, int>{};
    
    for (final office in offices) {
      final city = office.cityName;
      stats[city] = (stats[city] ?? 0) + 1;
    }
    
    return stats;
  }

  Map<String, int> get typeStatistics {
    final stats = <String, int>{};
    
    for (final office in offices) {
      final type = office.officeType;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    
    return stats;
  }

  Map<String, int> get sizeStatistics {
    final stats = <String, int>{};
    
    for (final office in offices) {
      final size = office.sizeCategory;
      stats[size] = (stats[size] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Toplam üye sayısı (tüm ofislerde)
  int get totalMembersAcrossOffices {
    return offices.fold(0, (sum, office) => sum + office.totalMembers);
  }

  /// Ortalama ofis büyüklüğü
  double get averageOfficeSize {
    if (offices.isEmpty) return 0.0;
    return totalMembersAcrossOffices / offices.length;
  }

  /// En büyük ofis
  OfficeModel? get largestOffice {
    if (offices.isEmpty) return null;
    return offices.reduce((a, b) => a.totalMembers > b.totalMembers ? a : b);
  }

  /// En küçük ofis
  OfficeModel? get smallestOffice {
    if (offices.isEmpty) return null;
    return offices.reduce((a, b) => a.totalMembers < b.totalMembers ? a : b);
  }

  /// En kaliteli ofis
  OfficeModel? get highestQualityOffice {
    if (offices.isEmpty) return null;
    return offices.reduce((a, b) => a.qualityScore > b.qualityScore ? a : b);
  }

  /// Rastgele ofis seç
  OfficeModel get randomOffice {
    if (offices.isEmpty) throw StateError('Offices list is empty');
    final random = DateTime.now().millisecondsSinceEpoch % offices.length;
    return offices[random];
  }

  /// Detaylı istatistik özeti
  Map<String, dynamic> get statisticsSummary {
    return {
      'total_offices': totalOffices,
      'total_members': totalMembersAcrossOffices,
      'average_office_size': averageOfficeSize,
      'city_distribution': cityStatistics,
      'type_distribution': typeStatistics,
      'size_distribution': sizeStatistics,
      'largest_office': largestOffice?.officeTitle,
      'smallest_office': smallestOffice?.officeTitle,
      'highest_quality_office': highestQualityOffice?.officeTitle,
      'pagination': {
        'current_page': page,
        'total_pages': totalPages,
        'total_count': totalCount,
        'has_more_pages': hasMorePages,
      },
    };
  }

  /// Gelişmiş filtreleme
  List<OfficeModel> filterOffices({
    String? cityCode,
    String? cityName,
    String? officeType,
    String? officeCategory,
    String? sizeCategory,
    String? qualityCategory,
    int? minMembers,
    int? maxMembers,
    bool? hasLogo,
    bool? hasPhone,
    bool? hasValidEmail,
  }) {
    return offices.where((office) {
      if (cityCode != null && office.city != cityCode) return false;
      if (cityName != null && office.cityName.toLowerCase() != cityName.toLowerCase()) return false;
      if (officeType != null && office.officeType != officeType) return false;
      if (officeCategory != null && office.officeCategory != officeCategory) return false;
      if (sizeCategory != null && office.sizeCategory != sizeCategory) return false;
      if (qualityCategory != null && office.qualityCategory != qualityCategory) return false;
      if (minMembers != null && office.totalMembers < minMembers) return false;
      if (maxMembers != null && office.totalMembers > maxMembers) return false;
      if (hasLogo != null && office.hasLogo != hasLogo) return false;
      if (hasPhone != null && office.hasPhone != hasPhone) return false;
      if (hasValidEmail != null && office.hasValidEmail != hasValidEmail) return false;
      
      return true;
    }).toList();
  }
}
