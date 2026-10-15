import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';

class AppConfig {
  // API Endpoints — origin [.env]; zecorner öneki [EnvApi]
  static String get baseUrl => EnvApi.origin;
  static String get apiBaseUrl => EnvApi.zecornerBase;
  
  // Contact endpoints
  static String get contactsEndpoint => '$apiBaseUrl/contacts';
  static String get contactTypesEndpoint => '$apiBaseUrl/refContactTypes';
  static String get professionsEndpoint => '$apiBaseUrl/refProfessions';
  static String get educationsEndpoint => '$apiBaseUrl/refEducations';
  static String get citiesEndpoint => '$apiBaseUrl/refCities';
  static String get countriesEndpoint => '$apiBaseUrl/refCountries';
  static String get provincesEndpoint => '$apiBaseUrl/refProvinces';
  static String get uploadEndpoint => '$apiBaseUrl/upload';
  static String get searchContactsEndpoint => '$apiBaseUrl/contacts/search';
  
  // Customer endpoints
  static String get customersEndpoint => '$apiBaseUrl/customer';
  
  // Province endpoints (ref: GET refProvince/{code} — ilçeler ve quarters aynı yanıtta)
  static String getDistrictsEndpoint(int provinceCode) => '$apiBaseUrl/refProvince/$provinceCode';
  /// Ayrı mahalle endpoint’i; mobilde çoğunlukla ilçe nesnesindeki `quarters` kullanılır.
  static String getQuartersEndpoint(int districtCode) => '$apiBaseUrl/refDistricts/$districtCode/quarters';
  
  // API Keys
  static String? get apiKey => dotenv.env['X_API_KEY'];
  static String? get appId => dotenv.env['X_APP_ID'];
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getHeaders(String? sessionToken) {
    final headers = Map<String, String>.from(defaultHeaders);
    
    if (sessionToken != null) {
      headers['X-SESSION'] = sessionToken;
    }
    
    if (apiKey != null) {
      headers['X-API-KEY'] = apiKey!;
    }
    
    if (appId != null) {
      headers['X-APP-ID'] = appId!;
    }
    
    return headers;
  }
  
  // File upload headers
  static Map<String, String> getUploadHeaders(String? sessionToken) {
    final headers = <String, String>{};
    
    if (sessionToken != null) {
      headers['X-SESSION'] = sessionToken;
    }
    
    if (apiKey != null) {
      headers['X-API-KEY'] = apiKey!;
    }
    
    if (appId != null) {
      headers['X-APP-ID'] = appId!;
    }
    
    headers['Accept'] = 'application/json';
    
    return headers;
  }
  
  // Validation
  static bool get isConfigured => apiKey != null && appId != null;
  
  static String? get configurationError {
    if (apiKey == null) return 'X_API_KEY is not configured';
    if (appId == null) return 'X_APP_ID is not configured';
    return null;
  }
}
