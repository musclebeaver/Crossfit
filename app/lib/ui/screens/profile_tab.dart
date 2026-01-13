import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isPremium = _userProfile['role'] == 'PREMIUM';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile['nickname'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_userProfile['email'], style: const TextStyle(color: AppColors.textSecondary)),
                if (isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                    child: const Text('PREMIUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            if (!isPremium) _buildAdBanner(),
            const SizedBox(height: 32),
            _buildListTile('Change Nickname', Icons.edit, _updateNickname),
            _buildListTile('Change Password', Icons.lock_outline, _updatePassword),
            _buildListTile('About App', Icons.info_outline, () {}),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                // TODO: Logout logic
                Navigator.of(context).popUntil((route) => route.isFirst);
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
        gradient: LinearGradient(colors: [AppColors.primary, Colors.deepPurple]),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            child: const Text('UPGRADE'),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
