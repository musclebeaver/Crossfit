import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'main_screen.dart';

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
  bool _isEmailValid = true;
  String? _emailError;
  String? _emailSuccess;
  String? _passwordError;
  String _role = 'USER';
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordConfirmFocusNode = FocusNode();

  // OTP State
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isEmailVerified = false;
  String? _otpError;
  String? _otpSuccess;
  Timer? _authTimer;
  int _secondsRemaining = 300; // 5 minutes
  String? _lastVerifiedEmail;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _checkEmail();
      }
    });
    _passwordConfirmFocusNode.addListener(() {
      if (!_passwordConfirmFocusNode.hasFocus) {
        _checkPasswordMatch();
      }
    });
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    _emailFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _authTimer?.cancel();
    _secondsRemaining = 300;
    _authTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _authTimer?.cancel();
        }
      });
    });
  }

  String _formatTimer(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email.';
        _emailSuccess = null;
      });
      return;
    }

    try {
      final res = await ApiClient().dio.get('/auth/check-email', queryParameters: {'email': email});
      if (res.data['success']) {
        final isDuplicated = res.data['data'];
        setState(() {
          _isEmailValid = !isDuplicated;
          _emailError = isDuplicated ? 'This email is already taken.' : null;
          _emailSuccess = !isDuplicated ? 'Email is available' : null;
          
          // Only reset OTP/Verification if email actually changed from the verified one
          if (isDuplicated || (_isEmailVerified && email != _lastVerifiedEmail)) {
             _isOtpSent = false;
             _isEmailVerified = false;
             _otpController.clear();
             _otpError = null;
             _otpSuccess = null;
             _authTimer?.cancel();
             _lastVerifiedEmail = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Email Check Error: $e");
      setState(() {
        _emailError = 'Connection error: Server is not responding.';
        _emailSuccess = null;
      });
    }
  }

  Future<void> _sendEmailVerification() async {
    if (!_isEmailValid || _emailController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.post('/auth/email/send', data: {'email': _emailController.text});
      if (res.data['success']) {
        setState(() {
          _isOtpSent = true;
          _otpError = null;
          _otpSuccess = 'OTP sent to your email.';
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint("Send OTP Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    if (_otpController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.post('/auth/email/verify', data: {
        'email': _emailController.text,
        'code': _otpController.text,
      });
      
      if (res.data['success'] == true && res.data['data'] == true) {
        setState(() {
          _isEmailVerified = true;
          _lastVerifiedEmail = _emailController.text;
          _otpError = null;
          _otpSuccess = 'Verification successful!';
          _authTimer?.cancel();
        });
      } else {
        setState(() {
          _otpError = 'Invalid or expired code.';
          _otpSuccess = null;
        });
      }
    } catch (e) {
      debugPrint("Verify OTP Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkPasswordMatch() {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = 'Passwords do not match.');
    } else {
      setState(() => _passwordError = null);
    }
  }

  Future<void> _handleSignup() async {
    _checkPasswordMatch();
    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify your email first.')));
      return;
    }
    if (_passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check your password.')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
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
        // 회원가입 성공 후 자동 로그인 및 메인 페이지 이동
        try {
          final loginRes = await ApiClient().dio.post('/auth/login', data: {
            'email': _emailController.text,
            'password': _passwordController.text,
          });

          if (loginRes.data['success'] == true) {
            final token = loginRes.data['data'];
            await const FlutterSecureStorage().write(key: 'jwt', value: token);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Welcome! Signup and Login successful.')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            }
          }
        } catch (loginError) {
          debugPrint("Auto Login Error: $loginError");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signup successful. Please login manually.')),
            );
            Navigator.pop(context); // 로그인 화면으로 이동
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String message = 'Signup failed: Connection error';
        if (e is DioException && e.response != null && e.response?.data != null) {
          message = 'Signup failed: ${e.response?.data['message'] ?? 'Unknown error'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    _emailController, 
                    'Email', 
                    Icons.email, 
                    focusNode: _emailFocusNode,
                    errorText: _emailError,
                    helperText: _emailSuccess,
                    enabled: !_isEmailVerified,
                  ),
                ),
                if (_isEmailValid && _emailError == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isEmailVerified) ? null : _sendEmailVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEmailVerified ? Colors.grey : AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _isOtpSent ? 'Resend' : 'Send Code', 
                          style: const TextStyle(color: Colors.white, fontSize: 13)
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_isOtpSent && !_isEmailVerified) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      _otpController, 
                      'Verification Code', 
                      Icons.security,
                      errorText: _otpError,
                      helperText: _otpSuccess != null ? '$_otpSuccess (${_formatTimer(_secondsRemaining)})' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyEmailCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verify', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            if (_isEmailVerified) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Email Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
            const SizedBox(height: 16),
            _buildTextField(
              _confirmPasswordController, 
              'Confirm Password', 
              Icons.lock_outline, 
              obscure: true,
              focusNode: _passwordConfirmFocusNode,
              errorText: _passwordError,
            ),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {bool obscure = false, FocusNode? focusNode, String? errorText, String? helperText, bool enabled = true}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      enabled: enabled,
      style: TextStyle(color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorText: errorText,
        helperText: helperText,
        helperStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.border.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
    );
  }
}
