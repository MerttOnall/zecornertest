class ProvincesResponseModel {
  final List<ProvinceModel> provinces;

  ProvincesResponseModel({
    required this.provinces,
  });

  factory ProvincesResponseModel.fromJson(List<dynamic> json) {
    return ProvincesResponseModel(
      provinces: json.map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return provinces.map((e) => e.toJson()).toList();
  }
}

class ProvinceModel {
  final int code;
  final String name;

  ProvinceModel({
    required this.code,
    required this.name,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      code: _asInt(json['code']),
      name: json['name']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProvinceModel && other.code == code && other.name == name;
  }

  @override
  int get hashCode => code.hashCode ^ name.hashCode;

  @override
  String toString() => 'ProvinceModel(code: $code, name: $name)';
}

// Helper Extension for ProvinceModel
extension ProvinceModelHelpers on ProvinceModel {
  /// İl adını düzgün formatta göster (İlk harf büyük, geri kalanı küçük)
  String get formattedName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// İl adını title case formatında göster (Her kelimenin ilk harfi büyük)
  String get titleCaseName {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Plaka kodu string olarak
  String get plateCode => code.toString().padLeft(2, '0');

  /// İl adı kısa versiyonu (bazı uzun iller için)
  String get shortName {
    switch (code) {
      case 3:
        return 'AFYONKARAHİSAR';
      case 46:
        return 'KAHRAMANMARAŞ';
      case 63:
        return 'ŞANLIURFA';
      default:
        return name;
    }
  }

  /// Coğrafi bölge bilgisi
  String get geographicRegion {
    switch (code) {
      // Marmara Bölgesi
      case 10: case 11: case 16: case 17: case 18: case 34: case 39: case 41: case 54: case 59: case 77: case 78:
        return 'Marmara';
      
      // Ege Bölgesi
      case 3: case 9: case 20: case 35: case 45: case 48: case 64:
        return 'Ege';
      
      // Akdeniz Bölgesi
      case 7: case 15: case 31: case 32: case 33: case 79: case 80:
        return 'Akdeniz';
      
      // İç Anadolu Bölgesi
      case 6: case 19: case 26: case 38: case 40: case 42: case 43: case 50: case 51: case 58: case 66: case 68: case 70: case 71:
        return 'İç Anadolu';
      
      // Karadeniz Bölgesi
      case 8: case 14: case 28: case 29: case 37: case 52: case 53: case 55: case 57: case 60: case 61: case 62: case 69: case 74: case 81:
        return 'Karadeniz';
      
      // Doğu Anadolu Bölgesi
      case 4: case 5: case 12: case 13: case 23: case 24: case 25: case 30: case 36: case 44: case 49: case 56: case 65: case 75: case 76:
        return 'Doğu Anadolu';
      
      // Güneydoğu Anadolu Bölgesi
      case 1: case 2: case 21: case 27: case 47: case 63: case 72: case 73:
        return 'Güneydoğu Anadolu';
      
      default:
        return 'Bilinmiyor';
    }
  }

  /// Büyükşehir mi kontrolü
  bool get isMetropolitanCity {
    const metropolitanCities = [
      1, 6, 7, 16, 20, 21, 27, 31, 33, 34, 35, 38, 41, 42, 44, 
      45, 47, 48, 52, 55, 58, 61, 63, 65
    ];
    return metropolitanCities.contains(code);
  }

  /// İl tipi (Büyükşehir/İl)
  String get cityType => isMetropolitanCity ? 'Büyükşehir' : 'İl';

  /// İl kodu emoji olarak (sadece bazı önemli iller için)
  String get cityEmoji {
    switch (code) {
      case 34: return '🏙️'; // İstanbul
      case 6: return '🏛️';  // Ankara
      case 35: return '🌊'; // İzmir
      case 7: return '🏖️';  // Antalya
      case 16: return '🌳'; // Bursa
      case 42: return '🏺'; // Konya
      case 38: return '🏔️'; // Kayseri
      case 61: return '⛰️'; // Trabzon
      case 21: return '🌾'; // Diyarbakır
      case 27: return '🥙'; // Gaziantep
      default: return '🏘️';
    }
  }

  /// Türkiye'nin hangi bölgesinde olduğuna göre renk kodu
  String get regionColor {
    switch (geographicRegion) {
      case 'Marmara':
        return '#3498db';     // Mavi
      case 'Ege':
        return '#2ecc71';     // Yeşil
      case 'Akdeniz':
        return '#f39c12';     // Turuncu
      case 'İç Anadolu':
        return '#9b59b6';     // Mor
      case 'Karadeniz':
        return '#34495e';     // Koyu gri
      case 'Doğu Anadolu':
        return '#e74c3c';     // Kırmızı
      case 'Güneydoğu Anadolu':
        return '#f1c40f';     // Sarı
      default:
        return '#95a5a6';     // Gri
    }
  }

  /// Nüfus kategorisi (tahmini - 2023 verilerine göre)
  String get populationCategory {
    switch (code) {
      case 34: return 'Çok Yüksek (15M+)';     // İstanbul
      case 6: return 'Çok Yüksek (5-15M)';     // Ankara
      case 35: return 'Çok Yüksek (4-5M)';     // İzmir
      case 16: case 7: return 'Yüksek (2-3M)'; // Bursa, Antalya
      case 1: case 21: case 27: case 31: case 33: case 38: case 41: case 42: case 44: case 45: case 47: case 48: case 52: case 55: case 58: case 61: case 63: case 65:
        return 'Orta (500K-2M)';
      default:
        return 'Düşük (<500K)';
    }
  }

  /// Ekonomik gelişmişlik seviyesi (genel değerlendirme)
  String get developmentLevel {
    switch (code) {
      case 34: case 6: case 35: case 16: case 41: case 54:
        return 'Çok Gelişmiş';
      case 7: case 1: case 20: case 26: case 27: case 33: case 38: case 42: case 45: case 48: case 52: case 55: case 59: case 61:
        return 'Gelişmiş';
      case 8: case 9: case 10: case 14: case 17: case 18: case 19: case 21: case 22: case 23: case 24: case 25: case 28: case 31: case 32: case 37: case 39: case 40: case 43: case 44: case 46: case 47: case 50: case 51: case 53: case 56: case 57: case 58: case 60: case 62: case 63: case 64: case 66: case 67:
        return 'Orta Gelişmiş';
      default:
        return 'Az Gelişmiş';
    }
  }

  /// Turistik önem derecesi
  String get touristImportance {
    switch (code) {
      case 34: case 6: case 35: case 7: case 48: case 50:
        return 'Çok Yüksek';
      case 17: case 20: case 22: case 28: case 31: case 38: case 42: case 61:
        return 'Yüksek';
      case 1: case 3: case 8: case 9: case 16: case 18: case 25: case 27: case 32: case 37: case 53: case 55: case 58: case 67:
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  /// İklim tipi
  String get climateType {
    switch (geographicRegion) {
      case 'Akdeniz':
        return 'Akdeniz İklimi';
      case 'Karadeniz':
        return 'Karadeniz İklimi';
      case 'Ege':
        return 'Ege İklimi';
      case 'Marmara':
        return 'Marmara İklimi';
      case 'İç Anadolu':
        return 'Karasal İklim';
      case 'Doğu Anadolu':
        return 'Doğu Anadolu İklimi';
      case 'Güneydoğu Anadolu':
        return 'Güneydoğu Anadolu İklimi';
      default:
        return 'Karma İklim';
    }
  }
}

// Helper Extension for ProvincesResponseModel
extension ProvincesResponseModelHelpers on ProvincesResponseModel {
  /// Toplam il sayısı
  int get totalProvinces => provinces.length;

  /// Plaka koduna göre il bul
  ProvinceModel? getProvinceByCode(int code) {
    try {
      return provinces.firstWhere((province) => province.code == code);
    } catch (e) {
      return null;
    }
  }

  /// İl adına göre il bul (büyük/küçük harf duyarsız)
  ProvinceModel? getProvinceByName(String name) {
    try {
      return provinces.firstWhere(
        (province) => province.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Bölgeye göre illeri grupla
  Map<String, List<ProvinceModel>> get groupedByRegion {
    final Map<String, List<ProvinceModel>> grouped = {};
    
    for (final province in provinces) {
      final region = province.geographicRegion;
      grouped[region] = (grouped[region] ?? [])..add(province);
    }
    
    return grouped;
  }

  /// Büyükşehirleri listele
  List<ProvinceModel> get metropolitanCities {
    return provinces.where((province) => province.isMetropolitanCity).toList();
  }

  /// Normal illeri listele
  List<ProvinceModel> get regularCities {
    return provinces.where((province) => !province.isMetropolitanCity).toList();
  }

  /// Gelişmişlik seviyesine göre grupla
  Map<String, List<ProvinceModel>> get groupedByDevelopment {
    final Map<String, List<ProvinceModel>> grouped = {};
    
    for (final province in provinces) {
      final level = province.developmentLevel;
      grouped[level] = (grouped[level] ?? [])..add(province);
    }
    
    return grouped;
  }

  /// Nüfus kategorisine göre grupla
  Map<String, List<ProvinceModel>> get groupedByPopulation {
    final Map<String, List<ProvinceModel>> grouped = {};
    
    for (final province in provinces) {
      final category = province.populationCategory;
      grouped[category] = (grouped[category] ?? [])..add(province);
    }
    
    return grouped;
  }

  /// Alfabetik sıralama
  List<ProvinceModel> get sortedAlphabetically {
    final sorted = List<ProvinceModel>.from(provinces);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Plaka koduna göre sıralama
  List<ProvinceModel> get sortedByCode {
    final sorted = List<ProvinceModel>.from(provinces);
    sorted.sort((a, b) => a.code.compareTo(b.code));
    return sorted;
  }

  /// Arama fonksiyonu (il adı veya plaka kodu)
  List<ProvinceModel> search(String query) {
    if (query.isEmpty) return provinces;
    
    final lowerQuery = query.toLowerCase();
    return provinces.where((province) {
      return province.name.toLowerCase().contains(lowerQuery) ||
             province.formattedName.toLowerCase().contains(lowerQuery) ||
             province.code.toString().contains(query);
    }).toList();
  }

  /// Bölge istatistikleri
  Map<String, int> get regionStatistics {
    final stats = <String, int>{};
    
    for (final province in provinces) {
      final region = province.geographicRegion;
      stats[region] = (stats[region] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Büyükşehir/Normal il istatistikleri
  Map<String, int> get cityTypeStatistics {
    return {
      'Büyükşehir': metropolitanCities.length,
      'İl': regularCities.length,
    };
  }

  /// En büyük ve en küçük plaka kodları
  Map<String, ProvinceModel> get plateCodeExtremes {
    if (provinces.isEmpty) return {};
    
    final sorted = sortedByCode;
    return {
      'minimum': sorted.first,
      'maximum': sorted.last,
    };
  }

  /// Rastgele il seç
  ProvinceModel get randomProvince {
    if (provinces.isEmpty) throw StateError('Provinces list is empty');
    final random = DateTime.now().millisecondsSinceEpoch % provinces.length;
    return provinces[random];
  }

  /// Belirli bir bölgedeki illeri getir
  List<ProvinceModel> getProvincesByRegion(String region) {
    return provinces.where((province) => province.geographicRegion == region).toList();
  }

  /// Gelişmişlik seviyesine göre il sayısı
  Map<String, int> get developmentStatistics {
    final stats = <String, int>{};
    
    for (final province in provinces) {
      final level = province.developmentLevel;
      stats[level] = (stats[level] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Komşu iller (basit yakınlık tahmini - gerçek komşuluk için ayrı veri gerekli)
  List<ProvinceModel> getSimilarRegionProvinces(int provinceCode) {
    final province = getProvinceByCode(provinceCode);
    if (province == null) return [];
    
    return getProvincesByRegion(province.geographicRegion)
        .where((p) => p.code != provinceCode)
        .toList();
  }

  /// En popüler turistik iller
  List<ProvinceModel> get topTouristicProvinces {
    return provinces
        .where((province) => province.touristImportance == 'Çok Yüksek')
        .toList();
  }

  /// İstatistik özeti
  Map<String, dynamic> get statisticsSummary {
    return {
      'total_provinces': totalProvinces,
      'metropolitan_cities': metropolitanCities.length,
      'regular_cities': regularCities.length,
      'regions': regionStatistics,
      'development_levels': developmentStatistics,
      'city_types': cityTypeStatistics,
    };
  }
}
