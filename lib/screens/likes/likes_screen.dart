import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ),
      body: Center(
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
      ),
    );
  }
}
