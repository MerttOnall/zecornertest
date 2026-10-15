import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/tilan/tum_ilan_model.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/config/env_api.dart';

class TumIlanApiRepository {
  static final TumIlanApiRepository _instance =
      TumIlanApiRepository._internal();
  factory TumIlanApiRepository() => _instance;
  TumIlanApiRepository._internal();

  final DioClient _client = DioClient();

  /// Panel listesi — `.env` `LIST` public `/listing` olabiliyor; burası her zaman myListings.
  static const String _bammaMyListings = '/api/zecorner/myListings';

  /// Web ile aynı: /api/get-my-listing/?sortOrder=asc&office=&page=1&pageSize=10&contact=all&sortColumn=created_at
  /// Satıldı/kiralandı çoğu zaman `internal: true` (Gizli); Tümü'nde bunlar da gelmeli.
  Future<Either<Failure, TumIlanResponse>> getTumIlanlar({
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? state,
    int? provinceCode,
    int? districtCode,
    int? quarterCode,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
    String? sortOrder,
    String? office,
    String? contact,
  }) async {
    final query = _query(
      page: page,
      limit: limit,
      search: search,
      type: type,
      state: state,
      provinceCode: provinceCode,
      districtCode: districtCode,
      quarterCode: quarterCode,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
      office: office,
      contact: contact,
    );

    final noState = state == null || state.trim().isEmpty;
    final specificContactNo = _specificContactNo(contact);

    // Web proxy karışık state dönerse (Gizli satıldı/kiralandı dahil) onu kullan.
    // Kişi filtresi varken API contact'ı yok sayarsa karışık sayfa dönmesin.
    final web = await _getViaWebProxy(query);
    if (web != null) {
      if (specificContactNo != null) {
        if (_allListingsMatchContact(web.listings, specificContactNo) &&
            (!noState ||
                _hasClosedListings(web.listings) ||
                web.listings.isNotEmpty)) {
          if (!noState || _hasClosedListings(web.listings)) {
            _logSnapshot('web get-my-listing contact=$specificContactNo', web);
            return Right(web);
          }
        }
      } else if (!noState || _hasClosedListings(web.listings)) {
        _logSnapshot('web get-my-listing', web);
        return Right(web);
      }
    }

    if (noState) {
      final merged = await _getBammaAllStates(query, limit);
      return merged.fold(
        (f) {
          if (web == null) return Left(f);
          if (specificContactNo != null &&
              !_allListingsMatchContact(web.listings, specificContactNo)) {
            return Left(f);
          }
          return Right(web);
        },
        (res) {
          _logSnapshot('bamma merged', res);
          return Right(res);
        },
      );
    }

    final once = await _getBammaOnce(query, limit);
    return once.fold(
      (f) {
        if (web == null) return Left(f);
        if (specificContactNo != null &&
            !_allListingsMatchContact(web.listings, specificContactNo)) {
          return Left(f);
        }
        return Right(web);
      },
      (res) {
        _logSnapshot('bamma once', res);
        return Right(res);
      },
    );
  }

  Map<String, dynamic> _query({
    required int page,
    required int limit,
    String? search,
    String? type,
    String? state,
    int? provinceCode,
    int? districtCode,
    int? quarterCode,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
    String? sortOrder,
    String? office,
    String? contact,
  }) {
    final contactParam = contact?.trim();
    final q = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'pageSize': limit,
      'limit': limit,
      'contact': (contactParam != null &&
              contactParam.isNotEmpty &&
              contactParam != 'all')
          ? contactParam
          : 'all',
      'office': office?.trim() ?? '',
      'sortColumn': sortBy ?? 'created_at',
      'sortOrder': sortOrder ?? 'asc',
    };
    final st = state?.trim();
    if (st != null && st.isNotEmpty) q['state'] = st;
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (type != null && type.isNotEmpty) q['type'] = type;
    if (provinceCode != null) q['province_code'] = provinceCode;
    if (districtCode != null) q['district_code'] = districtCode;
    if (quarterCode != null) q['quarter_code'] = quarterCode;
    if (minPrice != null) q['min_price'] = minPrice;
    if (maxPrice != null) q['max_price'] = maxPrice;
    return q;
  }

  int? _specificContactNo(String? contact) {
    final c = contact?.trim();
    if (c == null || c.isEmpty || c == 'all') return null;
    return int.tryParse(c);
  }

  bool _allListingsMatchContact(List<TumIlanModel> listings, int contactNo) {
    if (listings.isEmpty) return true;
    return listings.every((l) => l.contactNo == contactNo);
  }

  bool _hasClosedListings(List<TumIlanModel> listings) {
    return listings.any((l) {
      final s = l.state.toUpperCase();
      return s == 'SOLD' || s == 'RENTED';
    });
  }

  void _logSnapshot(String source, TumIlanResponse res) {
    if (!kDebugMode) return;
    final states = <String, int>{};
    var internalCount = 0;
    for (final l in res.listings) {
      final s = l.state.toUpperCase();
      states[s] = (states[s] ?? 0) + 1;
      if (l.internal) internalCount += 1;
    }
    debugPrint(
      'Tüm Portföyler [$source]: ${res.listings.length} ilan, '
      'total=${res.totalCount}, states=$states, gizli(internal)=$internalCount',
    );
  }

  /// Amplify Next proxy. DioClient kullanılmaz (401 oturumu düşürmesin).
  Future<TumIlanResponse?> _getViaWebProxy(Map<String, dynamic> query) async {
    final urls = _webListingUrls();
    if (urls.isEmpty) return null;

    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];
      final userId = pref.getString('userID');
      if (token == null || apiKey == null || appId == null) return null;

      final dio = Dio(
        BaseOptions(
          connectTimeout: ApiConfig.connectionTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

      for (final url in urls) {
        try {
          final uri = _uriWithQuery(url, query);
          final response = await dio.getUri(
            uri,
            options: Options(headers: {
              'Authorization': 'Bearer $token',
              'X-SESSION': token,
              if (userId != null && userId.isNotEmpty) 'X-UR-ID': userId,
              'X-API-KEY': apiKey,
              'X-APP-ID': appId,
              'X-HB-IP': dotenv.env['X_HB_IP']?.trim().isNotEmpty == true
                  ? dotenv.env['X_HB_IP']!.trim()
                  : '::1',
              'X-HB-USER-AGENT':
                  dotenv.env['X_HB_USER_AGENT']?.trim().isNotEmpty == true
                      ? dotenv.env['X_HB_USER_AGENT']!.trim()
                      : 'flutter-app',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            }),
          );

          if (response.statusCode == 200) {
            final parsed = _parseBody(response.data, query['pageSize'] as int);
            if (parsed != null) return parsed;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      // BAMMA yedek
    }
    return null;
  }

  List<String> _webListingUrls() {
    final urls = <String>[];
    final seen = <String>{};

    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final withSlash = EnvApi.amplifyStyleTrailingSlash(raw.trim());
      if (withSlash != null && seen.add(withSlash)) urls.add(withSlash);
    }

    final origin = EnvApi.webNextApiOrigin;
    if (origin != null && origin.isNotEmpty) {
      add('$origin/api/get-my-listing');
    }
    add('https://test.d1cegqpdj9080.amplifyapp.com/api/get-my-listing');
    add('https://zecorner.com/api/get-my-listing');
    add('https://www.zecorner.com/api/get-my-listing');
    return urls;
  }

  Future<Either<Failure, TumIlanResponse>> _getBammaAllStates(
    Map<String, dynamic> baseQuery,
    int limit,
  ) async {
    final first = await Future.wait([
      _getBammaOnce(baseQuery, limit),
      _getBammaOnce({...baseQuery, 'state': 'SOLD'}, limit),
      _getBammaOnce({...baseQuery, 'state': 'RENTED'}, limit),
    ]);

    var soldRes = first[1];
    var rentedRes = first[2];
    final retries = <Future<Either<Failure, TumIlanResponse>>>[];
    if (!_foldHasClosed(soldRes, 'SOLD')) {
      retries.add(
        _getBammaOnce(
          {...baseQuery, 'state': 'SOLD', 'internal': true},
          limit,
        ),
      );
    }
    if (!_foldHasClosed(rentedRes, 'RENTED')) {
      retries.add(
        _getBammaOnce(
          {...baseQuery, 'state': 'RENTED', 'internal': true},
          limit,
        ),
      );
    }
    if (retries.isNotEmpty) {
      final extra = await Future.wait(retries);
      var i = 0;
      if (!_foldHasClosed(soldRes, 'SOLD')) {
        soldRes = extra[i++];
      }
      if (!_foldHasClosed(rentedRes, 'RENTED')) {
        rentedRes = extra[i];
      }
    }

    return _mergeResults(
      [first[0], soldRes, rentedRes],
      page: baseQuery['page'] as int,
      limit: limit,
    );
  }

  bool _foldHasClosed(Either<Failure, TumIlanResponse> r, String state) {
    return r.fold((_) => false, (res) {
      return res.listings.any((l) => l.state.toUpperCase() == state);
    });
  }

  Either<Failure, TumIlanResponse> _mergeResults(
    List<Either<Failure, TumIlanResponse>> results, {
    required int page,
    required int limit,
  }) {
    final byId = <String, TumIlanModel>{};
    var totalCount = 0;
    var maxPages = 0;
    var hasMore = false;
    Failure? lastFailure;
    var ok = 0;

    for (final r in results) {
      r.fold((f) => lastFailure = f, (res) {
        ok += 1;
        totalCount += res.totalCount;
        if (res.totalPages > maxPages) maxPages = res.totalPages;
        if (res.hasMore) hasMore = true;
        for (final l in res.listings) {
          byId[l.id] = l;
        }
      });
    }

    if (ok == 0 && lastFailure != null) return Left(lastFailure!);

    final listings = byId.values.toList()
      ..sort((a, b) => b.createdAtDateTime.compareTo(a.createdAtDateTime));

    return Right(
      TumIlanResponse(
        listings: listings,
        totalCount: totalCount,
        totalPages: maxPages,
        page: page,
        hasMore: hasMore || listings.length >= limit,
      ),
    );
  }

  Future<Either<Failure, TumIlanResponse>> _getBammaOnce(
    Map<String, dynamic> query,
    int limit,
  ) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];
      final userId = pref.getString('userID');
      if (token == null) {
        return Left(
          AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'),
        );
      }
      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final uri = _uriWithQuery('${EnvApi.origin}$_bammaMyListings', query);
      final response = await _client.dio.get(
        uri.toString(),
        options: Options(
          headers: {
            'X-SESSION': token,
            'X-API-KEY': apiKey,
            'X-APP-ID': appId,
            if (userId != null && userId.isNotEmpty) 'X-UR-ID': userId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: const {'skipSessionExpire': true},
        ),
      );

      if (response.statusCode == 200) {
        final parsed = _parseBody(response.data, limit);
        if (parsed != null) return Right(parsed);
      }
      return Left(ServerFailure(
        message: 'Tüm ilanlar alınamadı',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          AuthFailure(
            message: 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
          ),
        );
      }
      if (e.response?.statusCode == 403) {
        return Left(
          AuthFailure(message: 'Bu işlem için yetkiniz bulunmamaktadır.'),
        );
      }
      return Left(NetworkFailure(message: 'Ağ bağlantısı hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }

  /// Boş `office=` tarayıcıdaki gibi URL'de kalsın (Dio map bazen düşürür).
  Uri _uriWithQuery(String url, Map<String, dynamic> query) {
    final base = Uri.parse(url);
    final parts = <String>[];
    query.forEach((key, value) {
      parts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}',
      );
    });
    if (!query.containsKey('office')) {
      parts.add('office=');
    }
    return base.replace(query: parts.join('&'));
  }

  TumIlanResponse? _parseBody(dynamic data, int limit) {
    final map = _asMap(data);
    if (map.isEmpty) return null;

    Map<String, dynamic> payload = map;
    for (final key in ['data', 'result', 'payload', 'body']) {
      final inner = map[key];
      if (inner is Map &&
          (inner['listings'] != null ||
              inner['totalCount'] != null ||
              inner['total_count'] != null)) {
        payload = _asMap(inner);
        break;
      }
    }

    if (payload['listings'] == null && map['listings'] == null) {
      return null;
    }

    return _wrap(
      TumIlanResponse.fromJson(payload),
      limit,
    );
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  TumIlanResponse _wrap(TumIlanResponse parsed, int limit) {
    return TumIlanResponse(
      listings: parsed.listings,
      totalCount: parsed.totalCount,
      totalPages: parsed.totalPages,
      page: parsed.page,
      hasMore: parsed.listings.length >= limit ||
          (parsed.totalCount > 0 &&
              parsed.listings.length < parsed.totalCount) ||
          (parsed.totalPages > parsed.page && parsed.page > 0),
    );
  }

  Future<Either<Failure, TumIlanModel>> getIlanDetay(String ilanId) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env['X_API_KEY'];
      final appId = dotenv.env['X_APP_ID'];
      if (token == null) {
        return Left(
          AuthFailure(message: 'Token bulunamadı. Lütfen tekrar giriş yapın.'),
        );
      }
      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final response = await _client.dio.get(
        '${EnvApi.origin}/api/zecorner/listing/$ilanId',
        options: Options(
          headers: {
            'X-SESSION': token,
            'X-API-KEY': apiKey,
            'X-APP-ID': appId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: const {'skipSessionExpire': true},
        ),
      );
      if (response.statusCode == 200) {
        final map = _asMap(response.data);
        final inner = map['data'] ?? map['listing'] ?? map;
        return Right(TumIlanModel.fromJson(_asMap(inner)));
      }
      return Left(ServerFailure(
        message: 'İlan detayı alınamadı',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(
          AuthFailure(
            message: 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
          ),
        );
      }
      return Left(NetworkFailure(message: 'Ağ bağlantısı hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: $e'));
    }
  }
}
