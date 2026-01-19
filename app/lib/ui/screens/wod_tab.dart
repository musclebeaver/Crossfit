import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';
import 'record_entry_screen.dart';

class WodTab extends StatefulWidget {
  const WodTab({super.key});

  @override
  State<WodTab> createState() => _WodTabState();
}

class _WodTabState extends State<WodTab> {
  bool _isLoading = true;
  List<dynamic> _globalWods = [];
  Map<String, List<dynamic>> _boxWods = {};

  @override
  void initState() {
    super.initState();
    _fetchWods();
  }

  Future<void> _fetchWods() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. 글로벌 WOD 가져오기 (boxId 없음)
      final globalRes = await ApiClient().dio.get('/wods', queryParameters: {'date': dateStr});
      if (globalRes.data['success']) {
        _globalWods = globalRes.data['data'];
      }

      // 2. 유저 정보 및 박스 WOD 가져오기
      final userRes = await ApiClient().dio.get('/users/me');
      if (userRes.data['success']) {
        final userData = userRes.data['data'];
        final boxId = userData['boxId'];
        final boxName = userData['boxName'] ?? 'My Box';

        if (boxId != null) {
          final boxWodRes = await ApiClient().dio.get('/wods', queryParameters: {
            'date': dateStr,
            'boxId': boxId,
          });
          if (boxWodRes.data['success']) {
            _boxWods = {boxName: boxWodRes.data['data']};
          }
        } else {
          _boxWods = {};
        }
      }

    } catch (e) {
      debugPrint("WOD Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout of the Day', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWods,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Global WOD'),
            ..._globalWods.map((w) => _buildWodCard(w, isGlobal: true)),
            if (_globalWods.isEmpty) _buildEmptyState('No Global WOD for today'),
            
            const SizedBox(height: 32),
            
            ..._boxWods.entries.expand((entry) => [
              _buildSectionHeader(entry.key),
              ...entry.value.map((w) => _buildWodCard(w)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildWodCard(dynamic wod, {bool isGlobal = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      color: isGlobal ? AppColors.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(wod['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(wod['type'] ?? 'WOD', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(wod['description'] ?? '', style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            if (wod['timeCap'] != null && wod['timeCap'] > 0)
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text("Time Cap: ${wod['timeCap'] ~/ 60} min", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordEntryScreen(wod: wod),
                    ),
                  );
                  if (result == true && mounted) {
                    // Optional: show a message or redirect to rankings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Record saved successfully!'))
                    );
                  }
                },
                icon: const Icon(Icons.edit_note, size: 20),
                label: const Text('Record Result', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(msg, style: const TextStyle(color: AppColors.textSecondary))),
    );
  }
}
