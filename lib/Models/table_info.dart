class TableInfo {
  final int id;
  final String slug;
  final String displayName;
  final DateTime? createdAt;
  TableInfo({
    required this.id,
    required this.slug,
    required this.displayName,
    this.createdAt,
  });
  factory TableInfo.fromJson(Map<String, dynamic> j) => TableInfo(
    id: j['id'] as int,
    slug: j['slug'] as String,
    displayName: j['displayName'] as String,
    createdAt:
        j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) : null,
  );
}
