class FieldInfo {
  final int id;
  final int tableId;
  final String fieldKey;
  final String name;
  final String dataType;
  final bool required;
  FieldInfo({
    required this.id,
    required this.tableId,
    required this.fieldKey,
    required this.name,
    required this.dataType,
    required this.required,
  });
  factory FieldInfo.fromJson(Map<String, dynamic> j) => FieldInfo(
    id: j['id'] as int,
    tableId: j['tableId'] as int,
    fieldKey: j['fieldKey'] as String,
    name: (j['name'] as String?) ?? j['fieldKey'] as String,
    dataType: j['dataType'] as String,
    required: (j['required'] as bool?) ?? false,
  );
}
