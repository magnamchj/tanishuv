import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/db_service.dart';
import '../../models/story_model.dart';
import '../../theme/app_theme.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories',
            style: TextStyle(
                color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppTheme.primaryColor),
            onPressed: () => _showAddStorySheet(context, dbService, currentUserId),
          ),
        ],
      ),
      body: StreamBuilder<List<StoryModel>>(
        stream: dbService.getStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = snapshot.data!;
          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories,
                      size: 80, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No stories yet',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Be the first to share!',
                      style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStorySheet(
                        context, dbService, currentUserId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Story'),
                  ),
                ],
              ),
            );
          }

          // Group stories by user
          final Map<String, List<StoryModel>> byUser = {};
          for (final story in stories) {
            byUser.putIfAbsent(story.userId, () => []).add(story);
          }
          final users = byUser.keys.toList();

          return Column(
            children: [
              // Stories carousel (top horizontal row)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final userStories = byUser[users[i]]!;
                    final first = userStories.first;
                    final isMe = first.userId == currentUserId;
                    return GestureDetector(
                      onTap: () => _openStoryViewer(
                          context, userStories, currentUserId, dbService),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isMe
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                border: isMe
                                    ? Border.all(
                                        color: Colors.white24, width: 2)
                                    : null,
                                color: isMe ? AppTheme.surfaceColor : null,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: first.userPhotoUrl.isNotEmpty
                                    ? Image.network(first.userPhotoUrl,
                                        fit: BoxFit.cover)
                                    : Container(
                                        color: AppTheme.surfaceColor,
                                        child: const Icon(Icons.person,
                                            color: Colors.white54),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isMe ? 'You' : first.userName.split(' ').first,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Divider
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              // Stories grid feed
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    final isLiked = story.likes.contains(currentUserId);
                    return GestureDetector(
                      onTap: () => _openStoryViewer(
                          context,
                          byUser[story.userId]!,
                          currentUserId,
                          dbService),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.surfaceColor,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background
                            if (story.photoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(story.photoUrl!,
                                    fit: BoxFit.cover),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.6),
                                      AppTheme.secondaryColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Content
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (story.text.isNotEmpty)
                                    Text(
                                      story.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppTheme.surfaceColor,
                                        backgroundImage: story.userPhotoUrl
                                                .isNotEmpty
                                            ? NetworkImage(story.userPhotoUrl)
                                            : null,
                                        child: story.userPhotoUrl.isEmpty
                                            ? const Icon(Icons.person,
                                                size: 12)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          story.userName,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Like button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => dbService.toggleStoryLike(
                                    story.id, currentUserId),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black38,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? AppTheme.primaryColor
                                            : Colors.white,
                                        size: 16,
                                      ),
                                      if (story.likes.isNotEmpty) ...[
                                        const SizedBox(width: 3),
                                        Text(
                                          '${story.likes.length}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openStoryViewer(
    BuildContext context,
    List<StoryModel> stories,
    String currentUserId,
    DatabaseService dbService,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: stories,
          currentUserId: currentUserId,
          dbService: dbService,
        ),
      ),
    );
  }

  void _showAddStorySheet(
      BuildContext context, DatabaseService dbService, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddStorySheet(
        dbService: dbService,
        currentUserId: currentUserId,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Story Viewer
// ─────────────────────────────────────────────
class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final String currentUserId;
  final DatabaseService dbService;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.currentUserId,
    required this.dbService,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _timer;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_index < widget.stories.length - 1) {
            setState(() => _index++);
            _timer.reset();
            _timer.forward();
          } else {
            Navigator.pop(context);
          }
        }
      });
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (d) => _timer.stop(),
        onTapUp: (d) => _timer.forward(),
        onTapCancel: () => _timer.forward(),
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity! < 0 &&
              _index < widget.stories.length - 1) {
            setState(() => _index++);
            _timer.reset();
            _timer.forward();
          } else if (d.primaryVelocity! > 0 && _index > 0) {
            setState(() => _index--);
            _timer.reset();
            _timer.forward();
          } else if (d.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (story.photoUrl != null)
              Image.network(story.photoUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
            // Progress bars
            Positioned(
              top: 48,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: i < _index
                          ? Container(color: Colors.white)
                          : i == _index
                              ? AnimatedBuilder(
                                  animation: _timer,
                                  builder: (_, __) => FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _timer.value,
                                    child: Container(
                                        color: Colors.white),
                                  ),
                                )
                              : null,
                    ),
                  );
                }),
              ),
            ),
            // User info top
            Positioned(
              top: 60,
              left: 16,
              right: 48,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.surfaceColor,
                    backgroundImage: story.userPhotoUrl.isNotEmpty
                        ? NetworkImage(story.userPhotoUrl)
                        : null,
                    child: story.userPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white54)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(
                        _timeAgo(story.timestamp),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close button
            Positioned(
              top: 52,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Story text
            if (story.text.isNotEmpty)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    story.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // Like button bottom
            Positioned(
              bottom: 48,
              right: 24,
              child: GestureDetector(
                onTap: () => widget.dbService
                    .toggleStoryLike(story.id, widget.currentUserId),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: Icon(
                    story.likes.contains(widget.currentUserId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: story.likes.contains(widget.currentUserId)
                        ? AppTheme.primaryColor
                        : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─────────────────────────────────────────────
// Add Story Bottom Sheet
// ─────────────────────────────────────────────
class AddStorySheet extends StatefulWidget {
  final DatabaseService dbService;
  final String currentUserId;

  const AddStorySheet({
    super.key,
    required this.dbService,
    required this.currentUserId,
  });

  @override
  State<AddStorySheet> createState() => _AddStorySheetState();
}

class _AddStorySheetState extends State<AddStorySheet> {
  final _textController = TextEditingController();
  File? _image;
  bool _posting = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _post() async {
    if (_textController.text.isEmpty && _image == null) return;
    setState(() => _posting = true);

    String? photoUrl;
    if (_image != null) {
      final ref = FirebaseStorage.instanceFor(bucket: 'tanishuv-667dd.appspot.com')
          .ref()
          .child('stories/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_image!);
      photoUrl = await ref.getDownloadURL();
    }

    await widget.dbService.postStory(
      userId: widget.currentUserId,
      userName: 'Me',
      userPhotoUrl: '',
      text: _textController.text.trim(),
      photoUrl: photoUrl,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Story',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover))
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.white38),
                            SizedBox(height: 8),
                            Text('Add photo (optional)',
                                style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 3,
              maxLength: 150,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _posting ? null : _post,
              child: _posting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Share Story'),
            ),
          ],
        ),
      ),
    );
  }
}
