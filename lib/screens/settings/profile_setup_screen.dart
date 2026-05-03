import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/db_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _bioController = TextEditingController();
  int _currentStep = 0;
  File? _photo;
  String _photoUrl = '';
  bool _uploading = false;
  final List<String> _selectedInterests = [];

  static const List<String> _allInterests = [
    '🎵 Music', '🎬 Movies', '📚 Books', '🏋️ Fitness', '✈️ Travel',
    '🍔 Food', '🎮 Gaming', '🎨 Art', '💃 Dancing', '🏊 Swimming',
    '📸 Photography', '🌿 Nature', '💻 Tech', '⚽ Football', '🎭 Theatre',
    '☕ Coffee', '🐾 Pets', '🧘 Yoga', '🚴 Cycling', '🎸 Guitar',
  ];

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      setState(() {
        _photo = File(picked.path);
      });
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_photo == null) return null;
    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instanceFor(bucket: 'tanishuv-667dd.appspot.com')
          .ref()
          .child('profile_photos/$uid.jpg');
      await ref.putFile(_photo!);
      final url = await ref.getDownloadURL();
      setState(() => _uploading = false);
      return url;
    } catch (e) {
      setState(() => _uploading = false);
      return null;
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _uploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    String? uploadedUrl = await _uploadPhoto(uid);
    if (uploadedUrl != null) _photoUrl = uploadedUrl;

    final existingData = await Provider.of<dynamic>(context, listen: false);

    await dbService.updateUserProfile(UserModel(
      uid: uid,
      name: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
      nickname: FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'user',
      photoUrl: _photoUrl,
      age: 22,
      gender: 'Unknown',
      interests: _selectedInterests,
      isAnonymous: false,
      
      bio: _bioController.text.trim(),
    ));

    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile',
            style: TextStyle(color: AppTheme.primaryColor)),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildInterestsStep();
      case 2:
        return _buildBioStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhotoStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step indicator
          _buildStepIndicator(0),
          const SizedBox(height: 32),
          const Text(
            'Add Your Best Photo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profiles with photos get 5x more matches',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor,
                border: Border.all(color: AppTheme.primaryColor, width: 3),
              ),
              child: _photo != null
                  ? ClipOval(
                      child: Image.file(_photo!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo,
                            size: 48, color: AppTheme.primaryColor),
                        SizedBox(height: 8),
                        Text('Tap to add',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54)),
            child: Text(_photo != null ? 'Continue →' : 'Skip for now →'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(1),
          const SizedBox(height: 32),
          const Text('Your Interests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Select at least 3 that match you',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allInterests.map((interest) {
                  final selected = _selectedInterests.contains(interest);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedInterests.remove(interest);
                        } else {
                          _selectedInterests.add(interest);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          color:
                              selected ? Colors.white : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedInterests.length >= 3
                ? () => setState(() => _currentStep = 2)
                : null,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54)),
            child: Text('Continue (${_selectedInterests.length} selected) →'),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(2),
          const SizedBox(height: 32),
          const Text('About You',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Write a short bio (optional)',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          TextField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 200,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'E.g. "Music lover, coffee addict, and avid traveler..."',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _uploading ? null : _completeSetup,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54)),
            child: _uploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Complete Setup 🎉',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activeStep == i ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: i <= activeStep ? AppTheme.primaryColor : Colors.white24,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
