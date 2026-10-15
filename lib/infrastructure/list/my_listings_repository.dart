import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/config/api_config.dart';
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
