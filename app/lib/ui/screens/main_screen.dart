import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import 'wod_tab.dart';
import 'ranking_tab.dart';
import 'records_tab.dart';
import 'my_box_tab.dart';
import 'profile_tab.dart';
import '../../core/services/sync_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SyncManager.syncPendingRecords();
  }

  final List<Widget> _screens = [
    const WodTab(),
    const RankingTab(),
    const MyBoxTab(),
    const RecordsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF115D33),
        unselectedItemColor: const Color(0xFF757575),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'WOD'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Ranking'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'My Box'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String text;
  const PlaceholderWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(fontSize: 24, color: Colors.black87)),
    );
  }
}
