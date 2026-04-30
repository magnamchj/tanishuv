import 'dart:io';
import 'package:flutter/material.dart';
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
  List<String> _photoUrls = []; // Existing remote URLs
  List<File> _newPhotos = [];   // Newly added local files pointing natively

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

    final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(uid).get();
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
        final ref = FirebaseStorage.instanceFor(bucket: 'tanishuv-667dd.appspot.com').ref().child('user_photos/$uid/new_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(_newPhotos[i]);
        finalUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(uid).update({
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
      return const Scaffold(backgroundColor: AppTheme.backgroundColor, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // room for floating button
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionPhotos(),
              const Divider(color: Colors.white12, height: 40),
              _buildSectionBasic(),
              const Divider(color: Colors.white12, height: 40),
              _buildSectionDetails(),
              const Divider(color: Colors.white12, height: 40),
              _buildSectionInterests(),
            ]
          )
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isSaving
          ? const CircularProgressIndicator(color: AppTheme.primaryColor)
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'Save Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildSectionPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Photos'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Drag to reorder photos. Max 6.', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
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
                      feedback: Transform.scale(
                        scale: 1.1,
                        child: _buildDraggablePhoto(index, isNetwork, true),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: _buildDraggablePhoto(index, isNetwork, false)),
                      child: _buildDraggablePhoto(index, isNetwork, false),
                    );
                  } else if (index == totalLength) {
                     return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), style: BorderStyle.solid),
                          ),
                          child: const Center(child: Icon(Icons.add, size: 40, color: AppTheme.primaryColor)),
                        ),
                     );
                  } else {
                     return Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                     );
                  }
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildDraggablePhoto(int index, bool isNetwork, bool isDragging) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isNetwork 
            ? Image.network(_photoUrls[index], fit: BoxFit.cover)
            : Image.file(_newPhotos[index - _photoUrls.length], fit: BoxFit.cover),
        ),
        if (!isDragging)
          Positioned(
            bottom: -5, right: -5,
            child: IconButton(
              icon: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: const Icon(Icons.cancel, color: AppTheme.primaryColor, size: 24)),
              onPressed: () {
                setState(() {
                   if (isNetwork) _photoUrls.removeAt(index);
                   else _newPhotos.removeAt(index - _photoUrls.length);
                });
              },
            ),
          )
      ],
    );
  }

  Widget _buildSectionBasic() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionHeader('Basic Info'),
           const SizedBox(height: 12),
           TextFormField(
             controller: _nameCtrl,
             style: const TextStyle(color: Colors.white),
             decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
             validator: (v) => v!.isEmpty ? 'Name required' : null,
           ),
           const SizedBox(height: 20),
           TextFormField(
             controller: _bioCtrl,
             style: const TextStyle(color: Colors.white),
             maxLines: 4,
             maxLength: 300,
             decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
           ),
        ],
      ),
    );
  }

  Widget _buildSectionDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionHeader('Details'),
           const SizedBox(height: 12),
           TextFormField(
             controller: _cityCtrl,
             style: const TextStyle(color: Colors.white),
             decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
           ),
           const SizedBox(height: 20),
           TextFormField(
             controller: _heightCtrl,
             style: const TextStyle(color: Colors.white),
             keyboardType: TextInputType.number,
             decoration: const InputDecoration(labelText: 'Height (cm) - optional', border: OutlineInputBorder()),
           ),
           const SizedBox(height: 20),
           TextFormField(
             controller: _languagesCtrl,
             style: const TextStyle(color: Colors.white),
             decoration: const InputDecoration(labelText: 'Languages (comma separated)', border: OutlineInputBorder()),
           ),
           const SizedBox(height: 24),
           DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Looking For', border: OutlineInputBorder()),
              value: _lookingFor,
              items: ['Men', 'Women', 'Everyone'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _lookingFor = v),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Relationship Goal', border: OutlineInputBorder()),
              value: _relationshipGoal,
              items: ['Serious relationship', 'Friendship', 'Dating', 'Not sure yet']
                .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _relationshipGoal = v),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionInterests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildSectionHeader('Interests'),
           const SizedBox(height: 12),
           Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableInterests.map((interest) {
              final isSelected = _interests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) _interests.remove(interest);
                    else _interests.add(interest);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white12,
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.white24),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      )
    );
  }

}
