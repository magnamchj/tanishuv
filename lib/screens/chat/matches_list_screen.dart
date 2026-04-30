import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../models/match_model.dart';
import '../../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'anonymous_chat_screen.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatService = Provider.of<ChatService>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  centerTitle: false,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Chats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -1)),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => HapticFeedback.lightImpact(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.search, color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => HapticFeedback.lightImpact(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildAnonymousChatTopBanner(context),
          ),
          SliverToBoxAdapter(
            child: _buildActiveUsersRow(context, currentUserId, chatService),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            sliver: _buildMatchesList(context, currentUserId, chatService),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousChatTopBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousChatScreen()));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent.shade400.withOpacity(0.85), Colors.blueAccent.shade400.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Anonymous Chat 👀', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Connect instantly, reveal later. 🔥', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 24),
          ],
        ),
      ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
    );
  }

  Widget _buildActiveUsersRow(BuildContext context, String currentUserId, ChatService chatService) {
    return StreamBuilder<List<MatchModel>>(
      stream: chatService.getMatches(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
        final matches = snapshot.data!.take(6).toList(); // Simulate top active

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 12, top: 8),
              child: Text('ACTIVE NOW', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<UserModel?>(
                    future: chatService.getMatchedUser(matches[index].id, currentUserId),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox(width: 80);
                      final user = userSnap.data!;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: matches[index].id, opponentUser: user)));
                        },
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          // Preview profile blur could go here
                        },
                        child: Container(
                          width: 76,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.greenAccent, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: ClipOval(
                                    child: ImageFiltered(
                                      // Simulated blur if anonymous, else clear
                                      imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                      child: user.photoUrl.isNotEmpty
                                          ? Image.network(user.photoUrl, fit: BoxFit.cover)
                                          : Container(color: AppTheme.surfaceColor),
                                    ),
                                  ),
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).custom(
                                duration: 1.5.seconds,
                                builder: (context, value, child) => Transform.scale(
                                  scale: 1.0 + (value * 0.05),
                                  child: child,
                                )
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.name.split(' ').first,
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.5),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchesList(BuildContext context, String currentUserId, ChatService chatService) {
    return StreamBuilder<List<MatchModel>>(
      stream: chatService.getMatches(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No messages yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Start a 1-Min Chat to connect!', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }

        final matches = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final match = matches[index];
              return _MatchListItem(match: match, currentUserId: currentUserId, chatService: chatService, index: index);
            },
            childCount: matches.length,
          ),
        );
      },
    );
  }
}

class _MatchListItem extends StatefulWidget {
  final MatchModel match;
  final String currentUserId;
  final ChatService chatService;
  final int index;

  const _MatchListItem({required this.match, required this.currentUserId, required this.chatService, required this.index});

  @override
  State<_MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<_MatchListItem> {
  Future<UserModel?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = widget.chatService.getMatchedUser(widget.match.id, widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox();
        final matchedUser = userSnapshot.data!;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: widget.chatService.getMatchMetadata(widget.match.id),
          builder: (context, metaSnap) {
            final lastMsg = metaSnap.data?['lastMessage'] as String?;
            final int unreadCount = 0; // Fetch real unread if available
            final bool isTyping = false; // Add typing logic

            return Slidable(
              key: ValueKey(widget.match.id),
              startActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) { 
                      HapticFeedback.mediumImpact(); 
                      widget.chatService.pinMatch(widget.match.id, widget.currentUserId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat pinned')));
                    },
                    backgroundColor: Colors.blueAccent.shade700,
                    foregroundColor: Colors.white,
                    icon: Icons.push_pin_rounded,
                    label: 'Pin',
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) { 
                      HapticFeedback.mediumImpact(); 
                      widget.chatService.muteMatch(widget.match.id, widget.currentUserId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat muted')));
                    },
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    icon: Icons.notifications_off_rounded,
                    label: 'Mute',
                  ),
                  SlidableAction(
                    onPressed: (context) { 
                      HapticFeedback.heavyImpact(); 
                      widget.chatService.deleteMatch(widget.match.id, widget.currentUserId);
                    },
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                  ),
                ],
              ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(chatId: widget.match.id, opponentUser: matchedUser)
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // Telegram Style Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.surfaceColor,
                                    image: matchedUser.photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(matchedUser.photoUrl), fit: BoxFit.cover) : null,
                                  ),
                                  child: ClipOval(
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Simulated blur
                                      child: matchedUser.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54) : Container(color: Colors.transparent),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Anonymous 👀',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)
                                      ),
                                      Text('14:24', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: isTyping 
                                          ? const Text('Typing...', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500)).animate(onPlay: (c) => c.repeat(reverse: true)).fade()
                                          : Text(
                                            lastMsg ?? 'Tap to reveal and chat! 🔥', 
                                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)), 
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ),
                                      if (unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(10)),
                                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 76),
                      child: Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.08)),
                    ),
                  ],
                ),
            ).animate().fade(delay: (widget.index * 50).ms).slideX(begin: 0.1);
          },
        );
      },
    );
  }
}


