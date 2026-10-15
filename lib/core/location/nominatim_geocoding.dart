import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoPlacemark {
  final String? street;
  final String? locality;
  final String? administrativeArea;

  const GeoPlacemark({
    this.street,
    this.locality,
    this.administrativeArea,
  });
}

class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

const _nominatimHeaders = {
  'User-Agent': 'zecorner/1.1.8 (contact@zecorner.com)',
};

String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

Future<List<GeoPlacemark>> placemarkFromCoordinates(
  double latitude,
  double longitude,
) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'lat': latitude.toString(),
    'lon': longitude.toString(),
    'format': 'json',
    'addressdetails': '1',
  });

  final response = await http.get(uri, headers: _nominatimHeaders);
  if (response.statusCode != 200) return [];

  final data = json.decode(response.body) as Map<String, dynamic>;
  final address = data['address'] as Map<String, dynamic>?;
  if (address == null) return [];

  return [
    GeoPlacemark(
      street: _firstNonEmpty(address, [
        'road',
        'pedestrian',
        'footway',
        'neighbourhood',
        'quarter',
      ]),
      locality: _firstNonEmpty(address, [
        'city',
        'town',
        'village',
        'suburb',
        'county',
      ]),
      administrativeArea: _firstNonEmpty(address, [
        'state',
        'province',
        'region',
      ]),
    ),
  ];
}

Future<List<GeoCoordinates>> locationFromAddress(String address) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': address,
    'format': 'json',
    'limit': '1',
  });

  final response = await http.get(uri, headers: _nominatimHeaders);
  if (response.statusCode != 200) return [];

  final results = json.decode(response.body) as List<dynamic>;
  if (results.isEmpty) return [];

  final item = results.first as Map<String, dynamic>;
  final lat = double.tryParse(item['lat']?.toString() ?? '');
  final lon = double.tryParse(item['lon']?.toString() ?? '');
  if (lat == null || lon == null) return [];

  return [GeoCoordinates(latitude: lat, longitude: lon)];
}
