import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home/main_layout.dart';
import 'auth/login_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _checkingOnboarding = true;
  bool _showingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenOnboarding') ?? false;
    setState(() {
      _checkingOnboarding = false;
      if (!seen) _showingOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show onboarding first, before auth check
    if (_showingOnboarding) {
      return OnboardingScreen(
        onDone: () => setState(() => _showingOnboarding = false),
      );
    }

    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<NotificationService>(context, listen: false).saveTokenToFirestore(user.uid);
            });

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                final data = userSnapshot.data?.data() as Map<String, dynamic>?;
                if (data != null && data['profileCompleted'] == true) {
                   return const MainLayout();
                } else {
                   return const ProfileSetupScreen();
                }
              }
            );
          }
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
