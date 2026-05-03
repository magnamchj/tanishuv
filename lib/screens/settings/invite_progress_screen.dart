import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';

class InviteProgressScreen extends StatelessWidget {
  const InviteProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<UserModel?>(
      stream: authService.currentUserModelStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: AppTheme.backgroundColor, body: Center(child: CircularProgressIndicator()));
        final user = snapshot.data!;
        final credits = user.inviteCredits;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Unlock Features'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.group_add, size: 80, color: Colors.pinkAccent),
                const SizedBox(height: 16),
                const Text(
                  'Invite Friends, \nUnlock Everything.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tanishuv is 100% free. Gain full access by inviting your friends. Each friend who signs up gives you 1 credit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                
                // Progress Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$credits Credits',
                        style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _buildMilestone(3, 'See Who Liked You', credits >= 3),
                      const SizedBox(height: 16),
                      _buildMilestone(5, 'Open Profiles Fully', credits >= 5),
                      const SizedBox(height: 16),
                      _buildMilestone(1, 'Unlimited Anonymous Chat', credits >= 1),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                Builder(
                  builder: (context) {
                    final String link =
                        "https://tanishuv-667dd.web.app/invite?ref=${user.uid}";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final shareText = 'Join Tanishuv 🔥\nUnlock anonymous chat:\n$link';
                            final box = context.findRenderObject();
                            if (box is RenderBox) {
                              await Share.share(
                                shareText,
                                subject: 'Tanishuv Invite',
                                sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
                              );
                            } else {
                              await Share.share(shareText, subject: 'Tanishuv Invite');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.share, size: 24),
                          label: const Text('Share Invite Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: link));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                icon: const Icon(Icons.copy, color: Colors.white),
                                label: const Text('Copy Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => launchUrl(Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(link)}')),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.blueAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                icon: const Icon(Icons.telegram, color: Colors.blueAccent),
                                label: const Text('Telegram', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                const Text(
                  'Note: We verify your invites to prevent spam device registrations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Invited Friends',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Provider.of<DatabaseService>(context, listen: false).getInvitedUsersStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No friends invited yet.\\nShare your link to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }
                    
                    final friends = snapshot.data!;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friends.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final joinedAt = friend['joinedAt']?.toDate() ?? DateTime.now();
                          final formattedDate = '${joinedAt.day}/${joinedAt.month}/${joinedAt.year}';
                          
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white10,
                              child: Icon(Icons.person, color: Colors.pinkAccent),
                            ),
                            title: Text(
                              friend['name'] ?? 'User',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Joined $formattedDate',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMilestone(int requiredCredits, String title, bool unlocked) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: unlocked ? Colors.green.withOpacity(0.2) : Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(color: unlocked ? Colors.green : Colors.transparent),
          ),
          child: Center(
            child: unlocked 
                ? const Icon(Icons.check, color: Colors.green)
                : Text('$requiredCredits', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (unlocked)
          const Text('UNLOCKED', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
