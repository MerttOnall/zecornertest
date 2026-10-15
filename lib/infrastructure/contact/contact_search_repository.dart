import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';

class ContactSearchRepository {
  static String get _baseUrl => EnvApi.zecornerBase;
  
  Future<List<ContactSearchModel>> searchContacts({
    required String query,
    int size = 10,
    String type = '',
    bool userContacts = false,
    List<int>? types, // Birden fazla type parametresi için
  }) async {
    try {
      // Authentication bilgilerini al
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null) {
        throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
      }

      if (apiKey == null || appId == null) {
        throw Exception('API anahtarları bulunamadı.');
      }

      // Web: pages/api/search-contacts.ts → BAMMA `/search/contacts` + orijinal query string
      // Mobil aynı BAMMA ucuna gider; query olduğu gibi eklenir.
      // Örnek: /search/contacts/?user_contacts=true&type=201&q=deneme&size=6
      final queryString = StringBuffer();
      
      // user_contacts parametresi
      if (userContacts) {
        queryString.write('user_contacts=true');
      }
      
      // Birden fazla type parametresi varsa (types listesi)
      if (types != null && types.isNotEmpty) {
        for (final typeValue in types) {
          if (queryString.isNotEmpty) queryString.write('&');
          queryString.write('type=$typeValue');
        }
      } else if (type.isNotEmpty) {
        // Tek type parametresi
        if (queryString.isNotEmpty) queryString.write('&');
        queryString.write('type=$type');
      }
      
      // q ve size parametreleri
      if (queryString.isNotEmpty) queryString.write('&');
      queryString.write('q=${Uri.encodeComponent(query)}');
      queryString.write('&size=$size');
      
      // Web'deki API koduna göre endpoint: /search/contacts/ (trailing slash var)
      final uri = Uri.parse('$_baseUrl/search/contacts/?$queryString');

      // DEBUG: API URL'ini yazdır
      print('🔍 ContactSearchRepository API URL: ${uri.toString()}');
      print('🔍 Query String: $queryString');

      final response = await http.get(
        uri,
        headers: {
          'X-SESSION': token,
          'X-API-KEY': apiKey,
          'X-APP-ID': appId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('🔍 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // DEBUG: API response'unu yazdır
        print('🔍 DEBUG: ContactSearchRepository API Response:');
        print('🔍 Response Body: ${response.body}');
        print('🔍 Decoded Type: ${decoded.runtimeType}');
        
        List<dynamic> jsonList;
        
        // API bazen array, bazen tek obje döndürebilir
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map) {
          // Tek obje ise listeye çevir
          jsonList = [decoded];
        } else {
          jsonList = [];
        }
        
        print('🔍 JSON List Length: ${jsonList.length}');
        
        if (jsonList.isNotEmpty) {
          print('🔍 First Contact JSON: ${jsonList[0]}');
        }
        
        final contacts = jsonList.map((json) {
          print('🔍 Processing Contact JSON: $json');
          final contact = ContactSearchModel.fromJson(json);
          print('🔍 Parsed Contact: contactNo=${contact.contactNo}, title=${contact.title}');
          return contact;
        }).toList();
        
        return contacts;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Contact search failed: $e');
      rethrow;
    }
  }
}
