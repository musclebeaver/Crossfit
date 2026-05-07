import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../styles/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  dynamic _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/users/me');
      if (res.data['success']) {
        setState(() => _userProfile = res.data['data']);
      }
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNickname() async {
    final controller = TextEditingController(text: _userProfile['nickname']);
    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Nickname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Update')),
        ],
      ),
    );

    if (newNickname != null && newNickname.isNotEmpty) {
      try {
        final res = await ApiClient().dio.patch('/users/nickname', data: {'nickname': newNickname});
        if (res.data['success']) {
          _fetchProfile();
        }
      } catch (e) {
        debugPrint("Update Nickname Error: $e");
      }
    }
  }

  Future<void> _updatePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final res = await ApiClient().dio.patch('/users/password', data: {
          'oldPassword': oldController.text,
          'newPassword': newController.text,
        });
        if (res.data['success']) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
        }
      } catch (e) {
        debugPrint("Update Password Error: $e");
      }
    }
  }

  Future<void> _upgradePremium() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Advantage'),
        content: const Text('Upgrade to Premium to remove all ads and support developers!\n\n(Demo: Mock Payment)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiClient().dio.post('/users/upgrade');
        if (res.data['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome to Premium!'), backgroundColor: Colors.green));
            _fetchProfile();
          }
        }
      } catch (e) {
        debugPrint("Upgrade Error: $e");
      }
    }
  }

  Future<void> _withdrawAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Account', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to withdraw? All your records, rankings, and personal data will be permanently deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Withdraw', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiClient().dio.delete('/users/me');
        if (res.data['success']) {
          await const FlutterSecureStorage().delete(key: 'jwt');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your account has been deleted.')));
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        debugPrint("Withdrawal Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete account. Please try again later.')));
        }
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('http://10.0.2.2:8080/privacy-policy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTermsOfService() async {
    final url = Uri.parse('http://10.0.2.2:8080/terms-of-service'); // 약관 페이지 (준비 필요)
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@beaverdeveloper.com',
      query: 'subject=[Crossfit App Inquiry]&body=User ID: ${_userProfile['id']}\n---',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email app.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final role = _userProfile['role'];
    final bool isPremium = role == 'PREMIUM_USER' || role == 'PREMIUM_COACH';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF115D33),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile['nickname'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _buildTierBadge(_userProfile['tier'].toString()),
            const SizedBox(height: 4),
            Text(
              '${_userProfile['points']} Total Points',
              style: const TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_userProfile['email'], style: const TextStyle(color: Color(0xFF757575))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPremium ? Colors.amber : const Color(0xFF115D33).withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    isPremium ? 'PREMIUM' : role, 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: isPremium ? Colors.black : const Color(0xFF115D33)
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!isPremium) _buildAdBanner(),
            const SizedBox(height: 32),
            _buildListTile('Change Nickname', Icons.edit, _updateNickname),
            _buildListTile('Change Password', Icons.lock_outline, _updatePassword),
            _buildListTile('Privacy Policy', Icons.policy_outlined, _openPrivacyPolicy),
            _buildListTile('Terms of Service', Icons.description_outlined, _openTermsOfService),
            _buildListTile('Contact Support', Icons.help_outline, _contactSupport),
            _buildListTile('About App', Icons.info_outline, () {}),
            const SizedBox(height: 24),
            _buildListTile('Withdraw Account', Icons.person_off_outlined, _withdrawAccount),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await const FlutterSecureStorage().delete(key: 'jwt');
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF115D33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Get Premium!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Remove all advertisements', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _upgradePremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: const Color(0xFF115D33),
              shape: const StadiumBorder(),
            ),
            child: const Text('UPGRADE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF115D33)),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0)),
      onTap: onTap,
    );
  }

  Widget _buildTierBadge(String? tier) {
    if (tier == null) return const SizedBox.shrink();
    
    Color color;
    switch (tier) {
      case 'LEGEND': color = Colors.orange; break;
      case 'ELITE': color = Colors.deepPurple; break;
      case 'PRO': color = Colors.red; break;
      case 'AMATEUR': color = Colors.green; break;
      default: color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
