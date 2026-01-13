import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailChecked = false;
  bool _isEmailValid = false;
  String _role = 'USER';

  Future<void> _checkEmail() async {
    if (_emailController.text.isEmpty) return;
    try {
      final res = await ApiClient().dio.get('/auth/check-email', queryParameters: {'email': _emailController.text});
      if (res.data['success']) {
        final isDuplicated = res.data['data'];
        setState(() {
          _isEmailChecked = true;
          _isEmailValid = !isDuplicated;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(!isDuplicated ? '사용 가능한 이메일입니다.' : '이미 사용 중인 이메일입니다.'),
              backgroundColor: !isDuplicated ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Email Check Error: $e");
    }
  }

  Future<void> _handleSignup() async {
    if (!_isEmailChecked || !_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일 중복 체크를 완료해 주세요.')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.post('/auth/signup', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
        'nickname': _nicknameController.text,
        'role': _role,
      });

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 완료! 이메일 인증을 진행해 주세요.')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(email: _emailController.text),
            ),
          );
        }
      }
    } catch (e) {
      // Error handled by interceptor but we might want local feedback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CREATE ACCOUNT',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join the Crossfit Competition Platform',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(child: _buildTextField(_emailController, 'Email', Icons.email)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _checkEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailChecked && _isEmailValid ? Colors.green : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Check', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
            const SizedBox(height: 16),
            _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            _buildTextField(_nicknameController, 'Nickname', Icons.person),
            const SizedBox(height: 16),
            const Text('Account Type', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('User', style: TextStyle(fontSize: 14)),
                    value: 'USER',
                    groupValue: _role,
                    onChanged: (val) => setState(() => _role = val!),
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Coach', style: TextStyle(fontSize: 14)),
                    value: 'COACH',
                    groupValue: _role,
                    onChanged: (val) => setState(() => _role = val!),
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
