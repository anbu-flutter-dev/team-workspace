/// Recursively converts Maps/Lists coming back out of Hive into the plain
/// `Map<String, dynamic>` / `List<dynamic>` shape json_serializable's
/// generated `fromJson` expects.
///
/// Hive only guarantees that shape at the top level of whatever you read —
/// anything nested inside (a field that's itself a serialized object) comes
/// back typed as `Map<dynamic, dynamic>`, which fails the `as Map<String,
/// dynamic>` cast a level deeper in the generated code.
Map<String, dynamic> normalizeJsonMap(Object? value) {
  final normalized = _normalize(value);
  return normalized is Map<String, dynamic> ? normalized : <String, dynamic>{};
}

Object? _normalize(Object? value) {
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, val) => MapEntry(key.toString(), _normalize(val)),
    );
  }
  if (value is List) {
    return value.map(_normalize).toList();
  }
  return value;
}
