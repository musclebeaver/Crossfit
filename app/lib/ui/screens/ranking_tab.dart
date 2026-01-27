import 'package:flutter/material.dart';
import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  List<dynamic> _rankings = [];
  int? _selectedWodId;
  List<dynamic> _availableWods = [];
  dynamic _userProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);
    _selectedWodId = widget.initialWodId;
    _initializeData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isMoreLoading && _hasMore) {
        _fetchMoreRankings();
      }
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _resetAndFetch();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndFetch();
    });
  }

  Future<void> _resetAndFetch() async {
    setState(() {
      _currentPage = 0;
      _rankings = [];
      _hasMore = true;
      _isLoading = true;
    });
    await _fetchRankings();
  }

  Future<void> _initializeData() async {
    await _fetchUserProfile();
    await _fetchDailyWods();
    if (_availableWods.isNotEmpty && _selectedWodId == null) {
      _selectedWodId = _availableWods.first['id'];
    }
    await _resetAndFetch(); // Call resetAndFetch to handle initial loading and potential search/tab state
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
    if (_selectedWodId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    final isBoxRanking = _tabController.index == 1;
    if (isBoxRanking && (_userProfile == null || _userProfile['boxId'] == null)) {
      setState(() {
        _rankings = [];
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'size': _pageSize,
      };
      if (isBoxRanking) {
        queryParams['boxId'] = _userProfile['boxId'];
      }
      if (_searchController.text.isNotEmpty) {
        queryParams['nickname'] = _searchController.text;
      }

      final res = await ApiClient().dio.get('/records/rankings/$_selectedWodId', queryParameters: queryParams);
      if (res.data['success']) {
        final List<dynamic> newEntries = res.data['data'];
        setState(() {
          _rankings = newEntries;
          _isLoading = false;
          _hasMore = newEntries.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint("Fetch Rankings Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreRankings() async {
    setState(() => _isMoreLoading = true);
    _currentPage++;
    
    final isBoxRanking = _tabController.index == 1;
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'size': _pageSize,
      };
      if (isBoxRanking) {
        queryParams['boxId'] = _userProfile['boxId'];
      }
      if (_searchController.text.isNotEmpty) {
        queryParams['nickname'] = _searchController.text;
      }

      final res = await ApiClient().dio.get('/records/rankings/$_selectedWodId', queryParameters: queryParams);
      if (res.data['success']) {
        final List<dynamic> newEntries = res.data['data'];
        setState(() {
          _rankings.addAll(newEntries);
          _isMoreLoading = false;
          _hasMore = newEntries.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint("Fetch More Rankings Error: $e");
      setState(() => _isMoreLoading = false);
    }
  }

  List<dynamic> get _filteredWods {
    if (_tabController.index == 0) {
      return _availableWods.where((w) => w['boxId'] == null).toList();
    } else {
      if (_userProfile == null || _userProfile['boxId'] == null) return [];
      return _availableWods.where((w) => w['boxId'] == _userProfile['boxId']).toList();
    }
  }

  dynamic get _selectedWod {
    if (_selectedWodId == null) return null;
    try {
      return _availableWods.firstWhere((w) => w['id'] == _selectedWodId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWods;
    
    // Auto-select first WOD if current selection is not in filtered list
    if (filtered.isNotEmpty && ( _selectedWodId == null || !filtered.any((w) => w['id'] == _selectedWodId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedWodId = filtered.first['id'];
          _resetAndFetch();
        });
      });
    }

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
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                onTap: (index) {
                   setState(() {
                     _selectedWodId = null; // Reset selection on tab change to trigger auto-select
                   });
                },
                tabs: const [
                  Tab(text: 'Global'),
                  Tab(text: 'My Box'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by nickname...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading && _rankings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (filtered.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filtered.map((wod) {
                          final isSelected = _selectedWodId == wod['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(wod['title']),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedWodId = wod['id']);
                                  _resetAndFetch();
                                }
                              },
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                if (_selectedWod != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(_selectedWod['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_selectedWod['type'], style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_selectedWod['description'], style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _selectedWodId == null
                      ? Center(child: Text(_tabController.index == 1 && (_userProfile == null || _userProfile['boxId'] == null) 
                          ? "Join a box to see rankings" 
                          : "No WOD for today"))
                      : _rankings.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _resetAndFetch,
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _rankings.length + (_hasMore ? 1 : 0),
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  if (index == _rankings.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 32),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  return _buildRankingItem(index);
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildRankingItem(int index) {
    final item = _rankings[index];
    final rank = item['rank'] ?? (index + 1); // Fallback to index if rank is missing
    
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
      title: Row(
        children: [
          Text(item['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          _buildTierBadge(item['tier']),
          if (item['isRx'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Rx', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      trailing: Text(
        '${item['displayValue']}',
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
    } else if (_searchController.text.isNotEmpty) {
      text = 'No users found with that nickname.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBoxRanking && hasNoBox ? Icons.door_front_door_outlined : (_searchController.text.isNotEmpty ? Icons.search_off : Icons.emoji_events_outlined),
            size: 64, 
            color: AppColors.textSecondary.withOpacity(0.5)
          ),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
