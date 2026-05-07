import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/user_role_service.dart';

class BoxManagementScreen extends StatefulWidget {
  final num boxId;
  final String boxName;

  const BoxManagementScreen({super.key, required this.boxId, required this.boxName});

  @override
  State<BoxManagementScreen> createState() => _BoxManagementScreenState();
}

class _BoxManagementScreenState extends State<BoxManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // WOD State
  List<dynamic> _wods = [];
  DateTime _selectedDate = DateTime.now();
  
  // Member State
  List<dynamic> _members = [];
  final TextEditingController _memberSearchController = TextEditingController();
  Timer? _memberSearchDebounce;

  // Box Config State
  bool _isAutoWodEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchSelectedTabData();
      }
    });
    _fetchSelectedTabData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberSearchController.dispose();
    _memberSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchSelectedTabData() async {
    if (_tabController.index == 0) {
      await _fetchWods();
      await _fetchBoxConfig();
    } else {
      await _fetchMembers();
    }
  }

  Future<void> _fetchBoxConfig() async {
    try {
      final res = await ApiClient().dio.get('/boxes/mine');
      if (res.data['success']) {
        final List boxes = res.data['data'];
        final myBox = boxes.firstWhere((b) => b['id'] == widget.boxId, orElse: () => null);
        if (myBox != null) {
          setState(() => _isAutoWodEnabled = myBox['isAutoWodEnabled'] ?? false);
        }
      }
    } catch (e) {
      debugPrint("Fetch Box Config Error: $e");
    }
  }

  Future<void> _toggleAutoWod(bool value) async {
    final original = _isAutoWodEnabled;
    setState(() => _isAutoWodEnabled = value);
    try {
      final res = await ApiClient().dio.patch('/boxes/${widget.boxId}/auto-wod', queryParameters: {'enabled': value});
      if (!res.data['success']) {
        setState(() => _isAutoWodEnabled = original);
      }
    } catch (e) {
      setState(() => _isAutoWodEnabled = original);
      debugPrint("Toggle Auto Wod Error: $e");
    }
  }

  Future<void> _fetchWods() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await ApiClient().dio.get('/wods', queryParameters: {
        'date': dateStr,
        'boxId': widget.boxId,
      });
      if (res.data['success']) {
        setState(() => _wods = res.data['data']);
      }
    } catch (e) {
      debugPrint("Fetch WODs Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMemberSearchChanged(String query) {
    if (_memberSearchDebounce?.isActive ?? false) _memberSearchDebounce!.cancel();
    _memberSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMembers();
    });
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get(
        '/boxes/${widget.boxId}/members',
        queryParameters: {'nickname': _memberSearchController.text},
      );
      if (res.data['success']) {
        setState(() => _members = res.data['data']);
      }
    } catch (e) {
      debugPrint("Fetch Members Error: $e");
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
          _fetchMembers();
        }
      }
    } catch (e) {
      debugPrint("Approval Error: $e");
    }
  }

  Future<void> _generateAiWod(String type, String requirements) async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await ApiClient().dio.post('/wods/ai-create', queryParameters: {
        'boxId': widget.boxId,
        'boxName': widget.boxName,
        'type': type,
        'requirements': requirements,
        'date': dateStr,
      });
      if (res.data['success']) {
        await _fetchWods();
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message'] ?? "AI generation failed")),
          );
        }
      }
    } catch (e) {
      debugPrint("AI Gen Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error during AI generation")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndGenerateAiWod(String type, String finalReq) async {
    if (UserRoleService.isPremium) {
      // 프리미엄 유저는 바로 생성
      _generateAiWod(type, finalReq);
      return;
    }

    // 일반 유저는 광고 시청 확인 팝업
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("AI WOD Generation"),
        content: const Text("Would you like to watch a short ad to generate an AI WOD?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF115D33), foregroundColor: Colors.white),
            child: const Text("Watch Ad"),
          ),
        ],
      ),
    );

    if (proceed == true) {
      AdService.showRewardedAd(
        onRewardEarned: () {
          _generateAiWod(type, finalReq);
        },
        onAdFailedToLoad: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load ad. Please try again.")),
          );
        },
      );
    }
  }

  Future<void> _showAiWodDialog() async {
    final reqController = TextEditingController();
    String type = 'RANDOM';
    String teamSize = 'Individual';
    String teamFormat = 'I Go You Go';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF115D33)),
              SizedBox(width: 8),
              Text('AI Auto Generate'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['RANDOM', 'AMRAP', 'FOR_TIME', 'MAX_WEIGHT', 'EMOM'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'WOD Type'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: teamSize,
                  items: ['Individual', 'Team of 2', 'Team of 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => teamSize = val!),
                  decoration: const InputDecoration(labelText: 'Team Size'),
                ),
                if (teamSize != 'Individual') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: teamFormat,
                    items: ['I Go You Go', 'Synchro', 'Relay'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => teamFormat = val!),
                    decoration: const InputDecoration(labelText: 'Team Format'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: reqController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Requirements (Optional)',
                    helperText: 'e.g., Include Burpees, Focus on legs',
                    helperMaxLines: 2,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                String finalReq = reqController.text;
                if (teamSize != 'Individual') {
                  finalReq = 'Team Size: $teamSize, Format: $teamFormat. ' + finalReq;
                }
                _verifyAndGenerateAiWod(type, finalReq);
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWodDialog({dynamic wod}) async {
    final isEdit = wod != null;
    final titleController = TextEditingController(text: isEdit ? wod['title'] : '');
    final descController = TextEditingController(text: isEdit ? wod['description'] : '');
    final timeCapController = TextEditingController(text: isEdit ? wod['timeCap']?.toString() : '');
    String type = isEdit ? wod['type'] : 'AMRAP';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit WOD' : 'New WOD'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['AMRAP', 'FOR_TIME', 'MAX_WEIGHT'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                TextField(controller: timeCapController, decoration: const InputDecoration(labelText: 'Time Cap (min)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final data = {
                  if (isEdit) 'id': wod['id'],
                  'boxId': widget.boxId,
                  'type': type,
                  'title': titleController.text,
                  'description': descController.text,
                  'timeCap': int.tryParse(timeCapController.text),
                  'date': dateStr,
                };
                
                try {
                  final res = await ApiClient().dio.post('/wods/manual', data: data);
                  if (res.data['success']) {
                    Navigator.pop(context);
                    _fetchWods();
                  }
                } catch (e) {
                  debugPrint("Upsert WOD Error: $e");
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Box Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Daily Auto-generation'),
                subtitle: const Text('Automatically generate a new AI WOD every day at midnight.'),
                value: _isAutoWodEnabled,
                onChanged: (val) {
                  setDialogState(() => _isAutoWodEnabled = val);
                  _toggleAutoWod(val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWod(dynamic wod) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete WOD"),
        content: Text("Are you sure you want to delete '${wod['title']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await ApiClient().dio.delete('/wods/${wod['id']}');
        if (res.data['success']) {
          _fetchWods();
        }
      } catch (e) {
        debugPrint("Delete WOD Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.boxName} Management', style: const TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF115D33)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF115D33)),
              onPressed: () => _showWodDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF115D33),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFF115D33),
          tabs: const [
            Tab(text: 'WOD'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWodManagement(),
          _buildMemberManagement(),
        ],
      ),
    );
  }

  Widget _buildWodManagement() {
    return RefreshIndicator(
      onRefresh: _fetchWods,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd (EEE)').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFF757575)),
                    onPressed: () {
                      _showSettingsDialog();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                      _fetchWods();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                      _fetchWods();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_wods.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  const Text("No WOD for this date."),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAiWodDialog,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("AI Auto Generate", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF115D33),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showWodDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Manual Add", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF115D33),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ..._wods.map((wod) => Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
              elevation: 0,
              child: ListTile(
                title: Text(wod['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${wod['type']} | ${wod['description']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF115D33)),
                      onPressed: () => _showWodDialog(wod: wod),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteWod(wod),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMemberManagement() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchMembers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _memberSearchController,
            onChanged: _onMemberSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by nickname...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF115D33)),
              isDense: true,
              filled: false,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33))),
              suffixIcon: _memberSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _memberSearchController.clear();
                        _fetchMembers();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          _buildMemberStatusSection(),
        ],
      ),
    );
  }

  Widget _buildMemberStatusSection() {
    final pending = _members.where((m) => m['status'] == 'PENDING').toList();
    final approved = _members.where((m) => m['status'] == 'APPROVED').toList();
    final rejected = _members.where((m) => m['status'] == 'REJECTED').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pending.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text("Pending Approval", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.map((m) => _buildMemberItem(m)),
          const SizedBox(height: 24),
        ],
        const Text("Approved Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (approved.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("No approved members yet.", style: TextStyle(color: Colors.grey)))
        else
          ...approved.map((m) => _buildMemberItem(m)),
        if (rejected.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text("Rejected", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ...rejected.map((m) => _buildMemberItem(m)),
        ],
      ],
    );
  }

  Widget _buildMemberItem(dynamic member) {
    final status = member['status'];
    Color statusColor = Colors.grey;
    if (status == 'APPROVED') statusColor = Colors.green;
    if (status == 'PENDING') statusColor = Colors.orange;
    if (status == 'REJECTED') statusColor = Colors.red;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
      elevation: 0,
      child: ListTile(
        title: Text(member['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Text("Status: "),
            Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: status == 'PENDING'
            ? Row(
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
              )
            : null,
      ),
    );
  }
}
