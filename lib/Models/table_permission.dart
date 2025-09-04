class TablePermission {
  final int tableId;
  final String tableName;
  bool canRead;
  bool canWrite;
  bool canManage;

  TablePermission({
    required this.tableId,
    required this.tableName,
    required this.canRead,
    required this.canWrite,
    required this.canManage,
  });

  factory TablePermission.fromJson(Map<String, dynamic> j) => TablePermission(
    tableId: j['tableId'] as int,
    tableName: (j['tableName'] as String?) ?? '',
    canRead: (j['canRead'] as bool?) ?? false,
    canWrite: (j['canWrite'] as bool?) ?? false,
    canManage: (j['canManage'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'tableId': tableId,
    'canRead': canRead,
    'canWrite': canWrite,
    'canManage': canManage,
  };

  TablePermission copy() => TablePermission(
    tableId: tableId,
    tableName: tableName,
    canRead: canRead,
    canWrite: canWrite,
    canManage: canManage,
  );
}
