import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../theme/app_theme.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final UserModel opponentUser;
  final bool isOneMinuteMode;

  const ChatDetailScreen({super.key, required this.chatId, required this.opponentUser, this.isOneMinuteMode = false});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  bool _isTyping = false;
  bool _isRecording = false;
  bool _isUploading = false;
  MessageModel? _replyingTo;
  String? _selectedMessageId;

  late final String currentUserId;
  late final ChatService chatService;

  Timer? _countdownTimer;
  int _secondsRemaining = 60;

  final AudioRecorder _audioRecorder = AudioRecorder();
  late AnimationController _recordingPulseController;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _recordingPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    chatService = Provider.of<ChatService>(context, listen: false);

    chatService.markMessagesAsRead(widget.chatId, currentUserId);
    _messageController.addListener(_onTypingChanged);

    if (widget.isOneMinuteMode) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _showTimeUpModal();
      }
    });
  }

  void _showTimeUpModal() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'Time is up! ⏳',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Do you want to reveal your profile and continue chatting, or end it here?',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Leave chat
                },
                child: const Text('End Chat', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Turn off 1 min mode logic
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile revealed! ✨')));
                },
                child: const Text(
                  'Reveal & Continue',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ).animate().scaleXY(begin: 0.8, curve: Curves.easeOutBack),
        );
      },
    );
  }

  @override
  void dispose() {
    _recordingPulseController.dispose();
    _audioRecorder.dispose();
    _countdownTimer?.cancel();
    chatService.setTypingStatus(widget.chatId, currentUserId, false);
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTypingChanged() {
    final typing = _messageController.text.isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      chatService.setTypingStatus(widget.chatId, currentUserId, typing);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    String text = _messageController.text.trim();
    if (_replyingTo != null) {
      chatService.sendMessage(
        widget.chatId, 
        currentUserId, 
        text, 
        type: 'reply', 
        replyToId: _replyingTo!.id,
        replyToText: _replyingTo!.text,
        replyToUserId: _replyingTo!.fromUserId,
      );
    } else {
      chatService.sendMessage(widget.chatId, currentUserId, text);
    }
    _messageController.clear();
    setState(() {
      _showEmojiPicker = false;
      _replyingTo = null;
    });
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingStartTime = DateTime.now();
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
        _recordingPulseController.repeat(reverse: true);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      final duration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!).inSeconds : 0;
      setState(() => _isRecording = false);
      _recordingPulseController.stop();
      _recordingPulseController.reset();
      
      if (path != null) {
        HapticFeedback.lightImpact();

        // Start Firebase Upload
        final File file = File(path);
        final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final storageRef = FirebaseStorage.instanceFor(bucket: 'tanishuv-667dd.appspot.com')
            .ref()
            .child('chats/${widget.chatId}/$fileName');
        
        setState(() => _isUploading = true);

        try {
          await storageRef.putFile(file);
          final downloadUrl = await storageRef.getDownloadURL();
          
          chatService.sendMessage(
            widget.chatId, 
            currentUserId, 
            downloadUrl, 
            type: 'audio',
            replyToId: _replyingTo?.id,
            replyToText: _replyingTo?.text,
            replyToUserId: _replyingTo?.fromUserId,
            audioDuration: duration > 0 ? duration : 1,
          );
        } catch (e) {
          debugPrint('Error uploading audio: $e');
        }

        setState(() {
          _isUploading = false;
          _replyingTo = null;
        });
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stop(); 
      setState(() => _isRecording = false);
      _recordingPulseController.stop();
      _recordingPulseController.reset();
    } catch (e) {
      debugPrint('Error cancelling record: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(widget.isOneMinuteMode ? 70 : 60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.surfaceColor,
                        backgroundImage: widget.opponentUser.photoUrl.isNotEmpty ? NetworkImage(widget.opponentUser.photoUrl) : null,
                        child: widget.opponentUser.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                      ),
                      if (widget.isOneMinuteMode)
                        Positioned.fill(
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(color: Colors.transparent),
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
                        Text(
                          widget.isOneMinuteMode ? 'Anonymous 👀' : widget.opponentUser.name.split(' ').first,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.white),
                        ),
                        StreamBuilder<bool>(
                          stream: chatService.getTypingStatus(widget.chatId, widget.opponentUser.uid),
                          builder: (context, snap) {
                            if (snap.data == true) {
                              return const Text(
                                'typing...',
                                style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms);
                            }
                            return const Text('online', style: TextStyle(fontSize: 12, color: Colors.white54));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: widget.isOneMinuteMode
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: _secondsRemaining / 60.0),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, _) {
                          Color barColor = Colors.greenAccent;
                          if (value < 0.3)
                            barColor = Colors.redAccent;
                          else if (value < 0.6)
                            barColor = Colors.amberAccent;
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(barColor),
                            minHeight: 3,
                          );
                        },
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _selectedMessageId = null;
                });
              },
              child: StreamBuilder<List<MessageModel>>(
                stream: chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👀', style: TextStyle(fontSize: 80)).animate().scaleXY(begin: 0.5, curve: Curves.elasticOut),
                          const SizedBox(height: 16),
                          Text(
                            'Say hi to ${widget.isOneMinuteMode ? "stranger" : widget.opponentUser.name}!',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80, 
                      bottom: 80 + MediaQuery.of(context).padding.bottom + (_replyingTo != null ? 50 : 0) + (_showEmojiPicker ? 280 : 0), 
                      left: 16, 
                      right: 16
                    ),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StreamBuilder<bool>(
                          stream: chatService.getTypingStatus(widget.chatId, widget.opponentUser.uid),
                          builder: (context, snap) {
                            if (snap.data == true) {
                              return _buildTypingIndicatorBubble();
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      }
                      final message = messages[index - 1];
                      final isMe = message.fromUserId == currentUserId;
                      return _buildAnimatedMessageBubble(message, isMe, index - 1);
                    },
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingTo != null) _buildReplyBanner(),
                _buildInputArea(),
                if (_showEmojiPicker)
                  SizedBox(
                    height: 280,
                    child: EmojiPicker(textEditingController: _messageController, config: const Config()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat()).fade(duration: 600.ms, delay: (index * 200).ms);
          }),
        ),
      ),
    ).animate().slideY(begin: 1.0, curve: Curves.easeOut).fade();
  }

  Widget _buildAnimatedMessageBubble(MessageModel message, bool isMe, int index) {
    final bool isGift = message.type == 'gift';
    final bool isAudio = message.type == 'audio';
    final bool isSelected = _selectedMessageId == message.id;

    Widget bubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: () {
          HapticFeedback.lightImpact();
          chatService.addReaction(widget.chatId, message.id, '❤️');
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showLongPressMenu(message, isMe);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(top: 2, bottom: 2, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          padding: EdgeInsets.symmetric(
            horizontal: isGift ? 24 : (isAudio ? 8 : 12),
            vertical: isGift ? 20 : 8,
          ),
          decoration: BoxDecoration(
            gradient: isMe 
                ? const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.bottomLeft, end: Alignment.topRight)
                : null,
            color: isMe ? null : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: isSelected ? Border.all(color: Colors.white38, width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border(left: BorderSide(color: isMe ? Colors.white : const Color(0xFF0A84FF), width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.replyToUserId == currentUserId ? 'You' : widget.opponentUser.name,
                        style: TextStyle(color: isMe ? Colors.white : const Color(0xFF0A84FF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.type == 'audio' ? '🎵 Audio message' : message.replyToText!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              if (isAudio)
                _buildAudioMessageUI(isMe, message)
              else
                Text(
                  message.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isGift ? 40 : 15,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? const Color(0xFF8BE0FF) : Colors.white38,
                    ),
                  ],
                ],
              ),
              if (message.reactions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1621),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.reactions.toSet().join(''),
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (message.reactions.length > 1) ...[
                        const SizedBox(width: 2),
                        Text(
                          '${message.reactions.length}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ).animate().scale(curve: Curves.elasticOut),
            ],
          ),
        ),
      ),
    );

    bubble = SwipeTo(
      onRightSwipe: (details) {
        HapticFeedback.lightImpact();
        setState(() => _replyingTo = message);
      },
      child: bubble,
    );

    if (index < 10) {
      bubble = bubble.animate().slideY(begin: 0.1, delay: (index * 50).ms, curve: Curves.easeOut).fade();
    }
    return bubble;
  }


  Widget _buildAudioMessageUI(bool isMe, MessageModel message) {
    return _PlayableAudioBubble(isMe: isMe, message: message);
  }

  void _showLongPressMenu(MessageModel message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(Icons.reply_rounded, 'Reply', () {
                  setState(() => _replyingTo = message);
                  Navigator.pop(context);
                }),
                _buildMenuOption(Icons.copy_rounded, 'Copy', () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(context);
                }),
                if (isMe)
                  _buildMenuOption(Icons.delete_outline_rounded, 'Delete', () {
                    // ChatService delete logic
                    Navigator.pop(context);
                  }, color: Colors.redAccent),
                if (!isMe)
                  _buildMenuOption(Icons.report_problem_rounded, 'Report', () {
                    Navigator.pop(context);
                  }, color: Colors.orangeAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildReplyBanner() {
    final isMe = _replyingTo!.fromUserId == currentUserId;
    final name = isMe ? 'You' : widget.opponentUser.name;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
            color: const Color(0xFF17212B),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFF0A84FF), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replying to $name',
                      style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _replyingTo!.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _replyingTo = null),
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      bottom: !_showEmojiPicker,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.75),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 28),
                    onPressed: () => HapticFeedback.lightImpact(),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
                    decoration: const BoxDecoration(
                      color: Colors.transparent, 
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_isRecording)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _recordingPulseController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _recordingPulseController.value,
                                        child: const Text('●', style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  StreamBuilder(
                                    stream: Stream.periodic(const Duration(seconds: 1)),
                                    builder: (context, snapshot) {
                                      final duration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;
                                      final m = duration.inMinutes.toString().padLeft(2, '0');
                                      final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
                                      return Text('$m:$s', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  const Text('Slide to cancel', style: TextStyle(color: Colors.grey, fontSize: 15)),
                                  const Icon(Icons.chevron_left_rounded, color: Colors.grey, size: 18),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _messageController,
                          builder: (context, value, _) {
                            final hasText = value.text.trim().isNotEmpty;
                            if (!hasText) {
                              return GestureDetector(
                                onTapDown: (_) => _startRecording(),
                                onTapUp: (_) => _stopRecordingAndSend(),
                                onTapCancel: () => _cancelRecording(),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6, right: 8, top: 6),
                                  child: _isUploading
                                      ? Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                        )
                                      : AnimatedBuilder(
                                          animation: _recordingPulseController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _isRecording ? 1.0 + (_recordingPulseController.value * 0.3) : 1.0,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _isRecording ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.mic_rounded,
                                                  color: _isRecording ? Colors.redAccent : Theme.of(context).primaryColor,
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4, right: 4),
                              child: _isUploading
                                  ? Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: _sendMessage,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                                          ]
                                        ),
                                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                                      ).animate().scaleXY(begin: 0.5, curve: Curves.elasticOut),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PlayableAudioBubble extends StatefulWidget {
  final bool isMe;
  final MessageModel message;

  const _PlayableAudioBubble({required this.isMe, required this.message});

  @override
  State<_PlayableAudioBubble> createState() => _PlayableAudioBubbleState();
}

class _PlayableAudioBubbleState extends State<_PlayableAudioBubble> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animCtrl;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = const Duration(seconds: 12);
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: _duration);
    _animCtrl.addListener(() => setState(() {}));
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
          _animCtrl.reset();
          _position = Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
          _animCtrl.duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted && _isPlaying) {
        setState(() {
          _position = newPosition;
          if (_duration.inMilliseconds > 0) {
            _animCtrl.value = _position.inMilliseconds / _duration.inMilliseconds;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      String audioPath = widget.message.text;
      Source source;
      
      if (audioPath.startsWith('http')) {
        source = UrlSource(audioPath);
      } else if (audioPath.contains('/')) {
        source = DeviceFileSource(audioPath);
      } else {
        source = UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
      }
      
      await _audioPlayer.play(source);
      if (_position > Duration.zero) {
        await _audioPlayer.seek(_position);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current seconds calculation either from actual position or fallbacks
    int totalSecs = widget.message.audioDuration ?? (_duration.inSeconds > 0 ? _duration.inSeconds : 12);
    int curSecs = _position.inSeconds > 0 ? _position.inSeconds : (_animCtrl.value * totalSecs).floor();
    int remSecs = totalSecs - curSecs;
    if (remSecs < 0) remSecs = 0;
    
    final timeStr = '${(remSecs / 60).floor()}:${(remSecs % 60).toString().padLeft(2, "0")}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: widget.isMe ? Colors.white24 : AppTheme.primaryColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: widget.isMe ? Colors.white : AppTheme.primaryColor, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 38,
          width: 140,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(140, 38),
            painter: _WaveformPainter(progress: _animCtrl.value, isMe: widget.isMe),
          ),
        ),
        const SizedBox(width: 12),
        Text(timeStr, style: TextStyle(color: widget.isMe ? Colors.white70 : Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isMe;

  _WaveformPainter({required this.progress, required this.isMe});

  // Dummy amplitude values simulating a voice note
  final List<double> amplitudes = [
    0.2, 0.4, 0.3, 0.6, 0.8, 1.0, 0.7, 0.5, 0.9, 0.4, 0.3, 0.8, 0.6, 0.4, 0.2, 0.5, 0.9, 0.7, 0.4, 0.6, 0.3, 0.5, 0.8, 0.9, 0.6, 0.4, 0.2
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final spacing = 2.0;
    final totalBars = amplitudes.length;
    
    final playedPaint = Paint()
      ..color = isMe ? Colors.white : AppTheme.primaryColor
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = isMe ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);
      if (x > size.width) break;

      final amp = amplitudes[i];
      final barHeight = size.height * amp;
      final yOffset = (size.height - barHeight) / 2;
      
      final barProgress = i / totalBars;
      final paint = barProgress <= progress ? playedPaint : unplayedPaint;
      
      canvas.drawLine(Offset(x, yOffset), Offset(x, yOffset + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => oldDelegate.progress != progress;
}
