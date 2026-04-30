import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/db_service.dart';
import '../../services/match_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import 'person_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  UserModel? _currentUserModel;
  String? _genderFilter;
  int _minAge = 18;
  int _maxAge = 50;

  // Match overlay
  bool _showMatchOverlay = false;
  UserModel? _matchedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    setState(() => _isLoading = true);

    if (_currentUserModel == null) {
      final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(currentUserId).get();
      if (doc.exists) {
        _currentUserModel = UserModel.fromMap(doc.data()!, doc.id);
      }
    }

    if (_currentUserModel != null) {
      // Load from discover with scoring
      final users = await dbService.getDiscoverUsersScored(
        currentUserId,
        _currentUserModel!,
        genderFilter: _genderFilter,
        minAgeFilter: _minAge,
        maxAgeFilter: _maxAge,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (previousIndex >= _users.length) return false;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetUser = _users[previousIndex];
    final matchService = Provider.of<MatchService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final bool isLike = direction == CardSwiperDirection.right ||
        direction == CardSwiperDirection.top;

    if (isLike && _currentUserModel != null) {
      final hasQuota = await dbService.canSwipe(currentUserId, _currentUserModel!.isPremium);
      if (!hasQuota) {
        if (mounted) _showLimitDialog();
        return false;
      }
    }

    dbService.incrementSwipeCount(currentUserId);

    final isMatch = await matchService.recordSwipe(currentUserId, targetUser.uid, isLike);
    
    if (isMatch && mounted) {
      setState(() {
        _matchedUser = targetUser;
        _showMatchOverlay = true;
      });
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tanishuv',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white70),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? _buildEmpty()
                  : _buildSwiperBody(),
          // Match overlay
          if (_showMatchOverlay && _matchedUser != null)
            _buildMatchOverlay(),
        ],
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('🌟 Limit Reached'),
        content: const Text(
          'Daily like limit reached. Upgrade to Premium for unlimited swipes!',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ignore')),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               // Navigate to Premium
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Upgrade'),
          )
        ],
      )
    );
  }

  Widget _buildSwiperBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: _users.length,
                onSwipe: _onSwipe,
                numberOfCardsDisplayed: _users.length > 2 ? 3 : _users.length,
                backCardOffset: const Offset(0, 30),
                padding: const EdgeInsets.all(4.0),
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                  return _buildCard(_users[index], percentThresholdX.toDouble());
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(UserModel user, double swipePercent) {
    final isLiking = swipePercent > 0.2;
    final isDisliking = swipePercent < -0.2;

    return GestureDetector(
      onTap: () {
         final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
         Provider.of<DatabaseService>(context, listen: false).markProfileSeen(currentUserId, user.uid);
         
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => PersonDetailScreen(
               user: user,
               onLike: () => controller.swipe(CardSwiperDirection.right),
               onPass: () => controller.swipe(CardSwiperDirection.left),
               onSuperLike: () => controller.swipe(CardSwiperDirection.top),
             ),
           ),
         );
      },
      child: Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            user.photoUrl.isNotEmpty
                ? Image.network(user.photoUrl, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.surfaceColor, Color(0xFF3A1C71)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        size: 100, color: Colors.white30),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Like / Nope labels
            if (isLiking)
              Positioned(
                top: 40,
                left: 20,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIKE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (isDisliking)
              Positioned(
                top: 40,
                right: 20,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NOPE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // Info bottom
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age.toDouble().toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified,
                            color: Colors.blueAccent, size: 24),
                      ],
                      if (user.isPremium) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.workspace_premium,
                            color: Colors.amber, size: 22),
                      ],
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (user.interests.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.interests.take(4).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.close,
          color: Colors.redAccent,
          size: 52,
          onTap: () => controller.swipe(CardSwiperDirection.left),
        ),
        _actionButton(
          icon: Icons.star,
          color: Colors.blue,
          size: 44,
          onTap: () => controller.swipe(CardSwiperDirection.top),
        ),
        _actionButton(
          icon: Icons.favorite,
          color: AppTheme.primaryColor,
          size: 52,
          onTap: () => controller.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  Widget _buildMatchOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showMatchOverlay = false),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                "It's a Match!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${_matchedUser?.name} liked each other!',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_matchedUser?.photoUrl.isNotEmpty == true)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primaryColor, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            NetworkImage(_matchedUser!.photoUrl),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => setState(() => _showMatchOverlay = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Send Message',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showMatchOverlay = false),
                child: const Text('Keep Swiping',
                    style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No more profiles nearby.',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later or expand your filters!',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Gender', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: ['Any', 'Man', 'Woman', 'Other'].map((g) {
                    final selected = _genderFilter == (g == 'Any' ? null : g);
                    return ChoiceChip(
                      label: Text(g),
                      selected: selected,
                      onSelected: (_) => setModalState(() {
                        _genderFilter = g == 'Any' ? null : g;
                      }),
                      selectedColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                    'Age Range: $_minAge – $_maxAge',
                    style: const TextStyle(color: Colors.white70)),
                RangeSlider(
                  values: RangeValues(
                      _minAge.toDouble(), _maxAge.toDouble()),
                  min: 18,
                  max: 60,
                  divisions: 42,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setModalState(() {
                    _minAge = v.start.toInt();
                    _maxAge = v.end.toInt();
                  }),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadUsers();
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
