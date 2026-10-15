class ProvincesDetailResponseModel {
  final List<DistrictModel> districts;

  ProvincesDetailResponseModel({
    required this.districts,
  });

  factory ProvincesDetailResponseModel.fromJson(List<dynamic> json) {
    return ProvincesDetailResponseModel(
      districts: json.map((e) => DistrictModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return districts.map((e) => e.toJson()).toList();
  }
}

class DistrictModel {
  final int code;
  final String name;
  final List<QuarterModel> quarters;

  DistrictModel({
    required this.code,
    required this.name,
    required this.quarters,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      code: json['code'] ?? 0,
      name: json['name'] ?? '',
      quarters: json['quarters'] != null
          ? (json['quarters'] as List).map((e) => QuarterModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'quarters': quarters.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DistrictModel && 
           other.code == code && 
           other.name == name;
  }

  @override
  int get hashCode => code.hashCode ^ name.hashCode;

  @override
  String toString() => 'DistrictModel(code: $code, name: $name, quarters: ${quarters.length})';
}

class QuarterModel {
  final int code;
  final String name;

  QuarterModel({
    required this.code,
    required this.name,
  });

  factory QuarterModel.fromJson(Map<String, dynamic> json) {
    return QuarterModel(
      code: json['code'] ?? 0,
      name: json['name'] ?? '',
    );
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
    return other is QuarterModel && other.code == code && other.name == name;
  }

  @override
  int get hashCode => code.hashCode ^ name.hashCode;

  @override
  String toString() => 'QuarterModel(code: $code, name: $name)';
}

// Helper Extension for DistrictModel
extension DistrictModelHelpers on DistrictModel {
  /// İlçe adını düzgün formatta göster (İlk harf büyük, geri kalanı küçük)
  String get formattedName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// İlçe adını title case formatında göster
  String get titleCaseName {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// İlçe kodu string olarak
  String get districtCode => code.toString();

  /// Toplam mahalle/köy sayısı
  int get totalQuarters => quarters.length;

  /// Merkez ilçe mi kontrolü
  bool get isCentralDistrict {
    return name.toLowerCase().contains('merkez');
  }

  /// İlçe tipi
  String get districtType {
    if (isCentralDistrict) return 'Merkez İlçe';
    if (totalQuarters > 50) return 'Büyük İlçe';
    if (totalQuarters > 20) return 'Orta İlçe';
    return 'Küçük İlçe';
  }

  /// Mahalle sayısı
  int get neighborhoodCount {
    return quarters.where((q) => q.isNeighborhood).length;
  }

  /// Köy sayısı
  int get villageCount {
    return quarters.where((q) => q.isVillage).length;
  }

  /// Belde sayısı
  int get townCount {
    return quarters.where((q) => q.isTown).length;
  }

  /// OSB sayısı
  int get osbCount {
    return quarters.where((q) => q.isOSB).length;
  }

  /// Mahalle tipine göre dağılım
  Map<String, int> get quarterTypeDistribution {
    return {
      'Mahalle': neighborhoodCount,
      'Köy': villageCount,
      'Belde': townCount,
      'OSB': osbCount,
    };
  }

  /// En uzun mahalle/köy adı
  QuarterModel? get longestQuarterName {
    if (quarters.isEmpty) return null;
    return quarters.reduce((a, b) => a.name.length > b.name.length ? a : b);
  }

  /// En kısa mahalle/köy adı
  QuarterModel? get shortestQuarterName {
    if (quarters.isEmpty) return null;
    return quarters.reduce((a, b) => a.name.length < b.name.length ? a : b);
  }

  /// Alfabetik ilk mahalle/köy
  QuarterModel? get firstAlphabetically {
    if (quarters.isEmpty) return null;
    final sorted = List<QuarterModel>.from(quarters);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted.first;
  }

  /// Alfabetik son mahalle/köy
  QuarterModel? get lastAlphabetically {
    if (quarters.isEmpty) return null;
    final sorted = List<QuarterModel>.from(quarters);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted.last;
  }

  /// İlçe büyüklük kategorisi
  String get sizeCategory {
    if (totalQuarters > 100) return 'Çok Büyük';
    if (totalQuarters > 50) return 'Büyük';
    if (totalQuarters > 20) return 'Orta';
    if (totalQuarters > 10) return 'Küçük';
    return 'Çok Küçük';
  }

  /// Kırsal/Kentsel dağılım yüzdesi
  Map<String, double> get ruralUrbanPercentage {
    if (totalQuarters == 0) return {'Kentsel': 0.0, 'Kırsal': 0.0};
    
    final urban = neighborhoodCount + townCount + osbCount;
    final rural = villageCount;
    
    return {
      'Kentsel': (urban / totalQuarters) * 100,
      'Kırsal': (rural / totalQuarters) * 100,
    };
  }

  /// Gelişmişlik tahmini (mahalle sayısına göre)
  String get developmentEstimate {
    final urbanPercentage = ruralUrbanPercentage['Kentsel'] ?? 0;
    
    if (urbanPercentage > 70) return 'Yüksek Gelişmiş';
    if (urbanPercentage > 40) return 'Orta Gelişmiş';
    if (urbanPercentage > 20) return 'Az Gelişmiş';
    return 'Kırsal Karakter';
  }

  /// İlçe emoji'si
  String get districtEmoji {
    if (isCentralDistrict) return '🏛️';
    if (developmentEstimate == 'Yüksek Gelişmiş') return '🏙️';
    if (developmentEstimate == 'Orta Gelişmiş') return '🏘️';
    if (villageCount > neighborhoodCount) return '🌾';
    return '🏞️';
  }

  /// İstatistik özeti
  Map<String, dynamic> get statistics {
    return {
      'total_quarters': totalQuarters,
      'neighborhoods': neighborhoodCount,
      'villages': villageCount,
      'towns': townCount,
      'osb': osbCount,
      'size_category': sizeCategory,
      'development_estimate': developmentEstimate,
      'urban_percentage': ruralUrbanPercentage['Kentsel'],
      'rural_percentage': ruralUrbanPercentage['Kırsal'],
    };
  }
}

// Helper Extension for QuarterModel
extension QuarterModelHelpers on QuarterModel {
  /// Mahalle/köy adını düzgün formatta göster
  String get formattedName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// Mahalle/köy adını title case formatında göster
  String get titleCaseName {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Mahalle mi kontrolü
  bool get isNeighborhood {
    return name.toLowerCase().contains('mah.') || 
           name.toLowerCase().contains('mh.') ||
           name.toLowerCase().contains('mahallesi');
  }

  /// Köy mü kontrolü
  bool get isVillage {
    return name.toLowerCase().contains('köyü');
  }

  /// Belde mi kontrolü
  bool get isTown {
    return name.toLowerCase().contains('bld.');
  }

  /// OSB mi kontrolü
  bool get isOSB {
    return name.toLowerCase().contains('osb');
  }

  /// Mahalle/köy tipi
  String get quarterType {
    if (isNeighborhood) return 'Mahalle';
    if (isVillage) return 'Köy';
    if (isTown) return 'Belde';
    if (isOSB) return 'OSB';
    return 'Diğer';
  }

  /// Mahalle/köy kodu string olarak
  String get quarterCode => code.toString();

  /// Temiz adı (Mh., Köyü vb. eklerini kaldırır)
  String get cleanName {
    String cleaned = name;
    
    // Mahalle eklerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s+(Mh\.|Mah\.|Mahallesi)$', caseSensitive: false), '');
    
    // Köy eklerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s+Köyü$', caseSensitive: false), '');
    
    // Belde eklerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s+Bld\.$', caseSensitive: false), '');
    
    // OSB eklerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s+OSB$', caseSensitive: false), '');
    
    return cleaned.trim();
  }

  /// Ad uzunluğu kategorisi
  String get nameLengthCategory {
    final length = name.length;
    if (length > 30) return 'Çok Uzun';
    if (length > 20) return 'Uzun';
    if (length > 15) return 'Orta';
    if (length > 10) return 'Kısa';
    return 'Çok Kısa';
  }

  /// Kelime sayısı
  int get wordCount {
    return name.trim().split(RegExp(r'\s+')).length;
  }

  /// Özel karakterler içeriyor mu
  bool get hasSpecialCharacters {
    return name.contains(RegExp(r'[^\w\s\u00C0-\u017F]'));
  }

  /// Sayı içeriyor mu
  bool get containsNumbers {
    return name.contains(RegExp(r'\d'));
  }

  /// Büyük harf sayısı
  int get uppercaseCount {
    return name.replaceAll(RegExp(r'[^A-ZİŞĞÜÖÇ]'), '').length;
  }

  /// Küçük harf sayısı
  int get lowercaseCount {
    return name.replaceAll(RegExp(r'[^a-zışğüöç]'), '').length;
  }

  /// Türkçe karakter içeriyor mu
  bool get hasTurkishCharacters {
    return name.contains(RegExp(r'[ışğüöçİŞĞÜÖÇ]'));
  }

  /// Mahalle/köy emoji'si
  String get quarterEmoji {
    if (isNeighborhood) return '🏘️';
    if (isVillage) return '🏞️';
    if (isTown) return '🏛️';
    if (isOSB) return '🏭';
    return '📍';
  }

  /// Renk kodu (tipe göre)
  String get typeColor {
    switch (quarterType) {
      case 'Mahalle':
        return '#3498db';  // Mavi
      case 'Köy':
        return '#27ae60';  // Yeşil
      case 'Belde':
        return '#f39c12';  // Turuncu
      case 'OSB':
        return '#e74c3c';  // Kırmızı
      default:
        return '#95a5a6';  // Gri
    }
  }

  /// Popülerlik tahmini (ad uzunluğuna göre ters orantılı)
  String get popularityEstimate {
    final length = cleanName.length;
    if (length < 8) return 'Çok Popüler';
    if (length < 12) return 'Popüler';
    if (length < 16) return 'Orta';
    if (length < 20) return 'Az Popüler';
    return 'Nadir';
  }

  /// Mahalle/köy bilgi özeti
  Map<String, dynamic> get info {
    return {
      'type': quarterType,
      'clean_name': cleanName,
      'word_count': wordCount,
      'length_category': nameLengthCategory,
      'popularity_estimate': popularityEstimate,
      'has_turkish_chars': hasTurkishCharacters,
      'contains_numbers': containsNumbers,
      'emoji': quarterEmoji,
      'color': typeColor,
    };
  }
}

// Helper Extension for ProvincesDetailResponseModel
extension ProvincesDetailResponseModelHelpers on ProvincesDetailResponseModel {
  /// Toplam ilçe sayısı
  int get totalDistricts => districts.length;

  /// Toplam mahalle/köy sayısı
  int get totalQuarters {
    return districts.fold(0, (sum, district) => sum + district.totalQuarters);
  }

  /// İlçe koduna göre ilçe bul
  DistrictModel? getDistrictByCode(int code) {
    try {
      return districts.firstWhere((district) => district.code == code);
    } catch (e) {
      return null;
    }
  }

  /// İlçe adına göre ilçe bul
  DistrictModel? getDistrictByName(String name) {
    try {
      return districts.firstWhere(
        (district) => district.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Mahalle/köy koduna göre bul
  QuarterModel? getQuarterByCode(int code) {
    for (final district in districts) {
      try {
        return district.quarters.firstWhere((quarter) => quarter.code == code);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Mahalle/köy adına göre bul (tüm ilçelerde ara)
  List<QuarterModel> getQuartersByName(String name) {
    final List<QuarterModel> result = [];
    
    for (final district in districts) {
      final matches = district.quarters.where(
        (quarter) => quarter.name.toLowerCase().contains(name.toLowerCase())
      );
      result.addAll(matches);
    }
    
    return result;
  }

  /// İlçe tipine göre grupla
  Map<String, List<DistrictModel>> get groupedByType {
    final Map<String, List<DistrictModel>> grouped = {};
    
    for (final district in districts) {
      final type = district.districtType;
      grouped[type] = (grouped[type] ?? [])..add(district);
    }
    
    return grouped;
  }

  /// Büyüklüğe göre grupla
  Map<String, List<DistrictModel>> get groupedBySize {
    final Map<String, List<DistrictModel>> grouped = {};
    
    for (final district in districts) {
      final size = district.sizeCategory;
      grouped[size] = (grouped[size] ?? [])..add(district);
    }
    
    return grouped;
  }

  /// Mahalle/köy tipine göre toplam sayılar
  Map<String, int> get quarterTypeStatistics {
    final stats = <String, int>{
      'Mahalle': 0,
      'Köy': 0,
      'Belde': 0,
      'OSB': 0,
    };
    
    for (final district in districts) {
      stats['Mahalle'] = (stats['Mahalle'] ?? 0) + district.neighborhoodCount;
      stats['Köy'] = (stats['Köy'] ?? 0) + district.villageCount;
      stats['Belde'] = (stats['Belde'] ?? 0) + district.townCount;
      stats['OSB'] = (stats['OSB'] ?? 0) + district.osbCount;
    }
    
    return stats;
  }

  /// En çok mahalle/köyü olan ilçeler
  List<DistrictModel> get largestDistricts {
    final sorted = List<DistrictModel>.from(districts);
    sorted.sort((a, b) => b.totalQuarters.compareTo(a.totalQuarters));
    return sorted.take(10).toList();
  }

  /// En az mahalle/köyü olan ilçeler
  List<DistrictModel> get smallestDistricts {
    final sorted = List<DistrictModel>.from(districts);
    sorted.sort((a, b) => a.totalQuarters.compareTo(b.totalQuarters));
    return sorted.take(10).toList();
  }

  /// Merkez ilçeler
  List<DistrictModel> get centralDistricts {
    return districts.where((district) => district.isCentralDistrict).toList();
  }

  /// Alfabetik sıralama (ilçeler)
  List<DistrictModel> get sortedDistrictsAlphabetically {
    final sorted = List<DistrictModel>.from(districts);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// İlçe koduna göre sıralama
  List<DistrictModel> get sortedDistrictsByCode {
    final sorted = List<DistrictModel>.from(districts);
    sorted.sort((a, b) => a.code.compareTo(b.code));
    return sorted;
  }

  /// Arama fonksiyonu (ilçe adı veya kodu)
  List<DistrictModel> searchDistricts(String query) {
    if (query.isEmpty) return districts;
    
    final lowerQuery = query.toLowerCase();
    return districts.where((district) {
      return district.name.toLowerCase().contains(lowerQuery) ||
             district.formattedName.toLowerCase().contains(lowerQuery) ||
             district.code.toString().contains(query);
    }).toList();
  }

  /// Mahalle/köy arama (tüm ilçelerde)
  List<Map<String, dynamic>> searchQuarters(String query) {
    if (query.isEmpty) return [];
    
    final List<Map<String, dynamic>> results = [];
    final lowerQuery = query.toLowerCase();
    
    for (final district in districts) {
      final matchingQuarters = district.quarters.where((quarter) {
        return quarter.name.toLowerCase().contains(lowerQuery) ||
               quarter.cleanName.toLowerCase().contains(lowerQuery) ||
               quarter.code.toString().contains(query);
      });
      
      for (final quarter in matchingQuarters) {
        results.add({
          'quarter': quarter,
          'district': district,
          'full_address': '${quarter.name}, ${district.name}',
        });
      }
    }
    
    return results;
  }

  /// İlçe büyüklük istatistikleri
  Map<String, int> get districtSizeStatistics {
    final stats = <String, int>{};
    
    for (final district in districts) {
      final size = district.sizeCategory;
      stats[size] = (stats[size] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Gelişmişlik istatistikleri
  Map<String, int> get developmentStatistics {
    final stats = <String, int>{};
    
    for (final district in districts) {
      final development = district.developmentEstimate;
      stats[development] = (stats[development] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Ortalama mahalle/köy sayısı
  double get averageQuartersPerDistrict {
    if (districts.isEmpty) return 0.0;
    return totalQuarters / districts.length;
  }

  /// En uzun adlı ilçe
  DistrictModel? get longestDistrictName {
    if (districts.isEmpty) return null;
    return districts.reduce((a, b) => a.name.length > b.name.length ? a : b);
  }

  /// En kısa adlı ilçe
  DistrictModel? get shortestDistrictName {
    if (districts.isEmpty) return null;
    return districts.reduce((a, b) => a.name.length < b.name.length ? a : b);
  }

  /// Rastgele ilçe seç
  DistrictModel get randomDistrict {
    if (districts.isEmpty) throw StateError('Districts list is empty');
    final random = DateTime.now().millisecondsSinceEpoch % districts.length;
    return districts[random];
  }

  /// Rastgele mahalle/köy seç
  Map<String, dynamic> get randomQuarter {
    if (districts.isEmpty) throw StateError('Districts list is empty');
    
    final randomDistrict = districts[DateTime.now().millisecondsSinceEpoch % districts.length];
    if (randomDistrict.quarters.isEmpty) throw StateError('No quarters in district');
    
    final randomQuarter = randomDistrict.quarters[DateTime.now().millisecondsSinceEpoch % randomDistrict.quarters.length];
    
    return {
      'quarter': randomQuarter,
      'district': randomDistrict,
      'full_address': '${randomQuarter.name}, ${randomDistrict.name}',
    };
  }

  /// Kırsal/kentsel genel dağılım
  Map<String, double> get overallRuralUrbanPercentage {
    if (totalQuarters == 0) return {'Kentsel': 0.0, 'Kırsal': 0.0};
    
    final stats = quarterTypeStatistics;
    final urban = (stats['Mahalle'] ?? 0) + (stats['Belde'] ?? 0) + (stats['OSB'] ?? 0);
    final rural = stats['Köy'] ?? 0;
    
    return {
      'Kentsel': (urban / totalQuarters) * 100,
      'Kırsal': (rural / totalQuarters) * 100,
    };
  }

  /// Belirli tipteki mahalle/köyleri getir
  List<Map<String, dynamic>> getQuartersByType(String type) {
    final List<Map<String, dynamic>> results = [];
    
    for (final district in districts) {
      final quarters = district.quarters.where((quarter) => quarter.quarterType == type);
      
      for (final quarter in quarters) {
        results.add({
          'quarter': quarter,
          'district': district,
          'full_address': '${quarter.name}, ${district.name}',
        });
      }
    }
    
    return results;
  }

  /// İstatistik özeti
  Map<String, dynamic> get statisticsSummary {
    return {
      'total_districts': totalDistricts,
      'total_quarters': totalQuarters,
      'average_quarters_per_district': averageQuartersPerDistrict,
      'central_districts': centralDistricts.length,
      'quarter_types': quarterTypeStatistics,
      'district_sizes': districtSizeStatistics,
      'development_levels': developmentStatistics,
      'rural_urban_distribution': overallRuralUrbanPercentage,
      'largest_district': largestDistricts.isNotEmpty ? largestDistricts.first.name : null,
      'smallest_district': smallestDistricts.isNotEmpty ? smallestDistricts.first.name : null,
    };
  }

  /// En popüler mahalle/köy isimleri (tekrar sayısına göre)
  Map<String, int> get mostCommonQuarterNames {
    final Map<String, int> nameCount = {};
    
    for (final district in districts) {
      for (final quarter in district.quarters) {
        final cleanName = quarter.cleanName;
        nameCount[cleanName] = (nameCount[cleanName] ?? 0) + 1;
      }
    }
    
    // En çok tekrar edenleri al (en az 3 kez geçen)
    final common = Map<String, int>.fromEntries(
      nameCount.entries.where((entry) => entry.value >= 3)
    );
    
    // Sırala
    final sortedEntries = common.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map<String, int>.fromEntries(sortedEntries.take(20));
  }

  /// Belirli kelimeyi içeren mahalle/köyler
  List<Map<String, dynamic>> getQuartersContaining(String keyword) {
    final List<Map<String, dynamic>> results = [];
    final lowerKeyword = keyword.toLowerCase();
    
    for (final district in districts) {
      final quarters = district.quarters.where((quarter) => 
        quarter.cleanName.toLowerCase().contains(lowerKeyword)
      );
      
      for (final quarter in quarters) {
        results.add({
          'quarter': quarter,
          'district': district,
          'full_address': '${quarter.name}, ${district.name}',
        });
      }
    }
    
    return results;
  }
}
