import 'package:zecorner/core/config/env_api.dart';

/// API Configuration for Zecorner Application
///
/// Organized by feature modules following the same structure as AppRouter
/// for better consistency and maintainability.
abstract class ApiConfig {
  // =====================================================
  // BASE CONFIGURATION
  // =====================================================

  /// [.env] `BASE_URL` + `/api/zecorner` — tek kaynak [EnvApi].
  static String get baseUrl => EnvApi.zecornerBase;
  
  /// API version prefix
  static const String apiVersion = '/v1';
  
  /// Full base URL with version
  static String get fullBaseUrl => baseUrl + apiVersion;

  // =====================================================
  // NETWORK CONFIGURATION
  // =====================================================
  
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;

  /// Base64 görsel/belge yükleme (Next ~135MB limit); gövde büyük, `sendTimeout` uzun olmalı.
  static const Duration mediaUploadSendTimeout = Duration(minutes: 10);
  static const Duration mediaUploadReceiveTimeout = Duration(minutes: 6);
  
  // =====================================================
  // API CREDENTIALS
  // =====================================================
  
  /// API Key for authentication
  /// TODO: Move to .env file for production
  static const String apiKey = 'ed017c68-24ca-4239-ae68-0fa041391855';
  
  /// Application ID
  static const String appId = 'zecorner';
  
  // =====================================================
  // DEFAULT HEADERS
  // =====================================================
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Client': 'flutter-app',
    'X-API-KEY': apiKey,
    'X-APP-ID': appId,
  };

  // =====================================================
  // UTILITY METHODS
  // =====================================================
  
  /// Replace path parameters in endpoint URL
  static String replacePath(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }

  /// Build full URL with base URL
  static String buildUrl(String path) {
    return fullBaseUrl + path;
  }

  /// Build URL with path parameters
  static String buildUrlWithParams(String path, Map<String, dynamic> params) {
    return buildUrl(replacePath(path, params));
  }

  /// Environment check
  static bool get isProduction => !baseUrl.contains('localhost');
  static bool get isDevelopment => baseUrl.contains('localhost');
}

// =====================================================
// AUTH & SECURITY
// =====================================================

/// Authentication and security endpoints
abstract class AuthEndpoints {
  // Login & Register
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  
  // Profile & Session
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String refresh = '/auth/refresh';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  
  // Verification
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String twoFactorAuth = '/auth/2fa';
}

// =====================================================
// HOME SCREENS DATA
// =====================================================

/// Home page content and public data endpoints  
abstract class HomeEndpoints {
  // Main content
  static const String homeData = '/home';
  static const String homeIlan = '/home/ilan';
  static const String homeOffice = '/home/office';
  static const String homePortfoy = '/home/portfoy';
  static const String homeDanisman = '/home/danisman';
  static const String homeFranchise = '/home/franchise';
  
  // Listings
  static const String homeListings = '/home/listings';
  static const String homeListingDetail = '/home/listings/{id}';
  static const String homeTumIlans = '/home/all-listings';
  static const String homeIlanDetail = '/home/ilan/{id}';
  
  // Office data
  static const String homeOfficeDetail = '/home/office/{id}';
  
  // Content pages
  static const String about = '/home/about';
  static const String team = '/home/team';
  static const String contact = '/home/contact';
  static const String sss = '/home/sss';
  static const String blog = '/home/blog';
  static const String blogDetail = '/home/blog/{id}';
  
  // News
  static const String zehaber = '/home/zehaber';
  static const String zehaberDetail = '/home/zehaber/{id}';
  
  // Seminar
  static const String seminer = '/home/seminer';
  
  // Legal pages
  static const String profileCerez = '/home/cerez';
  static const String profileKvkk = '/home/kvkk';
  static const String profileKosul = '/home/kosul';
}

// =====================================================
// PANEL & DASHBOARDS
// =====================================================

/// Dashboard and panel data endpoints
abstract class DashboardEndpoints {
  static const String dashboard = '/dashboard';
  static const String brokerDashboard = '/dashboard/broker';
  static const String danismanDashboard = '/dashboard/danisman';
  static const String adminDashboard = '/dashboard/admin';
  
  // Dashboard widgets data
  static const String stats = '/dashboard/stats';
  static const String recentActivity = '/dashboard/activity';
  static const String notifications = '/dashboard/notifications';
  static const String quickActions = '/dashboard/quick-actions';
}

// =====================================================
// USER MANAGEMENT
// =====================================================

/// User and person management endpoints
abstract class UserEndpoints {
  // Users
  static const String users = '/users';
  static const String addUser = '/users';
  static const String showUser = '/users/{id}';
  static const String editUser = '/users/{id}';
  static const String deleteUser = '/users/{id}';
  
  // Persons (Kişiler)
  static const String persons = '/persons';
  static const String addPerson = '/persons';
  static const String showPerson = '/persons/{id}';
  static const String editPerson = '/persons/{id}';
  static const String deletePerson = '/persons/{id}';
  
  // Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String accountSettings = '/profile/settings';
  
  // Favorites
  static const String favoriteList = '/profile/favorites';
  static const String favoriteDanisman = '/profile/favorite-danisman';
}

// =====================================================
// OFFICE MANAGEMENT
// =====================================================

/// Office and branch management endpoints
abstract class OfficeEndpoints {
  // Offices (Admin)
  static const String offices = '/offices';
  static const String addOffice = '/offices';
  static const String showOffice = '/offices/{id}';
  static const String editOffice = '/offices/{id}';
  static const String deleteOffice = '/offices/{id}';
  
  // My Office (User)
  static const String myOffice = '/my-office';
  static const String myOfficeDetail = '/my-office/{id}';
  static const String myOfficeAdd = '/my-office';
  static const String myOfficeEdit = '/my-office/{id}';
}

// =====================================================
// CUSTOMER MANAGEMENT
// =====================================================

/// Customer and client management endpoints
abstract class CustomerEndpoints {
  static const String customers = '/customers';
  static const String addCustomer = '/customers';
  static const String showCustomer = '/customers/{id}';
  static const String editCustomer = '/customers/{id}';
  static const String deleteCustomer = '/customers/{id}';
  static const String mulkCustomer = '/customers/mulk';
}

// =====================================================
// PORTFOLIO MANAGEMENT
// =====================================================

/// Portfolio and property management endpoints
abstract class PortfolioEndpoints {
  static const String portfolio = '/portfolio';
  static const String addPortfolio = '/realEstate'; // Web API: /realEstate
  static const String showPortfolio = '/portfolio/{id}';
  static const String editPortfolio = '/portfolio/{id}';
  static const String deletePortfolio = '/portfolio/{id}';
  static const String detailPortfolio = '/portfolio/{id}/detail';
  
  // File upload endpoints
  static const String uploadImage = '/upload-image';
  static const String uploadFile = '/upload-file';
}

// =====================================================
// LISTING MANAGEMENT
// =====================================================

/// Property listing management endpoints
abstract class ListingEndpoints {
  // My Listings
  static const String listings = '/my-listings';
  static const String addListing = '/my-listings';
  static const String showListing = '/my-listings/{id}';
  static const String editListing = '/my-listings/{id}';
  static const String deleteListing = '/my-listings/{id}';
  
  // Listing update endpoints (matching working API)
  static const String updateListing = '/listing/{id}';
  static const String updateListingState = '/listing/{id}/state';
  static const String getListingDetail = '/listing/{id}';
  static const String getListingStates = '/refListingStates';
  static const String getPreSale = '/preSale/{id}';
  
  // Listing approval process
  static const String listingApproval = '/listings/approval';
  static const String listingsPendingApproval = '/listingsPendingApproval';
  static const String getAdvisorListings = '/get-advisor-listings/{contactNo}';
  static const String approveListing = '/listings/{id}/approve';
  static const String rejectListing = '/listings/{id}/reject';
  static const String requestListingEdit = '/listings/{id}/request-edit';
}

// =====================================================
// CONTENT MANAGEMENT
// =====================================================

/// Content management endpoints (Zehaber, Zeblog, etc.)
abstract class ContentEndpoints {
  // Zehaber (News)
  static const String zehaber = '/zehaber';
  static const String addZehaber = '/zehaber';
  static const String showZehaber = '/zehaber/{id}';
  static const String editZehaber = '/zehaber/{id}';
  static const String deleteZehaber = '/zehaber/{id}';
  
  // Zeblog (Blog)
  static const String zeblog = '/zeblog';
  static const String addZeblog = '/zeblog';
  static const String showZeblog = '/zeblog/{id}';
  static const String editZeblog = '/zeblog/{id}';
  static const String deleteZeblog = '/zeblog/{id}';
  
  // SSS (FAQ)
  static const String adminsss = '/admin/sss';
  static const String addSss = '/admin/sss';
  static const String showSss = '/admin/sss/{id}';
  static const String editSss = '/admin/sss/{id}';
  static const String deleteSss = '/admin/sss/{id}';
}

// =====================================================
// COMMUNICATION
// =====================================================

/// Communication and messaging endpoints
abstract class CommunicationEndpoints {
  // Chat
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String chatMessages = '/chatMessages';
  static const String sendMessage = '/chat/send';
  static const String chatHistory = '/chat/history';
  static const String profileChat = '/profile/chat';
  
  // Notifications
  static const String profileNotification = '/profile/notifications';
  static const String markAsRead = '/notifications/{id}/read';
  
  // Bform (Contact forms)
  static const String bform = '/bform';
  static const String submitForm = '/bform/submit';
}

// =====================================================
// BUSINESS OPERATIONS
// =====================================================

/// Business operation endpoints
abstract class BusinessEndpoints {
  // Offers
  static const String offers = '/offers';
  static const String addOffer = '/offers';
  static const String editOffer = '/offers/{id}';
  static const String deleteOffer = '/offers/{id}';
  
  // Task Manager
  static const String taskManager = '/task-manager';
  static const String addTask = '/task-manager';
  static const String editTask = '/task-manager/{id}';
  static const String deleteTask = '/task-manager/{id}';
  
  // Announcements
  static const String announcements = '/announcements';
  static const String addAnnouncement = '/announcements';
  static const String editAnnouncement = '/announcements/{id}';
  static const String deleteAnnouncement = '/announcements/{id}';
  
  // Finance
  static const String finance = '/finance';
  static const String financeReport = '/finance/report';
  
  // Seminar
  static const String seminar = '/seminar';
  static const String addSeminar = '/seminar';
  static const String showSeminar = '/seminar/{id}';
  static const String editSeminar = '/seminar/{id}';
  static const String deleteSeminar = '/seminar/{id}';
}

// =====================================================
// PAYMENT & INVOICES
// =====================================================

/// Invoice and payment endpoints
abstract class InvoiceEndpoints {
  // Invoices (Faturalar)
  static const String invoices = '/pay/invoices';
  static const String invoiceDetail = '/pay/invoices/{id}';
  static const String invoicePdf = '/pay/invoices/{id}/pdf';
  
  // Payment processing
  static const String makePayment = '/pay/invoices/{id}/pay';
  static const String paymentHistory = '/pay/history';
  
  // Coupons
  static const String coupons = '/pay/coupons';
  static const String applyCoupon = '/pay/apply-coupon';
  
  // Payment notification
  static const String paymentNotification = '/pay/notification';
}

// =====================================================
// SYSTEM & TOOLS
// =====================================================

/// System settings and tool endpoints
abstract class SystemEndpoints {
  // System Settings
  static const String systemSettings = '/system-settings';
  static const String oneOfTheConsultants = '/system/consultants';
  
  // ZeDosya (Document management)
  static const String zedosya = '/zedosya';
  static const String editZeDosya = '/zedosya/{id}';
  static const String uploadDocument = '/zedosya/upload';

  // Dosyalarım (kişinin kendi dosyaları — ZeDosya değil)
  static const String myFiles = '/myFiles';
  static const String myFile = '/myFile/{id}';
  
  // Zeilan (Property ads)
  static const String zeilan = '/zeilan';
  
  // Agenda
  static const String agenda = '/agenda';
  static const String addAgenda = '/agenda';
  static const String editAgenda = '/agenda/{id}';
  
  // Map
  static const String fullMap = '/map/full';
  static const String mapData = '/map/data';
}

// =====================================================
// ROLE & PERMISSION MANAGEMENT
// =====================================================

/// Role and permission management endpoints
abstract class RoleEndpoints {
  static const String roles = '/zecorner/roles';
  static const String showRole = '/zecorner/roles/{id}';
  static const String permissions = '/zecorner/permissions';
  static const String userPermissions = '/zecorner/users/{userId}/permissions';
}

// =====================================================
// REFERENCE DATA (İller, İlçeler, Mahalleler, vb.)
// =====================================================

/// Reference data endpoints for dropdowns and lookups
abstract class ReferenceEndpoints {
  // Location data
  static const String provinces = '/refProvinces';
  static const String districts = '/refProvince/{code}'; // Web API: /refProvince/{code} - ilçeler ve quarters içinde geliyor
  // quarters artık districts response içinde geliyor, ayrı endpoint yok
  
  // Real Estate Properties (Portfolio attributes)
  /// Web proxy: `GET /api/get-property-attributes/?type={type}`
  /// BAMMA: `{BAMMA_APP_URL}/refRealEstateProperties?type={type}`
  static const String realEstateProperties = '/refRealEstateProperties';
  static const String categories = '/refCategories';
  static const String categoryListingTypes = '/refCategoryListingTypes';
  /// Web proxy: `GET /api/get-listing-properties-types?category={cat}&listing_type={type}`
  /// BAMMA: `{BAMMA_APP_URL}/refListingProperties?category={cat}&listing_type={type}`
  static const String listingProperties = '/refListingProperties';
  /// Web proxy: `GET /api/get-dictionary/` — Gayrimenkul Sahibi vb. sabit listeler
  /// BAMMA: `{BAMMA_APP_URL}/refDictionary`
  static const String dictionary = '/refDictionary';
  
  // Other reference data
  static const String countries = '/refCountries';
  static const String cities = '/refCities';
  static const String professions = '/refProfessions';
  static const String educations = '/refEducations';
  static const String contactTypes = '/refContactTypes';
} 