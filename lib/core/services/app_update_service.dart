import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.storeVersion,
    required this.storeUrl,
    required this.storeLabel,
  });

  final String currentVersion;
  final String storeVersion;
  final String storeUrl;
  final String storeLabel;
}

/// Mağazadaki sürümü okur; yüklü sürüm gerideyse zorunlu güncelleme bilgisi döner.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const _iosBundleId = 'com.zeholding.zecorner.test';
  static const _androidPackageId = 'com.zeholding.zecornertest';
  static const _storeCountry = 'tr';
  static const _timeout = Duration(seconds: 8);

  Future<AppUpdateInfo?> checkForRequiredUpdate() async {
    if (kIsWeb) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      if (currentVersion.isEmpty) return null;

      final AppUpdateInfo? store = Platform.isIOS
          ? await _lookupIos(currentVersion)
          : Platform.isAndroid
              ? await _lookupAndroid(currentVersion)
              : null;

      if (store == null) return null;
      if (compareVersions(currentVersion, store.storeVersion) >= 0) {
        return null;
      }
      return store;
    } catch (e) {
      debugPrint('AppUpdateService: kontrol hatası: $e');
      return null;
    }
  }

  Future<AppUpdateInfo?> _lookupIos(String currentVersion) async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': _iosBundleId,
      'country': _storeCountry,
    });
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    final count = body['resultCount'];
    final results = body['results'];
    if (count is! num || count < 1 || results is! List || results.isEmpty) {
      return null;
    }
    final first = results.first;
    if (first is! Map) return null;
    final storeVersion = first['version']?.toString().trim() ?? '';
    final storeUrl = first['trackViewUrl']?.toString().trim() ?? '';
    if (storeVersion.isEmpty) return null;

    return AppUpdateInfo(
      currentVersion: currentVersion,
      storeVersion: storeVersion,
      storeUrl: storeUrl.isNotEmpty
          ? storeUrl
          : 'https://apps.apple.com/$_storeCountry/app/id${first['trackId']}',
      storeLabel: "App Store'dan Güncelle",
    );
  }

  Future<AppUpdateInfo?> _lookupAndroid(String currentVersion) async {
    final uri = Uri.https(
      'play.google.com',
      '/store/apps/details',
      {'id': _androidPackageId, 'hl': _storeCountry, 'gl': _storeCountry},
    );
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept-Language': 'tr-TR,tr;q=0.9',
      },
    ).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final storeVersion = _parsePlayStoreVersion(response.body);
    if (storeVersion == null || storeVersion.isEmpty) return null;

    return AppUpdateInfo(
      currentVersion: currentVersion,
      storeVersion: storeVersion,
      storeUrl:
          'https://play.google.com/store/apps/details?id=$_androidPackageId',
      storeLabel: "Play Store'dan Güncelle",
    );
  }

  static String? _parsePlayStoreVersion(String html) {
    final patterns = <RegExp>[
      RegExp(r'\[\[\["(\d+(?:\.\d+){1,3})"\]\]'),
      RegExp(
        r'Current Version</div><span[^>]*>[^<]*<span[^>]*>([\d.]+)</span>',
        caseSensitive: false,
      ),
      RegExp(r'"softwareVersion"\s*:\s*"([\d.]+)"'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// `a < b` → negatif, eşit → 0, `a > b` → pozitif.
  static int compareVersions(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final len = math.max(pa.length, pb.length);
    for (var i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  static List<int> _parts(String version) {
    return version.split('.').map((raw) {
      final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
      return int.tryParse(digits ?? '') ?? 0;
    }).toList();
  }
}
