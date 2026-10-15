import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/config/api_config.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/models/award/award_filter_options.dart';
import 'package:zecorner/models/award/reward_model.dart';

class AwardQueryParams {
  final DateTime startDate;
  final DateTime endDate;
  final AwardFilterConfig filter;

  const AwardQueryParams({
    required this.startDate,
    required this.endDate,
    required this.filter,
  });

  Map<String, dynamic> toQueryMap() {
    final query = <String, dynamic>{
      'group_by': filter.groupBy,
      'start_date': _formatDate(startDate, isEndDate: false),
      'end_date': _formatDate(endDate, isEndDate: true),
    };

    if (filter.listingType != null && filter.listingType!.isNotEmpty) {
      query['listing_type'] = filter.listingType;
    }

    if (filter.contactTypes != null && filter.contactTypes!.isNotEmpty) {
      query['contact_type'] = filter.contactTypes;
    }

    return query;
  }

  /// Web: `YYYY-MM-DDTHH:mm:ss` (gün başı / gün sonu)
  static String _formatDate(DateTime date, {required bool isEndDate}) {
    final normalized = isEndDate
        ? DateTime(date.year, date.month, date.day, 23, 59, 59)
        : DateTime(date.year, date.month, date.day);
    final y = normalized.year.toString().padLeft(4, '0');
    final m = normalized.month.toString().padLeft(2, '0');
    final d = normalized.day.toString().padLeft(2, '0');
    final h = normalized.hour.toString().padLeft(2, '0');
    final min = normalized.minute.toString().padLeft(2, '0');
    final s = normalized.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }
}

class AwardRepository {
  static const String defaultAwardTitle = AwardFilterOptions.defaultTitle;

  Future<Either<Failure, RewardResponse>> getRewards({
    required DateTime startDate,
    required DateTime endDate,
    String? awardTitle,
  }) {
    return getRewardsWithParams(
      AwardQueryParams(
        startDate: startDate,
        endDate: endDate,
        filter: AwardFilterOptions.resolve(awardTitle),
      ),
    );
  }

  Future<Either<Failure, RewardResponse>> getRewardsWithParams(
    AwardQueryParams params,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      if (token == null || token.isEmpty) {
        return Left(AuthFailure(message: 'Kullanıcı oturumu bulunamadı'));
      }

      final apiKey = dotenv.env['X_API_KEY'] ?? ApiConfig.apiKey;
      final appId = dotenv.env['X_APP_ID'] ?? ApiConfig.appId;

      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final urls = _resolveRewardsUrls();
      int? lastStatus;
      String? lastMessage;

      for (final url in urls) {
        try {
          final response = await Dio().get<dynamic>(
            url,
            queryParameters: params.toQueryMap(),
            options: Options(
              headers: headers,
              responseType: ResponseType.json,
              listFormat: ListFormat.multi,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            return Right(
              RewardResponse.fromJson(
                response.data,
                groupBy: params.filter.groupBy,
              ),
            );
          }

          lastStatus = response.statusCode;
          final data = response.data;
          if (data is Map<String, dynamic> && data['message'] != null) {
            lastMessage = data['message'].toString();
          }

          if (_shouldTryNextUrl(response.statusCode)) {
            continue;
          }

          return Left(
            ServerFailure(
              message: lastMessage ?? 'Ödül verileri yüklenemedi (${response.statusCode})',
              statusCode: response.statusCode,
            ),
          );
        } on DioException catch (e) {
          lastStatus = e.response?.statusCode;
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            lastMessage = data['message'].toString();
          }
          if (_shouldTryNextUrl(e.response?.statusCode)) {
            continue;
          }
          rethrow;
        }
      }

      if (lastStatus == 401) {
        return Left(AuthFailure(message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.'));
      }

      return Left(
        ServerFailure(
          message: lastMessage ?? 'Ödül verileri yüklenemedi${lastStatus != null ? ' ($lastStatus)' : ''}',
          statusCode: lastStatus,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(AuthFailure(message: 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.'));
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Geçersiz filtre parametreleri';
        return Left(ServerFailure(message: message, statusCode: 400));
      }
      return Left(ServerFailure(message: 'Ağ hatası: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen hata: $e'));
    }
  }

  bool _shouldTryNextUrl(int? statusCode) {
    return statusCode == null ||
        statusCode == 401 ||
        statusCode == 404 ||
        statusCode == 405;
  }

  List<String> _resolveRewardsUrls() {
    final urls = <String>[];

    final explicit = dotenv.env['FINANCE_REWARDS']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      if (explicit.startsWith('http')) {
        urls.add(EnvApi.amplifyStyleTrailingSlash(explicit)!);
      } else {
        final path = explicit.startsWith('/') ? explicit : '/$explicit';
        urls.add(
          '${EnvApi.origin}${path.endsWith('/') ? path : '$path/'}',
        );
      }
    } else {
      urls.add('${EnvApi.origin}/api/zecorner/finance/rewards/');
    }

    return urls.toSet().toList();
  }
}
