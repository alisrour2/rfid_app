import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthState extends ChangeNotifier {
  final _api = ApiService();

  bool get isLoggedIn => _api.userId != null;
  String? get username => _api.username;
  bool get isAdmin => _api.isAdmin;

  Future<bool> login(String tenant, String user, String pass) async {
    final ok = await _api.login(
      tenantCode: tenant,
      username: user,
      password: pass,
    );
    if (ok) notifyListeners();
    return ok;
  }

  void logout() {
    _api.clearSession();
    notifyListeners();
  }
}
