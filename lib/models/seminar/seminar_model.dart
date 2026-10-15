import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/utils/image_utils.dart';

class SeminarMedia {
  final String hd;
  final String standart;
  final String thumbnail;
  final bool isCover;
  final int sequenceNo;

  SeminarMedia({
    required this.hd,
    required this.standart,
    required this.thumbnail,
    required this.isCover,
    required this.sequenceNo,
  });

  factory SeminarMedia.fromJson(Map<String, dynamic> json) {
    final file = _firstString(json, const [
          'hd',
          'standart',
          'standard',
          'thumbnail',
          'url',
          'path',
          'name',
          'file',
          'key',
        ]) ??
        '';
    return SeminarMedia(
      hd: _asString(json['hd']) ?? file,
      standart: _asString(json['standart']) ??
          _asString(json['standard']) ??
          file,
      thumbnail: _asString(json['thumbnail']) ?? file,
      isCover: _asBool(json['is_cover']) ||
          _asBool(json['isCover']) ||
          _asBool(json['cover']),
      sequenceNo: _asInt(json['sequence_no'] ?? json['sequenceNo'] ?? json['order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hd': hd,
      'standart': standart,
      'thumbnail': thumbnail,
      'is_cover': isCover,
      'sequence_no': sequenceNo,
    };
  }
}

class Seminar {
  final int id;
  final String title;
  final String? caption1;
  final String? caption2;
  final String? caption3;
  final String instructor;
  final String? instructor1;
  final String? instructor2;
  final String? instructor3;
  final String? instructor4;
  final String? instructor5;
  final int city;
  final int district;
  final String address;
  final String organizationHotelName;
  final String directions;
  final DateTime date;
  final int status;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SeminarMedia> medias;
  final String districtText;
  final bool firstSeminar;

  /// Yeni API: `event` | `education`
  final String? type;
  final DateTime? applicationStart;
  final DateTime? applicationEnd;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final int quota;
  final int applicationCount;
  final bool isFree;
  final String? coverUrl;
  final double? price;
  final List<String> extraInstructors;

  Seminar({
    required this.id,
    required this.title,
    this.caption1,
    this.caption2,
    this.caption3,
    required this.instructor,
    this.instructor1,
    this.instructor2,
    this.instructor3,
    this.instructor4,
    this.instructor5,
    required this.city,
    required this.district,
    required this.address,
    required this.organizationHotelName,
    required this.directions,
    required this.date,
    required this.status,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.medias,
    required this.districtText,
    required this.firstSeminar,
    this.type,
    this.applicationStart,
    this.applicationEnd,
    this.eventStart,
    this.eventEnd,
    this.quota = 0,
    this.applicationCount = 0,
    this.isFree = true,
    this.coverUrl,
    this.price,
    this.extraInstructors = const [],
  });

  factory Seminar.fromJson(Map<String, dynamic> json, {String? fallbackType}) {
    final eventStart = _firstDate(json, const [
      'seminar_start_date',
      'seminar_start',
      'event_start',
      'eventStart',
      'start_time',
      'startTime',
      'date',
    ]);
    final eventEnd = _firstDate(json, const [
      'seminar_end_date',
      'seminar_end',
      'event_end',
      'eventEnd',
      'end_time',
      'endTime',
    ]);
    final applicationStart = _firstDate(json, const [
      'application_start_date',
      'application_start',
      'applicationStart',
      'apply_start',
      'registration_start',
      'start_date',
    ]);
    final applicationEnd = _firstDate(json, const [
      'application_end_date',
      'application_end',
      'applicationEnd',
      'apply_end',
      'registration_end',
      'end_date',
    ]);
    final date = eventStart ??
        _parseDateTime(json['date']) ??
        applicationStart ??
        DateTime.now();

    final mediaList = _asList(json['medias'] ?? json['media'] ?? json['images']);
    final coverUrl = _firstString(json, const [
      'cover',
      'cover_picture',
      'coverPicture',
      'cover_url',
      'coverUrl',
      'image',
      'image_url',
      'imageUrl',
      'picture',
      'banner',
    ]);

    final priceRaw = json['price'] ?? json['fee'] ?? json['amount'];
    final parsedPrice = priceRaw == null ? null : _asNum(priceRaw);
    final extraInstructors = _parseInstructorList(
      json['instructors'] ?? json['trainers'] ?? json['speakers'],
    );
    final explicitPaid = _asBool(json['is_paid']) ||
        _asBool(json['isPaid']) ||
        _asBool(json['paid']);
    final isFree = explicitPaid
        ? false
        : (json.containsKey('is_free') ||
                json.containsKey('isFree') ||
                json.containsKey('free')
            ? (_asBool(json['is_free']) ||
                _asBool(json['isFree']) ||
                _asBool(json['free']))
            : (parsedPrice == null || parsedPrice == 0));

    return Seminar(
      id: _asInt(json['seminar_id'] ?? json['id']),
      title: _firstString(json, const ['title', 'name']) ?? '',
      caption1: _firstString(json, const [
        'caption_1',
        'caption1',
        'slogan',
        'caption',
        'description',
        'subtitle',
      ]),
      caption2: _asString(json['caption_2'] ?? json['caption2']),
      caption3: _asString(json['caption_3'] ?? json['caption3']),
      instructor: _firstString(json, const [
            'instructor',
            'trainer',
            'speaker',
          ]) ??
          '',
      instructor1: _asString(json['instructor_1'] ?? json['instructor1']),
      instructor2: _asString(json['instructor_2'] ?? json['instructor2']),
      instructor3: _asString(json['instructor_3'] ?? json['instructor3']),
      instructor4: _asString(json['instructor_4'] ?? json['instructor4']),
      instructor5: _asString(json['instructor_5'] ?? json['instructor5']),
      city: _asInt(json['city']),
      district: _asInt(json['district']),
      address: _firstString(json, const ['address', 'full_address']) ?? '',
      organizationHotelName: _firstString(json, const [
            'organization_hotel_name',
            'organizationHotelName',
            'hotel',
            'location',
            'venue',
            'place',
          ]) ??
          '',
      directions: _firstString(json, const [
            'directions',
            'location_info',
            'locationInfo',
          ]) ??
          '',
      date: date,
      status: _asInt(json['status'], defaultValue: 1),
      order: _asInt(json['order'] ?? json['sequence']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
      medias: mediaList
          .whereType<Map>()
          .map((item) => SeminarMedia.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      districtText: _firstString(json, const [
            'district_text',
            'districtText',
            'city_text',
            'cityText',
          ]) ??
          '',
      firstSeminar: _asBool(json['first_seminar']) ||
          _asBool(json['firstSeminar']) ||
          _asBool(json['featured']),
      type: (_asString(json['type'] ?? json['seminar_type'] ?? json['seminarType']) ??
              fallbackType)
          ?.toLowerCase(),
      applicationStart: applicationStart,
      applicationEnd: applicationEnd,
      eventStart: eventStart ?? date,
      eventEnd: eventEnd,
      quota: _asInt(
        json['application_limit'] ??
            json['quota'] ??
            json['capacity'] ??
            json['max_participants'] ??
            json['maxParticipants'] ??
            json['limit'] ??
            json['max_count'],
      ),
      applicationCount: _asInt(
        json['application_count'] ??
            json['applicationCount'] ??
            json['applicant_count'] ??
            json['applicantCount'] ??
            json['current_count'] ??
            json['registered_count'] ??
            json['applications'],
      ),
      isFree: isFree,
      coverUrl: coverUrl,
      price: parsedPrice,
      extraInstructors: extraInstructors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'caption_1': caption1,
      'caption_2': caption2,
      'caption_3': caption3,
      'instructor': instructor,
      'instructor_1': instructor1,
      'instructor_2': instructor2,
      'instructor_3': instructor3,
      'instructor_4': instructor4,
      'instructor_5': instructor5,
      'city': city,
      'district': district,
      'address': address,
      'organization_hotel_name': organizationHotelName,
      'directions': directions,
      'date': date.toIso8601String(),
      'status': status,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'medias': medias.map((m) => m.toJson()).toList(),
      'district_text': districtText,
      'first_seminar': firstSeminar,
      'type': type,
      'application_start': applicationStart?.toIso8601String(),
      'application_end': applicationEnd?.toIso8601String(),
      'event_start': eventStart?.toIso8601String(),
      'event_end': eventEnd?.toIso8601String(),
      'quota': quota,
      'application_count': applicationCount,
      'is_free': isFree,
      'cover': coverUrl,
      'price': price,
      'instructors': extraInstructors,
    };
  }

  bool get isActive => status == 1;
  bool get isPassive => status == 0;

  String get statusText => isActive ? 'Aktif' : 'Pasif';

  String get slogan => caption1?.trim() ?? '';

  String get locationLabel {
    if (organizationHotelName.trim().isNotEmpty) return organizationHotelName.trim();
    if (districtText.trim().isNotEmpty) return districtText.trim();
    return address;
  }

  bool get isEvent => type == 'event';
  bool get isEducation => type == 'education';

  String get typeLabel {
    if (isEducation) return 'Eğitim';
    if (isEvent) return 'Etkinlik';
    return 'Seminer';
  }

  String get priceBadgeLabel {
    if (isFree || price == null || price == 0) return 'Ücretsiz';
    return 'Ücretli - ${_formatPrice(price!)}';
  }

  DateTime get displayEventStart => eventStart ?? date;
  DateTime? get displayEventEnd => eventEnd;

  bool get isApplicationNotStarted {
    final start = applicationStart;
    if (start == null) return false;
    return DateTime.now().isBefore(start);
  }

  bool get isApplicationPassed {
    final end = applicationEnd;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  bool get isQuotaFull => quota > 0 && applicationCount >= quota;

  bool get canApply =>
      isActive && !isApplicationPassed && !isApplicationNotStarted && !isQuotaFull;

  String get ctaLabel {
    if (isApplicationPassed) return 'Başvuru tarihi geçti';
    if (isQuotaFull) return 'Kontenjan doldu';
    if (isApplicationNotStarted) return 'Başvuru henüz başlamadı';
    if (!isActive) return 'Başvuru kapalı';
    return 'Başvur';
  }

  double get quotaProgress {
    if (quota <= 0) return 0;
    return (applicationCount / quota).clamp(0, 1).toDouble();
  }

  String get coverImageUrl {
    final resolved = resolvedCoverUrl;
    if (resolved == null || resolved.isEmpty) return '';
    return resolved;
  }

  String? get resolvedCoverUrl {
    final candidates = <String>[];
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      candidates.add(coverUrl!.trim());
    }
    if (medias.isNotEmpty) {
      final cover = medias.firstWhere(
        (m) => m.isCover,
        orElse: () => medias.first,
      );
      for (final path in [cover.hd, cover.standart, cover.thumbnail]) {
        if (path.trim().isNotEmpty) candidates.add(path.trim());
      }
    }

    for (final raw in candidates) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }
      if (raw.startsWith('/api/retrieve-file') || raw.contains('retrieve-file')) {
        final host = dotenv.env['NEXT_PUBLIC_HOST'] ?? EnvApi.origin;
        return raw.startsWith('http')
            ? raw
            : '$host${raw.startsWith('/') ? raw : '/$raw'}';
      }
      if (raw.contains('/')) {
        final origin = EnvApi.webNextApiOrigin ?? EnvApi.origin;
        return raw.startsWith('/') ? '$origin$raw' : '$origin/$raw';
      }

      final host = dotenv.env['NEXT_PUBLIC_HOST'] ?? ImageUtils.imageHost;
      final normalizedHost = host.replaceAll(RegExp(r'/$'), '');
      return '$normalizedHost/api/retrieve-file/?name=$raw';
    }
    return null;
  }

  String get orderText => order > 0 ? order.toString() : '-';

  String get firstSeminarText => firstSeminar ? 'İlk Sırada Gösteriliyor' : '-';

  List<String> get instructors {
    final fromFields = [
      instructor,
      instructor1,
      instructor2,
      instructor3,
      instructor4,
      instructor5,
      ...extraInstructors,
    ]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final unique = <String>[];
    final seen = <String>{};
    for (final name in fromFields) {
      final key = name.toLowerCase();
      if (seen.add(key)) unique.add(name);
    }

    if (unique.length == 1 && unique.first.contains(',')) {
      return unique.first
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return unique;
  }

  String get instructorsText => instructors.join(', ');
}

class SeminarResponse {
  final List<Seminar> data;
  final int totalCount;
  final int page;
  final int pageSize;

  SeminarResponse({
    required this.data,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory SeminarResponse.fromJson(Map<String, dynamic> json, {String? fallbackType}) {
    final nested = json['data'];
    Map<String, dynamic> root = json;
    if (nested is Map<String, dynamic>) {
      root = nested;
    }

    final rawList = root['seminar'] ??
        json['seminar'] ??
        root['seminars'] ??
        json['seminars'] ??
        root['data'] ??
        root['items'] ??
        root['results'] ??
        (nested is List ? nested : null) ??
        json['items'];

    final items = <Seminar>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        try {
          items.add(Seminar.fromJson(
            Map<String, dynamic>.from(item),
            fallbackType: fallbackType,
          ));
        } catch (e) {
          print('⚠️ Seminar parse atlandı: $e');
        }
      }
    }

    final page = _asInt(root['page'] ?? json['page'], defaultValue: 1);
    final pageSize = _asInt(
      root['pageSize'] ??
          json['pageSize'] ??
          root['page_size'] ??
          json['limit'] ??
          json['_pageSize'],
      defaultValue: items.isEmpty ? 10 : items.length,
    );
    final totalCount = _asInt(
      root['totalCount'] ??
          json['totalCount'] ??
          root['total'] ??
          json['total'] ??
          root['count'],
      defaultValue: items.length,
    );

    return SeminarResponse(
      data: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((s) => s.toJson()).toList(),
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
    };
  }

  bool get hasMore => data.length < totalCount;
}

int _asInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _asNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value) {
  if (value == true || value == 1 || value == '1' || value == 'true') {
    return true;
  }
  return false;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _asString(json[key]);
    if (value != null) return value;
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _parseDateTime(json[key]);
    if (value != null) return value;
  }
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

List<String> _parseInstructorList(dynamic value) {
  if (value is! List) return const [];
  final names = <String>[];
  for (final item in value) {
    if (item is String && item.trim().isNotEmpty) {
      names.add(item.trim());
      continue;
    }
    if (item is Map) {
      final name = item['name'] ??
          item['title'] ??
          item['full_name'] ??
          item['fullName'] ??
          item['instructor'];
      if (name != null && name.toString().trim().isNotEmpty) {
        names.add(name.toString().trim());
      }
    }
  }
  return names;
}

String _formatPrice(double value) {
  final raw = value.toStringAsFixed(2);
  final parts = raw.split('.');
  final whole = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write('.');
    buffer.write(whole[i]);
  }
  buffer.write(',${parts[1]} TL');
  return buffer.toString();
}
