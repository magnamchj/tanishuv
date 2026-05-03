import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminService _adminService;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adminService = AdminService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _seedData() async {
    setState(() => _seeding = true);
    await _adminService.seedDummyData();
    if (mounted) {
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('✅ Dummy data seeded: 10 users, 5 events, 3 stories'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel',
            style: TextStyle(color: Colors.orangeAccent)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'Users'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(),
          _buildUsersTab(),
          _buildReportsTab(),
        ],
      ),
      // FAB for seeding dummy data
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _seeding ? null : _seedData,
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: _seeding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
            : const Icon(Icons.data_array),
        label: Text(_seeding ? 'Seeding...' : 'Seed Dummy Data'),
      ),
    );
  }

  // ── Events Tab ──────────────────────────────────
  Widget _buildEventsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showCreateEventDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create New Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminService.getAllUsers(),
            builder: (context, snapshot) {
              // Reusing the events stream from Firestore
              return const Center(
                child: Text(
                  'Events are managed from the events tab.\nUse seed button to add test data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Users Tab ──────────────────────────────────
  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isBanned = user['isBanned'] == true;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (user['photoUrl'] as String?)?.isNotEmpty ==
                        true
                    ? NetworkImage(user['photoUrl'])
                    : null,
                backgroundColor: AppTheme.surfaceColor,
                child: (user['photoUrl'] as String?)?.isEmpty != false
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              title: Row(
                children: [
                  Text(user['name'] ?? 'Unknown'),
                  if (isBanned) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('BANNED',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '@${user['nickname'] ?? ''} • Age ${user['age']}',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              trailing: isBanned
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.block, color: Colors.redAccent),
                      onPressed: () async {
                        await _adminService.banUser(user['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${user['name']} banned.')),
                          );
                        }
                      },
                    ),
            );
          },
        );
      },
    );
  }

  // ── Reports Tab ──────────────────────────────────
  Widget _buildReportsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getReports(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;

        if (reports.isEmpty) {
          return const Center(
            child: Text('No reports yet.',
                style: TextStyle(color: Colors.white38)),
          );
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.flag, color: Colors.redAccent),
                title: Text('Report against: ${report['targetUserId']}',
                    style: const TextStyle(fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('By: ${report['reporterId']}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    Text(report['reason'] ?? 'No reason given',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.block, color: Colors.orangeAccent),
                  onPressed: () =>
                      _adminService.banUser(report['targetUserId']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    bool premiumOnly = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Event title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Location name'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('VIP / Premium Only'),
                  value: premiumOnly,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) => setDialogState(() => premiumOnly = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _adminService.createEvent(
                  title: titleController.text,
                  description: descController.text,
                  locationName: locationController.text,
                  latitude: 41.2995,
                  longitude: 69.2401,
                  time: DateTime.now().add(const Duration(days: 7)),
                  premiumOnly: premiumOnly,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Event created!'),
                        backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
