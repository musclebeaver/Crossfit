import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../../data/models/wod_model.dart';
import '../../data/repositories/wod_repository.dart';
import 'package:intl/intl.dart';

class WodListScreen extends StatefulWidget {
  const WodListScreen({super.key});

  @override
  State<WodListScreen> createState() => _WodListScreenState();
}

class _WodListScreenState extends State<WodListScreen> {
  final WodRepository _repository = WodRepository();
  List<WodModel> _wods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWods();
  }

  Future<void> _fetchWods() async {
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final wods = await _repository.getWods(date);
      setState(() {
        _wods = wods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY WOD', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _wods.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wods.length,
                  itemBuilder: (context, index) => _buildWodCard(_wods[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No WODs for today', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildWodCard(WodModel wod) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    wod.type,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (wod.timeCap != null)
                  Text('Time Cap: ${wod.timeCap! ~/ 60}m',
                      style: const TextStyle(color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              wod.title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              wod.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Record result', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Ranking', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
