import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Saha ziyareti. API bağlanınca aynı alanlarla repository'den gelecek.
class FieldVisit {
  final String id;
  final String provinceId;
  final String districtId;
  final String neighborhoodId;
  final String officeName;
  final String personName;
  final int score;
  final List<String> notes;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final String createdByTitle;
  final String? ilName;
  final String? ilceName;
  final String? mahalleName;

  const FieldVisit({
    required this.id,
    required this.provinceId,
    required this.districtId,
    required this.neighborhoodId,
    required this.officeName,
    required this.personName,
    required this.score,
    required this.notes,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.createdByTitle = '',
    this.ilName,
    this.ilceName,
    this.mahalleName,
  });

  LatLng get point => LatLng(lat, lng);

  FieldVisit copyWith({
    String? officeName,
    String? personName,
    int? score,
    List<String>? notes,
    double? lat,
    double? lng,
  }) {
    return FieldVisit(
      id: id,
      provinceId: provinceId,
      districtId: districtId,
      neighborhoodId: neighborhoodId,
      officeName: officeName ?? this.officeName,
      personName: personName ?? this.personName,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt,
      createdByTitle: createdByTitle,
      ilName: ilName,
      ilceName: ilceName,
      mahalleName: mahalleName,
    );
  }

  factory FieldVisit.fromApi(
    Map<String, dynamic> json, {
    String? ilName,
    String? ilceName,
    String? mahalleName,
  }) {
    final cityCode = _asInt(json['city_code']);
    final districtCode = _asInt(json['district_code']);
    final quarterCode = _asInt(json['quarter_code']);
    final notesRaw = json['notes'];
    final notes = notesRaw is List
        ? notesRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    return FieldVisit(
      id: '${json['id']}',
      provinceId: cityCode == null ? '' : cityCode.toString().padLeft(2, '0'),
      districtId: districtCode?.toString() ?? '',
      neighborhoodId: quarterCode?.toString() ?? '',
      officeName: (json['office_name'] ?? '').toString(),
      personName: (json['met_person'] ?? '').toString(),
      score: _asInt(json['score']) ?? 0,
      notes: notes,
      lat: _asDouble(json['lat']) ?? 0,
      lng: _asDouble(json['lon']) ?? 0,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      createdByTitle: (json['created_by_title'] ?? '').toString(),
      ilName: ilName,
      ilceName: ilceName,
      mahalleName: mahalleName,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

class GeoNode {
  final String id;
  final String name;
  final String? parentId;
  final double lat;
  final double lng;

  const GeoNode({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.parentId,
  });

  LatLng get point => LatLng(lat, lng);
}

/// Yerel katalog. İl / ilçe / mahalle ağacı ve örnek ziyaretler.
/// Endpoint gelince bu sınıfın yerini repository alacak.
class FranchiseMapCatalog {
  FranchiseMapCatalog._();

  static const turkey = LatLng(39.05, 35.15);

  static const List<GeoNode> provinces = [
    GeoNode(id: '34', name: 'İstanbul', lat: 41.015, lng: 28.979),
    GeoNode(id: '06', name: 'Ankara', lat: 39.920, lng: 32.854),
    GeoNode(id: '35', name: 'İzmir', lat: 38.419, lng: 27.129),
    GeoNode(id: '16', name: 'Bursa', lat: 40.195, lng: 29.061),
    GeoNode(id: '07', name: 'Antalya', lat: 36.897, lng: 30.713),
    GeoNode(id: '41', name: 'Kocaeli', lat: 40.765, lng: 29.940),
    GeoNode(id: '54', name: 'Sakarya', lat: 40.694, lng: 30.435),
    GeoNode(id: '59', name: 'Tekirdağ', lat: 40.978, lng: 27.511),
    GeoNode(id: '22', name: 'Edirne', lat: 41.677, lng: 26.556),
    GeoNode(id: '39', name: 'Kırklareli', lat: 41.735, lng: 27.225),
    GeoNode(id: '77', name: 'Yalova', lat: 40.650, lng: 29.267),
    GeoNode(id: '10', name: 'Balıkesir', lat: 39.648, lng: 27.883),
    GeoNode(id: '17', name: 'Çanakkale', lat: 40.147, lng: 26.409),
    GeoNode(id: '48', name: 'Muğla', lat: 37.215, lng: 28.364),
    GeoNode(id: '09', name: 'Aydın', lat: 37.844, lng: 27.846),
    GeoNode(id: '20', name: 'Denizli', lat: 37.776, lng: 29.086),
    GeoNode(id: '26', name: 'Eskişehir', lat: 39.777, lng: 30.521),
    GeoNode(id: '42', name: 'Konya', lat: 37.874, lng: 32.493),
    GeoNode(id: '01', name: 'Adana', lat: 37.000, lng: 35.321),
    GeoNode(id: '27', name: 'Gaziantep', lat: 37.066, lng: 37.383),
    GeoNode(id: '61', name: 'Trabzon', lat: 41.003, lng: 39.717),
    GeoNode(id: '55', name: 'Samsun', lat: 41.286, lng: 36.330),
    GeoNode(id: '38', name: 'Kayseri', lat: 38.731, lng: 35.478),
    GeoNode(id: '21', name: 'Diyarbakır', lat: 37.914, lng: 40.231),
    GeoNode(id: '33', name: 'Mersin', lat: 36.812, lng: 34.641),
  ];

  static const List<GeoNode> districts = [
    GeoNode(id: '34-kadikoy', name: 'Kadıköy', parentId: '34', lat: 40.981, lng: 29.028),
    GeoNode(id: '34-besiktas', name: 'Beşiktaş', parentId: '34', lat: 41.043, lng: 29.007),
    GeoNode(id: '34-sisli', name: 'Şişli', parentId: '34', lat: 41.060, lng: 28.987),
    GeoNode(id: '34-uskudar', name: 'Üsküdar', parentId: '34', lat: 41.027, lng: 29.016),
    GeoNode(id: '34-sile', name: 'Şile', parentId: '34', lat: 41.175, lng: 29.613),
    GeoNode(id: '34-sariyer', name: 'Sarıyer', parentId: '34', lat: 41.167, lng: 29.057),
    GeoNode(id: '34-beykoz', name: 'Beykoz', parentId: '34', lat: 41.135, lng: 29.092),
    GeoNode(id: '34-pendik', name: 'Pendik', parentId: '34', lat: 40.878, lng: 29.233),
    GeoNode(id: '34-atasehir', name: 'Ataşehir', parentId: '34', lat: 40.983, lng: 29.127),
    GeoNode(id: '34-maltepe', name: 'Maltepe', parentId: '34', lat: 40.935, lng: 29.131),
    GeoNode(id: '34-fatih', name: 'Fatih', parentId: '34', lat: 41.019, lng: 28.949),
    GeoNode(id: '34-beyoglu', name: 'Beyoğlu', parentId: '34', lat: 41.037, lng: 28.977),
    GeoNode(id: '34-bakirkoy', name: 'Bakırköy', parentId: '34', lat: 40.980, lng: 28.872),
    GeoNode(id: '34-kartal', name: 'Kartal', parentId: '34', lat: 40.888, lng: 29.186),
    GeoNode(id: '34-cekmekoy', name: 'Çekmeköy', parentId: '34', lat: 41.033, lng: 29.182),
    GeoNode(id: '34-umraniye', name: 'Ümraniye', parentId: '34', lat: 41.016, lng: 29.124),
  ];

  static const List<GeoNode> neighborhoods = [
    GeoNode(id: '34-sile-agacdere', name: 'Ağaçdere', parentId: '34-sile', lat: 41.198, lng: 29.662),
    GeoNode(id: '34-sile-balibey', name: 'Balibey', parentId: '34-sile', lat: 41.176, lng: 29.609),
    GeoNode(id: '34-sile-cavus', name: 'Çavuş', parentId: '34-sile', lat: 41.186, lng: 29.642),
    GeoNode(id: '34-sile-hacikasim', name: 'Hacıkasım', parentId: '34-sile', lat: 41.163, lng: 29.588),
    GeoNode(id: '34-sile-kumbaba', name: 'Kumbaba', parentId: '34-sile', lat: 41.169, lng: 29.628),
    GeoNode(id: '34-kadikoy-caferaga', name: 'Caferağa', parentId: '34-kadikoy', lat: 40.990, lng: 29.026),
    GeoNode(id: '34-kadikoy-moda', name: 'Moda', parentId: '34-kadikoy', lat: 40.980, lng: 29.025),
    GeoNode(id: '34-kadikoy-fenerbahce', name: 'Fenerbahçe', parentId: '34-kadikoy', lat: 40.970, lng: 29.037),
    GeoNode(id: '34-pendik-kaynarca', name: 'Kaynarca', parentId: '34-pendik', lat: 40.883, lng: 29.255),
    GeoNode(id: '34-pendik-bati', name: 'Batı', parentId: '34-pendik', lat: 40.876, lng: 29.228),
    GeoNode(id: '34-pendik-yesilbaglar', name: 'Yeşilbağlar', parentId: '34-pendik', lat: 40.890, lng: 29.236),
    GeoNode(id: '34-sariyer-yenikoy', name: 'Yeniköy', parentId: '34-sariyer', lat: 41.122, lng: 29.070),
    GeoNode(id: '34-sariyer-tarabya', name: 'Tarabya', parentId: '34-sariyer', lat: 41.136, lng: 29.054),
    GeoNode(id: '34-sariyer-istinye', name: 'İstinye', parentId: '34-sariyer', lat: 41.116, lng: 29.054),
  ];

  static List<GeoNode> childrenOf(String? parentId, List<GeoNode> nodes) {
    return nodes.where((n) => n.parentId == parentId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static GeoNode? find(String? id, List<GeoNode> nodes) {
    if (id == null) return null;
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  static List<FieldVisit> seedVisits() {
    final now = DateTime.now();
    return [
      FieldVisit(
        id: 'v-agacdere',
        provinceId: '34',
        districtId: '34-sile',
        neighborhoodId: '34-sile-agacdere',
        officeName: 'Kadıköy Ofisi',
        personName: 'Ayşe Yılmaz',
        score: 3,
        notes: const ['Köy meydanı görüşmesi', 'Tabela ihtiyacı var'],
        lat: 41.1992,
        lng: 29.6604,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FieldVisit(
        id: 'v-moda',
        provinceId: '34',
        districtId: '34-kadikoy',
        neighborhoodId: '34-kadikoy-moda',
        officeName: 'Moda Sahil',
        personName: 'Kerem Acar',
        score: 5,
        notes: const ['Franchise ilgisi yüksek'],
        lat: 40.9794,
        lng: 29.0248,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      FieldVisit(
        id: 'v-kaynarca',
        provinceId: '34',
        districtId: '34-pendik',
        neighborhoodId: '34-pendik-kaynarca',
        officeName: 'Pendik Merkez',
        personName: 'Selin Koç',
        score: 2,
        notes: const ['Ulaşım notu alındı'],
        lat: 40.8841,
        lng: 29.2562,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      FieldVisit(
        id: 'v-yenikoy',
        provinceId: '34',
        districtId: '34-sariyer',
        neighborhoodId: '34-sariyer-yenikoy',
        officeName: 'Yeniköy',
        personName: 'Deniz Usta',
        score: 4,
        notes: const ['İkinci görüşme planlandı'],
        lat: 41.1216,
        lng: 29.0711,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }
}

Color scoreColor(num? score) {
  if (score == null) return const Color(0xFFD0D5DD);
  if (score < 1.5) return const Color(0xFFEE2E24);
  if (score < 2.5) return const Color(0xFFF97316);
  if (score < 3.5) return const Color(0xFFF5B301);
  if (score < 4.5) return const Color(0xFF84CC16);
  return const Color(0xFF16A34A);
}
