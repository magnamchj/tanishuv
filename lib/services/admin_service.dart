import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Future<void> createEvent({
    required String title,
    required String description,
    required String locationName,
    required double latitude,
    required double longitude,
    required DateTime time,
    required bool premiumOnly,
    String? category,
  }) async {
    await _db.collection('events').add({
      'title': title,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'time': Timestamp.fromDate(time),
      'premiumOnly': premiumOnly,
      'attendees': [],
      'category': category,
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  Future<void> banUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isBanned': true});
  }

  Future<void> seedDummyData() async {
    final batch = _db.batch();

    // Exactly 10 Female Demo Profiles scaling realistically for matching criteria!
    final users = [
      {
        'name': 'Madina',
        'nickname': 'madina_uz',
        'photoUrl': 'https://randomuser.me/api/portraits/women/1.jpg',
        'age': 24,
        'gender': 'Female',
        'city': 'Tashkent',
        'interests': ['Travel', 'Music', 'Fitness'],
        'languages': ['Uzbek', 'English'],
        'relationshipGoal': 'Long-term relationship',
        'isAnonymous': false,
        'isPremium': true,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Love traveling and coffee ☕ Exploring the world!',
        'photos': [
          'https://randomuser.me/api/portraits/women/1.jpg',
          'https://randomuser.me/api/portraits/women/11.jpg',
          'https://randomuser.me/api/portraits/women/21.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2002, 5, 14)),
      },
      {
        'name': 'Shahlo',
        'nickname': 'shahlo_88',
        'photoUrl': 'https://randomuser.me/api/portraits/women/2.jpg',
        'age': 28,
        'gender': 'Female',
        'city': 'Samarkand',
        'interests': ['Photography', 'Music', 'Travel', 'Movies'],
        'languages': ['Uzbek', 'Russian'],
        'relationshipGoal': 'Casual dates',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Capturing moments through my lens 📸 Let\'s go to a movie.',
        'photos': [
          'https://randomuser.me/api/portraits/women/2.jpg',
          'https://randomuser.me/api/portraits/women/12.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(1998, 1, 10)),
      },
      {
        'name': 'Nilufar',
        'nickname': 'nilu_99',
        'photoUrl': 'https://randomuser.me/api/portraits/women/3.jpg',
        'age': 22,
        'gender': 'Female',
        'city': 'Tashkent',
        'interests': ['Fitness', 'Movies', 'Music'],
        'languages': ['Uzbek', 'English', 'Turkish'],
        'relationshipGoal': 'New friends',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Gym addict working on myself 💪 Always down for good food.',
        'photos': [
          'https://randomuser.me/api/portraits/women/3.jpg',
          'https://randomuser.me/api/portraits/women/13.jpg',
          'https://randomuser.me/api/portraits/women/33.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2004, 3, 22)),
      },
      {
        'name': 'Dilnoza',
        'nickname': 'dilya_d',
        'photoUrl': 'https://randomuser.me/api/portraits/women/4.jpg',
        'age': 26,
        'gender': 'Female',
        'city': 'Bukhara',
        'interests': ['Travel', 'Photography', 'Art'],
        'languages': ['Uzbek', 'Russian'],
        'relationshipGoal': 'Long-term relationship',
        'isAnonymous': false,
        'isPremium': true,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Art lovers are my favorite people 🎨 Let\'s visit a gallery.',
        'photos': [
          'https://randomuser.me/api/portraits/women/4.jpg',
          'https://randomuser.me/api/portraits/women/14.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2000, 8, 15)),
      },
      {
        'name': 'Sevara',
        'nickname': 'seva_12',
        'photoUrl': 'https://randomuser.me/api/portraits/women/5.jpg',
        'age': 29,
        'gender': 'Female',
        'city': 'Tashkent',
        'interests': ['Music', 'Fitness', 'Coffee'],
        'languages': ['Uzbek', 'English'],
        'relationshipGoal': 'Casual dates',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'I know the best coffee spots in the city ☕ Let\'s debate music over a cappuccino.',
        'photos': [
          'https://randomuser.me/api/portraits/women/5.jpg',
          'https://randomuser.me/api/portraits/women/15.jpg',
          'https://randomuser.me/api/portraits/women/25.jpg',
          'https://randomuser.me/api/portraits/women/35.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(1997, 11, 2)),
      },
      {
        'name': 'Guzal',
        'nickname': 'guzal_o',
        'photoUrl': 'https://randomuser.me/api/portraits/women/6.jpg',
        'age': 23,
        'gender': 'Female',
        'city': 'Samarkand',
        'interests': ['Travel', 'Movies', 'Dancing'],
        'languages': ['Uzbek', 'Russian', 'Arabic'],
        'relationshipGoal': 'Not sure yet',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Living for the weekend 💃 Love traveling to historical places.',
        'photos': [
          'https://randomuser.me/api/portraits/women/6.jpg',
          'https://randomuser.me/api/portraits/women/16.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2003, 6, 19)),
      },
      {
        'name': 'Ziyoda',
        'nickname': 'ziyoda_m',
        'photoUrl': 'https://randomuser.me/api/portraits/women/7.jpg',
        'age': 27,
        'gender': 'Female',
        'city': 'Tashkent',
        'interests': ['Photography', 'Travel', 'Reading'],
        'languages': ['Uzbek', 'English'],
        'relationshipGoal': 'Long-term relationship',
        'isAnonymous': false,
        'isPremium': true,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Books + Coffee + Cozy cafes = Perfection.',
        'photos': [
          'https://randomuser.me/api/portraits/women/7.jpg',
          'https://randomuser.me/api/portraits/women/17.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(1999, 12, 5)),
      },
      {
        'name': 'Kamila',
        'nickname': 'kami_la',
        'photoUrl': 'https://randomuser.me/api/portraits/women/8.jpg',
        'age': 21,
        'gender': 'Female',
        'city': 'Bukhara',
        'interests': ['Music', 'Fitness'],
        'languages': ['Uzbek'],
        'relationshipGoal': 'New friends',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': false,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Looking for genuine connections.',
        'photos': [
          'https://randomuser.me/api/portraits/women/8.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2005, 4, 30)),
      },
      {
        'name': 'Lola',
        'nickname': 'lola_k',
        'photoUrl': 'https://randomuser.me/api/portraits/women/9.jpg',
        'age': 25,
        'gender': 'Female',
        'city': 'Tashkent',
        'interests': ['Travel', 'Movies', 'Music', 'Fitness'],
        'languages': ['Uzbek', 'Russian', 'English'],
        'relationshipGoal': 'Casual dates',
        'isAnonymous': false,
        'isPremium': false,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Let\'s go on a road trip. The playlist is already made. 🚗',
        'photos': [
          'https://randomuser.me/api/portraits/women/9.jpg',
          'https://randomuser.me/api/portraits/women/19.jpg',
          'https://randomuser.me/api/portraits/women/29.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(2001, 7, 12)),
      },
      {
        'name': 'Maftuna',
        'nickname': 'maftuna_00',
        'photoUrl': 'https://randomuser.me/api/portraits/women/10.jpg',
        'age': 30,
        'gender': 'Female',
        'city': 'Samarkand',
        'interests': ['Cooking', 'Travel', 'Photography'],
        'languages': ['Uzbek', 'Russian'],
        'relationshipGoal': 'Long-term relationship',
        'isAnonymous': false,
        'isPremium': true,
        'isVerified': true,
        'isAdmin': false,
        'blockedUsers': [],
        'swipesToday': 0,
        'bio': 'Foodie looking for someone with good taste.',
        'photos': [
          'https://randomuser.me/api/portraits/women/10.jpg',
          'https://randomuser.me/api/portraits/women/20.jpg',
          'https://randomuser.me/api/portraits/women/30.jpg'
        ],
        'profileCompleted': true,
        'birthdate': Timestamp.fromDate(DateTime(1996, 9, 21)),
      },
    ];

    for (int i = 0; i < users.length; i++) {
      final ref = _db.collection('users').doc('female_demo_$i');
      batch.set(ref, users[i]);
    }

    // Dummy stories
    final stories = [
      {
        'userId': 'female_demo_0',
        'userName': 'Madina',
        'userPhotoUrl': 'https://randomuser.me/api/portraits/women/1.jpg',
        'text': 'Who wants to grab a coffee today? ☕',
        'photoUrl': null,
        'timestamp': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'likes': [],
      },
      {
        'userId': 'female_demo_3',
        'userName': 'Dilnoza',
        'userPhotoUrl': 'https://randomuser.me/api/portraits/women/4.jpg',
        'text': 'Finally visited the new art gallery! Beautiful 🎨',
        'photoUrl': null,
        'timestamp': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 20))),
        'likes': [],
      },
    ];

    for (int i = 0; i < stories.length; i++) {
      final ref = _db.collection('stories').doc('demo_story_$i');
      batch.set(ref, stories[i]);
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final snap = await _db
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    });
  }
}
