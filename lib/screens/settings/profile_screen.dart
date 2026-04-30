import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../premium/subscription_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/edit_profile_screen.dart';
import '../settings/fullscreen_image_viewer.dart';
import '../admin/admin_panel_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/demo_user_seeder_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;
  int _likesReceived = 0;
  bool _isSeeding = false;
  Future<UserModel?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _fetchLikesData();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userFuture = authService.getUserData(user.uid);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchLikesData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv')
          .collection('swipes')
          .where('toUserId', isEqualTo: user.uid)
          .where('isLike', isEqualTo: true)
          .count()
          .get();
      if (mounted) setState(() => _likesReceived = snap.count ?? 0);
    }
  }

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    final service = DemoUserSeederService();
    final count = await service.seedDemoUsers();
    
    if (mounted) {
      setState(() => _isSeeding = false);
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo profiles added successfully'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo profiles already exist'), backgroundColor: Colors.orange));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          final userData = snapshot.data;
          if (userData == null) {
             return const Center(child: Text('Error loading profile', style: TextStyle(color: Colors.white)));
          }

          return CustomScrollView(
            slivers: [
              _buildModernAppBar(context, userData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderInfo(userData),
                      const SizedBox(height: 24),
                      _buildActionButtonsRow(context, userData),
                      const SizedBox(height: 32),
                      _buildGroupedCard([
                        _buildSettingsRow(Icons.favorite, 'Likes Received', '$_likesReceived', Colors.redAccent),
                        _buildDivider(),
                        _buildMatchesRow(user!.uid),
                      ]),
                      const SizedBox(height: 24),
                      if (userData.bio != null && userData.bio!.isNotEmpty) ...[
                        _buildSectionHeader('ABOUT ME'),
                        _buildGroupedCard([
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(userData.bio!, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                          )
                        ]),
                        const SizedBox(height: 24),
                      ],
                      if (userData.interests.isNotEmpty) ...[
                        _buildSectionHeader('INTERESTS'),
                        _buildGroupedCard([
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildInterestsWrap(userData.interests),
                          )
                        ]),
                        const SizedBox(height: 24),
                      ],
                      if (userData.languages.isNotEmpty || userData.height != null || (userData.relationshipGoal != null && userData.relationshipGoal!.isNotEmpty)) ...[
                         _buildSectionHeader('DETAILS'),
                         _buildModernDetailsCard(userData),
                         const SizedBox(height: 24),
                      ],
                      _buildSeedButton(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ]
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderInfo(UserModel user) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final photos = user.photos.isNotEmpty ? user.photos : [user.photoUrl];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenImageViewer(
                  imageUrls: photos,
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, Colors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0), // The stroke width of the ring
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                  border: Border.all(color: AppTheme.backgroundColor, width: 3),
                ),
                child: ClipOval(
                  child: user.photoUrl.isNotEmpty
                      ? Image.network(user.photoUrl, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '${user.age}',
              style: const TextStyle(fontSize: 26, color: Colors.white70, fontWeight: FontWeight.w400),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
            ]
          ],
        ),
        if (user.city != null && user.city!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 14),
              const SizedBox(width: 4),
              Text(
                user.city!, 
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)
              ),
            ],
          )
        ]
      ],
    );
  }

  Widget _buildActionButtonsRow(BuildContext context, UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildiOSActionButton(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => setState(() {}));
          },
        ),
        if (!user.isPremium)
          _buildiOSActionButton(
            icon: Icons.star_border_rounded,
            label: 'Premium',
            color: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
        if (user.isAdmin)
          _buildiOSActionButton(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin',
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
          ),
      ],
    );
  }

  Widget _buildiOSActionButton({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    final effectiveColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Icon(icon, color: effectiveColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.1), indent: 16);
  }

  Widget _buildSettingsRow(IconData icon, String title, String trailing, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
          Text(trailing, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
        ],
      ),
    );
  }

  Widget _buildMatchesRow(String currentUserId) {
    return StreamBuilder<List<dynamic>>(
      stream: Provider.of<ChatService>(context, listen: false).getMatches(currentUserId),
      builder: (context, snapshot) {
         final count = snapshot.data?.length ?? 0;
         return _buildSettingsRow(Icons.people_alt, 'Matches', '$count', Colors.purpleAccent);
      },
    );
  }

  Widget _buildInterestsWrap(List<String> interests) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            interest,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernDetailsCard(UserModel user) {
    List<Widget> rows = [];
    if (user.height != null) {
      rows.add(_buildDetailRow(Icons.height, 'Height', '${user.height} cm'));
    }
    if (user.relationshipGoal != null && user.relationshipGoal!.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(_buildDivider());
      rows.add(_buildDetailRow(Icons.favorite_outline, 'Looking for', user.relationshipGoal!));
    }
    if (user.languages.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(_buildDivider());
      rows.add(_buildDetailRow(Icons.language, 'Languages', user.languages.join(', ')));
    }
    
    return _buildGroupedCard(rows);
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSeedButton() {
    return GestureDetector(
      onTap: _isSeeding ? null : _seedDemoData,
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceColor,
        ),
        child: Center(
          child: _isSeeding
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Add Demo Profiles', style: TextStyle(color: Colors.blueAccent.shade200, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

