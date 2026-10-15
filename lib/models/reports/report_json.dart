double pickDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }
  return fallback;
}

int pickInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String pickString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

dynamic firstKey(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  return null;
}

Map<String, dynamic>? asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> pickList(dynamic json, [List<String> keys = const []]) {
  if (json is List) return json;
  final map = asJsonMap(json);
  if (map == null) return const [];
  for (final key in keys) {
    final value = map[key];
    if (value is List) return value;
  }
  for (final nestedKey in ['data', 'result', 'payload']) {
    final nested = map[nestedKey];
    if (nested is List) return nested;
    final nestedMap = asJsonMap(nested);
    if (nestedMap != null) {
      for (final key in keys) {
        final value = nestedMap[key];
        if (value is List) return value;
      }
    }
  }
  return const [];
}

Map<String, dynamic> pickMap(dynamic json) {
  final map = asJsonMap(json);
  if (map == null) return <String, dynamic>{};
  final nested = asJsonMap(map['data']) ??
      asJsonMap(map['result']) ??
      asJsonMap(map['payload']);
  return nested ?? map;
}
