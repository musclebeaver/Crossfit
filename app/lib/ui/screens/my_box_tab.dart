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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String _currentQuery = '';
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _searchResults = [];
  dynamic _userProfile;
  dynamic _membershipStatus;
  List<dynamic> _ownedBoxes = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoadingMore) {
        _loadMoreBoxes();
      }
    });
    _fetchInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    _searchBoxes(''); // Default empty search to load initial 20 boxes!
  }

  Future<void> _searchBoxes(String query) async {
    _currentQuery = query;
    _currentPage = 0;
    _hasMore = true;
    try {
      final res = await ApiClient().dio.get('/boxes/search', queryParameters: {
        'name': query,
        'page': 0,
        'size': 20
      });
      if (res.data['success']) {
        setState(() {
          _searchResults = res.data['data']['content'];
          _hasMore = !res.data['data']['last'];
        });
      }
    } catch (e) {
      debugPrint("Search Box Error: $e");
    }
  }

  Future<void> _loadMoreBoxes() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    
    _currentPage++;
    try {
      final res = await ApiClient().dio.get('/boxes/search', queryParameters: {
        'name': _currentQuery,
        'page': _currentPage,
        'size': 20
      });
      if (res.data['success']) {
        setState(() {
          _searchResults.addAll(res.data['data']['content']);
          _hasMore = !res.data['data']['last'];
        });
      }
    } catch (e) {
      debugPrint("Load More Boxes Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Box', style: TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_userProfile['role'].toString().contains('COACH'))
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BoxRegistrationScreen()));
                if (result == true) _fetchInitialData();
              },
              icon: const Icon(Icons.add, color: Color(0xFF115D33)),
              label: const Text("Register Box", style: TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: ListView(
          controller: _scrollController,
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
      const Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 12),
      if (_ownedBoxes.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("You haven't registered a box yet.", style: TextStyle(color: Color(0xFF757575)))))
      else
        ..._ownedBoxes.map((box) => Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: ListTile(
            title: Text(box['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text(box['location'], style: const TextStyle(color: Color(0xFF757575))),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF115D33), 
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BoxManagementScreen(boxId: box['id'], boxName: box['name']))),
              child: const Text("Manage", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        )),
    ];
  }

  List<Widget> _buildUserUI() {
    final status = _membershipStatus['status'];
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    
    if (status == 'APPROVED') {
      statusColor = const Color(0xFF115D33);
      statusIcon = Icons.verified;
    } else if (status == 'PENDING') {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (status == 'REJECTED') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    }

    return [
      if (_membershipStatus != null) ...[
        const Text("My Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Card(
          color: statusColor.withOpacity(0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: statusColor.withOpacity(0.2))),
          child: ListTile(
            title: Text(_membershipStatus['boxName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text("Status: $status", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            trailing: Icon(statusIcon, color: statusColor),
          ),
        ),
        const SizedBox(height: 32),
      ],
      const Text("Find a Box", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 12),
      TextField(
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33), width: 1.5)),
        ),
        onChanged: _searchBoxes,
      ),
      const SizedBox(height: 16),
      ..._searchResults.map((box) => ListTile(
        title: Text(box['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(box['location'], style: const TextStyle(color: Color(0xFF757575))),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF115D33), 
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          onPressed: () => _applyBox(box['id']),
          child: const Text("Join", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      )),
      if (_isLoadingMore)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }
}
