import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zecorner/core/config/env_api.dart';

/// Image utility functions for Zecorner Application
/// 
/// Handles S3 image URL generation and image widget creation
class ImageUtils {
  // =====================================================
  // BASE CONFIGURATION
  // =====================================================
  
  /// Get production host URL for images (from NEXT_PUBLIC_HOST env var)
  static String get imageHost => dotenv.env['NEXT_PUBLIC_HOST'] ?? 'https://zecorner.com';
  
  /// Get backend host URL for API calls (from BAMMA_URL env var) 
  static String get apiHost => dotenv.env['BAMMA_URL'] ?? '${EnvApi.origin}';
  
  /// S3 file retrieve endpoint (matches web implementation)
  static const String fileRetrieveEndpoint = '/api/retrieve-file';
  
  // =====================================================
  // S3 IMAGE URL GENERATION
  // =====================================================
  
  /// Generate S3 image URL from file ID
  /// 
  /// Exact match of web function: `${process.env.NEXT_PUBLIC_HOST}/api/retrieve-file?name=${s3Id}`
  /// Mobile: `${imageHost}/api/retrieve-file?name=${s3Id}`
  /// 
  /// [s3Id] - S3 file identifier
  /// Returns full URL to retrieve the image
  static String getS3FileUrl(String? s3Id) {
    if (s3Id == null || s3Id.isEmpty) {
      return '';
    }
    
    return '$imageHost$fileRetrieveEndpoint?name=$s3Id';
  }

  /// Get alternative image URLs to try if the main one fails
  /// 
  /// [s3Id] - S3 file identifier
  /// Returns list of URLs to try in order
  static List<String> getAlternativeImageUrls(String? s3Id) {
    if (s3Id == null || s3Id.isEmpty) {
      return [];
    }
    
    final bammaAppUrl = dotenv.env['BAMMA_APP_URL'] ?? 'https://bamma.zecorner.com/api/zecorner';
    final bammaBaseUrl = bammaAppUrl.replaceAll('/api/zecorner', '');
    
    return [
      '$imageHost/api/retrieve-file?name=$s3Id',                  // Main production URL (web format)
      '$bammaBaseUrl/api/retrieve-file?name=$s3Id',               // BAMMA API URL  
      '$apiHost/api/retrieve-file?name=$s3Id',                    // Backend IP
      '$apiHost/api/zecorner/retrieve-file?name=$s3Id',           // Backend with zecorner prefix
      '$apiHost/storage/images/$s3Id',                            // Laravel storage format
      '$imageHost/uploads/$s3Id',                                 // Simple uploads folder
    ];
  }
  
  /// Generate cover image URL for listings
  /// 
  /// [coverPicture] - Cover picture S3 ID from listing
  /// Returns full URL or empty string if no image
  static String getCoverImageUrl(String? coverPicture) {
    return getS3FileUrl(coverPicture);
  }
  
  /// Generate profile picture URL
  /// 
  /// [picture] - Profile picture S3 ID
  /// Returns full URL or empty string if no image
  static String getProfileImageUrl(String? picture) {
    return getS3FileUrl(picture);
  }
  
  /// Generate gallery image URL
  /// 
  /// [imageId] - Gallery image S3 ID
  /// Returns full URL or empty string if no image
  static String getGalleryImageUrl(String? imageId) {
    return getS3FileUrl(imageId);
  }
  
  // =====================================================
  // IMAGE VALIDATION
  // =====================================================
  
  /// Check if image URL is valid
  /// 
  /// [url] - Image URL to validate
  /// Returns true if URL is valid and not empty
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    return url.startsWith('http') && url.contains(fileRetrieveEndpoint);
  }
  
  /// Check if S3 ID is valid
  /// 
  /// [s3Id] - S3 file ID to validate
  /// Returns true if ID is valid and not empty
  static bool isValidS3Id(String? s3Id) {
    if (s3Id == null || s3Id.isEmpty) {
      return false;
    }
    
    // S3 IDs are typically UUIDs or alphanumeric strings
    // Basic validation: should contain letters/numbers and hyphens
    final s3IdRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    return s3IdRegex.hasMatch(s3Id) && s3Id.length > 5;
  }
  
  // =====================================================
  // IMAGE WIDGET HELPERS
  // =====================================================
  
  /// Get placeholder image widget for when no image ID exists
  /// 
  /// [size] - Icon size for placeholder
  /// Returns widget to display when there's no image ID
  static Widget getNoImageWidget({double size = 40}) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: size,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 4),
          const Text(
            'Resim Yok',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFBDBDBD),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get placeholder image widget for failed loads
  /// 
  /// [size] - Icon size for placeholder
  /// Returns widget to display when image fails to load
  static Widget getFailedImageWidget({double size = 40}) {
    return Container(
      color: const Color(0xFFFFF3F3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: size,
            color: const Color(0xFFEE2E24),
          ),
          const SizedBox(height: 4),
          const Text(
            'Yüklenmedi',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFEE2E24),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get loading widget for image loading states
  /// 
  /// Returns widget to display while image is loading
  static Widget getLoadingWidget() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE2E24)),
          ),
          SizedBox(height: 8),
          Text(
            'Yükleniyor...',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
