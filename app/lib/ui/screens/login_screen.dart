import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter 추가
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart'; // 관리자 화면 추가
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/services/user_role_service.dart';

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
      if (res.data is Map && res.data['success'] == true) {
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
            onPressed: () async {
              final uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
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

    if (params.containsKey('token') && params.containsKey('refreshToken')) {
      final token = params['token']!;
      final refreshToken = params['refreshToken']!;
      setState(() => _isLoading = true);
      
      try {
        await const FlutterSecureStorage().write(key: 'jwt', value: token);
        await const FlutterSecureStorage().write(key: 'refreshToken', value: refreshToken);
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

  Future<void> _handleNavigateByRole() async {
    if (mounted) {
      await _navigateByRole();
    }
  }

  Future<void> _handleNativeSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      String? accessToken;

      if (provider == 'kakao') {
        if (await kakao.isKakaoTalkInstalled()) {
          try {
            await kakao.UserApi.instance.loginWithKakaoTalk();
          } catch (error) {
            await kakao.UserApi.instance.loginWithKakaoAccount();
          }
        } else {
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
        final token = await kakao.TokenManagerProvider.instance.manager.getToken();
        accessToken = token?.accessToken;
      } else if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? account = await googleSignIn.signIn();
        final GoogleSignInAuthentication? auth = await account?.authentication;
        accessToken = auth?.accessToken;
      } else if (provider == 'naver') {
        final NaverLoginResult result = await FlutterNaverLogin.logIn();
        final NaverAccessToken resToken = await FlutterNaverLogin.currentAccessToken;
        accessToken = resToken.accessToken;
      } else if (provider == 'apple') {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScope.email,
            AppleIDAuthorizationScope.fullName,
          ],
        );
        accessToken = credential.identityToken; // ID Token을 전송
      }

      if (accessToken != null) {
        // 백엔드 API로 네이티브 액세스 토큰 전송
        final response = await ApiClient().dio.post('/auth/social-login', data: {
          'provider': provider.toUpperCase(),
          'accessToken': accessToken,
        });

        if (response.data['success'] == true) {
          final data = response.data['data'];
          final jwt = data['accessToken'];
          final refreshToken = data['refreshToken'];
          
          await const FlutterSecureStorage().write(key: 'jwt', value: jwt);
          await const FlutterSecureStorage().write(key: 'refreshToken', value: refreshToken);
          
          // FCM 토큰 등록
          await PushNotificationService.registerToken();
          
          await _handleNavigateByRole();
        }
      }
    } catch (e) {
      debugPrint("Native Social Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $provider')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        final data = response.data['data'];
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        
        await const FlutterSecureStorage().write(key: 'jwt', value: accessToken);
        await const FlutterSecureStorage().write(key: 'refreshToken', value: refreshToken);
        
        // FCM 토큰 등록
        await PushNotificationService.registerToken();
        
        await _handleNavigateByRole();
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
        UserRoleService.setRole(role); // 전역 상태 업데이트
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
      backgroundColor: Colors.white, // 순백색 배경
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fitness_center, size: 72, color: Color(0xFF115D33)),
              const SizedBox(height: 16),
              const Text(
                'CROSSFIT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF115D33),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black87),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                ],
                decoration: _buildInputDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black87),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣\u4e00-\u9fa5\u3040-\u30ff]')),
                ],
                decoration: _buildInputDecoration('Password', Icons.lock_outline),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF115D33),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 48),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSocialButton('Google', const Color(0xFFEB4335)),
              const SizedBox(height: 12),
              _buildSocialButton('Naver', const Color(0xFF03C75A)),
              const SizedBox(height: 12),
              _buildSocialButton('Kakao', const Color(0xFFFEE500), textColor: Colors.black87),
              const SizedBox(height: 12),
              _buildSocialButton('Apple', Colors.black),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                ),
                child: const Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.w600),
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
      onPressed: () => _handleNativeSocialLogin(label.toLowerCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: Text(
        'Continue with $label',
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      prefixIcon: Icon(icon, color: const Color(0xFF757575)),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF115D33), width: 1.5),
      ),
    );
  }
}
