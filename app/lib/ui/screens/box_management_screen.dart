import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class BoxManagementScreen extends StatefulWidget {
  final Long boxId;
  final String boxName;

  const BoxManagementScreen({super.key, required this.boxId, required this.boxName});

  @override
  State<BoxManagementScreen> createState() => _BoxManagementScreenState();
}

class _BoxManagementScreenState extends State<BoxManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingMembers();
  }

  Future<void> _fetchPendingMembers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/boxes/${widget.boxId}/members/pending');
      if (res.data['success']) {
        setState(() => _pendingMembers = res.data['data']);
      }
    } catch (e) {
      debugPrint("Fetch Pending Members Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApproval(int memberId, bool approve) async {
    try {
      final res = await ApiClient().dio.post(
        '/boxes/members/$memberId/approve',
        queryParameters: {'approve': approve},
      );
      if (res.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approve ? "Approved!" : "Rejected.")),
          );
          _fetchPendingMembers();
        }
      }
    } catch (e) {
      debugPrint("Approval Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.boxName} Management', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPendingMembers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Pending Membership Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  if (_pendingMembers.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No pending requests.")))
                  else
                    ..._pendingMembers.map((m) => _buildMemberItem(m)),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberItem(dynamic member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      elevation: 0,
      child: ListTile(
        title: Text(member['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Status: PENDING"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _handleApproval(member['memberId'], true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _handleApproval(member['memberId'], false),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for type safety if needed, but using dynamic for simplicity in proto
typedef Long = num;
