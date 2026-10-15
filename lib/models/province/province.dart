class Province {
  final String id;
  final String code;
  final String name;
  final String? parentId;
  final List<Province>? quarters; // Mahalleler (sadece ilçelerde var)

  Province({
    required this.id,
    required this.code,
    required this.name,
    this.parentId,
    this.quarters,
  });

  bool get hasEmbeddedQuarters =>
      quarters != null && quarters!.isNotEmpty;

  /// `type=place` cevabı: `villages[].quarters` — köy/mahalle gruplarını tek listede birleştirir.
  static List<Province>? quartersFromVillagesList(List<dynamic> villages) {
    final out = <Province>[];
    for (final raw in villages) {
      if (raw is! Map<String, dynamic>) continue;
      final vName = raw['name']?.toString() ?? '';
      final vCode = raw['code']?.toString();
      final qList = raw['quarters'];
      if (qList is! List<dynamic>) continue;
      for (final q in qList) {
        if (q is! Map<String, dynamic>) continue;
        final quarterCode = q['code']?.toString() ?? '';
        final quarterName = q['name']?.toString() ?? '';
        final label = (vName.isNotEmpty && quarterName.isNotEmpty)
            ? '$quarterName · $vName'
            : quarterName;
        out.add(
          Province(
            id: quarterCode,
            code: quarterCode,
            name: label,
            parentId: vCode,
          ),
        );
      }
    }
    return out.isEmpty ? null : out;
  }

  /// Tek ilçe objesi (API): doğrudan `quarters` veya `villages` altı mahalleler.
  static List<Province> neighborhoodListFromDistrictNode(
    Map<String, dynamic> json,
  ) {
    final q = json['quarters'];
    if (q is List<dynamic>) {
      final list = q
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => Province.fromJson({
              'code': e['code']?.toString() ?? '',
              'name': e['name'] ?? '',
            }),
          )
          .toList();
      if (list.isNotEmpty) return list;
    }
    final v = json['villages'];
    if (v is List<dynamic>) {
      return quartersFromVillagesList(v) ?? [];
    }
    return [];
  }

  factory Province.fromJson(Map<String, dynamic> json) {
    // Web API'den gelen response'da id yok, code var
    // Eğer id yoksa code'u id olarak kullan
    final id = json['id']?.toString() ?? json['code']?.toString() ?? '';
    final code = json['code']?.toString() ?? '';

    List<Province>? quarters;
    if (json['quarters'] != null) {
      final ql = (json['quarters'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(
            (q) => Province.fromJson({
              'code': q['code']?.toString() ?? '',
              'name': q['name'] ?? '',
            }),
          )
          .toList();
      quarters = ql.isEmpty ? null : ql;
    } else if (json['villages'] != null) {
      quarters =
          quartersFromVillagesList(json['villages'] as List<dynamic>);
    }

    return Province(
      id: id,
      code: code,
      name: json['name'] ?? '',
      parentId: json['parent_id']?.toString(),
      quarters: quarters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'parent_id': parentId,
      if (quarters != null)
        'quarters': quarters!.map((q) => q.toJson()).toList(),
    };
  }
}

