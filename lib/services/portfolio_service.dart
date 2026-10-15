import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import '../core/network/dio_client.dart';
import '../core/config/api_config.dart';
import '../core/config/env_api.dart';
import '../models/portfolio/property_attribute.dart';
import '../models/portfolio/category.dart';
import '../models/portfolio/category_listing_type.dart';
import '../models/province/province.dart';

/// Service for managing portfolio-related API calls
/// Uses the app's DioClient for consistent network handling
class PortfolioService {
  final DioClient _dioClient = DioClient();
  final ContactApiRepository _contactUpload = ContactApiRepository();

  /// Next `get-upload-url` + doğrudan S3 PUT (kişi yükleme ile aynı). Üç JPEG varyant = web `imageToBundle` mantığı.
  Future<Map<String, String>?> _uploadPortfolioImageViaS3(File imageFile) async {
    final raw = await imageFile.readAsBytes();
    img.Image? decoded;
    try {
      decoded = img.decodeImage(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      debugPrint(
          '⚠️ S3 görsel: decode başarısız (HEIC/desteklenmeyen), upload-image fallback');
      return null;
    }

    img.Image resizeMax(img.Image src, int maxW) {
      if (src.width <= maxW) return src;
      return img.copyResize(src, width: maxW, interpolation: img.Interpolation.linear);
    }

    final thumbImg = resizeMax(decoded, 400);
    final stdImg = resizeMax(decoded, 1200);
    final hdImg = resizeMax(decoded, 2048);

    Future<String?> putJpeg(img.Image image, int quality) async {
      final jpg = img.encodeJpg(image, quality: quality);
      return _contactUpload.tryPresignedS3UploadBytes(
        bytes: jpg,
        mimeType: 'image/jpeg',
      );
    }

    final t = await putJpeg(thumbImg, 78);
    final s = await putJpeg(stdImg, 82);
    final h = await putJpeg(hdImg, 85);

    if (t == null || t.isEmpty || s == null || s.isEmpty || h == null || h.isEmpty) {
      debugPrint('⚠️ S3 görsel: presign veya PUT eksik, upload-image fallback');
      return null;
    }
    debugPrint('✅ Görsel S3 (presign): thumbnail + standart + hd');
    return {
      'thumbnail': t,
      'standart': s,
      'hd': h,
    };
  }

  /// BAMMA / Next gateway: `X-SESSION` (+ API anahtarları). Bearer eklenmesin diye burada set edilir.
  Future<Map<String, String>> _bammaAuthHeaders() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('userJWT') ?? pref.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    final apiKey = dotenv.env['X_API_KEY']?.trim();
    final appId = dotenv.env['X_APP_ID']?.trim();
    return {
      'X-SESSION': token,
      'X-API-KEY':
          (apiKey != null && apiKey.isNotEmpty) ? apiKey : ApiConfig.apiKey,
      'X-APP-ID':
          (appId != null && appId.isNotEmpty) ? appId : ApiConfig.appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  double? _parseFormDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Web / Postman ile aynı: `uavt_adress` (backend yazımı `adress`).
  Map<String, dynamic>? _buildBammaUavtAdress(Map<String, dynamic> formData) {
    final lat = _parseFormDouble(formData['latitude']);
    final lon = _parseFormDouble(formData['longitude']);
    final quarter = int.tryParse(formData['neighborhood_id']?.toString() ?? '');
    if (lat == null || lon == null || quarter == null) {
      debugPrint(
        '⚠️ uavt_adress: mahalle (neighborhood_id) veya lat/lon eksik',
      );
      return null;
    }
    return {
      'quarter': quarter,
      'lat': lat,
      'lon': lon,
      'detail': '',
    };
  }

  /// `refRealEstateProperties` / `refListingProperties` ağacından satır `id` map’i.
  ///
  /// API çoğu satırda kök `id` vermez; `depozito-tl` gibi alanlarda tek elemanlı
  /// `values: [{ id, code }]` içindeki `id` aslında BAMMA `properties[].id` ile aynı.
  static String? _rowIdFromPropertyAttribute(PropertyAttribute n) {
    final direct = n.id?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final vals = n.values;
    if (vals.isEmpty) return null;

    if (vals.length == 1) {
      final vid = vals.first.id?.toString().trim();
      if (vid != null && vid.isNotEmpty) return vid;
    }

    final ctrl = n.control.toLowerCase();
    if (ctrl == 'number' ||
        ctrl == 'text' ||
        ctrl == 'textarea' ||
        ctrl == 'currency') {
      for (final v in vals) {
        final vid = v.id?.toString().trim();
        if (vid != null && vid.isNotEmpty) return vid;
      }
    }

    return null;
  }

  static void collectPropertyRowIds(
    List<PropertyAttribute> roots,
    Map<String, String> out,
  ) {
    for (final n in roots) {
      final children = n.properties;
      if (children != null && children.isNotEmpty) {
        collectPropertyRowIds(children, out);
      } else {
        final rowId = _rowIdFromPropertyAttribute(n);
        final code = n.propertyCode.trim();
        if (rowId != null && rowId.isNotEmpty && code.isNotEmpty) {
          out[code] = rowId;
        }
      }
    }
  }

  /// `refRealEstateProperties` / `refListingProperties` ağacında select alanı bulur.
  static PropertyAttribute? findPropertyAttribute(
    PropertyAttributesResponse? response,
    String propertyCode,
  ) {
    if (response == null) return null;
    PropertyAttribute? found;

    void walk(List<PropertyAttribute> nodes) {
      for (final node in nodes) {
        if (found != null) return;
        if (node.propertyCode == propertyCode) {
          found = node;
          return;
        }
        final children = node.properties;
        if (children != null && children.isNotEmpty) {
          walk(children);
        }
      }
    }

    walk(response.properties);
    return found;
  }

  static const _propertyOwnerOptionLabels = {
    'tc-vatandasi': 'T.C. vatandaşı',
    'tc-vatandasi-degil': 'T.C. vatandaşı değil',
    'banka-vakif-dernek-sendika': 'Banka / Vakıf / Dernek / Sendika',
    'kamu-kurumu': 'Kamu Kurumu',
  };

  static String formatPropertyOwnerOptionLabel(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return code;
    final mapped = _propertyOwnerOptionLabels[trimmed];
    if (mapped != null) return mapped;
    return trimmed
        .split('-')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  /// Örn. `gayrimenkul-sahibi` — web `get-property-attributes` / `get-listing-properties-types` yanıtından.
  static List<MapEntry<String, String>> extractSelectPropertyOptions(
    PropertyAttributesResponse? response,
    String propertyCode,
  ) {
    final attribute = findPropertyAttribute(response, propertyCode);
    if (attribute == null || attribute.control != 'select') {
      return const [];
    }

    final out = <MapEntry<String, String>>[];
    for (final value in attribute.values) {
      final code = value.code?.trim();
      if (code == null || code.isEmpty) continue;
      final label = propertyCode == 'gayrimenkul-sahibi'
          ? formatPropertyOwnerOptionLabel(code)
          : code;
      out.add(MapEntry(code, label));
    }
    return out;
  }

  String _descriptionForBammaRealEstate(String description) {
    final t = description.trim();
    if (t.isEmpty) return '<p></p>';
    if (t.contains('<') && RegExp(r'<[a-zA-Z]').hasMatch(t)) return t;
    final esc = t
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    return '<p>$esc</p>';
  }

  bool _bammaPropertyPreferNumeric(String code) {
    return code == 'm2-brut' ||
        code == 'm2-net' ||
        code.endsWith('-tl') ||
        code.contains('acik-alan-m2') ||
        code.contains('kapali-alan-m2') ||
        code.contains('arazi-m2');
  }

  Map<String, dynamic> _bammaPropertyRow({
    required String code,
    required String rowId,
    required dynamic raw,
  }) {
    if (raw == null) {
      return {
        'code': code,
        'id': rowId,
        'value': null,
        'string_value': null,
      };
    }
    if (raw is List) {
      if (raw.isEmpty) {
        return {
          'code': code,
          'id': rowId,
          'value': null,
          'string_value': null,
        };
      }
      return {
        'code': code,
        'id': rowId,
        'value': null,
        'string_value': jsonEncode(raw),
      };
    }
    final s = raw.toString().trim();
    if (s.isEmpty) {
      return {
        'code': code,
        'id': rowId,
        'value': null,
        'string_value': null,
      };
    }
    if (code.contains('numarasi')) {
      return {
        'code': code,
        'id': rowId,
        'value': null,
        'string_value': s,
      };
    }
    if (_bammaPropertyPreferNumeric(code)) {
      final n = num.tryParse(s.replaceAll(',', '.'));
      if (n != null) {
        if (n % 1 == 0) {
          return {
            'code': code,
            'id': rowId,
            'value': n.toInt(),
            'string_value': null,
          };
        }
        return {
          'code': code,
          'id': rowId,
          'value': n.toDouble(),
          'string_value': null,
        };
      }
    }
    return {
      'code': code,
      'id': rowId,
      'value': null,
      'string_value': s,
    };
  }

  List<Map<String, dynamic>> _buildBammaPropertiesArray({
    required Map<String, dynamic> formData,
    required Map<String, String> rowIdsByCode,
  }) {
    final codes = rowIdsByCode.keys.toList()..sort();
    return [
      for (final code in codes)
        _bammaPropertyRow(
          code: code,
          rowId: rowIdsByCode[code]!,
          raw: formData[code],
        ),
    ];
  }

  static const _bammaFormKeysExcludedFromProperties = {
    'province_id',
    'province_name',
    'district_id',
    'district_name',
    'neighborhood_id',
    'neighborhood_name',
    'latitude',
    'longitude',
    'price',
    'currency',
  };

  /// Ref API satır `id` dönmediğinde (ör. yalnızca `values[].id` var) web dizisi yerine düz harita.
  Map<String, dynamic> _buildLegacyBammaPropertiesMap(
    Map<String, dynamic> formData,
  ) {
    final out = <String, dynamic>{};
    formData.forEach((key, value) {
      if (_bammaFormKeysExcludedFromProperties.contains(key) || value == null) {
        return;
      }
      if (value is List) {
        out[key] = value;
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }

  /// Görsel bundle (thumbnail/standart/hd) — Next route: **`/api/upload-image/`**, `/api/upload/` çoğu deploy’da yok (404).
  String? _uploadImageAbsoluteUrlFromEnv() {
    final explicit = dotenv.env['UPLOAD_IMAGE_API_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return EnvApi.amplifyStyleTrailingSlash(explicit);
    }
    final fileUrl = dotenv.env['UPLOAD_FILE_API_URL']?.trim();
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final u = Uri.tryParse(fileUrl);
      if (u != null && u.path.contains('upload-file')) {
        final newPath =
            u.path.replaceAll(RegExp(r'upload-file/?$'), 'upload-image');
        return EnvApi.amplifyStyleTrailingSlash(
          u.replace(path: newPath).toString(),
        );
      }
    }
    final uploadApi = dotenv.env['UPLOAD_API_URL']?.trim();
    if (uploadApi != null && uploadApi.isNotEmpty) {
      return EnvApi.amplifyStyleTrailingSlash(
        _legacyUploadApiUrlToUploadImage(uploadApi),
      );
    }
    return null;
  }

  /// Eski `.env`: `.../api/upload` — yayında route yok; handler adı **upload-image**.
  String _legacyUploadApiUrlToUploadImage(String raw) {
    final u = Uri.tryParse(raw.trim());
    if (u == null || (u.scheme != 'http' && u.scheme != 'https')) {
      return raw.trim();
    }
    var path = u.path;
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    if (path.endsWith('/api/upload')) {
      path = '$path-image';
    }
    return u.replace(path: path.isEmpty ? '/' : '$path/').toString();
  }

  String? _uploadFileAbsoluteUrlFromEnv() {
    final u = dotenv.env['UPLOAD_FILE_API_URL']?.trim();
    if (u != null && u.isNotEmpty) return EnvApi.amplifyStyleTrailingSlash(u);
    return null;
  }

  /// Büyük JSON/base64 gövde — varsayılan Dio 15 sn `sendTimeout` yetersiz.
  Options _mediaUploadOptions(Map<String, String> headers) {
    return Options(
      headers: headers,
      sendTimeout: ApiConfig.mediaUploadSendTimeout,
      receiveTimeout: ApiConfig.mediaUploadReceiveTimeout,
    );
  }

  /// BAMMA `POST /api/zecorner/realEstate` — web ile aynı gateway; medya ayrıca Amplify/S3.
  Future<Response<dynamic>> _postCreateRealEstate({
    required Map<String, dynamic> data,
    required Map<String, dynamic>? queryParameters,
    required Map<String, String> headers,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '📡 Portfolio create → BAMMA ${EnvApi.zecornerBase}${PortfolioEndpoints.addPortfolio}',
      );
    }
    return _dioClient.dio.post(
      PortfolioEndpoints.addPortfolio,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  Future<Response<dynamic>> _postUpdateRealEstate({
    required String portfolioId,
    required Map<String, dynamic> data,
    required Map<String, dynamic>? queryParameters,
    required Map<String, String> headers,
  }) async {
    return _dioClient.dio.post(
      '${PortfolioEndpoints.addPortfolio}/$portfolioId',
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  /// Özellikler (Özellikler adımı) — web `/api/get-property-attributes/`, BAMMA `/refRealEstateProperties`.
  ///
  /// Example types: 'konut-daire', 'konut-rezidans', 'konut-villa', etc.
  Future<PropertyAttributesResponse> getPropertyAttributes(String type) async {
    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.realEstateProperties,
        queryParameters: {'type': type},
      );

      if (response.statusCode == 200) {
        return PropertyAttributesResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load property attributes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching property attributes: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetches all available categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.categories,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching categories: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<CategoryListingType>> getCategoryListingTypes(String category) async {
    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.categoryListingTypes,
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => CategoryListingType.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load category listing types: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching category listing types: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Gayrimenkul Sahibi seçenekleri — web `/api/get-dictionary/`, BAMMA `/refDictionary`.
  Future<List<MapEntry<String, String>>> getPropertyOwnerOptions() async {
    const fallback = <MapEntry<String, String>>[
      MapEntry('tc-vatandasi', 'T.C. vatandaşı'),
      MapEntry('tc-vatandasi-degil', 'T.C. vatandaşı değil'),
      MapEntry(
        'banka-vakif-dernek-sendika',
        'Banka / Vakıf / Dernek / Sendika',
      ),
      MapEntry('kamu-kurumu', 'Kamu Kurumu'),
    ];

    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.dictionary,
      );

      if (response.statusCode != 200) {
        return fallback;
      }

      final parsed = _parseDictionaryOwnerOptions(response.data);
      return parsed.isNotEmpty ? parsed : fallback;
    } on DioException catch (e) {
      debugPrint('❌ [API ERROR] Failed to load dictionary: ${e.message}');
      return fallback;
    } catch (e) {
      debugPrint('❌ [API ERROR] Unexpected dictionary error: $e');
      return fallback;
    }
  }

  List<MapEntry<String, String>> _parseDictionaryOwnerOptions(dynamic data) {
    const keys = [
      'gayrimenkul-sahibi',
      'gayrimenkul_sahibi',
      'property-owner',
      'property_owner',
    ];

    dynamic node = data;
    if (node is Map<String, dynamic>) {
      if (node.containsKey('data') && node['data'] is Map) {
        node = node['data'];
      }
      for (final key in keys) {
        final list = (node as Map)[key];
        final options = _dictionaryEntriesFromList(list);
        if (options.isNotEmpty) return options;
      }
      for (final value in node.values) {
        final options = _dictionaryEntriesFromList(value);
        if (options.isNotEmpty) return options;
      }
    } else if (node is List) {
      for (final item in node) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = map['type']?.toString() ??
            map['key']?.toString() ??
            map['code']?.toString() ??
            '';
        if (keys.any((k) => type.contains(k.replaceAll('_', '-')))) {
          final options = _dictionaryEntriesFromList(
            map['values'] ?? map['items'] ?? map['options'],
          );
          if (options.isNotEmpty) return options;
        }
      }
    }

    return const [];
  }

  List<MapEntry<String, String>> _dictionaryEntriesFromList(dynamic list) {
    if (list is! List) return const [];

    final out = <MapEntry<String, String>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final code = map['code']?.toString() ??
          map['value']?.toString() ??
          map['id']?.toString();
      final label = map['label']?.toString() ??
          map['name']?.toString() ??
          map['title']?.toString();
      if (code == null || code.isEmpty || label == null || label.isEmpty) {
        continue;
      }
      out.add(MapEntry(code, label));
    }
    return out;
  }

  /// İlan tipi özellikleri (depozito, tapu vb.) — web `/api/get-listing-properties-types/`,
  /// BAMMA `/refListingProperties`.
  ///
  /// Example: category='konut-rezidans', listingType='kiralik'
  Future<PropertyAttributesResponse> getListingProperties(String category, String listingType) async {
    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.listingProperties,
        queryParameters: {
          'category': category,
          'listing_type': listingType,
        },
      );

      if (response.statusCode == 200) {
        return PropertyAttributesResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load listing properties: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching listing properties: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Tüm iller.
  ///
  /// BAMMA `refProvinces` `country_code` (TR / CT) olmadan boş `PROVINCES` döner.
  /// Gövde düz liste ya da `{ data: { PROVINCES: [...] } }` olabilir.
  Future<List<Province>> getProvinces({String countryCode = 'TR'}) async {
    final resolved =
        countryCode.trim().isEmpty ? 'TR' : countryCode.trim();
    try {
      final response = await _dioClient.dio.get(
        ReferenceEndpoints.provinces,
        queryParameters: {'country_code': resolved},
      );

      if (response.statusCode == 200) {
        return _provincesFromBody(response.data);
      }
      throw Exception('Failed to load provinces: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error fetching provinces: ${e.message}');
    }
  }

  List<Province> _provincesFromBody(dynamic data) {
    final raw = _extractRefList(
      data,
      nestedKeys: const ['PROVINCES', 'provinces', 'cities', 'Response'],
      rootKeys: const ['PROVINCES', 'provinces', 'cities', 'data'],
    );
    return raw
        .whereType<Map>()
        .map((json) => Province.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// ref* gövdesinden liste çıkarır (düz dizi veya dump sarmalayıcısı).
  List<dynamic> _extractRefList(
    dynamic data, {
    required List<String> nestedKeys,
    required List<String> rootKeys,
  }) {
    if (data is List) return data;
    if (data is! Map) return const [];

    final map = Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is List) return nested;
    if (nested is Map) {
      final nestedMap = Map<String, dynamic>.from(nested);
      for (final key in nestedKeys) {
        final value = nestedMap[key];
        if (value is List) return value;
      }
    }

    for (final key in rootKeys) {
      final value = map[key];
      if (value is List) return value;
    }
    return const [];
  }

  /// Fetches districts for a given province code
  /// Web (Next `get-districts`) ile aynı: önce `GET /refProvince/{code}?type=place` (villages+quarters),
  /// hiç mahalle çıkmazsa eski `quarters` düz şeması için parametresiz tekrar dene.
  Future<List<Province>> getDistricts(String provinceCode) async {
    final endpoint = ReferenceEndpoints.districts.replaceAll('{code}', provinceCode);

    List<Province> parseList(dynamic body) {
      final data = _extractRefList(
        body,
        nestedKeys: const ['districts', 'DISTRICTS', 'data', 'Response'],
        rootKeys: const ['districts', 'data'],
      );
      return data
          .whereType<Map>()
          .map((json) => Province.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    try {
      Response response;
      try {
        response = await _dioClient.dio.get(
          endpoint,
          queryParameters: const {'type': 'place', 'country_code': 'TR'},
        );
      } on DioException catch (e) {
        final sc = e.response?.statusCode;
        if (sc == 400 || sc == 404 || sc == 422) {
          response = await _dioClient.dio.get(
            endpoint,
            queryParameters: const {'country_code': 'TR'},
          );
        } else {
          rethrow;
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }

      var list = parseList(response.data);
      final anyQuarters =
          list.any((d) => d.hasEmbeddedQuarters);
      if (list.isNotEmpty && !anyQuarters) {
        final legacy = await _dioClient.dio.get(
          endpoint,
          queryParameters: const {'country_code': 'TR'},
        );
        if (legacy.statusCode == 200) {
          final alt = parseList(legacy.data);
          if (alt.any((d) => d.hasEmbeddedQuarters)) {
            list = alt;
          }
        }
      }

      return list;
    } on DioException catch (e) {
      throw Exception('Error fetching districts: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
  Future<List<Province>> getNeighborhoods(String districtCode) async {
    final endpoint = ReferenceEndpoints.districts.replaceAll('{code}', districtCode);

    List<Province> parseBody(dynamic responseData) {
      if (responseData is List && responseData.isNotEmpty) {
        final firstItem = responseData.first;
        if (firstItem is Map<String, dynamic>) {
          return Province.neighborhoodListFromDistrictNode(firstItem);
        }
      } else if (responseData is Map<String, dynamic>) {
        return Province.neighborhoodListFromDistrictNode(responseData);
      }
      return [];
    }

    try {
      Response response;
      try {
        response = await _dioClient.dio.get(
          endpoint,
          queryParameters: const {'type': 'place'},
        );
      } on DioException catch (e) {
        final sc = e.response?.statusCode;
        if (sc == 400 || sc == 404 || sc == 422) {
          response = await _dioClient.dio.get(endpoint);
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint('🔵 Neighborhoods API for district $districtCode');
        var list = parseBody(responseData);
        if (list.isEmpty) {
          final legacy = await _dioClient.dio.get(endpoint);
          if (legacy.statusCode == 200) {
            list = parseBody(legacy.data);
          }
        }
        debugPrint('✅ Parsed ${list.length} neighborhoods');
        return list;
      }
      throw Exception('Failed to load neighborhoods: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.message}');
      throw Exception('Error fetching neighborhoods: ${e.message}');
    } catch (e) {
      debugPrint('❌ Exception: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, String>> uploadImage(File imageFile) async {
    try {
      debugPrint('📤 Uploading image: ${imageFile.path}');

      final viaS3 = await _uploadPortfolioImageViaS3(imageFile);
      if (viaS3 != null) {
        return viaS3;
      }

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Get file extension to determine MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default
      }
      
      // Convert to base64 with data URI prefix
      final base64String = base64Encode(bytes);
      final base64DataUri = 'data:$mimeType;base64,$base64String';
      
      // Prepare request body
      final requestBody = {
        'base64': base64DataUri,
      };

      final headers = await _bammaAuthHeaders();
      final uploadOptions = _mediaUploadOptions(headers);
      final absolute = _uploadImageAbsoluteUrlFromEnv();
      final response = absolute != null
          ? await _dioClient.dio.post(
              absolute,
              data: requestBody,
              options: uploadOptions,
            )
          : await _dioClient.dio.post(
              PortfolioEndpoints.uploadImage,
              data: requestBody,
              options: uploadOptions,
            );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ Image uploaded successfully: $data');
        
        return {
          'thumbnail': data['thumbnail']?.toString() ?? '',
          'standart': data['standart']?.toString() ?? '',
          'hd': data['hd']?.toString() ?? '',
        };
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Image upload error: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      throw Exception('Error uploading image: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Yetki belgesi: önce **S3 presign** + PUT, olmazsa Next `upload-file` (base64).
  Future<String> uploadAuthorizationFile(File file) async {
    try {
      debugPrint('📤 Uploading authorization file: ${file.path}');
      
      // Read file as bytes
      final bytes = await file.readAsBytes();
      
      // Get file extension to determine MIME type
      final extension = file.path.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'doc':
          mimeType = 'application/msword';
          break;
        case 'docx':
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          mimeType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          mimeType = 'application/octet-stream'; // Default
      }

      final s3Key = await _contactUpload.tryPresignedS3UploadBytes(
        bytes: bytes,
        mimeType: mimeType,
      );
      if (s3Key != null && s3Key.isNotEmpty) {
        debugPrint('✅ Yetki belgesi S3 (presign): $s3Key');
        return s3Key;
      }
      debugPrint('⚠️ Yetki belgesi: presign yok, upload-file (base64) deneniyor');
      
      // Convert to base64 with data URI prefix
      final base64String = base64Encode(bytes);
      final base64DataUri = 'data:$mimeType;base64,$base64String';
      
      // Prepare request body
      final requestBody = {
        'base64': base64DataUri,
      };

      final headers = await _bammaAuthHeaders();
      final uploadOptions = _mediaUploadOptions(headers);
      final absolute = _uploadFileAbsoluteUrlFromEnv();
      final response = absolute != null
          ? await _dioClient.dio.post(
              absolute,
              data: requestBody,
              options: uploadOptions,
            )
          : await _dioClient.dio.post(
              PortfolioEndpoints.uploadFile,
              data: requestBody,
              options: uploadOptions,
            );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final fileId = data['fileId']?.toString() ?? data['id']?.toString() ?? '';
        
        if (fileId.isEmpty) {
          throw Exception('File ID not found in response');
        }
        
        debugPrint('✅ Authorization file uploaded successfully: $fileId');
        return fileId;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ File upload error: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      throw Exception('Error uploading file: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  Future<String?> createPortfolio({
    required String title,
    required String description,
    required String portfolioType,
    required String categoryId,
    required Map<String, dynamic> formData,
    required Map<String, String> propertyRowIdsByCode,
    List<File>? images,
    File? authorizationFile,
  }) async {
    try {
      debugPrint('🚀 Creating portfolio...');
      debugPrint('📋 Title: $title');
      debugPrint('📋 Type: $portfolioType');
      debugPrint('📋 Category ID: $categoryId');

      List<Map<String, dynamic>> medias = [];
      if (images != null && images.isNotEmpty) {
        debugPrint('📤 Uploading ${images.length} images...');
        for (var i = 0; i < images.length; i++) {
          try {
            final imageData = await uploadImage(images[i]);
            // Create media object with all image IDs
            medias.add({
              'type': 'image',
              'thumbnail': imageData['thumbnail'] ?? '',
              'standart': imageData['standart'] ?? '',
              'hd': imageData['hd'] ?? '',
              'is_cover': i == 0, // First image is cover
            });
            debugPrint('✅ Image ${i + 1}/${images.length} uploaded');
          } catch (e) {
            debugPrint('❌ Failed to upload image ${i + 1}: $e');
            throw Exception('Görsel ${i + 1} yüklenemedi: $e');
          }
        }
        debugPrint('✅ All images uploaded: ${medias.length} medias');
      }

      // Step 2: Upload authorization file if provided
      String? authorizationCertificateId;
      if (authorizationFile != null) {
        try {
          authorizationCertificateId = await uploadAuthorizationFile(authorizationFile);
          debugPrint('✅ Authorization file uploaded: $authorizationCertificateId');
        } catch (e) {
          debugPrint('❌ Failed to upload authorization file: $e');
          throw Exception('Yetki belgesi yüklenemedi: $e');
        }
      }

      // Step 3: `uavt_adress` + HTML açıklama. `properties`: satır id varsa web dizisi, yoksa düz harita.
      final portfolioData = <String, dynamic>{
        'title': title,
        'description': _descriptionForBammaRealEstate(description),
        'type': portfolioType,
      };

      if (medias.isNotEmpty) {
        portfolioData['medias'] = medias;
      }

      if (authorizationCertificateId != null) {
        portfolioData['authorization_certificate'] = authorizationCertificateId;
      }

      final uavt = _buildBammaUavtAdress(formData);
      if (uavt == null) {
        throw Exception(
          'Konum eksik: haritadan konum seçin ve mahalle (UAVT) seçili olsun.',
        );
      }
      portfolioData['uavt_adress'] = uavt;

      if (propertyRowIdsByCode.isNotEmpty) {
        portfolioData['properties'] = _buildBammaPropertiesArray(
          formData: formData,
          rowIdsByCode: propertyRowIdsByCode,
        );
      } else {
        debugPrint(
          '⚠️ Ref özellik satır id toplanamadı; properties düz harita (mobil geri uyum).',
        );
        final legacyProps = _buildLegacyBammaPropertiesMap(formData);
        if (legacyProps.isNotEmpty) {
          portfolioData['properties'] = legacyProps;
        }
      }

      debugPrint('📤 Sending portfolio data to API...');
      debugPrint('📋 Portfolio data keys: ${portfolioData.keys.toList()}');

      // Step 4: BAMMA POST .../api/zecorner/realEstate (thumbnailIndex yalnızca eski Next route içindi)
      final authHeaders = await _bammaAuthHeaders();
      final response = await _postCreateRealEstate(
        data: portfolioData,
        queryParameters: null,
        headers: authHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Portfolio created successfully');
        debugPrint('📋 Response: ${response.data}');
        
        // Extract portfolio ID from response
        final responseData = response.data;
        String? portfolioId;
        if (responseData is Map<String, dynamic>) {
          portfolioId = responseData['id']?.toString();
        }
        
        if (portfolioId != null) {
          debugPrint('✅ Portfolio ID: $portfolioId');
          return portfolioId;
        } else {
          debugPrint('⚠️ Portfolio ID not found in response');
          return null;
        }
      } else {
        debugPrint('❌ Portfolio creation failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.data}');
        throw Exception('Portföy oluşturulamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      final serverMsg = _bammaErrorMessageFromResponse(e.response?.data);
      throw Exception(
        serverMsg != null
            ? 'Portföy oluşturulurken hata: $serverMsg'
            : 'Portföy oluşturulurken hata oluştu: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  static String? _bammaErrorMessageFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      if (m is List && m.isNotEmpty) return m.first.toString();
    }
    return null;
  }

  Future<String?> updatePortfolio({
    required String portfolioId,
    required String title,
    required String description,
    required String portfolioType,
    required String categoryId,
    required Map<String, dynamic> formData,
    required Map<String, String> propertyRowIdsByCode,
    List<File>? images,
    File? authorizationFile,
    String? existingAuthorizationCertificateId,
  }) async {
    try {
      debugPrint('🔄 Updating portfolio: $portfolioId');
      debugPrint('📋 Title: $title');
      debugPrint('📋 Type: $portfolioType');
      debugPrint('📋 Category ID: $categoryId');
      
      // Step 1: Upload all images and collect their IDs (if new images are provided)
      List<Map<String, dynamic>> medias = [];
      if (images != null && images.isNotEmpty) {
        debugPrint('📤 Uploading ${images.length} new images...');
        for (var i = 0; i < images.length; i++) {
          try {
            final imageData = await uploadImage(images[i]);
            medias.add({
              'type': 'image',
              'thumbnail': imageData['thumbnail'] ?? '',
              'standart': imageData['standart'] ?? '',
              'hd': imageData['hd'] ?? '',
              'is_cover': i == 0,
            });
            debugPrint('✅ Image ${i + 1}/${images.length} uploaded');
          } catch (e) {
            debugPrint('❌ Failed to upload image ${i + 1}: $e');
            throw Exception('Görsel ${i + 1} yüklenemedi: $e');
          }
        }
        debugPrint('✅ All new images uploaded: ${medias.length} medias');
      }

      // Step 2: Upload authorization file if provided
      String? authorizationCertificateId;
      if (authorizationFile != null) {
        try {
          authorizationCertificateId = await uploadAuthorizationFile(authorizationFile);
          debugPrint('✅ Authorization file uploaded: $authorizationCertificateId');
        } catch (e) {
          debugPrint('❌ Failed to upload authorization file: $e');
          throw Exception('Yetki belgesi yüklenemedi: $e');
        }
      }

      final portfolioData = <String, dynamic>{
        'title': title,
        'description': _descriptionForBammaRealEstate(description),
        'type': portfolioType,
      };

      if (medias.isNotEmpty) {
        portfolioData['medias'] = medias;
      }

      if (authorizationCertificateId != null) {
        portfolioData['authorization_certificate'] = authorizationCertificateId;
      } else if (existingAuthorizationCertificateId != null &&
          existingAuthorizationCertificateId.isNotEmpty) {
        portfolioData['authorization_certificate'] =
            existingAuthorizationCertificateId;
      }

      final uavtUpdate = _buildBammaUavtAdress(formData);
      if (uavtUpdate == null) {
        throw Exception(
          'Konum eksik: haritadan konum seçin ve mahalle (UAVT) seçili olsun.',
        );
      }
      portfolioData['uavt_adress'] = uavtUpdate;

      if (propertyRowIdsByCode.isNotEmpty) {
        portfolioData['properties'] = _buildBammaPropertiesArray(
          formData: formData,
          rowIdsByCode: propertyRowIdsByCode,
        );
      } else {
        debugPrint(
          '⚠️ Ref özellik satır id toplanamadı; properties düz harita (mobil geri uyum).',
        );
        final legacyProps = _buildLegacyBammaPropertiesMap(formData);
        if (legacyProps.isNotEmpty) {
          portfolioData['properties'] = legacyProps;
        }
      }

      debugPrint('📤 Sending portfolio update data to API...');
      debugPrint('📋 Portfolio data keys: ${portfolioData.keys.toList()}');

      // Step 4: BAMMA POST .../api/zecorner/realEstate/{id}
      final authHeaders = await _bammaAuthHeaders();
      final response = await _postUpdateRealEstate(
        portfolioId: portfolioId,
        data: portfolioData,
        queryParameters: null,
        headers: authHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Portfolio updated successfully');
        debugPrint('📋 Response: ${response.data}');
        
        final responseData = response.data;
        String? updatedPortfolioId;
        if (responseData is Map<String, dynamic>) {
          updatedPortfolioId = responseData['id']?.toString() ?? portfolioId;
        }
        
        if (updatedPortfolioId != null) {
          debugPrint('✅ Updated Portfolio ID: $updatedPortfolioId');
          return updatedPortfolioId;
        } else {
          debugPrint('⚠️ Portfolio ID not found in response, using provided ID');
          return portfolioId;
        }
      } else {
        debugPrint('❌ Portfolio update failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.data}');
        throw Exception('Portföy güncellenemedi: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      final serverMsg = _bammaErrorMessageFromResponse(e.response?.data);
      throw Exception(
        serverMsg != null
            ? 'Portföy güncellenirken hata: $serverMsg'
            : 'Portföy güncellenirken hata oluştu: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  /// BAMMA üzerinden portföy detayını getirir (düzenleme modu için tam veri).
  Future<Map<String, dynamic>?> fetchPortfolioDetail(String portfolioId) async {
    try {
      final headers = await _bammaAuthHeaders();
      final response = await _dioClient.dio.get(
        '${PortfolioEndpoints.addPortfolio}/$portfolioId',
        options: Options(headers: headers),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      debugPrint('❌ fetchPortfolioDetail: ${e.message}');
    } catch (e) {
      debugPrint('❌ fetchPortfolioDetail: $e');
    }
    return null;
  }

  /// İlanın bağlı olduğu portföy (BAMMA `real_estate`) id'sini döner.
  /// `GET /listing/{id}` yanıtı kök, `detail`, `data` veya `listing`
  /// altında olabilir; hepsine bakılır.
  Future<String?> fetchListingRealEstateId(String listingId) async {
    if (listingId.trim().isEmpty) return null;
    try {
      final headers = await _bammaAuthHeaders();
      final response = await _dioClient.dio.get(
        ListingEndpoints.getListingDetail.replaceFirst('{id}', listingId),
        options: Options(headers: headers),
      );
      if (response.statusCode != 200 || response.data is! Map) return null;
      final root = Map<String, dynamic>.from(response.data as Map);
      for (final candidate in [root, root['detail'], root['data'], root['listing']]) {
        if (candidate is! Map) continue;
        final id = _readRealEstateId(Map<String, dynamic>.from(candidate));
        if (id != null) return id;
      }
    } on DioException catch (e) {
      debugPrint('❌ fetchListingRealEstateId: ${e.message}');
    } catch (e) {
      debugPrint('❌ fetchListingRealEstateId: $e');
    }
    return null;
  }

  static String? _readRealEstateId(Map<String, dynamic> json) {
    for (final key in ['real_estate', 'real_estate_id', 'realEstate', 'realEstateId']) {
      final v = json[key];
      if (v == null) continue;
      if (v is Map) {
        final id = v['id']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
