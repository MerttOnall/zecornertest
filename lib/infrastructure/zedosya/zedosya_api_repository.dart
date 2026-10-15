import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/utils/zedosya_utils.dart';
import 'package:zecorner/models/zedosya/zedosya_api_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zecorner/core/config/env_api.dart';

class ZeDosyaApiRepository {
  final Dio _dio;

  ZeDosyaApiRepository({required Dio dio}) : _dio = dio;

  String get _filesEndpoint {
    final configured = dotenv.env['MYOFFICEC']?.trim();
    if (configured != null && configured.isNotEmpty && configured.contains('files')) {
      return configured.startsWith('/') ? configured : '/$configured';
    }
    return '/api/zecorner/files';
  }

  Future<Map<String, String>?> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userJWT');
    final apiKey = dotenv.env['X_API_KEY'];
    final appId = dotenv.env['X_APP_ID'];

    if (token == null) return null;
    if (apiKey == null || appId == null) return null;

    return {
      'X-SESSION': token,
      'X-API-KEY': apiKey,
      'X-APP-ID': appId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  String get _baseUrl => EnvApi.origin;

  Future<Either<Failure, ZeDosyaResponse>> getZeDosyaFiles({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      final baseUrl = _baseUrl;
      final endpoint = _filesEndpoint;

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty && category != 'Hepsi') {
        queryParams['category'] = ZeDosyaUtils.filterCategoryToId(category);
      }

      print('🌐 API Endpoint: $baseUrl$endpoint');
      print('📋 Query Params: $queryParams');

      final response = await _dio.get(
        '$baseUrl$endpoint',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('📥 Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        return Right(ZeDosyaResponse.fromJson(response.data));
      } else {
        return Left(ServerFailure(
            message: 'Failed to load ZeDosya files: ${response.statusCode} ${response.data}'));
      }
    } on DioException catch (e) {
      print('❌ ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('❌ Request: ${e.requestOptions.uri}');
      return Left(_getErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  /// Yeni ZeDosya kaydı oluştur (dosya S3'e ayrı yüklenmiş olmalı).
  Future<Either<Failure, ZeDosyaApiModel>> createFile({
    required String title,
    required String subTitle,
    required String fileName,
    required String uuid,
    required int category,
    String? thumbnail,
    bool featured = false,
    int status = 1,
    List<int>? connectedContacts,
  }) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) {
        return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
      }

      final data = <String, dynamic>{
        'title': title,
        'sub_title': subTitle,
        'file_name': fileName,
        'uuid': uuid,
        'category': category,
        'featured': featured,
        'status': status,
        if (thumbnail != null && thumbnail.isNotEmpty) 'thumbnail': thumbnail,
        if (connectedContacts != null) 'connected_contacts': connectedContacts,
      };

      final url = '$_baseUrl$_filesEndpoint';
      print('📤 ZeDosya create: $url');
      print('📋 Body: $data');

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = _extractFilePayload(response.data);
        if (payload != null) {
          return Right(ZeDosyaApiModel.fromJson(payload));
        }
        return Left(ServerFailure(message: 'Dosya kaydedildi ancak yanıt okunamadı.'));
      }

      return Left(ServerFailure(
        message: _messageFromResponse(response.data) ??
            'Dosya kaydedilemedi (${response.statusCode})',
      ));
    } on DioException catch (e) {
      return Left(_getErrorMessage(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Dosya kaydetme hatası: $e'));
    }
  }

  /// Mevcut ZeDosya kaydını güncelle.
  Future<Either<Failure, ZeDosyaApiModel>> updateFile({
    required int id,
    required String title,
    required String subTitle,
    required String fileName,
    required String uuid,
    required int category,
    String? thumbnail,
    bool featured = false,
    int status = 1,
    List<int>? connectedContacts,
  }) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) {
        return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
      }

      final data = <String, dynamic>{
        'id': id,
        'title': title,
        'sub_title': subTitle,
        'file_name': fileName,
        'uuid': uuid,
        'category': category,
        'featured': featured,
        'status': status,
        if (thumbnail != null && thumbnail.isNotEmpty) 'thumbnail': thumbnail,
        if (connectedContacts != null) 'connected_contacts': connectedContacts,
      };

      final url = '$_baseUrl$_filesEndpoint';
      print('📤 ZeDosya update: $url');
      print('📋 Body: $data');

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = _extractFilePayload(response.data);
        if (payload != null) {
          return Right(ZeDosyaApiModel.fromJson(payload));
        }
        return Right(
          ZeDosyaApiModel(
            id: id,
            title: title,
            subTitle: subTitle,
            fileName: fileName,
            uuid: uuid,
            category: category,
            thumbnail: thumbnail,
            status: status,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            featured: featured,
            connectedContacts: connectedContacts,
          ),
        );
      }

      return Left(ServerFailure(
        message: _messageFromResponse(response.data) ??
            'Dosya güncellenemedi (${response.statusCode})',
      ));
    } on DioException catch (e) {
      return Left(_getErrorMessage(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Dosya güncelleme hatası: $e'));
    }
  }

  /// ZeDosya kaydını sil (status = 0).
  Future<Either<Failure, bool>> deleteFile(int id) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) {
        return Left(AuthFailure(message: 'Oturum bilgisi bulunamadı.'));
      }

      final url = '$_baseUrl$_filesEndpoint';
      final data = {'id': id, 'status': 0};

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return const Right(true);
      }

      return Left(ServerFailure(
        message: _messageFromResponse(response.data) ??
            'Dosya silinemedi (${response.statusCode})',
      ));
    } on DioException catch (e) {
      return Left(_getErrorMessage(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Dosya silme hatası: $e'));
    }
  }

  Map<String, dynamic>? _extractFilePayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('id') && data.containsKey('uuid')) {
        return data;
      }
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      if (data['result'] is Map<String, dynamic>) {
        return data['result'] as Map<String, dynamic>;
      }
    }
    return null;
  }

  String? _messageFromResponse(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['DESCRIPTION'] ?? data['description'];
      if (msg != null) return msg.toString();
    }
    return null;
  }

  Failure _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? 'Server error';
      if (statusCode == 401) {
        return AuthFailure(message: message);
      } else {
        return ServerFailure(message: message);
      }
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'No internet connection.');
    } else {
      return ServerFailure(message: e.message ?? 'An unknown error occurred.');
    }
  }

  /// Dosya indirme metodu
  Future<Either<Failure, String>> downloadFile(ZeDosyaApiModel file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        return Left(AuthFailure(message: 'JWT token not found.'));
      }

      if (apiKey == null || appId == null) {
        return Left(AuthFailure(message: 'API anahtarları bulunamadı.'));
      }

      final headers = {
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('📁 File: ${file.fileName}');

      // Gerçekçi endpoint listesi - mevcut API yapısına göre
      final endpoints = [
        // Mevcut API'deki dosya endpoint'leri
        "${EnvApi.origin}/api/zecorner/files/${file.id}",
        "${EnvApi.origin}/api/zecorner/files/${file.uuid}",
        
        // Dosya içeriği için alternatif endpoint'ler
        "${EnvApi.origin}/api/zecorner/files/${file.id}/content",
        "${EnvApi.origin}/api/zecorner/files/${file.uuid}/content",
        "${EnvApi.origin}/api/zecorner/files/${file.id}/file",
        "${EnvApi.origin}/api/zecorner/files/${file.uuid}/file",
        
        // Retrieve file endpoint'leri
        "${EnvApi.origin}/api/retrieve-file?name=${file.uuid}",
        "${EnvApi.origin}/api/retrieve-file?name=${file.fileName}",
        "${EnvApi.origin}/api/zecorner/retrieve-file?name=${file.uuid}",
        "${EnvApi.origin}/api/zecorner/retrieve-file?name=${file.fileName}",
        
        // Storage endpoint'leri
        "${EnvApi.origin}/storage/files/${file.uuid}",
        "${EnvApi.origin}/storage/files/${file.fileName}",
        "${EnvApi.origin}/uploads/${file.uuid}",
        "${EnvApi.origin}/uploads/${file.fileName}",
        
        // Download endpoint'leri (son çare)
        "${EnvApi.origin}/api/zecorner/files/${file.id}/download",
        "${EnvApi.origin}/api/zecorner/files/${file.uuid}/download",
      ];

      for (String endpoint in endpoints) {
        try {
          print('🔄 Trying endpoint: $endpoint');
          
          // Önce bytes olarak dene
          Response response = await _dio.get(
            endpoint,
            options: Options(
              headers: headers,
              responseType: ResponseType.bytes,
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (status) {
                return status! < 500;
              },
            ),
          );

          // Eğer bytes boşsa, JSON olarak dene
          if (response.data == null || (response.data as List<int>).isEmpty) {
            print('🔄 Trying as JSON: $endpoint');
            response = await _dio.get(
              endpoint,
              options: Options(
                headers: headers,
                responseType: ResponseType.json,
                followRedirects: true,
                maxRedirects: 5,
                validateStatus: (status) {
                  return status! < 500;
                },
              ),
            );
          }

          if (response.statusCode == 200) {
            try {
              List<int> bytes;
              
              // Response type'a göre bytes'ı al
              if (response.data is List<int>) {
                bytes = response.data as List<int>;
              } else if (response.data is Map<String, dynamic>) {
                // JSON response ise, dosya URL'ini çıkar
                final jsonData = response.data as Map<String, dynamic>;
                if (jsonData.containsKey('file_url') || jsonData.containsKey('url')) {
                  final fileUrl = jsonData['file_url'] ?? jsonData['url'];
                  print('🔄 Found file URL in JSON: $fileUrl');
                  
                  // URL'den dosyayı indir
                  final fileResponse = await _dio.get(
                    fileUrl,
                    options: Options(
                      responseType: ResponseType.bytes,
                      headers: headers,
                    ),
                  );
                  
                  if (fileResponse.statusCode == 200) {
                    bytes = fileResponse.data as List<int>;
                  } else {
                    print('❌ Failed to download from URL: $fileUrl');
                    continue;
                  }
                } else {
                  print('❌ No file URL found in JSON response');
                  continue;
                }
              } else {
                print('❌ Unknown response type: ${response.data.runtimeType}');
                continue;
              }
              
              if (bytes.isEmpty) {
                print('❌ Empty file data from: $endpoint');
                continue;
              }
              
              final directory = await _getDownloadDirectory();
              
              // Dizin yoksa oluştur
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
              
              // Güvenli dosya adı oluştur
              final safeFileName = _getSafeFileName(file.fileName);
              final filePath = '${directory.path}/$safeFileName';
              final downloadedFile = File(filePath);
              
              await downloadedFile.writeAsBytes(bytes);
              final onDisk = await downloadedFile.length();
              if (onDisk == 0) {
                print('❌ Disk üzerinde dosya boyutu 0: $filePath');
                continue;
              }

              print('✅ File downloaded: $filePath ($onDisk bytes)');
              return Right(filePath);
            } catch (e) {
              print('❌ File save error: $e');
              continue;
            }
          } else {
            print('❌ Endpoint failed: $endpoint - Status: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Endpoint error: $endpoint - $e');
          continue;
        }
      }

      // Tüm endpoint'ler başarısız oldu
      return Left(ServerFailure(
        message: 'Dosya indirilemedi: Tüm endpoint\'ler başarısız oldu',
      ));
    } on DioException catch (e) {
      print('❌ Download ERROR: ${e.type}');
      print('❌ Response: ${e.response?.statusCode} - ${e.response?.data}');
      return Left(_getErrorMessage(e));
    } catch (e) {
      print('❌ Download Unexpected Error: $e');
      return Left(ServerFailure(message: 'Dosya indirme hatası: $e'));
    }
  }

  /// Kullanıcının erişebileceği indirme klasörü (All Files Access gerektirmez).
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isIOS) {
      final doc = await getApplicationDocumentsDirectory();
      final sub = Directory('${doc.path}/Downloads');
      if (!await sub.exists()) {
        await sub.create(recursive: true);
      }
      return sub;
    }
    if (Platform.isAndroid) {
      try {
        final pub = await getDownloadsDirectory();
        if (pub != null) {
          final sub = Directory('${pub.path}/Zecorner');
          if (!await sub.exists()) {
            await sub.create(recursive: true);
          }
          return sub;
        }
      } catch (_) {}
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final sub = Directory('${ext.path}/Downloads');
          if (!await sub.exists()) {
            await sub.create(recursive: true);
          }
          return sub;
        }
      } catch (_) {}
    }
    final fallback = await getApplicationDocumentsDirectory();
    final sub = Directory('${fallback.path}/Downloads');
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return sub;
  }

  /// Güvenli dosya adı oluştur
  String _getSafeFileName(String fileName) {
    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final finalName = safeName.replaceAll(' ', '_');
    if (finalName.length > 100) {
      final dot = finalName.lastIndexOf('.');
      if (dot <= 0 || dot >= finalName.length - 1) {
        return finalName.substring(0, 100);
      }
      final ext = finalName.substring(dot + 1);
      final base = finalName.substring(0, dot);
      final keep = base.length > 95 ? 95 : base.length;
      return '${base.substring(0, keep)}.$ext';
    }
    return finalName;
  }
}
