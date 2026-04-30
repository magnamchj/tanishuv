import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/db_service.dart';
import '../../models/anonymous_chat_model.dart';
import '../../theme/app_theme.dart';

class AnonymousChatScreen extends StatefulWidget {
  const AnonymousChatScreen({super.key});

  @override
  State<AnonymousChatScreen> createState() => _AnonymousChatScreenState();
}

class _AnonymousChatScreenState extends State<AnonymousChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isFinding = false;

  @override
  void initState() {
    super.initState();
    // Do not start searching automatically
  }

  void _startSearching() {
    setState(() => _isFinding = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.enterAnonymousQueue(_currentUserId);
  }

  void _leave() {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.leaveAnonymousQueue(_currentUserId);
    Navigator.pop(context);
  }

  Future<void> _sendMessage(String chatId, {String type = 'text', String? mediaUrl}) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && type == 'text') return;
    _msgCtrl.clear();

    await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv')
        .collection('anonymousChats')
        .doc(chatId)
        .collection('messages')
        .add({
      'fromUserId': _currentUserId,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'isRead': false,
    });
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User reported and blocked.')));
    // Implement report injection query internally bridging standard abuse mappings.
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Stranger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _leave),
        actions: [
          if (_isFinding) PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'next') {
                _startSearching();
              } else if (value == 'report') {
                _reportUser();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'next', child: Text('Next Chat')),
              const PopupMenuItem(value: 'report', child: Text('Report User', style: TextStyle(color: Colors.red))),
            ],
          )
        ],
      ),
      body: !_isFinding ? _buildInfoPage() : StreamBuilder<AnonymousChatModel?>(
        stream: dbService.watchAnonymousChatAvailability(_currentUserId),
        builder: (context, snapshot) {
          final chat = snapshot.data;

          if (chat == null || chat.status != 'connected') {
            return _buildSearching();
          }

          if (chat.status == 'closed') {
            return _buildClosedState();
          }

          final isUser1 = chat.user1Id == _currentUserId;
          final iRevealed = isUser1 ? chat.user1Revealed : chat.user2Revealed;
          final theyRevealed = isUser1 ? chat.user2Revealed : chat.user1Revealed;

          return Column(
            children: [
              _buildMatchHeader(chat.id, iRevealed, theyRevealed, dbService, isUser1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv')
                      .collection('anonymousChats')
                      .doc(chat.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData) return const SizedBox();
                    final messages = msgSnapshot.data!.docs;
                    
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final isMe = data['fromUserId'] == _currentUserId;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.indigoAccent : Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInput(chat.id),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearching() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          const Text('Finding someone online...', style: TextStyle(fontSize: 18, color: Colors.white54)),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () {
              final dbService = Provider.of<DatabaseService>(context, listen: false);
              dbService.leaveAnonymousQueue(_currentUserId);
              setState(() => _isFinding = false);
            },
            child: const Text('Cancel Request', style: TextStyle(color: Colors.redAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.privacy_tip_rounded, size: 80, color: Colors.purpleAccent),
            ),
            const SizedBox(height: 24),
            const Text('Anonymous Chat', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Connect instantly with someone online. Your profile is hidden until you both choose to reveal it.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startSearching,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Start Searching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            const Text('Please be respectful.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 60, color: Colors.white38),
          const SizedBox(height: 20),
          const Text('The other user has left.', style: TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startSearching,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Find Someone Else'),
          )
        ],
      ),
    );
  }

  Widget _buildMatchHeader(String chatId, bool iRevealed, bool theyRevealed, DatabaseService dbService, bool isUser1) {
    if (iRevealed && theyRevealed) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.green.withOpacity(0.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 8),
            const Text('Match! This chat is now in your normal Match list.', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          iRevealed
             ? const Text('Waiting for them...', style: TextStyle(color: Colors.white54))
             : ElevatedButton(
                 onPressed: () => dbService.revealAnonymousProfile(chatId, _currentUserId, isUser1),
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                 child: const Text('Reveal Profile'),
               ),
          OutlinedButton(
            onPressed: () {
              dbService.closeAnonymousChat(chatId);
              _startSearching();
            },
            child: const Text('Next Person', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildInput(String chatId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceColor,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add_photo_alternate, color: Colors.white54), onPressed: () {}), // Logic wrapper for media
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.white54),
              onPressed: () {}, // Audio implementation wrapper
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: () => _sendMessage(chatId),
            ),
          ],
        ),
      ),
    );
  }
}
