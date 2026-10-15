import 'package:zecorner/models/province/provinces_detail_model.dart';

/// Ref API’deki ilçe/mahalle isimleri ile formda tutulan (veya sunucudan gelen)
/// metinlerin birebir eşleşmemesi durumunda kod çözümü için ortak mantık.
/// Tüm adres formlarında aynı kuralları kullanın; sabit il/ilçe listesi kullanmayın.

DistrictModel? fuzzyMatchDistrict(ProvincesDetailResponseModel detail, String raw) {
  final n = raw.toLowerCase().trim();
  if (n.isEmpty) return null;
  final exact = detail.getDistrictByName(raw);
  if (exact != null) return exact;
  for (final d in detail.districts) {
    final dn = d.name.toLowerCase().trim();
    if (dn == n) return d;
    if (dn.contains(n) || n.contains(dn)) return d;
  }
  if (n == 'merkez') {
    for (final d in detail.districts) {
      if (d.name.toLowerCase().contains('merkez')) return d;
    }
  }
  return null;
}

DistrictModel? resolveDistrictModel(ProvincesDetailResponseModel detail, String? name) {
  if (name == null || name.trim().isEmpty) return null;
  return detail.getDistrictByName(name) ?? fuzzyMatchDistrict(detail, name.trim());
}

QuarterModel? findQuarterInDistrict(DistrictModel district, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final n = raw.toLowerCase().trim();
  try {
    return district.quarters.firstWhere((q) => q.name.toLowerCase().trim() == n);
  } catch (_) {
    for (final q in district.quarters) {
      final qn = q.name.toLowerCase();
      if (qn.contains(n) || n.contains(qn)) return q;
    }
  }
  return null;
}
