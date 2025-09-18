import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rfid_app/Models/effective_permissions.dart';
import 'package:rfid_app/Models/field_info.dart';
import 'package:rfid_app/Models/record_info.dart';
import 'package:rfid_app/Models/table_info.dart';
import 'package:rfid_app/Models/table_permission.dart';
import 'package:rfid_app/Models/user_info.dart';
import 'package:rfid_app/constants.dart';

extension _Resp on http.Response {
  String get safeBody => body.isEmpty ? '<empty>' : body;
}

class ApiService {
  ApiService._();
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;

  static const String baseUrl = Constants.apiBaseUrl;

  int? _tenantId;
  int? _userId;
  bool _isAdmin = false;
  String? _username;

  // Optional token if/when you add JWT later.
  String? _token;
  void setAuthToken(String? token) => _token = token;

  int? get tenantId => _tenantId;
  int? get userId => _userId;
  bool get isAdmin => _isAdmin;
  String? get username => _username;

  Map<String, String> _headers({bool json = false}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (_tenantId != null) 'X-Tenant-Id': '$_tenantId',
    if (_userId != null) 'X-User-Id': '$_userId',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  void _requireSession() {
    if (_tenantId == null || _userId == null) {
      throw Exception('Not logged in: missing tenant/user (no headers).');
    }
  }

  void clearSession() {
    _tenantId = null;
    _userId = null;
    _isAdmin = false;
    _username = null;
    _token = null;
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  void _setSession(Map<String, dynamic> body) {
    _userId = _toInt(body['id'] ?? body['userId'] ?? body['UserId']);
    _username =
        (body['username'] ?? body['userName'] ?? body['UserName']) as String?;
    _tenantId = _toInt(body['tenantId'] ?? body['TenantId']);
    _isAdmin = _toBool(body['isAdmin'] ?? body['IsAdmin'] ?? body['admin']);
  }

  /* ----------------------------- LOGIN ----------------------------- */

  Future<bool> login({
    required String tenantCode,
    required String username,
    required String password,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: _headers(json: true),
      body: jsonEncode({
        'tenantCode': tenantCode,
        'username': username,
        'password': password,
      }),
    );
    if (r.statusCode == 200) {
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      _setSession(map);
      return true;
    }
    return false;
  }

  /* ----------------------- EFFECTIVE PERMISSIONS ------------------- */

  /// Fetch all effective permissions for current user (list of tables).
  Future<List<EffectivePermission>> fetchAllEffectivePermissions() async {
    _requireSession();

    final r = await http.get(
      Uri.parse('$baseUrl/api/permissions'),
      headers: _headers(),
    );

    if (r.statusCode != 200) {
      throw Exception(
        'Fetch permissions list failed (${r.statusCode}): ${r.safeBody}',
      );
    }

    final data = jsonDecode(r.body);
    if (data is! List) return const <EffectivePermission>[];

    return data.map<EffectivePermission>((e) {
      final m = e as Map<String, dynamic>;
      return EffectivePermission.fromJson(m);
    }).toList();
  }

  /// Current user's effective permissions for a table.
  /// Uses the list-all endpoint to avoid any per-table 404s.
  Future<EffectivePermission> fetchEffectivePermission(int tableId) async {
    _requireSession();

    // Ask the single, stable endpoint…
    final all = await fetchAllEffectivePermissions();

    // …pick the matching row (or safe default if none found).
    return all.firstWhere(
      (p) => p.tableId == tableId,
      orElse:
          () => EffectivePermission(
            tableId: tableId,
            canRead: false,
            canWrite: false,
            canManage: false,
          ),
    );
  }

  /* ----------------------------- TABLES ----------------------------- */

  Future<List<TableInfo>> fetchTables() async {
    _requireSession();
    final r = await http.get(
      Uri.parse('$baseUrl/api/Tables'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw Exception('Fetch tables failed (${r.statusCode})');
    }
    final List data = jsonDecode(r.body);
    return data.map((e) => TableInfo.fromJson(e)).toList();
  }

  Future<void> createTable({
    required String slug,
    required String displayName,
  }) async {
    _requireSession();
    final r = await http.post(
      Uri.parse('$baseUrl/api/Tables'),
      headers: _headers(json: true),
      body: jsonEncode({'slug': slug, 'displayName': displayName}),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Create table failed (${r.statusCode}): ${r.body}');
    }
  }

  Future<void> updateTable({
    required int id,
    String? slug,
    String? displayName,
  }) async {
    _requireSession();
    final payload = <String, dynamic>{};
    if (slug != null && slug.isNotEmpty) payload['slug'] = slug;
    if (displayName != null && displayName.isNotEmpty) {
      payload['displayName'] = displayName;
    }
    if (payload.isEmpty) return;

    final r = await http.put(
      Uri.parse('$baseUrl/api/Tables/$id'),
      headers: _headers(json: true),
      body: jsonEncode(payload),
    );
    if (r.statusCode != 204) {
      throw Exception('Update table failed (${r.statusCode})');
    }
  }

  Future<void> deleteTable(int id) async {
    _requireSession();
    final r = await http.delete(
      Uri.parse('$baseUrl/api/Tables/$id'),
      headers: _headers(),
    );
    if (r.statusCode != 204) {
      throw Exception('Delete table failed (${r.statusCode})');
    }
  }

  /* ----------------------------- FIELDS ----------------------------- */

  Future<List<FieldInfo>> fetchFields(int tableId) async {
    _requireSession();
    final r = await http.get(
      Uri.parse('$baseUrl/api/tables/$tableId/fields'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw Exception('Fetch fields failed (${r.statusCode})');
    }
    final List data = jsonDecode(r.body);
    return data.map((e) => FieldInfo.fromJson(e)).toList();
  }

  Future<void> addField(int tableId, FieldInfo f) async {
    _requireSession();
    final r = await http.post(
      Uri.parse('$baseUrl/api/tables/$tableId/fields'),
      headers: _headers(json: true),
      body: jsonEncode({
        'fieldKey': f.fieldKey,
        'name': f.name,
        'dataType': f.dataType,
        'required': f.required,
      }),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Add field failed (${r.statusCode}): ${r.body}');
    }
  }

  Future<void> deleteField(int tableId, String fieldKey) async {
    _requireSession();
    final r = await http.delete(
      Uri.parse('$baseUrl/api/tables/$tableId/fields/$fieldKey'),
      headers: _headers(),
    );
    if (r.statusCode != 204) {
      throw Exception('Delete field failed (${r.statusCode})');
    }
  }

  /* ----------------------------- RECORDS ---------------------------- */

  Future<List<RecordInfo>> fetchRecords(int tableId) async {
    _requireSession();
    final r = await http.get(
      Uri.parse('$baseUrl/api/Records?tableId=$tableId'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw Exception('Fetch records failed (${r.statusCode})');
    }
    final List data = jsonDecode(r.body);
    return data.map((e) => RecordInfo.fromJson(e)).toList();
  }

  Future<void> addRecord(int tableId, Map<String, dynamic> data) async {
    _requireSession();
    final r = await http.post(
      Uri.parse('$baseUrl/api/Records'),
      headers: _headers(json: true),
      body: jsonEncode({'tableId': tableId, 'data': data}),
    );
    if (r.statusCode != 201) {
      throw Exception('Create record failed (${r.statusCode})');
    }
  }

  Future<void> updateRecord({
    required int id,
    required int tableId,
    required Map<String, dynamic> data,
  }) async {
    _requireSession();
    final r = await http.put(
      Uri.parse('$baseUrl/api/Records/$id'),
      headers: _headers(json: true),
      body: jsonEncode({'tableId': tableId, 'data': data}),
    );
    if (r.statusCode != 204) {
      throw Exception('Update record failed (${r.statusCode})');
    }
  }

  Future<void> deleteRecord(int id) async {
    _requireSession();
    final r = await http.delete(
      Uri.parse('$baseUrl/api/Records/$id'),
      headers: _headers(),
    );
    if (r.statusCode != 204) {
      throw Exception('Delete record failed (${r.statusCode})');
    }
  }

  /* ------------------------------ ADMIN ----------------------------- */

  Future<List<UserInfo>> fetchUsers() async {
    _requireSession();
    final r = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw 'Fetch users failed (${r.statusCode}): ${r.body}';
    }
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) => UserInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addUser({
    required String username,
    required String password,
    required bool isAdmin,
    required bool isActive,
  }) async {
    _requireSession();
    final r = await http.post(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _headers(json: true),
      body: jsonEncode({
        'username': username,
        'password': password,
        'isAdmin': isAdmin,
        'isActive': isActive,
      }),
    );
    if (r.statusCode != 201) {
      throw 'Create user failed (${r.statusCode}): ${r.body}';
    }
  }

  Future<void> setUserRole({required int id, required bool isAdmin}) async {
    _requireSession();
    // Controller expects PUT (not PATCH)
    final r = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$id/role'),
      headers: _headers(json: true),
      body: jsonEncode({'isAdmin': isAdmin}),
    );
    if (r.statusCode != 204) {
      throw 'Set role failed (${r.statusCode}): ${r.body}';
    }
  }

  Future<void> setUserActive({required int id, required bool isActive}) async {
    _requireSession();
    // Controller expects PUT (not PATCH)
    final r = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$id/active'),
      headers: _headers(json: true),
      body: jsonEncode({'isActive': isActive}),
    );
    if (r.statusCode != 204) {
      throw 'Set active failed (${r.statusCode}): ${r.body}';
    }
  }

  Future<void> resetUserPassword({
    required int id,
    required String newPassword,
  }) async {
    _requireSession();
    final r = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$id/password'),
      headers: _headers(json: true),
      body: jsonEncode({'password': newPassword}),
    );
    if (r.statusCode != 204) {
      throw 'Reset password failed (${r.statusCode}): ${r.body}';
    }
  }

  Future<void> deleteUser({required int id}) async {
    _requireSession();
    final r = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: _headers(), // no need for Content-Type on DELETE
    );
    if (r.statusCode != 204) {
      throw 'Delete user failed (${r.statusCode}): ${r.body}';
    }
  }

  Future<List<TablePermission>> fetchUserPermissions(int userId) async {
    _requireSession();
    final r = await http.get(
      Uri.parse('$baseUrl/api/admin/users/$userId/permissions'),
      headers: _headers(),
    );
    if (r.statusCode != 200) {
      throw 'Fetch permissions failed (${r.statusCode}): ${r.body}';
    }
    final list = jsonDecode(r.body) as List;
    return list.map((e) => TablePermission.fromJson(e)).toList();
  }

  Future<void> saveUserPermissions(
    int userId,
    List<TablePermission> rows,
  ) async {
    _requireSession();
    final r = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$userId/permissions'),
      headers: _headers(json: true),
      body: jsonEncode(rows.map((e) => e.toJson()).toList()),
    );
    if (r.statusCode != 204) {
      throw 'Save permissions failed (${r.statusCode}): ${r.body}';
    }
  }
}
