// =====================================================
// PROPERTY TYPE MODELS - Emlak Türü Modelleri
// =====================================================

class PropertyTypeResponseModel {
  final List<PropertyTypeModel> propertyTypes;

  PropertyTypeResponseModel({
    required this.propertyTypes,
  });

  factory PropertyTypeResponseModel.fromJson(List<dynamic> json) {
    return PropertyTypeResponseModel(
      propertyTypes: json
          .map((e) => PropertyTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return propertyTypes.map((e) => e.toJson()).toList();
  }
}

class PropertyTypeModel {
  final String code;
  final String label;
  final List<PropertyTypeChildModel> children;

  PropertyTypeModel({
    required this.code,
    required this.label,
    required this.children,
  });

  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeModel(
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => PropertyTypeChildModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

class PropertyTypeChildModel {
  final String code;
  final String label;

  PropertyTypeChildModel({
    required this.code,
    required this.label,
  });

  factory PropertyTypeChildModel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeChildModel(
      code: json['code'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
    };
  }
}

// Helper Extension for Property Types
extension PropertyTypeModelHelpers on PropertyTypeModel {
  /// Ana kategorinin alt türlerini kontrol eder
  bool get hasChildren => children.isNotEmpty;

  /// Belirli kod ile alt tür bulur
  PropertyTypeChildModel? findChild(String code) {
    try {
      return children.firstWhere((child) => child.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Tüm alt türlerin kodlarını liste olarak döndürür
  List<String> get childCodes => children.map((child) => child.code).toList();

  /// Tüm alt türlerin etiketlerini liste olarak döndürür
  List<String> get childLabels => children.map((child) => child.label).toList();

  /// Ana kategori için ikon döndürür
  String get categoryIcon {
    switch (code) {
      case 'konut':
        return '🏠';
      case 'is-yeri':
        return '🏢';
      case 'arsa':
        return '🌾';
      default:
        return '🏘️';
    }
  }

  /// Ana kategori rengini döndürür (hex color)
  String get categoryColor {
    switch (code) {
      case 'konut':
        return '#4CAF50'; // Yeşil
      case 'is-yeri':
        return '#2196F3'; // Mavi
      case 'arsa':
        return '#FF9800'; // Turuncu
      default:
        return '#9E9E9E'; // Gri
    }
  }
}

extension PropertyTypeChildModelHelpers on PropertyTypeChildModel {
  /// Alt tür için ikon döndürür
  String get typeIcon {
    switch (code) {
      // Konut türleri
      case 'konut-daire':
        return '🏠';
      case 'konut-rezidans':
        return '🏢';
      case 'konut-mustakil-ev':
        return '🏡';
      case 'konut-villa':
        return '🏛️';
      case 'konut-ciftlik-evi':
        return '🚜';
      case 'konut-kosk-konak':
        return '🏰';
      case 'konut-yali':
        return '🏖️';
      case 'konut-yali-dairesi':
        return '🌊';
      case 'konut-yazlik':
        return '☀️';
      
      // İş yeri türleri
      case 'is-yeri-apartman-dairesi':
        return '🏢';
      case 'is-yeri-atolye':
        return '🔧';
      case 'is-yeri-depo-antrepo':
        return '📦';
      case 'is-yeri-fabrika':
        return '🏭';
      case 'is-yeri-imalathane':
        return '⚙️';
      case 'is-yeri-is-hani-kati-ofisi':
        return '🏢';
      case 'is-yeri-dukkan-magaza':
        return '🛍️';
      case 'is-yeri-muayenehane':
        return '🏥';
      case 'is-yeri-plaza':
        return '🏢';
      case 'is-yeri-plaza-kati-ofisi':
        return '🏢';
      case 'is-yeri-restoran-lokanta':
        return '🍽️';
      case 'is-yeri-tamirhane':
        return '🔧';
      case 'is-yeri-cafe-bar':
        return '☕';
      case 'is-yeri-buro-ofis':
        return '🏢';
      case 'is-yeri-maden-ocagi':
        return '⛏️';
      case 'is-yeri-kuafor-guzellik-merkezi':
        return '💄';
      case 'is-yeri-oto-yikama-kuafor':
        return '🚗';
      case 'is-yeri-okul-kurs':
        return '🎓';
      case 'is-yeri-taksi-duragi':
        return '🚕';
      case 'is-yeri-market':
        return '🛒';
      case 'is-yeri-eczane-medikal':
        return '💊';
      case 'is-yeri-pastane-firin':
        return '🥖';
      case 'is-yeri-pazar-yeri':
        return '🛍️';
      case 'is-yeri-saglik-merkezi':
        return '🏥';
      case 'is-yeri-prova-kayit-studyosu':
        return '🎵';
      case 'is-yeri-sinema-konferans-salonu':
        return '🎬';
      case 'is-yeri-fotograf-studyosu':
        return '📸';
      case 'is-yeri-yurt':
        return '🏠';
      case 'is-yeri-akaryakit-istasyonu':
        return '⛽';
      case 'is-yeri-bufe':
        return '🥙';
      case 'is-yeri-komple-bina':
        return '🏢';
      case 'is-yeri-otopark':
        return '🅿️';
      case 'is-yeri-spor-tesisi':
        return '🏃';
      case 'is-yeri-spa-hamam-sauna':
        return '🛁';
      case 'is-yeri-ciftlik':
        return '🚜';
      case 'is-yeri-dugun-salonu':
        return '💒';
      case 'is-yeri-hazir-sanal-ofis':
        return '💻';
      case 'is-yeri-radyo-istasyonu-tv-kanali':
        return '📻';
      case 'is-yeri-kiraathane':
        return '📚';
      case 'is-yeri-kir-kahvalti-bahcesi':
        return '🌳';
      case 'is-yeri-rezidans-kati-ofisi':
        return '🏢';
      case 'is-yeri-avm':
        return '🛍️';
      case 'is-yeri-garaj':
        return '🚗';
      case 'is-yeri-kantin':
        return '🍽️';
      case 'is-yeri-villa':
        return '🏛️';
      case 'is-yeri-radyo-istasyonu':
        return '📻';
      case 'is-yeri-plaza-kati':
        return '🏢';
      case 'is-yeri-enerji-santrali':
        return '⚡';
      case 'is-yeri-garaj-park-yeri':
        return '🅿️';
      
      // Arsa türleri
      case 'arsa-arsa':
        return '🌾';
      
      default:
        return '🏘️';
    }
  }

  /// Ana kategoriyi döndürür
  String get parentCategory {
    if (code.startsWith('konut-')) return 'konut';
    if (code.startsWith('is-yeri-')) return 'is-yeri';
    if (code.startsWith('arsa-')) return 'arsa';
    return 'diger';
  }

  /// Kısa etiket döndürür (daha kompakt görünüm için)
  String get shortLabel {
    return label.length > 15 ? '${label.substring(0, 12)}...' : label;
  }

  /// Türkçe tam etiket döndürür
  String get displayName {
    switch (code) {
      // Konut türleri
      case 'konut-daire':
        return 'Konut - Daire';
      case 'konut-rezidans':
        return 'Konut - Rezidans';
      case 'konut-mustakil-ev':
        return 'Konut - Müstakil Ev';
      case 'konut-villa':
        return 'Konut - Villa';
      case 'konut-ciftlik-evi':
        return 'Konut - Çiftlik Evi';
      case 'konut-kosk-konak':
        return 'Konut - Köşk & Konak';
      case 'konut-yali':
        return 'Konut - Yalı';
      case 'konut-yali-dairesi':
        return 'Konut - Yalı Dairesi';
      case 'konut-yazlik':
        return 'Konut - Yazlık';
      
      // İş yeri türleri
      case 'is-yeri-apartman-dairesi':
        return 'İş Yeri - Apartman Dairesi';
      case 'is-yeri-atolye':
        return 'İş Yeri - Atölye';
      case 'is-yeri-depo-antrepo':
        return 'İş Yeri - Depo & Antrepo';
      case 'is-yeri-fabrika':
        return 'İş Yeri - Fabrika';
      case 'is-yeri-imalathane':
        return 'İş Yeri - İmalathane';
      case 'is-yeri-is-hani-kati-ofisi':
        return 'İş Yeri - İş Hanı Katı & Ofisi';
      case 'is-yeri-dukkan-magaza':
        return 'İş Yeri - Dükkan & Mağaza';
      case 'is-yeri-muayenehane':
        return 'İş Yeri - Muayenehane';
      case 'is-yeri-plaza':
        return 'İş Yeri - Plaza';
      case 'is-yeri-plaza-kati-ofisi':
        return 'İş Yeri - Plaza Katı & Ofisi';
      case 'is-yeri-restoran-lokanta':
        return 'İş Yeri - Restoran & Lokanta';
      case 'is-yeri-tamirhane':
        return 'İş Yeri - Tamirhane';
      case 'is-yeri-cafe-bar':
        return 'İş Yeri - Cafe & Bar';
      case 'is-yeri-buro-ofis':
        return 'İş Yeri - Büro & Ofis';
      case 'is-yeri-maden-ocagi':
        return 'İş Yeri - Maden Ocağı';
      case 'is-yeri-kuafor-guzellik-merkezi':
        return 'İş Yeri - Kuaför & Güzellik Merkezi';
      case 'is-yeri-oto-yikama-kuafor':
        return 'İş Yeri - Oto Yıkama & Kuaför';
      case 'is-yeri-okul-kurs':
        return 'İş Yeri - Okul & Kurs';
      case 'is-yeri-taksi-duragi':
        return 'İş Yeri - Taksi Durağı';
      case 'is-yeri-market':
        return 'İş Yeri - Market';
      case 'is-yeri-eczane-medikal':
        return 'İş Yeri - Eczane & Medikal';
      case 'is-yeri-pastane-firin':
        return 'İş Yeri - Pastane & Fırın';
      case 'is-yeri-pazar-yeri':
        return 'İş Yeri - Pazar Yeri';
      case 'is-yeri-saglik-merkezi':
        return 'İş Yeri - Sağlık Merkezi';
      case 'is-yeri-prova-kayit-studyosu':
        return 'İş Yeri - Prova & Kayıt Stüdyosu';
      case 'is-yeri-sinema-konferans-salonu':
        return 'İş Yeri - Sinema & Konferans Salonu';
      case 'is-yeri-fotograf-studyosu':
        return 'İş Yeri - Fotoğraf Stüdyosu';
      case 'is-yeri-yurt':
        return 'İş Yeri - Yurt';
      case 'is-yeri-akaryakit-istasyonu':
        return 'İş Yeri - Akaryakıt İstasyonu';
      case 'is-yeri-bufe':
        return 'İş Yeri - Büfe';
      case 'is-yeri-komple-bina':
        return 'İş Yeri - Komple Bina';
      case 'is-yeri-otopark':
        return 'İş Yeri - Otopark';
      case 'is-yeri-spor-tesisi':
        return 'İş Yeri - Spor Tesisi';
      case 'is-yeri-spa-hamam-sauna':
        return 'İş Yeri - Spa, Hamam & Sauna';
      case 'is-yeri-ciftlik':
        return 'İş Yeri - Çiftlik';
      case 'is-yeri-dugun-salonu':
        return 'İş Yeri - Düğün Salonu';
      case 'is-yeri-hazir-sanal-ofis':
        return 'İş Yeri - Hazır & Sanal Ofis';
      case 'is-yeri-radyo-istasyonu-tv-kanali':
        return 'İş Yeri - Radyo İstasyonu & TV Kanalı';
      case 'is-yeri-kiraathane':
        return 'İş Yeri - Kıraathane';
      case 'is-yeri-kir-kahvalti-bahcesi':
        return 'İş Yeri - Kır & Kahvaltı Bahçesi';
      case 'is-yeri-rezidans-kati-ofisi':
        return 'İş Yeri - Rezidans Katı & Ofisi';
      case 'is-yeri-avm':
        return 'İş Yeri - AVM';
      case 'is-yeri-garaj':
        return 'İş Yeri - Garaj';
      case 'is-yeri-kantin':
        return 'İş Yeri - Kantin';
      case 'is-yeri-villa':
        return 'İş Yeri - Villa';
      case 'is-yeri-radyo-istasyonu':
        return 'İş Yeri - Radyo İstasyonu';
      case 'is-yeri-plaza-kati':
        return 'İş Yeri - Plaza Katı';
      case 'is-yeri-enerji-santrali':
        return 'İş Yeri - Enerji Santrali';
      case 'is-yeri-garaj-park-yeri':
        return 'İş Yeri - Garaj & Park Yeri';
      
      // Arsa türleri
      case 'arsa-arsa':
        return 'Arsa';
      
      default:
        return label;
    }
  }
}

extension PropertyTypeResponseModelHelpers on PropertyTypeResponseModel {
  /// Belirli kategoriye ait türü bulur
  PropertyTypeModel? findCategory(String code) {
    try {
      return propertyTypes.firstWhere((type) => type.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Belirli kod ile alt türü bulur (tüm kategorilerde arar)
  PropertyTypeChildModel? findChildByCode(String code) {
    for (final category in propertyTypes) {
      final child = category.findChild(code);
      if (child != null) return child;
    }
    return null;
  }

  /// Tüm alt türleri tek liste halinde döndürür
  List<PropertyTypeChildModel> get allChildren {
    List<PropertyTypeChildModel> allChildren = [];
    for (final category in propertyTypes) {
      allChildren.addAll(category.children);
    }
    return allChildren;
  }

  /// Kategori bazında gruplama
  Map<String, List<PropertyTypeChildModel>> get groupedByCategory {
    Map<String, List<PropertyTypeChildModel>> grouped = {};
    for (final category in propertyTypes) {
      grouped[category.code] = category.children;
    }
    return grouped;
  }

  /// Arama için tüm kodları döndürür
  List<String> get allCodes {
    List<String> codes = [];
    for (final category in propertyTypes) {
      codes.add(category.code);
      codes.addAll(category.childCodes);
    }
    return codes;
  }

  /// Konut türlerini döndürür
  List<PropertyTypeChildModel> get housingTypes {
    final konut = findCategory('konut');
    return konut?.children ?? [];
  }

  /// İş yeri türlerini döndürür
  List<PropertyTypeChildModel> get commercialTypes {
    final isYeri = findCategory('is-yeri');
    return isYeri?.children ?? [];
  }

  /// Arsa türlerini döndürür
  List<PropertyTypeChildModel> get landTypes {
    final arsa = findCategory('arsa');
    return arsa?.children ?? [];
  }

  /// Popüler emlak türlerini döndürür (ilk 10)
  List<PropertyTypeChildModel> get popularTypes {
    final popular = <PropertyTypeChildModel>[];
    
    // Popüler konut türleri
    final housing = housingTypes;
    if (housing.isNotEmpty) {
      popular.addAll(housing.take(5)); // İlk 5 konut türü
    }
    
    // Popüler iş yeri türleri
    final commercial = commercialTypes;
    if (commercial.isNotEmpty) {
      popular.addAll(commercial.take(5)); // İlk 5 iş yeri türü
    }
    
    return popular.take(10).toList(); // Toplam 10 tane
  }

  /// Dropdown liste için kategori seçenekleri
  List<Map<String, dynamic>> get categoryOptions {
    return propertyTypes.map((category) => {
      'value': category.code,
      'label': category.label,
      'icon': category.categoryIcon,
      'color': category.categoryColor,
      'count': category.children.length,
    }).toList();
  }

  /// Arama filtresi için flat liste
  List<Map<String, dynamic>> get searchFilterOptions {
    List<Map<String, dynamic>> options = [];
    
    for (final category in propertyTypes) {
      for (final child in category.children) {
        options.add({
          'value': child.code,
          'label': child.label,
          'displayName': child.displayName,
          'icon': child.typeIcon,
          'category': category.code,
          'categoryLabel': category.label,
          'parentIcon': category.categoryIcon,
        });
      }
    }
    
    return options;
  }
}
