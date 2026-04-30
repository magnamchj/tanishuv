import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyMessages = true;
  bool _notifyMatches = true;
  bool _notifyEvents = true;
  bool _privateMode = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Safety',
            style: TextStyle(color: AppTheme.primaryColor)),
      ),
      body: ListView(
        children: [
          // Profile Edit
          _sectionHeader('Profile'),
          ListTile(
            leading: const Icon(Icons.person, color: AppTheme.primaryColor),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update photos, bio, interests', style: TextStyle(fontSize: 12, color: Colors.white38)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),

          // Profile Privacy
          _sectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Anonymous / Private Mode'),
            subtitle: const Text('Hide your profile from discover',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
            value: _privateMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _privateMode = v),
          ),

          // Notifications
          _sectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('New Messages'),
            value: _notifyMessages,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _notifyMessages = v),
          ),
          SwitchListTile(
            title: const Text('New Matches'),
            value: _notifyMatches,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _notifyMatches = v),
          ),
          SwitchListTile(
            title: const Text('Event Reminders'),
            value: _notifyEvents,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _notifyEvents = v),
          ),

          // Safety
          _sectionHeader('Safety'),
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.blueAccent),
            title: const Text('Verify My Identity'),
            subtitle: const Text('Via phone number or ID',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVerifyDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.orangeAccent),
            title: const Text('Block a User'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBlockDialog(context, currentUserId, dbService),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined, color: Colors.redAccent),
            title: const Text('Report a User'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showReportDialog(context, currentUserId, dbService),
          ),

          // Account
          _sectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white54),
            title: const Text('Language'),
            subtitle: const Text('O\'zbek / Русский / English',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white54),
            title: const Text('About Tanishuv'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Tanishuv',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 Tanishuv. All rights reserved.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54),
            title: const Text('Logout'),
            onTap: () => _showLogoutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showVerifyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Identity Verification'),
        content: const Text(
          'To verify via phone number, we\'ll send you an SMS code.\n\nVerification confirms you\'re a real person and adds a badge to your profile.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Verification request submitted! (coming soon)')),
              );
            },
            child: const Text('Verify via Phone'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(
      BuildContext context, String currentUserId, DatabaseService dbService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Block User'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter User ID to block',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await dbService.blockUser(
                    currentUserId, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User blocked successfully.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(
      BuildContext context, String currentUserId, DatabaseService dbService) {
    final idController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'User ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Reason for report'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isNotEmpty) {
                await dbService.reportUser(
                  currentUserId,
                  idController.text.trim(),
                  reasonController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Report submitted. Thank you.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Pop SettingsScreen
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
