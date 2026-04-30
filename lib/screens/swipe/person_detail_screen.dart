import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../settings/fullscreen_image_viewer.dart';

class PersonDetailScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;

  const PersonDetailScreen({
    super.key,
    required this.user,
    required this.onLike,
    required this.onPass,
    required this.onSuperLike,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(widget.user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderInfo(widget.user),
                  const SizedBox(height: 32),
                  if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                    const Text('About', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.user.bio!, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                    const SizedBox(height: 32),
                  ],
                  if (widget.user.interests.isNotEmpty) ...[
                    const Text('Interests', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildInterestsWrap(widget.user.interests),
                    const SizedBox(height: 32),
                  ],
                  _buildDetailsCard(widget.user),
                  const SizedBox(height: 120), // Padding for buttons
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildActionButtons(),
    );
  }

  Widget _buildSliverAppBar(UserModel user) {
    final photos = user.photos.isNotEmpty ? user.photos : [user.photoUrl];

    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, size: 36, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenImageViewer(
                      imageUrls: photos,
                      initialIndex: _currentPhotoIndex,
                    ),
                  ),
                );
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
                itemBuilder: (context, index) {
                   final url = photos[index];
                   return Hero(
                     tag: 'person_image_$index',
                     child: url.isNotEmpty 
                         ? Image.network(url, fit: BoxFit.cover)
                         : Container(color: AppTheme.surfaceColor, child: const Icon(Icons.person, size: 100, color: Colors.white24)),
                   );
                },
              ),
            ),
            // Gradient Overlay
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 150,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppTheme.backgroundColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 60, right: 16, // Offset for back button
                child: Row(
                  children: List.generate(photos.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _currentPhotoIndex == index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${user.age}',
              style: const TextStyle(fontSize: 28, color: Colors.white70),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Colors.blueAccent, size: 28),
            ]
          ],
        ),
        const SizedBox(height: 8),
        if (user.city != null && user.city!.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(user.city!, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          )
      ],
    );
  }

  Widget _buildInterestsWrap(List<String> interests) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            interest,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailsCard(UserModel user) {
    if (user.languages.isEmpty && user.height == null && (user.relationshipGoal == null || user.relationshipGoal!.isEmpty)) {
      return const SizedBox();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (user.height != null)
            _buildDetailRow(Icons.height, 'Height', '${user.height} cm'),
          if (user.relationshipGoal != null && user.relationshipGoal!.isNotEmpty) ...[
            if (user.height != null) const Divider(color: Colors.white12, height: 24),
            _buildDetailRow(Icons.favorite_border, 'Looking for', user.relationshipGoal!),
          ],
          if (user.languages.isNotEmpty) ...[
            if (user.height != null || (user.relationshipGoal != null && user.relationshipGoal!.isNotEmpty))
              const Divider(color: Colors.white12, height: 24),
            _buildDetailRow(Icons.language, 'Languages', user.languages.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 12),
        Text('$title:', style: const TextStyle(color: Colors.white54, fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: Icons.close,
            color: Colors.redAccent,
            size: 64,
            onTap: () {
              widget.onPass();
              Navigator.pop(context);
            },
          ),
          _actionButton(
            icon: Icons.star,
            color: Colors.blue,
            size: 52,
            onTap: () {
              widget.onSuperLike();
              Navigator.pop(context);
            },
          ),
          _actionButton(
            icon: Icons.favorite,
            color: AppTheme.primaryColor,
            size: 64,
            onTap: () {
              widget.onLike();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required double size, required VoidCallback onTap}) {
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
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
