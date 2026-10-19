import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';

class MyListingsRepository {
  final Dio _dio;

  /// Danışman oturumunda myListings yalnızca kendi contact'ı ile çağrılır.
  /// Broker, ofis asistanı ve admin `all` olarak kalır.
  static Future<String> contactQueryForSession() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? const <String>[];
    final isAdmin =
        prefs.getBool('userIsAdmin') == true || roles.contains('role_admin');
    final isBroker = roles.contains('role_office_broker') ||
        roles.contains('role_office_assistant');
    if (roles.contains('role_advisor') && !isAdmin && !isBroker) {
      final id = prefs.getString('userID')?.trim() ?? '';
      if (id.isNotEmpty && id != '0') return id;
    }
    return 'all';
  }

  /// API contact filtresini yok sayarsa danışmanın dışındaki ilanları düşür.
  /// Kayıtlarda contact_no yoksa listeyi boşaltma; sunucunun döndürdüğünü bırak.
  static List<ListingPanelModel> keepSessionListings(
    List<ListingPanelModel> items,
    String contact,
  ) {
    if (contact == 'all') return items;
    final id = int.tryParse(contact) ?? 0;
    if (id <= 0) return items;
    if (!items.any((item) => item.contactNo > 0)) return items;
    return items.where((item) => item.contactNo == id).toList();
  }

  /// Broker: başka ofisin ilanı düşer. Ofis alanı boşsa ve sayfalama olduğu gibi kalır.
  static ListingPanelResponseModel scopeListingResponse(
    ListingPanelResponseModel response,
    AdvisorOfficeScope scope,
  ) {
    if (!scope.officeTeam) return response;
    final listings = response.listings
        .where(
          (item) => !scope.isForeignOffice(
            officeId: item.connectedContact > 0 ? item.connectedContact : null,
            officeTitle: item.connectedContactTitle,
          ),
        )
        .toList();
    return ListingPanelResponseModel(
      listings: listings,
      totalCount: response.totalCount,
      totalPages: response.totalPages,
      page: response.page,
    );
  }

  MyListingsRepository() : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectionTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    // Default header'ları kaldırıyorum çünkü authentication header'ı ile çakışabilir
    // headers: ApiConfig.defaultHeaders,
  ));

  Future<Either<Failure, ListingPanelResponseModel>> getMyListings({
    int page = 0,
    int pageSize = 10,
    String? status,
    String? state,
    String? search,
    String? office,
    String? contact,
    String? sortOrder,
    String? sortColumn,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      
      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      final scope = await AdvisorOfficeScope.load();

      // Web get-my-listing:
      // contact=all&pageSize=12&page=1&sortOrder=asc&sortColumn=created_at&state=SOLD&office=
      final hasState = state != null && state.isNotEmpty;
      final safePage = page < 1 ? 1 : page;

      final Map<String, dynamic> queryParams = {
        'page': safePage,
        'pageSize': pageSize,
        'contact': (contact != null && contact.isNotEmpty) ? contact : 'all',
        'office': office ?? '',
        'sortOrder': (sortOrder != null && sortOrder.isNotEmpty)
            ? sortOrder
            : (hasState ? 'asc' : 'desc'),
        'sortColumn': (sortColumn != null && sortColumn.isNotEmpty)
            ? sortColumn
            : 'created_at',
      };

      // state parametresi öncelikli (web API'de state kullanılıyor)
      if (hasState) {
        queryParams['state'] = state;
      } else if (status != null && status != 'Tümü') {
        queryParams['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('🔑 JWT Token: ${userJWT.substring(0, 20)}...');
      print('🌐 API Endpoint: ${ApiConfig.baseUrl}/myListings');
      print('📋 Query Parameters: $queryParams');
      print('📋 Headers: {X-SESSION: ${userJWT.substring(0, 20)}..., X-API-KEY: ed017c68-24ca-4239-ae68-0fa041391855, X-APP-ID: zecorner}');

      final response = await _dio.get(
        '/myListings', // /api/zecorner prefix'i kaldırıldı çünkü baseUrl'de zaten var
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-SESSION': userJWT, // Authorization: Bearer yerine X-SESSION kullanıyoruz
            'X-API-KEY': 'ed017c68-24ca-4239-ae68-0fa041391855',
            'X-APP-ID': 'zecorner',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final listingResponse = ListingPanelResponseModel.fromJson(response.data);
        return Right(scopeListingResponse(listingResponse, scope));
      } else {
        return Left(ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      print('❌ MyListings API Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      } else if (e.response?.statusCode == 404) {
        return Left(ServerFailure(message: 'API endpoint bulunamadı'));
      } else {
        return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
      }
    } catch (e) {
      print('❌ MyListings Repository Error: $e');
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  /// Web işlem bildirimi: `GET /preSale/{listingId}`.
  /// Sahip yoksa veya istek düşerse `owner` 0 döner; form kapanmaz.
  Future<ListingPreSale> getPreSale(String listingId) async {
    const empty = ListingPreSale(
      owner: 0,
      ownerTitle: '',
      ownerTypeDescription: '',
      ownerPicture: '',
    );
    if (listingId.trim().isEmpty) return empty;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');
      if (userJWT == null || userJWT.isEmpty) return empty;

      final response = await _dio.get(
        ListingEndpoints.getPreSale.replaceAll('{id}', listingId),
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': ApiConfig.apiKey,
            'X-APP-ID': ApiConfig.appId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        return ListingPreSale.fromJson(Map<String, dynamic>.from(data));
      }
      return empty;
    } catch (e) {
      print('❌ PreSale yüklenemedi: $e');
      return empty;
    }
  }

  Future<Either<Failure, ListingPanelResponseModel>> getListingsPendingApproval({
    int page = 1,
    int pageSize = 100,
    String? search,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');

      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      final scope = await AdvisorOfficeScope.load();

      final Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        ListingEndpoints.listingsPendingApproval,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': ApiConfig.apiKey,
            'X-APP-ID': ApiConfig.appId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final listingResponse =
            ListingPanelResponseModel.fromJson(response.data);
        return Right(scopeListingResponse(listingResponse, scope));
      }

      return Left(
        ServerFailure(message: 'Sunucu hatası: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  Future<Either<Failure, String>> approveListing(String listingId) {
    return _updateListingState(
      listingId,
      state: 'LIVE',
    );
  }

  Future<Either<Failure, String>> rejectListing(
    String listingId, {
    required String message,
  }) {
    return _updateListingState(
      listingId,
      state: 'REJECTED',
      message: message,
    );
  }

  Future<Either<Failure, String>> requestListingEdit(
    String listingId, {
    required String message,
  }) {
    return _updateListingState(
      listingId,
      state: 'CHANGE_REQUIRED',
      message: message,
    );
  }

  /// Web işlem bildirimi onayı: `GET /api/closeListingApprove/{id}`.
  /// Portföy yayına alma (`approveListing` → LIVE) ile karışmaz.
  Future<Either<Failure, String>> approveClosureListing(String listingId) {
    return _decideClosure(
      listingId: listingId,
      method: 'GET',
      bammaPath: '/closeListingApprove/$listingId',
      webPath: '/api/closeListingApprove/$listingId',
      successMessage: 'İşlem bildirimi başarıyla onaylandı',
    );
  }

  /// Web işlem bildirimi reddi: `POST /api/update-listing-status/{id}`
  /// gövdesi `{state: CHANGES_REQUIRED, message}`.
  Future<Either<Failure, String>> rejectClosureListing(
    String listingId, {
    required String message,
  }) {
    return _decideClosure(
      listingId: listingId,
      method: 'POST',
      bammaPath: '/listing/$listingId',
      webPath: '/api/update-listing-status/$listingId',
      body: {
        'state': 'CHANGES_REQUIRED',
        'message': message,
      },
      successMessage: 'İşlem bildirimi başarıyla reddedildi',
    );
  }

  Future<Either<Failure, String>> _decideClosure({
    required String listingId,
    required String method,
    required String bammaPath,
    required String webPath,
    required String successMessage,
    Map<String, dynamic>? body,
  }) async {
    if (listingId.trim().isEmpty) {
      return const Left(ServerFailure(message: 'İlan bulunamadı'));
    }

    final headers = await _closureHeaders();
    if (headers == null) {
      return const Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
    }

    final attempts = <Future<Either<Failure, String>?> Function()>[];
    for (final url in _closureWebUrls(webPath)) {
      attempts.add(() async {
        final webHeaders = await _closureHeaders(web: true);
        if (webHeaders == null) return null;
        return _sendClosure(
          method: method,
          url: url,
          headers: webHeaders,
          body: body,
          successMessage: successMessage,
          absolute: true,
        );
      });
    }
    attempts.add(() {
      return _sendClosure(
        method: method,
        url: bammaPath,
        headers: headers,
        body: body,
        successMessage: successMessage,
        absolute: false,
      );
    });

    Either<Failure, String>? authFailure;
    for (final attempt in attempts) {
      final result = await attempt();
      if (result == null) continue;
      final stop = result.fold((failure) {
        if (failure is AuthFailure) {
          authFailure = result;
          return false;
        }
        return true;
      }, (_) => true);
      if (stop) return result;
    }

    return authFailure ??
        const Left(ServerFailure(message: 'İşlem tamamlanamadı'));
  }

  List<String> _closureWebUrls(String path) {
    final urls = <String>[];
    void add(String? origin) {
      if (origin == null || origin.trim().isEmpty) return;
      final url = EnvApi.amplifyStyleTrailingSlash(
        '${origin.replaceAll(RegExp(r'/$'), '')}$path',
      );
      if (url != null && url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }

    add('https://zecorner.com');
    add('https://www.zecorner.com');
    add(EnvApi.webNextApiOrigin);
    return urls;
  }

  Future<Map<String, String>?> _closureHeaders({bool web = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userJWT = prefs.getString('userJWT');
    if (userJWT == null || userJWT.isEmpty) return null;

    final headers = <String, String>{
      'X-SESSION': userJWT,
      'X-API-KEY': ApiConfig.apiKey,
      'X-APP-ID': ApiConfig.appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (web) {
      headers['Authorization'] = 'Bearer $userJWT';
      final userId = prefs.getString('userID');
      if (userId != null && userId.isNotEmpty) {
        headers['X-UR-ID'] = userId;
      }
    }
    return headers;
  }

  /// `null` dönerse bir sonraki adres denenir (404 / 405 / ağ).
  Future<Either<Failure, String>?> _sendClosure({
    required String method,
    required String url,
    required Map<String, String> headers,
    required String successMessage,
    required bool absolute,
    Map<String, dynamic>? body,
  }) async {
    try {
      final dio = absolute
          ? Dio(
              BaseOptions(
                connectTimeout: ApiConfig.connectionTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                followRedirects: true,
                validateStatus: (status) => status != null && status < 500,
              ),
            )
          : _dio;

      final options = Options(
        headers: headers,
        validateStatus: (status) => status != null && status < 500,
      );
      final response = method == 'GET'
          ? await dio.get(url, options: options)
          : await dio.post(url, data: body, options: options);

      final code = response.statusCode ?? 0;
      if (code == 404 || code == 405 || code == 308) return null;
      if (code == 401 || code == 403) {
        return const Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }

      final data = response.data;
      final apiMessage = _closureMessage(data);
      if (code == 200 || code == 201) {
        if (data is Map && data['success'] == false) {
          return Left(
            ServerFailure(message: apiMessage ?? 'İşlem tamamlanamadı'),
          );
        }
        if (data is Map &&
            data['code'] != null &&
            data['code'].toString().toUpperCase() == 'ERROR') {
          return Left(
            ServerFailure(message: apiMessage ?? 'İşlem tamamlanamadı'),
          );
        }
        return Right(
          (apiMessage != null && apiMessage.isNotEmpty)
              ? apiMessage
              : successMessage,
        );
      }

      final notFound = apiMessage != null &&
          apiMessage.toLowerCase().contains('not found');
      if (notFound) return null;
      return Left(
        ServerFailure(message: apiMessage ?? 'Sunucu hatası: $code'),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == null || code == 404 || code == 405 || code >= 500) {
        return null;
      }
      if (code == 401 || code == 403) {
        return const Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      return Left(
        ServerFailure(
          message: _closureMessage(e.response?.data) ??
              e.message ??
              'Ağ hatası',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String? _closureMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['DESCRIPTION'] ?? data['description'];
      final text = message?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }

  Future<Either<Failure, String>> _updateListingState(
    String listingId, {
    required String state,
    String? message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJWT = prefs.getString('userJWT');

      if (userJWT == null) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      final path = ListingEndpoints.updateListing.replaceAll('{id}', listingId);
      final body = <String, dynamic>{'state': state};
      if (message != null && message.isNotEmpty) {
        body['message'] = message;
      }

      final response = await _dio.post(
        path,
        data: body,
        options: Options(
          headers: {
            'X-SESSION': userJWT,
            'X-API-KEY': ApiConfig.apiKey,
            'X-APP-ID': ApiConfig.appId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map && data['code'] == 'SUCCESS') {
          return Right(
            data['message']?.toString() ?? 'İşlem tamamlandı.',
          );
        }
        if (data is Map && data['message'] != null) {
          return Right(data['message'].toString());
        }
        return const Right('İşlem tamamlandı.');
      }

      return Left(
        ServerFailure(
          message: data is Map
              ? (data['message']?.toString() ??
                  'Sunucu hatası: ${response.statusCode}')
              : 'Sunucu hatası: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Oturum süresi dolmuş'));
      }
      final errorData = e.response?.data;
      return Left(
        ServerFailure(
          message: errorData is Map
              ? (errorData['message']?.toString() ?? 'Ağ hatası: ${e.message}')
              : 'Ağ hatası: ${e.message}',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }
}

class ListingPreSale {
  final int owner;
  final String ownerTitle;
  final String ownerTypeDescription;
  final String ownerPicture;

  const ListingPreSale({
    required this.owner,
    required this.ownerTitle,
    required this.ownerTypeDescription,
    required this.ownerPicture,
  });

  bool get hasOwner => owner > 0;

  factory ListingPreSale.fromJson(Map<String, dynamic> json) {
    final nested = json['data'] ?? json['preSale'] ?? json['presale'];
    final source = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;

    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ListingPreSale(
      owner: asInt(source['owner']),
      ownerTitle: source['owner_title']?.toString() ?? '',
      ownerTypeDescription: source['owner_type_description']?.toString() ?? '',
      ownerPicture: source['owner_picture']?.toString() ?? '',
    );
  }
}

class ListingPanelResponseModel {
  final List<ListingPanelModel> listings;
  final int totalCount;
  final int totalPages;
  final int page;

  ListingPanelResponseModel({
    required this.listings,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ListingPanelResponseModel.fromJson(Map<String, dynamic> json) {
    return ListingPanelResponseModel(
      listings: (json['listings'] as List? ?? [])
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return ListingPanelModel.fromJson(item);
              }
              if (item is Map) {
                return ListingPanelModel.fromJson(Map<String, dynamic>.from(item));
              }
            } catch (e) {
              print('⚠️ Listing parse hatası: $e');
            }
            return null;
          })
          .whereType<ListingPanelModel>()
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listings': listings.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
