import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late UserModel _user;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _languagesCtrl;

  String? _lookingFor;
  String? _relationshipGoal;
  List<String> _interests = [];
  List<String> _photoUrls = [];
  List<File> _newPhotos = [];

  final List<String> availableInterests = [
    'Photography', 'Traveling', 'Music', 'Fitness', 'Food', 'Gaming',
    'Art', 'Reading', 'Movies', 'Nature', 'Technology', 'Sports'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv')
        .collection('users').doc(uid).get();
    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!, doc.id);

      _nameCtrl = TextEditingController(text: _user.name);
      _bioCtrl = TextEditingController(text: _user.bio ?? '');
      _cityCtrl = TextEditingController(text: _user.city ?? '');
      _heightCtrl = TextEditingController(text: _user.height?.toString() ?? '');
      _languagesCtrl = TextEditingController(text: _user.languages.join(', '));

      _lookingFor = _user.lookingFor;
      _relationshipGoal = _user.relationshipGoal;
      _interests = List.from(_user.interests);
      _photoUrls = List.from(_user.photos);

      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if ((_photoUrls.length + _newPhotos.length) >= 6) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _newPhotos.add(File(pickedFile.path)));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if ((_photoUrls.length + _newPhotos.length) < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 1 photo is required.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      List<String> finalUrls = List.from(_photoUrls);
      for (int i = 0; i < _newPhotos.length; i++) {
        final ref = FirebaseStorage.instanceFor(bucket: 'tanishuv-667dd.appspot.com')
            .ref().child('user_photos/$uid/new_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(_newPhotos[i]);
        finalUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv')
          .collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'height': double.tryParse(_heightCtrl.text.trim()),
        'languages': _languagesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'lookingFor': _lookingFor,
        'relationshipGoal': _relationshipGoal,
        'interests': _interests,
        'photos': finalUrls,
        'photoUrl': finalUrls.isNotEmpty ? finalUrls.first : '',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.backgroundColor.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              leading: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
                      : Text('Save', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 70,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionLabel('PHOTOS'),
              _buildPhotosGrid(),
              const SizedBox(height: 28),

              _buildSectionLabel('ABOUT YOU'),
              _buildGroupedCard([
                _buildTextField(_nameCtrl, 'Name', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Name required' : null),
                _buildDivider(),
                _buildTextField(_bioCtrl, 'Bio', Icons.edit_outlined, maxLines: 4, maxLength: 300),
                _buildDivider(),
                _buildTextField(_cityCtrl, 'City', Icons.location_on_outlined),
              ]),
              const SizedBox(height: 28),

              _buildSectionLabel('DETAILS'),
              _buildGroupedCard([
                _buildTextField(_heightCtrl, 'Height (cm)', Icons.height, keyboardType: TextInputType.number),
                _buildDivider(),
                _buildTextField(_languagesCtrl, 'Languages (comma separated)', Icons.language),
                _buildDivider(),
                _buildDropdown(
                  label: 'Looking for',
                  icon: Icons.search_rounded,
                  value: _lookingFor,
                  items: ['Men', 'Women', 'Everyone'],
                  onChanged: (v) => setState(() => _lookingFor = v),
                ),
                _buildDivider(),
                _buildDropdown(
                  label: 'Relationship goal',
                  icon: Icons.favorite_border_rounded,
                  value: _relationshipGoal,
                  items: ['Serious relationship', 'Friendship', 'Dating', 'Not sure yet'],
                  onChanged: (v) => setState(() => _relationshipGoal = v),
                ),
              ]),
              const SizedBox(height: 28),

              _buildSectionLabel('INTERESTS'),
              _buildInterestsCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, right: 24),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.08), indent: 56);

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int? maxLines,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: maxLines ?? 1,
              maxLength: maxLength,
              keyboardType: keyboardType,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
                counterStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              dropdownColor: AppTheme.surfaceColor,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return DragTarget<int>(
            onAcceptWithDetails: (details) {
              setState(() {
                final totalContent = [..._photoUrls, ..._newPhotos];
                final oldIndex = details.data;
                if (oldIndex < totalContent.length) {
                  final item = totalContent.removeAt(oldIndex);
                  final finalIndex = index < totalContent.length ? index : totalContent.length;
                  totalContent.insert(finalIndex, item);
                  _photoUrls = totalContent.whereType<String>().toList();
                  _newPhotos = totalContent.whereType<File>().toList();
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              final totalLength = _photoUrls.length + _newPhotos.length;

              if (index < totalLength) {
                final isNetwork = index < _photoUrls.length;
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Transform.scale(scale: 1.1, child: _buildPhotoTile(index, isNetwork, true)),
                  childWhenDragging: Opacity(opacity: 0.3, child: _buildPhotoTile(index, isNetwork, false)),
                  child: _buildPhotoTile(index, isNetwork, false),
                );
              } else if (index == totalLength) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppTheme.primaryColor.withOpacity(0.8)),
                    ),
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPhotoTile(int index, bool isNetwork, bool isDragging) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: isNetwork
              ? Image.network(_photoUrls[index], fit: BoxFit.cover)
              : Image.file(_newPhotos[index - _photoUrls.length], fit: BoxFit.cover),
        ),
        if (!isDragging)
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => setState(() {
                if (isNetwork) _photoUrls.removeAt(index);
                else _newPhotos.removeAt(index - _photoUrls.length);
              }),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        if (index == 0)
          Positioned(
            bottom: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  Widget _buildInterestsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: availableInterests.map((interest) {
          final isSelected = _interests.contains(interest);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) _interests.remove(interest);
                else _interests.add(interest);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.12),
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                interest,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
