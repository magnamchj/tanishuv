import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import 'home/main_layout.dart';
import 'auth/login_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _checkingOnboarding = true;
  bool _showingOnboarding = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  // Track which users we've already processed referrals for (avoid re-processing on rebuilds)
  final Set<String> _processedReferralUsers = {};

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Cold-start: app opened via a link while not running
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (e) {
      debugPrint('[DEEPLINK] Error getting initial link: $e');
    }

    // Warm/foreground: app already running when link is tapped
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (e) => debugPrint('[DEEPLINK] Stream error: $e'),
    );
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('[DEEPLINK] Received: $uri');
    if (uri.path.contains('/invite') || uri.toString().contains('/invite')) {
      final code = uri.queryParameters['ref'];
      if (code != null && code.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_referral', code);
        debugPrint('[DEEPLINK] ✓ Stored pending_referral=$code');
      }
    }
  }

  /// Called ONCE after auth completes and Firestore doc exists.
  /// Reads the pending referral from SharedPreferences and processes it.
  Future<void> _processPendingReferral(String userId) async {
    // Avoid processing multiple times for the same user in the same session
    if (_processedReferralUsers.contains(userId)) return;
    _processedReferralUsers.add(userId);

    final prefs = await SharedPreferences.getInstance();
    final pendingRef = prefs.getString('pending_referral');
    
    debugPrint('[REFERRAL] Checking pending referral for user $userId: pending_referral=$pendingRef');

    if (pendingRef == null || pendingRef.isEmpty) {
      debugPrint('[REFERRAL] No pending referral found');
      return;
    }

    // Process the referral
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final success = await dbService.processReferralRegistration(pendingRef, userId);
    debugPrint('[REFERRAL] Processing result: ${success ? "SUCCESS" : "FAILED/BLOCKED"}');

    // Clear after processing attempt to ensure state isn't lost if the app was killed during processing or auth flow
    await prefs.remove('pending_referral');
    debugPrint('[REFERRAL] Cleared pending_referral from prefs');
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
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
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                // Post-auth tasks: FCM token + referral processing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<NotificationService>(context, listen: false).saveTokenToFirestore(user.uid);
                  _processPendingReferral(user.uid);
                });
                
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
