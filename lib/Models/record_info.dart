class RecordInfo {
  final int id;
  final int tableId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> data;
  RecordInfo({
    required this.id,
    required this.tableId,
    required this.data,
    this.createdAt,
    this.updatedAt,
  });
  factory RecordInfo.fromJson(Map<String, dynamic> j) => RecordInfo(
    id: j['id'] as int,
    tableId: j['tableId'] as int,
    createdAt:
        j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
    updatedAt:
        j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt']) : null,
    data:
        (j['data'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
  );
}
