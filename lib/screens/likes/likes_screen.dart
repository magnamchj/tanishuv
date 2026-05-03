import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../settings/invite_progress_screen.dart';
import '../../theme/app_theme.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ),
      body: StreamBuilder<UserModel?>(
        stream: authService.currentUserModelStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          Widget content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 16),
                const Text('No likes yet.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Keep swiping to get more likes!', style: TextStyle(color: Colors.white38)),
              ],
            ),
          );

          if (!user.canSeeLikes) {
            final needed = 3 - user.inviteCredits;
            return Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: IgnorePointer(child: content),
                ),
                Container(color: Colors.black.withOpacity(0.4)),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 64, color: Colors.white70),
                        const SizedBox(height: 16),
                        const Text('Hidden Likes', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'Invite $needed more friend${needed == 1 ? '' : 's'} to unlock your likes permanently!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          label: const Text('Invite Friends'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteProgressScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return content;
        },
      ),
    );
  }
}
