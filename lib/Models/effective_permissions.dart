class EffectivePermission {
  final int tableId; // <-- needed when listing all permissions
  final bool canRead;
  final bool canWrite;
  final bool canManage;

  const EffectivePermission({
    required this.tableId,
    required this.canRead,
    required this.canWrite,
    required this.canManage,
  });

  factory EffectivePermission.fromJson(Map<String, dynamic> j) {
    // API returns camelCase (tableId/canRead/...), but be resilient either way
    final tidRaw = j['tableId'] ?? j['TableId'];
    final tid = tidRaw is int ? tidRaw : int.tryParse('$tidRaw') ?? 0;

    bool b(dynamic v) => v == true || v == 'true' || v == 1 || v == '1';

    return EffectivePermission(
      tableId: tid,
      canRead: b(j['canRead'] ?? j['CanRead']),
      canWrite: b(j['canWrite'] ?? j['CanWrite']),
      canManage: b(j['canManage'] ?? j['CanManage']),
    );
  }

  EffectivePermission copyWith({
    int? tableId,
    bool? canRead,
    bool? canWrite,
    bool? canManage,
  }) => EffectivePermission(
    tableId: tableId ?? this.tableId,
    canRead: canRead ?? this.canRead,
    canWrite: canWrite ?? this.canWrite,
    canManage: canManage ?? this.canManage,
  );
}
