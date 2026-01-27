import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../styles/app_colors.dart';
import '../../core/api/api_client.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const AdminBoxTab(),
    const AdminUserTab(),
    const AdminAiTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ADMIN CONSOLE', 
          style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'), 
          )
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.business_center), label: 'Boxes'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI WOD'),
        ],
      ),
    );
  }
}

class AdminBoxTab extends StatefulWidget {
  const AdminBoxTab({super.key});

  @override
  State<AdminBoxTab> createState() => _AdminBoxTabState();
}

class _AdminBoxTabState extends State<AdminBoxTab> {
  List<dynamic> _boxes = [];
  List<dynamic> _filteredBoxes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBoxes();
    _searchController.addListener(_filterBoxes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBoxes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBoxes = _boxes.where((box) {
        final name = box['name'].toString().toLowerCase();
        final owner = box['ownerEmail'].toString().toLowerCase();
        return name.contains(query) || owner.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchBoxes() async {
    try {
      final res = await ApiClient().dio.get('/admin/boxes');
      setState(() {
        _boxes = res.data['data'];
        _filteredBoxes = _boxes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Boxes Error: $e");
    }
  }

  Future<void> _toggleAutoWod(int boxId, bool currentStatus) async {
    try {
      await ApiClient().dio.patch('/admin/boxes/$boxId/auto-wod', queryParameters: {'enabled': !currentStatus});
      _fetchBoxes();
    } catch (e) {
      debugPrint("Toggle Auto WOD Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search boxes by name or owner...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _filteredBoxes.isEmpty
              ? const Center(child: Text('No boxes found.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _filteredBoxes.length,
                  itemBuilder: (context, index) {
                    final box = _filteredBoxes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(box['name'], style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('ID: ${box['id']} | Owner: ${box['ownerEmail']}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('AI WOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: box['isAutoWodEnabled'] ?? false,
                                activeColor: AppColors.primary,
                                onChanged: (val) => _toggleAutoWod(box['id'], box['isAutoWodEnabled']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class AdminUserTab extends StatefulWidget {
  const AdminUserTab({super.key});

  @override
  State<AdminUserTab> createState() => _AdminUserTabState();
}

class _AdminUserTabState extends State<AdminUserTab> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final nickname = user['nickname'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        return nickname.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await ApiClient().dio.get('/admin/users');
      setState(() {
        _users = res.data['data'];
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Users Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by nickname or email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _filteredUsers.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.separated(
                  itemCount: _filteredUsers.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      title: Text(user['nickname'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'], style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.stars, size: 14, color: AppColors.primary.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text('${user['tier']} (${user['points']} pts)', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                      trailing: _buildRoleBadge(user['role']),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'ADMIN') color = Colors.red;
    if (role.contains('PREMIUM')) color = Colors.amber;
    if (role == 'COACH') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(role, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class AdminAiTab extends StatefulWidget {
  const AdminAiTab({super.key});

  @override
  State<AdminAiTab> createState() => _AdminAiTabState();
}

class _AdminAiTabState extends State<AdminAiTab> {
  List<dynamic> _globalWods = [];
  List<dynamic> _selectedDateWods = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchGlobalWods();
  }

  Future<void> _fetchGlobalWods() async {
    try {
      final res = await ApiClient().dio.get('/admin/global-wods');
      setState(() {
        _globalWods = res.data['data'];
        _updateSelectedDateWods();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Global Wods Error: $e");
    }
  }

  void _updateSelectedDateWods() {
    if (_selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    setState(() {
      _selectedDateWods = _globalWods.where((wod) => wod['date'] == dateStr).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _updateSelectedDateWods();
            },
            eventLoader: (day) {
              final dStr = DateFormat('yyyy-MM-dd').format(day);
              return _globalWods.where((wod) => wod['date'] == dStr).toList();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WODs for ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: _fetchGlobalWods, icon: const Icon(Icons.refresh, size: 20)),
            ],
          ),
        ),
        Expanded(
          child: _selectedDateWods.isEmpty 
            ? const Center(child: Text('No WODs for this date.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedDateWods.length,
                itemBuilder: (context, index) {
                  final wod = _selectedDateWods[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(wod['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(wod['type'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to WOD detail/edit
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.add), 
            label: const Text('New Global WOD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        )
      ],
    );
  }
}
