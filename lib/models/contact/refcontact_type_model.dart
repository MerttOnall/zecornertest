class RefContactTypeResponseModel {
  final List<ContactTypeModel> contactTypes;

  RefContactTypeResponseModel({
    required this.contactTypes,
  });

  factory RefContactTypeResponseModel.fromJson(List<dynamic> json) {
    final types = <ContactTypeModel>[];
    for (final item in json) {
      if (item is! Map) continue;
      try {
        types.add(ContactTypeModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return RefContactTypeResponseModel(contactTypes: types);
  }

  List<Map<String, dynamic>> toJson() {
    return contactTypes.map((e) => e.toJson()).toList();
  }
}

class ContactTypeModel {
  final int code;
  final String description;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final bool isCustomer;
  final bool isAdmin;
  final bool isAgencyEmployee;
  final int? status; // 1 = aktif, 0 = pasif

  ContactTypeModel({
    required this.code,
    required this.description,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    required this.isCustomer,
    required this.isAdmin,
    required this.isAgencyEmployee,
    this.status,
  });

  factory ContactTypeModel.fromJson(Map<String, dynamic> json) {
    // API bazen description yerine type_description dönebiliyor (web ile uyum)
    final description = json['description']?.toString() ??
        json['type_description']?.toString() ??
        '';
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString().trim());
    }

    return ContactTypeModel(
      code: asInt(json['code'] ?? json['id']) ?? 0,
      description: description,
      isCompany: json['is_company'] == true,
      isEmployee: json['is_employee'] == true,
      isAgency: json['is_agency'] == true,
      isCustomer: json['is_customer'] == true,
      isAdmin: json['is_admin'] == true,
      isAgencyEmployee: json['is_agency_employee'] == true,
      status: asInt(json['status']) ??
          (json['is_active'] == true
              ? 1
              : (json['is_active'] == false ? 0 : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'is_company': isCompany,
      'is_employee': isEmployee,
      'is_agency': isAgency,
      'is_customer': isCustomer,
      'is_admin': isAdmin,
      'is_agency_employee': isAgencyEmployee,
      if (status != null) 'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactTypeModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'ContactTypeModel(code: $code, description: $description)';
}

// Helper Extension for ContactTypeModel
extension ContactTypeModelHelpers on ContactTypeModel {
  /// Contact türü kategorisi
  String get category {
    if (isAdmin) return 'Yönetici';
    if (isAgency && isCompany) return 'Ofis/Acente';
    if (isEmployee && !isAgencyEmployee) return 'Merkez Çalışanı';
    if (isAgencyEmployee) return 'Acente Çalışanı';
    if (isAgency && !isCompany) return 'Acente Adayı';
    if (isCustomer) return 'Müşteri';
    if (isCompany && !isAgency) return 'Şirket';
    return 'Genel';
  }

  /// Contact türü ana grubu
  String get mainGroup {
    if (isAdmin) return 'ADMİN';
    if (isEmployee || isAgencyEmployee) return 'ÇALIŞAN';
    if (isAgency) return 'ACENTE';
    if (isCustomer) return 'MÜŞTERİ';
    if (isCompany) return 'ŞİRKET';
    return 'KİŞİ';
  }

  /// Contact türü alt grubu
  String get subGroup {
    if (isAdmin) {
      if (code == 4) return 'Super Admin';
      if (code == 3) return 'Admin';
      return 'Yönetici';
    }
    
    if (isAgencyEmployee) {
      if (description.contains('Broker')) return 'Broker';
      if (description.contains('Danışman')) return 'Danışman';
      if (description.contains('Takım')) return 'Takım Lideri';
      if (description.contains('Asistan')) return 'Asistan';
      return 'Acente Çalışanı';
    }
    
    if (isEmployee && !isAgencyEmployee) {
      if (description.contains('Franchise')) return 'Franchise';
      if (description.contains('Saha')) return 'Saha Satış';
      if (description.contains('Müdür')) return 'Müdür';
      return 'Merkez Çalışanı';
    }
    
    if (isCustomer) {
      if (description.contains('Potansiyel')) return 'Potansiyel';
      if (description.contains('Alıcı') && description.contains('Satıcı')) return 'Alıcı & Satıcı';
      if (description.contains('Alıcı')) return 'Alıcı';
      if (description.contains('Satıcı')) return 'Satıcı';
      return 'Müşteri';
    }
    
    if (isAgency) {
      if (description.contains('Aday')) return 'Aday';
      if (description.contains('Broker')) return 'Broker Ofis';
      return 'Acente';
    }
    
    if (isCompany) {
      if (description.contains('Merkez')) return 'Merkez Ofis';
      if (description.contains('Broker')) return 'Broker Ofis';
      if (description.contains('ZECorner')) return 'ZECorner Ofis';
      return 'Şirket';
    }
    
    return category;
  }

  /// Yetki seviyesi (1: En düşük, 10: En yüksek)
  int get authorityLevel {
    if (code == 4) return 10; // Super Admin
    if (code == 3) return 9;  // Admin
    if (code == 16) return 8; // Müdür
    if (code == 306) return 7; // Direktör
    if (code == 305 || code == 301) return 6; // Yöneticiler
    if (code == 13) return 5; // Takım Lideri
    if (code == 10) return 4; // Broker
    if (code == 11) return 3; // Gayrimenkul Danışmanı
    if (isEmployee) return 2; // Diğer çalışanlar
    return 1; // Müşteri, aday vb.
  }

  /// Hiyerarşi seviyesi açıklaması
  String get hierarchyLevel {
    final level = authorityLevel;
    if (level >= 9) return 'Üst Yönetim';
    if (level >= 7) return 'Orta Yönetim';
    if (level >= 5) return 'Takım Yönetimi';
    if (level >= 3) return 'Operasyonel';
    if (level >= 2) return 'Giriş Seviyesi';
    return 'Harici';
  }

  /// İş rolü tipi
  String get roleType {
    if (isAdmin) return 'Sistem Yöneticisi';
    if (description.contains('Danışman')) return 'Satış Danışmanı';
    if (description.contains('Broker')) return 'Emlak Brokeri';
    if (description.contains('Franchise')) return 'Franchise Uzmanı';
    if (description.contains('Müdür')) return 'Yönetici';
    if (description.contains('Takım')) return 'Takım Lideri';
    if (description.contains('Asistan')) return 'Destek Personeli';
    if (isCustomer && description.contains('Alıcı')) return 'Alıcı Müşteri';
    if (isCustomer && description.contains('Satıcı')) return 'Satıcı Müşteri';
    if (isCustomer) return 'Müşteri';
    if (isCompany) return 'Kurumsal';
    return 'Genel';
  }

  /// Departman
  String get department {
    if (isAdmin) return 'Bilgi İşlem';
    if (description.contains('Franchise')) return 'Franchise';
    if (description.contains('Saha')) return 'Saha Satış';
    if (isAgencyEmployee || isAgency) return 'Emlak';
    if (isEmployee) return 'Merkez Ofis';
    if (isCustomer) return 'Müşteri İlişkileri';
    return 'Genel';
  }

  /// Contact türü emoji'si
  String get typeEmoji {
    if (code == 4) return '👑'; // Super Admin
    if (code == 3) return '🛡️'; // Admin
    if (description.contains('Müdür')) return '👔';
    if (description.contains('Direktör')) return '🎯';
    if (description.contains('Yönetici')) return '📋';
    if (description.contains('Takım')) return '👥';
    if (description.contains('Broker')) return '🏢';
    if (description.contains('Danışman')) return '💼';
    if (description.contains('Asistan')) return '📝';
    if (description.contains('Aday')) return '🎓';
    if (description.contains('Alıcı')) return '🛒';
    if (description.contains('Satıcı')) return '🏠';
    if (description.contains('Potansiyel')) return '🔍';
    if (isCompany) return '🏬';
    if (description.contains('Kişi')) return '👤';
    if (description.contains('Tüzel')) return '🏛️';
    return '👤';
  }

  /// Renk kodu (hex)
  String get colorCode {
    switch (mainGroup) {
      case 'ADMİN':
        return '#e74c3c'; // Kırmızı
      case 'ÇALIŞAN':
        return '#3498db'; // Mavi
      case 'ACENTE':
        return '#f39c12'; // Turuncu
      case 'MÜŞTERİ':
        return '#27ae60'; // Yeşil
      case 'ŞİRKET':
        return '#9b59b6'; // Mor
      default:
        return '#95a5a6'; // Gri
    }
  }

  /// Sistem erişim izni var mı?
  bool get hasSystemAccess {
    return isAdmin || isEmployee || isAgencyEmployee || (isAgency && !description.contains('Aday'));
  }

  /// Portal erişim tipi
  String get portalAccessType {
    if (isAdmin) return 'Admin Panel';
    if (isEmployee && !isAgencyEmployee) return 'Merkez Portal';
    if (isAgencyEmployee || isAgency) return 'Emlak Portal';
    if (isCustomer) return 'Müşteri Portal';
    if (isCompany) return 'Kurumsal Portal';
    return 'Genel Portal';
  }

  /// Satış yetkilisi mi?
  bool get isSalesAuthorized {
    return description.contains('Danışman') || 
           description.contains('Broker') || 
           description.contains('Satış') ||
           description.contains('Takım');
  }

  /// Yönetici mi?
  bool get isManager {
    return description.contains('Müdür') || 
           description.contains('Direktör') || 
           description.contains('Yönetici') ||
           description.contains('Takım Lideri') ||
           isAdmin;
  }

  /// Franchise ile ilgili mi?
  bool get isFranchiseRelated {
    return description.contains('Franchise');
  }

  /// Aday pozisyonu mu?
  bool get isCandidatePosition {
    return description.contains('Aday');
  }

  /// Aktif çalışan mı?
  bool get isActiveEmployee {
    return (isEmployee || isAgencyEmployee) && !isCandidatePosition;
  }

  /// İletişim kategorisi
  String get communicationCategory {
    if (isAdmin) return 'Acil İletişim';
    if (isManager) return 'Öncelikli İletişim';
    if (isActiveEmployee) return 'İç İletişim';
    if (isCustomer) return 'Müşteri İletişimi';
    return 'Genel İletişim';
  }

  /// Rapor kategorisi
  String get reportCategory {
    if (isAdmin) return 'Sistem Raporları';
    if (isManager) return 'Yönetici Raporları';
    if (isEmployee && isFranchiseRelated) return 'Franchise Raporları';
    if (isSalesAuthorized) return 'Satış Raporları';
    if (isCustomer) return 'Müşteri Raporları';
    return 'Genel Raporlar';
  }

  /// Görev sorumluluğu
  String get responsibility {
    if (code == 4) return 'Sistem yönetimi ve genel denetim';
    if (code == 3) return 'Platform yönetimi ve kullanıcı denetimi';
    if (description.contains('Direktör')) return 'Stratejik planlama ve yönetim';
    if (description.contains('Müdür')) return 'Operasyonel yönetim';
    if (description.contains('Yönetici')) return 'Departman yönetimi';
    if (description.contains('Takım Lideri')) return 'Takım koordinasyonu';
    if (description.contains('Broker')) return 'Emlak portföy yönetimi';
    if (description.contains('Danışman')) return 'Müşteri danışmanlığı ve satış';
    if (description.contains('Asistan')) return 'Operasyonel destek';
    if (description.contains('Uzman')) return 'Uzmanlık alanında hizmet';
    if (isCustomer) return 'Emlak alım/satım işlemleri';
    return 'Genel görevler';
  }

  /// Kısa tanım
  String get shortDescription {
    if (description.length <= 20) return description;
    
    // Kısaltmalar
    String short = description
        .replaceAll('Gayrimenkul', 'GYM')
        .replaceAll('Danışmanı', 'Danışman')
        .replaceAll('Franchise', 'FR')
        .replaceAll('Geliştirme', 'Gel.')
        .replaceAll('Uzmanı', 'Uzman')
        .replaceAll('Direktörü', 'Dir.')
        .replaceAll('Yöneticisi', 'Yön.')
        .replaceAll('Asistanı', 'Asist.')
        .replaceAll('ZECorner', 'ZE');
    
    return short.length <= 20 ? short : '${short.substring(0, 17)}...';
  }

  /// Contact türü bilgi özeti
  Map<String, dynamic> get typeInfo {
    return {
      'code': code,
      'description': description,
      'short_description': shortDescription,
      'category': category,
      'main_group': mainGroup,
      'sub_group': subGroup,
      'role_type': roleType,
      'department': department,
      'authority_level': authorityLevel,
      'hierarchy_level': hierarchyLevel,
      'portal_access': portalAccessType,
      'communication_category': communicationCategory,
      'emoji': typeEmoji,
      'color': colorCode,
      'flags': {
        'is_admin': isAdmin,
        'is_manager': isManager,
        'is_employee': isActiveEmployee,
        'is_sales_authorized': isSalesAuthorized,
        'has_system_access': hasSystemAccess,
        'is_franchise_related': isFranchiseRelated,
        'is_candidate': isCandidatePosition,
      },
    };
  }
}

// Helper Extension for RefContactTypeResponseModel
extension RefContactTypeResponseModelHelpers on RefContactTypeResponseModel {
  /// Toplam contact türü sayısı
  int get totalTypes => contactTypes.length;

  /// Koda göre contact türü bul
  ContactTypeModel? getContactTypeByCode(int code) {
    try {
      return contactTypes.firstWhere((type) => type.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Açıklamaya göre contact türü bul
  ContactTypeModel? getContactTypeByDescription(String description) {
    try {
      return contactTypes.firstWhere(
        (type) => type.description.toLowerCase() == description.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Arama fonksiyonu
  List<ContactTypeModel> searchContactTypes(String query) {
    if (query.isEmpty) return contactTypes;
    
    final lowerQuery = query.toLowerCase();
    return contactTypes.where((type) {
      return type.description.toLowerCase().contains(lowerQuery) ||
             type.category.toLowerCase().contains(lowerQuery) ||
             type.mainGroup.toLowerCase().contains(lowerQuery) ||
             type.code.toString().contains(query);
    }).toList();
  }

  /// Admin türlerini getir
  List<ContactTypeModel> get adminTypes {
    return contactTypes.where((type) => type.isAdmin).toList();
  }

  /// Çalışan türlerini getir
  List<ContactTypeModel> get employeeTypes {
    return contactTypes.where((type) => type.isEmployee).toList();
  }

  /// Acente türlerini getir
  List<ContactTypeModel> get agencyTypes {
    return contactTypes.where((type) => type.isAgency).toList();
  }

  /// Müşteri türlerini getir
  List<ContactTypeModel> get customerTypes {
    return contactTypes.where((type) => type.isCustomer).toList();
  }

  /// Şirket türlerini getir
  List<ContactTypeModel> get companyTypes {
    return contactTypes.where((type) => type.isCompany).toList();
  }

  /// Acente çalışanı türlerini getir
  List<ContactTypeModel> get agencyEmployeeTypes {
    return contactTypes.where((type) => type.isAgencyEmployee).toList();
  }

  /// Ana gruplarına göre grupla
  Map<String, List<ContactTypeModel>> get groupedByMainGroup {
    final Map<String, List<ContactTypeModel>> grouped = {};
    
    for (final type in contactTypes) {
      final group = type.mainGroup;
      grouped[group] = (grouped[group] ?? [])..add(type);
    }
    
    return grouped;
  }

  /// Kategorilere göre grupla
  Map<String, List<ContactTypeModel>> get groupedByCategory {
    final Map<String, List<ContactTypeModel>> grouped = {};
    
    for (final type in contactTypes) {
      final category = type.category;
      grouped[category] = (grouped[category] ?? [])..add(type);
    }
    
    return grouped;
  }

  /// Departmanlara göre grupla
  Map<String, List<ContactTypeModel>> get groupedByDepartment {
    final Map<String, List<ContactTypeModel>> grouped = {};
    
    for (final type in contactTypes) {
      final department = type.department;
      grouped[department] = (grouped[department] ?? [])..add(type);
    }
    
    return grouped;
  }

  /// Yetki seviyesine göre grupla
  Map<String, List<ContactTypeModel>> get groupedByAuthorityLevel {
    final Map<String, List<ContactTypeModel>> grouped = {};
    
    for (final type in contactTypes) {
      final level = type.hierarchyLevel;
      grouped[level] = (grouped[level] ?? [])..add(type);
    }
    
    return grouped;
  }

  /// Yetki seviyesine göre sırala (yüksekten düşüğe)
  List<ContactTypeModel> get sortedByAuthority {
    final sorted = List<ContactTypeModel>.from(contactTypes);
    sorted.sort((a, b) => b.authorityLevel.compareTo(a.authorityLevel));
    return sorted;
  }

  /// Alfabetik sıralama
  List<ContactTypeModel> get sortedAlphabetically {
    final sorted = List<ContactTypeModel>.from(contactTypes);
    sorted.sort((a, b) => a.description.compareTo(b.description));
    return sorted;
  }

  /// Koda göre sıralama
  List<ContactTypeModel> get sortedByCode {
    final sorted = List<ContactTypeModel>.from(contactTypes);
    sorted.sort((a, b) => a.code.compareTo(b.code));
    return sorted;
  }

  /// Sistem erişimi olan türler
  List<ContactTypeModel> get systemAccessTypes {
    return contactTypes.where((type) => type.hasSystemAccess).toList();
  }

  /// Satış yetkisi olan türler
  List<ContactTypeModel> get salesAuthorizedTypes {
    return contactTypes.where((type) => type.isSalesAuthorized).toList();
  }

  /// Yönetici türleri
  List<ContactTypeModel> get managerTypes {
    return contactTypes.where((type) => type.isManager).toList();
  }

  /// Aktif çalışan türleri
  List<ContactTypeModel> get activeEmployeeTypes {
    return contactTypes.where((type) => type.isActiveEmployee).toList();
  }

  /// Aday türleri
  List<ContactTypeModel> get candidateTypes {
    return contactTypes.where((type) => type.isCandidatePosition).toList();
  }

  /// Franchise ile ilgili türler
  List<ContactTypeModel> get franchiseTypes {
    return contactTypes.where((type) => type.isFranchiseRelated).toList();
  }

  /// Portal erişim tipine göre grupla
  Map<String, List<ContactTypeModel>> get groupedByPortalAccess {
    final Map<String, List<ContactTypeModel>> grouped = {};
    
    for (final type in contactTypes) {
      final portalType = type.portalAccessType;
      grouped[portalType] = (grouped[portalType] ?? [])..add(type);
    }
    
    return grouped;
  }

  /// En yüksek yetkili türler (Admin seviyesi)
  List<ContactTypeModel> get highestAuthorityTypes {
    return contactTypes.where((type) => type.authorityLevel >= 9).toList();
  }

  /// En düşük yetkili türler
  List<ContactTypeModel> get lowestAuthorityTypes {
    return contactTypes.where((type) => type.authorityLevel <= 2).toList();
  }

  /// Tip istatistikleri
  Map<String, int> get typeStatistics {
    return {
      'total_types': totalTypes,
      'admin_types': adminTypes.length,
      'employee_types': employeeTypes.length,
      'agency_types': agencyTypes.length,
      'customer_types': customerTypes.length,
      'company_types': companyTypes.length,
      'agency_employee_types': agencyEmployeeTypes.length,
      'system_access_types': systemAccessTypes.length,
      'sales_authorized_types': salesAuthorizedTypes.length,
      'manager_types': managerTypes.length,
      'candidate_types': candidateTypes.length,
      'franchise_types': franchiseTypes.length,
    };
  }

  /// Ana grup istatistikleri
  Map<String, int> get mainGroupStatistics {
    final stats = <String, int>{};
    
    for (final type in contactTypes) {
      final group = type.mainGroup;
      stats[group] = (stats[group] ?? 0) + 1;
    }
    
    return stats;
  }

  /// En popüler kategoriler
  Map<String, int> get categoryStatistics {
    final stats = <String, int>{};
    
    for (final type in contactTypes) {
      final category = type.category;
      stats[category] = (stats[category] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Rastgele contact türü seç
  ContactTypeModel get randomContactType {
    if (contactTypes.isEmpty) throw StateError('Contact types list is empty');
    final random = DateTime.now().millisecondsSinceEpoch % contactTypes.length;
    return contactTypes[random];
  }

  /// Belirli kriterlere göre filtrele
  List<ContactTypeModel> filterByCriteria({
    bool? isAdmin,
    bool? isEmployee,
    bool? isAgency,
    bool? isCustomer,
    bool? isCompany,
    bool? isAgencyEmployee,
    String? mainGroup,
    String? category,
    int? minAuthorityLevel,
    int? maxAuthorityLevel,
  }) {
    return contactTypes.where((type) {
      if (isAdmin != null && type.isAdmin != isAdmin) return false;
      if (isEmployee != null && type.isEmployee != isEmployee) return false;
      if (isAgency != null && type.isAgency != isAgency) return false;
      if (isCustomer != null && type.isCustomer != isCustomer) return false;
      if (isCompany != null && type.isCompany != isCompany) return false;
      if (isAgencyEmployee != null && type.isAgencyEmployee != isAgencyEmployee) return false;
      if (mainGroup != null && type.mainGroup != mainGroup) return false;
      if (category != null && type.category != category) return false;
      if (minAuthorityLevel != null && type.authorityLevel < minAuthorityLevel) return false;
      if (maxAuthorityLevel != null && type.authorityLevel > maxAuthorityLevel) return false;
      
      return true;
    }).toList();
  }

  /// İstatistik özeti
  Map<String, dynamic> get statisticsSummary {
    return {
      'total_types': totalTypes,
      'main_group_stats': mainGroupStatistics,
      'category_stats': categoryStatistics,
      'type_flags': typeStatistics,
      'authority_distribution': {
        'highest_authority': highestAuthorityTypes.length,
        'manager_level': managerTypes.length,
        'employee_level': activeEmployeeTypes.length,
        'lowest_authority': lowestAuthorityTypes.length,
      },
      'access_levels': {
        'system_access': systemAccessTypes.length,
        'sales_authorized': salesAuthorizedTypes.length,
        'candidates': candidateTypes.length,
      }
    };
  }

  /// En yüksek ve en düşük yetkili türler
  Map<String, ContactTypeModel?> get authorityExtremes {
    if (contactTypes.isEmpty) return {'highest': null, 'lowest': null};
    
    final sortedByAuth = sortedByAuthority;
    return {
      'highest': sortedByAuth.first,
      'lowest': sortedByAuth.last,
    };
  }
}
