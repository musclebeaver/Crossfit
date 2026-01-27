import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter 추가
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart'; // 관리자 화면 추가
import 'dart:html' as html; // Flutter Web 환경 대응
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkVersion(); // 버전 체크 추가
    _checkSocialLoginToken();
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final res = await ApiClient().dio.get('/app/version');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final latestVersion = data['latestVersion'];
        final minVersion = data['minVersion'];
        final updateUrl = data['updateUrl'];

        if (_isVersionLower(currentVersion, minVersion)) {
          // 강제 업데이트
          if (mounted) _showUpdateDialog(updateUrl, isForce: true);
        } else if (_isVersionLower(currentVersion, latestVersion)) {
          // 선택 업데이트
          if (mounted) _showUpdateDialog(updateUrl, isForce: false);
        }
      }
    } catch (e) {
      debugPrint("Version Check Error: $e");
    }
  }

  bool _isVersionLower(String current, String target) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> targetParts = target.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String updateUrl, {required bool isForce}) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) => AlertDialog(
        title: Text(isForce ? 'Update Required' : 'Update Available'),
        content: Text(isForce 
          ? 'A newer version is required to continue using the app.' 
          : 'A new version is available. Would you like to update?'),
        actions: [
          if (!isForce)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () => html.window.open(updateUrl, '_blank'),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _checkSocialLoginToken() async {
    // 1. 일반 쿼리 파라미터에서 추출
    Map<String, String> params = Uri.base.queryParameters;
    
    // 2. Hash (#) 기반 라우팅인 경우 fragment에서 추출
    if (!params.containsKey('token') && Uri.base.fragment.contains('token')) {
      final fragment = Uri.base.fragment;
      // fragment 예: "/?token=xxx" 혹은 "token=xxx"
      final fragmentUri = Uri.parse(fragment.startsWith('/') ? fragment : "/$fragment");
      params = fragmentUri.queryParameters;
    }

    if (params.containsKey('token')) {
      final token = params['token']!;
      setState(() => _isLoading = true);
      
      try {
        await const FlutterSecureStorage().write(key: 'jwt', value: token);
        // 토큰 처리 후 URL 깨끗하게 정리 (선택 사항)
        // html.window.history.replaceState(null, '', html.window.location.href.split('?')[0]);
        
        if (mounted) {
          await _navigateByRole();
        }
      } catch (e) {
        debugPrint("Token Storage Error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.post('/auth/login', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.data['success'] == true) {
        final token = response.data['data'];
        await const FlutterSecureStorage().write(key: 'jwt', value: token);
        if (mounted) {
          await _navigateByRole();
        }
      }
    } catch (e) {
      if (mounted) {
        String message = 'Login failed: Connection error';
        if (e is DioException && e.response != null && e.response?.data != null) {
          message = 'Login failed: ${e.response?.data['message'] ?? 'Unknown error'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateByRole() async {
    try {
      final res = await ApiClient().dio.get('/users/me');
      if (res.data['success'] == true) {
        final role = res.data['data']['role'];
        if (mounted) {
          if (role == 'ADMIN') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("NavigateByRole Error: $e");
      // 프로필 조회 실패 시 기본 경로로 이동 시도
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'CROSSFIT PLATFORM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                ],
                decoration: _buildInputDecoration('Email', Icons.email),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣\u4e00-\u9fa5\u3040-\u30ff]')),
                ],
                decoration: _buildInputDecoration('Password', Icons.lock),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 32),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 32),
              _buildSocialButton('Google', const Color(0xFFDB4437)),
              const SizedBox(height: 12),
              _buildSocialButton('Naver', const Color(0xFF03C75A)),
              const SizedBox(height: 12),
              _buildSocialButton('Kakao', const Color(0xFFFEE500), textColor: Colors.black87),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                ),
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, Color color, {Color textColor = Colors.white}) {
    return ElevatedButton(
      onPressed: () {
        final provider = label.toLowerCase();
        // ApiClient의 baseUrl을 활용하여 백엔드 주소 도출 (api/v1 제거)
        final baseUrl = ApiClient().dio.options.baseUrl.replaceAll('/api/v1', '');
        final authUrl = "$baseUrl/oauth2/authorization/$provider";
        
        // Flutter Web의 경우 브라우저 창 자체를 이동시킴
        html.window.location.href = authUrl;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        'Continue with $label',
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
