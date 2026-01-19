import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'box_registration_screen.dart';
import 'box_management_screen.dart';

class MyBoxTab extends StatefulWidget {
  const MyBoxTab({super.key});

  @override
  State<MyBoxTab> createState() => _MyBoxTabState();
}

class _MyBoxTabState extends State<MyBoxTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _searchResults = [];
  dynamic _userProfile;
  dynamic _membershipStatus;
  List<dynamic> _ownedBoxes = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final profileRes = await ApiClient().dio.get('/users/me');
      if (profileRes.data['success']) {
        _userProfile = profileRes.data['data'];
        
        final role = _userProfile['role'].toString();
        if (role.contains('COACH')) {
          final ownedRes = await ApiClient().dio.get('/boxes/mine');
          if (ownedRes.data['success']) {
            _ownedBoxes = ownedRes.data['data'];
          }
        } else {
          final statusRes = await ApiClient().dio.get('/boxes/my-status');
          if (statusRes.data['success']) {
            _membershipStatus = statusRes.data['data'];
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch Initial Data Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchBoxes(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final res = await ApiClient().dio.get('/boxes/search', queryParameters: {'name': query});
      if (res.data['success']) {
        setState(() => _searchResults = res.data['data']);
      }
    } catch (e) {
      debugPrint("Search Box Error: $e");
    }
  }

  Future<void> _applyBox(int boxId) async {
    try {
      final res = await ApiClient().dio.post('/boxes/$boxId/apply');
      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membership application submitted!')));
          _fetchInitialData();
        }
      }
    } catch (e) {
      debugPrint("Apply Box Error: $e");
      if (mounted) {
        String message = 'Failed to submit application: Connection error';
        if (e is DioException && e.response != null && e.response?.data != null) {
          message = 'Failed to submit application: ${e.response?.data['message'] ?? 'Unknown error'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Box', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_userProfile['role'].toString().contains('COACH'))
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BoxRegistrationScreen()));
                if (result == true) _fetchInitialData();
              },
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text("Register Box", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_userProfile['role'].toString().contains('COACH')) ..._buildCoachUI() else ..._buildUserUI(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCoachUI() {
    return [
      const Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (_ownedBoxes.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("You haven't registered a box yet.")))
      else
        ..._ownedBoxes.map((box) => Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
          child: ListTile(
            title: Text(box['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(box['location']),
            trailing: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BoxManagementScreen(boxId: box['id'], boxName: box['name']))),
              child: const Text("Manage"),
            ),
          ),
        )),
    ];
  }

  List<Widget> _buildUserUI() {
    return [
      if (_membershipStatus != null) ...[
        const Text("My Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primary)),
          child: ListTile(
            title: Text(_membershipStatus['boxName'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Status: ${_membershipStatus['status']}"),
            trailing: Icon(
              _membershipStatus['status'] == 'APPROVED' ? Icons.verified : Icons.hourglass_empty,
              color: _membershipStatus['status'] == 'APPROVED' ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
      const Text("Find a Box", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextField(
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: _searchBoxes,
      ),
      const SizedBox(height: 16),
      ..._searchResults.map((box) => ListTile(
        title: Text(box['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(box['location']),
        trailing: ElevatedButton(
          onPressed: () => _applyBox(box['id']),
          child: const Text("Join"),
        ),
      )),
    ];
  }
}
