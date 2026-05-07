import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.get('/records/history');
      if (res.data['success']) {
        setState(() {
          _history = res.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Fetch History Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Records', style: TextStyle(color: Color(0xFF115D33), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildChartSection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ranking Trends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _history.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['rank'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF115D33),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF115D33).withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Activity History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No data yet", style: TextStyle(color: Color(0xFF757575))))),
        ..._history.map((h) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.fitness_center, color: Color(0xFF115D33))),
            title: Text("WOD #${h['wodId']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            subtitle: Text("${h['date']}", style: const TextStyle(color: Color(0xFF757575))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${h['rank']}th", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF115D33), fontSize: 16)),
                Text(h['isRx'] ? "Rx'd" : "Scaled", style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
