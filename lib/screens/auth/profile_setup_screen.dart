import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../home/main_layout.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Form State
  String? _name;
  DateTime? _birthdate;
  String? _gender;
  String? _lookingFor;
  List<File> _photos = [];
  String? _bio;
  List<String> _selectedInterests = [];
  String? _city;
  double? _height;
  List<String> _languages = [];
  String? _relationshipGoal;

  final _formKeyNameBio = GlobalKey<FormState>();
  final _formKeyDetails = GlobalKey<FormState>();

  final List<String> availableInterests = [
    'Photography',
    'Traveling',
    'Music',
    'Fitness',
    'Food',
    'Gaming',
    'Art',
    'Reading',
    'Movies',
    'Nature',
    'Technology',
    'Sports',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();

    // Step Validation
    if (_currentPage == 0) {
      if (!_formKeyNameBio.currentState!.validate() || _birthdate == null) {
        _showSnack('Please fill your name and select valid birthdate.');
        return;
      }
      _formKeyNameBio.currentState!.save();
    } else if (_currentPage == 1) {
      if (_gender == null || _lookingFor == null) {
        _showSnack('Select your gender and preference.');
        return;
      }
    } else if (_currentPage == 2) {
      if (_photos.isEmpty) {
        _showSnack('Please add at least one photo.');
        return;
      }
    } else if (_currentPage == 3) {
      if (_selectedInterests.isEmpty) {
        _showSnack('Select at least one interest.');
        return;
      }
      _formKeyNameBio.currentState?.save(); // save bio
    } else if (_currentPage == 4) {
      if (!_formKeyDetails.currentState!.validate() || _relationshipGoal == null) {
        _showSnack('Please fill your details.');
        return;
      }
      _formKeyDetails.currentState!.save();
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (birthDate.month > currentDate.month || (birthDate.month == currentDate.month && birthDate.day > currentDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _pickImage() async {
    if (_photos.length >= 6) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _photos.add(File(pickedFile.path)));
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      // Upload photos sequentially
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        final ref = FirebaseStorage.instance.ref().child('user_photos/${user.uid}/photo_$i.jpg');
        await ref.putFile(_photos[i]);
        photoUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv').collection('users').doc(user.uid).update({
        'name': _name,
        'birthdate': Timestamp.fromDate(_birthdate!),
        'age': _calculateAge(_birthdate!),
        'gender': _gender,
        'lookingFor': _lookingFor,
        'bio': _bio,
        'interests': _selectedInterests,
        'city': _city,
        'height': _height,
        'languages': _languages,
        'relationshipGoal': _relationshipGoal,
        'photos': photoUrls,
        'photoUrl': photoUrls.first, // Legacy compatibility
        'profileCompleted': true,
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
      }
    } catch (e) {
      if (mounted) _showSnack('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4(), _buildStep5(), _buildPreview()],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
                  ),
                ),
              const Expanded(
                child: Text(
                  'Set up Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 6,
            color: AppTheme.primaryColor,
            backgroundColor: Colors.white12,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _isSaving
          ? const CircularProgressIndicator(color: AppTheme.primaryColor)
          : Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(28)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _currentPage == 5 ? _completeSetup : _nextPage,
                child: Text(
                  _currentPage == 5 ? 'Finish Profile' : 'Continue',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyNameBio,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What\'s your first name?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v,
            ),
            const SizedBox(height: 40),
            const Text('My birthdate is', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your age will be public.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _birthdate == null ? 'DD / MM / YYYY' : DateFormat('dd / MM / yyyy').format(_birthdate!),
                      style: TextStyle(fontSize: 18, color: _birthdate == null ? Colors.white38 : Colors.white),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('I am a', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSelectionCard('Male', _gender, (v) => setState(() => _gender = v)),
          _buildSelectionCard('Female', _gender, (v) => setState(() => _gender = v)),
          const SizedBox(height: 40),
          const Text('Show me', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSelectionCard('Men', _lookingFor, (v) => setState(() => _lookingFor = v)),
          _buildSelectionCard('Women', _lookingFor, (v) => setState(() => _lookingFor = v)),
          _buildSelectionCard('Everyone', _lookingFor, (v) => setState(() => _lookingFor = v)),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(String label, String? groupValue, Function(String) onSelect) {
    bool selected = label == groupValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(30),
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: Colors.white),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add recent photos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload at least 1 photo. Drag to reorder.', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
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
                      final item = _photos.removeAt(details.data);
                      _photos.insert(index < _photos.length ? index : _photos.length, item);
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    if (index < _photos.length) {
                      return LongPressDraggable<int>(
                        data: index,
                        feedback: Transform.scale(scale: 1.1, child: _buildPhotoBox(_photos[index], null, true)),
                        childWhenDragging: Opacity(opacity: 0.3, child: _buildPhotoBox(_photos[index], null, false)),
                        child: _buildPhotoBox(_photos[index], () {
                          setState(() => _photos.removeAt(index));
                        }, false),
                      );
                    } else if (index == _photos.length) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox(File file, VoidCallback? onRemove, bool isDragging) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        if (!isDragging && onRemove != null)
          Positioned(
            bottom: -5,
            right: -5,
            child: IconButton(
              icon: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Icon(Icons.cancel, color: AppTheme.primaryColor, size: 24),
              ),
              onPressed: onRemove,
            ),
          ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a short bio', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Form(
            key: _formKeyNameBio,
            child: TextFormField(
              initialValue: _bio,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Tell them what makes you stand out...',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                fillColor: Colors.black26,
              ),
              onSaved: (v) => _bio = v,
            ),
          ),
          const SizedBox(height: 40),
          const Text('Your Interests', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select what you are passionate about', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected)
                      _selectedInterests.remove(interest);
                    else
                      _selectedInterests.add(interest);
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Enter your city' : null,
              onSaved: (v) => _city = v,
            ),
            const SizedBox(height: 20),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Height (cm) - Optional', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onSaved: (v) => _height = v != null && v.isNotEmpty ? double.tryParse(v) : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Languages (comma separated)', hintText: 'Uzbek, English', border: OutlineInputBorder()),
              onSaved: (v) => _languages = v?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [],
              validator: (v) => v!.isEmpty ? 'Enter at least one language' : null,
            ),
            const SizedBox(height: 40),
            const Text('Relationship Goal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ['Serious relationship', 'Friendship', 'Dating', 'Not sure yet'].map((goal) {
                return _buildSelectionCard(goal, _relationshipGoal, (v) => setState(() => _relationshipGoal = v));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_photos.isEmpty) return const SizedBox();
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: const Text('Profile Preview', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppTheme.surfaceColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.file(_photos.first, height: 350, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _name ?? '',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(_birthdate != null ? _calculateAge(_birthdate!).toString() : '', style: const TextStyle(fontSize: 24, color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_city != null && _city!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text(_city!, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(_bio ?? '', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedInterests
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: Text(e, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
