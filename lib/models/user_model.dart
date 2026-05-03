import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String nickname;
  final String photoUrl;
  final int age;
  final String gender;
  final List<String> interests;
  final bool isAnonymous;
  final bool isVerified;
  final bool isAdmin;
  final String? bio;
  final GeoPoint? location;
  final String? fcmToken;
  final List<String> blockedUsers;
  final int swipesToday;
  final String? lastSwipeDate;
  
  // New Setup & Profile Fields
  final bool profileCompleted;
  final DateTime? birthdate;
  final String? city;
  final double? height;
  final List<String> languages;
  final String? lookingFor;
  final String? relationshipGoal;
  final List<String> photos;

  // Preferences
  final int minAgePref;
  final int maxAgePref;
  final String? genderPref;
  final double distancePref;
  
  // Referral System
  final String? referralCode;
  final String? invitedBy;
  final int inviteCredits;

  bool get canSeeLikes => inviteCredits >= 3;
  bool get canOpenProfiles => inviteCredits >= 5;
  bool get canAnonymousChat => inviteCredits >= 1;

  UserModel({
    required this.uid,
    required this.name,
    required this.nickname,
    required this.photoUrl,
    required this.age,
    required this.gender,
    required this.interests,
    required this.isAnonymous,
    this.isVerified = false,
    this.isAdmin = false,
    this.bio,
    this.location,
    this.fcmToken,
    this.blockedUsers = const [],
    this.swipesToday = 0,
    this.lastSwipeDate,
    this.profileCompleted = false,
    this.birthdate,
    this.city,
    this.height,
    this.languages = const [],
    this.lookingFor,
    this.relationshipGoal,
    this.photos = const [],
    this.minAgePref = 18,
    this.maxAgePref = 60,
    this.genderPref,
    this.distancePref = 50.0,
    this.referralCode,
    this.invitedBy,
    this.inviteCredits = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      nickname: data['nickname'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      age: data['age'] ?? 18,
      gender: data['gender'] ?? 'Unknown',
      interests: List<String>.from(data['interests'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      bio: data['bio'],
      location: data['location'],
      fcmToken: data['fcmToken'],
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      swipesToday: data['swipesToday'] ?? 0,
      lastSwipeDate: data['lastSwipeDate'],
      profileCompleted: data['profileCompleted'] ?? false,
      birthdate: data['birthdate'] != null ? (data['birthdate'] as Timestamp).toDate() : null,
      city: data['city'],
      height: data['height'] != null ? (data['height'] as num).toDouble() : null,
      languages: List<String>.from(data['languages'] ?? []),
      lookingFor: data['lookingFor'],
      relationshipGoal: data['relationshipGoal'],
      photos: List<String>.from(data['photos'] ?? []),
      minAgePref: data['minAgePref'] ?? 18,
      maxAgePref: data['maxAgePref'] ?? 60,
      genderPref: data['genderPref'],
      distancePref: data['distancePref'] != null ? (data['distancePref'] as num).toDouble() : 50.0,
      referralCode: data['referralCode'],
      invitedBy: data['invitedBy'],
      inviteCredits: data['inviteCredits'] ?? data['bonusCoins'] ?? 0, // Fallback to bonusCoins for old data
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'interests': interests,
      'isAnonymous': isAnonymous,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'bio': bio,
      'location': location,
      'fcmToken': fcmToken,
      'blockedUsers': blockedUsers,
      'swipesToday': swipesToday,
      'lastSwipeDate': lastSwipeDate,
      'profileCompleted': profileCompleted,
      if (birthdate != null) 'birthdate': Timestamp.fromDate(birthdate!),
      'city': city,
      'height': height,
      'languages': languages,
      'lookingFor': lookingFor,
      'relationshipGoal': relationshipGoal,
      'photos': photos,
      'minAgePref': minAgePref,
      'maxAgePref': maxAgePref,
      'genderPref': genderPref,
      'distancePref': distancePref,
      'referralCode': referralCode,
      'invitedBy': invitedBy,
      'inviteCredits': inviteCredits,
    };
  }

  int interestOverlapWith(UserModel other) {
    return interests.where((i) => other.interests.contains(i)).length;
  }
}
