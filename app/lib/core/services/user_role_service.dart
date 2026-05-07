import '../../core/api/api_client.dart';

class UserRoleService {
  static String? _currentRole;

  static bool get isPremium {
    if (_currentRole == null) return false;
    return _currentRole!.startsWith('PREMIUM_') || _currentRole == 'ADMIN';
  }

  static Future<void> refreshRole() async {
    try {
      final res = await ApiClient().dio.get('/users/me');
      if (res.data['success'] == true) {
        _currentRole = res.data['data']['role'];
      }
    } catch (e) {
      // ignore
    }
  }

  static void setRole(String role) {
    _currentRole = role;
  }
}
