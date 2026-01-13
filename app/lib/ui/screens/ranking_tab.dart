import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class RankingTab extends StatefulWidget {
  final int? initialWodId;
  const RankingTab({super.key, this.initialWodId});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _rankings = [];
  int? _selectedWodId;
  List<dynamic> _availableWods = [];
  dynamic _userProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _selectedWodId = widget.initialWodId;
    _initializeData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _fetchRankings();
  }

  Future<void> _initializeData() async {
    await _fetchUserProfile();
    await _fetchDailyWods();
    if (_availableWods.isNotEmpty && _selectedWodId == null) {
      _selectedWodId = _availableWods.first['id'];
    }
    await _fetchRankings();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final res = await ApiClient().dio.get('/users/me');
      if (res.data['success']) {
        setState(() => _userProfile = res.data['data']);
      }
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
    }
  }

  Future<void> _fetchDailyWods() async {
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final res = await ApiClient().dio.get('/wods', queryParameters: {'date': dateStr});
      if (res.data['success']) {
        setState(() {
          _availableWods = res.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Fetch WODs Error: $e");
    }
  }

  Future<void> _fetchRankings() async {
    if (_selectedWodId == null) return;
    
    final isBoxRanking = _tabController.index == 1;
    if (isBoxRanking && (_userProfile == null || _userProfile['boxId'] == null)) {
      setState(() {
        _rankings = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{'limit': 50};
      if (isBoxRanking) {
        queryParams['boxId'] = _userProfile['boxId'];
      }

      final res = await ApiClient().dio.get('/records/rankings/$_selectedWodId', queryParameters: queryParams);
      if (res.data['success']) {
        setState(() {
          _rankings = res.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Fetch Rankings Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rankings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              if (_availableWods.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _availableWods.map((wod) {
                      final isSelected = _selectedWodId == wod['id'];
                      return Padding(
                        padding: const EdgeInsets.right(8),
                        child: ChoiceChip(
                          label: Text(wod['title']),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedWodId = wod['id']);
                              _fetchRankings();
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Global'),
                  Tab(text: 'My Box'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _selectedWodId == null 
              ? const Center(child: Text("No WOD selected"))
              : _rankings.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rankings.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) => _buildRankingItem(index),
                    ),
    );
  }

  Widget _buildRankingItem(int index) {
    final item = _rankings[index];
    final rank = index + 1;
    
    Color rankColor = AppColors.textPrimary;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rank <= 3 ? rankColor.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rankColor,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(item['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(
        '${item['score'].toStringAsFixed(1)}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isBoxRanking = _tabController.index == 1;
    final hasNoBox = _userProfile != null && _userProfile['boxId'] == null;

    String text = 'No records found yet!';
    if (isBoxRanking && hasNoBox) {
      text = 'Join a box to see your box rankings!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBoxRanking && hasNoBox ? Icons.door_front_door_outlined : Icons.emoji_events_outlined,
            size: 64, 
            color: AppColors.textSecondary.withOpacity(0.5)
          ),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
