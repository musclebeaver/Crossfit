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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('DAILY WOD', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF115D33))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person, color: Color(0xFF115D33)), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF115D33)))
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
          const Icon(Icons.event_busy, size: 64, color: Color(0xFF757575)),
          const SizedBox(height: 16),
          const Text('No WODs for today', style: TextStyle(color: Color(0xFF757575), fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildWodCard(WodModel wod) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
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
                    color: const Color(0xFF115D33).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    wod.type,
                    style: const TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold),
                  ),
                ),
                if (wod.timeCap != null)
                  Text('Time Cap: ${wod.timeCap! ~/ 60}m',
                      style: const TextStyle(color: Color(0xFF757575))),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              wod.title,
              style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              wod.description,
              style: const TextStyle(color: Color(0xFF757575), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF115D33),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: const Text('Record result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Ranking', style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
