import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const String demoUsersJson = '''
[
{
"id": "demo_user_1",
"name": "Madina",
"age": 24,
"gender": "female",
"city": "Tashkent",
"bio": "Coffee lover ☕ and travel enthusiast. Always looking for new places to explore.",
"interests": ["Travel","Music","Photography","Fitness"],
"languages": ["Uzbek","Russian","English"],
"height": 167,
"relationshipGoal": "Serious relationship",
"photos": [
"https://randomuser.me/api/portraits/women/11.jpg",
"https://randomuser.me/api/portraits/women/12.jpg",
"https://randomuser.me/api/portraits/women/13.jpg"
]
},
{
"id": "demo_user_2",
"name": "Aziza",
"age": 22,
"gender": "female",
"city": "Samarkand",
"bio": "Love sunsets, books and good conversations.",
"interests": ["Books","Travel","Art","Movies"],
"languages": ["Uzbek","Russian"],
"height": 164,
"relationshipGoal": "Dating",
"photos": [
"https://randomuser.me/api/portraits/women/21.jpg",
"https://randomuser.me/api/portraits/women/22.jpg",
"https://randomuser.me/api/portraits/women/23.jpg"
]
},
{
"id": "demo_user_3",
"name": "Malika",
"age": 26,
"gender": "female",
"city": "Bukhara",
"bio": "Photographer 📷 who loves adventure and nature.",
"interests": ["Photography","Nature","Travel","Hiking"],
"languages": ["Uzbek","English"],
"height": 170,
"relationshipGoal": "Serious relationship",
"photos": [
"https://randomuser.me/api/portraits/women/31.jpg",
"https://randomuser.me/api/portraits/women/32.jpg",
"https://randomuser.me/api/portraits/women/33.jpg"
]
},
{
"id": "demo_user_4",
"name": "Shahnoza",
"age": 23,
"gender": "female",
"city": "Tashkent",
"bio": "Gym girl 💪 and foodie. Let’s find the best cafe in the city.",
"interests": ["Fitness","Food","Travel","Music"],
"languages": ["Uzbek","Russian"],
"height": 168,
"relationshipGoal": "Dating",
"photos": [
"https://randomuser.me/api/portraits/women/41.jpg",
"https://randomuser.me/api/portraits/women/42.jpg",
"https://randomuser.me/api/portraits/women/43.jpg"
]
},
{
"id": "demo_user_5",
"name": "Dilnoza",
"age": 25,
"gender": "female",
"city": "Namangan",
"bio": "Simple girl who enjoys nature, movies and good vibes.",
"interests": ["Movies","Nature","Music","Travel"],
"languages": ["Uzbek"],
"height": 165,
"relationshipGoal": "Friendship",
"photos": [
"https://randomuser.me/api/portraits/women/51.jpg",
"https://randomuser.me/api/portraits/women/52.jpg",
"https://randomuser.me/api/portraits/women/53.jpg"
]
},
{
"id": "demo_user_6",
"name": "Sabina",
"age": 27,
"gender": "female",
"city": "Tashkent",
"bio": "Designer 🎨 who loves art galleries and city walks.",
"interests": ["Art","Design","Photography","Travel"],
"languages": ["Uzbek","Russian","English"],
"height": 169,
"relationshipGoal": "Serious relationship",
"photos": [
"https://randomuser.me/api/portraits/women/61.jpg",
"https://randomuser.me/api/portraits/women/62.jpg",
"https://randomuser.me/api/portraits/women/63.jpg"
]
},
{
"id": "demo_user_7",
"name": "Gulnoza",
"age": 21,
"gender": "female",
"city": "Andijan",
"bio": "Student who loves music and late night talks.",
"interests": ["Music","Movies","Travel","Food"],
"languages": ["Uzbek","Russian"],
"height": 162,
"relationshipGoal": "Not sure yet",
"photos": [
"https://randomuser.me/api/portraits/women/71.jpg",
"https://randomuser.me/api/portraits/women/72.jpg",
"https://randomuser.me/api/portraits/women/73.jpg"
]
},
{
"id": "demo_user_8",
"name": "Zarina",
"age": 28,
"gender": "female",
"city": "Samarkand",
"bio": "Businesswoman who loves traveling the world.",
"interests": ["Travel","Business","Fitness","Books"],
"languages": ["Uzbek","Russian","English"],
"height": 171,
"relationshipGoal": "Serious relationship",
"photos": [
"https://randomuser.me/api/portraits/women/81.jpg",
"https://randomuser.me/api/portraits/women/82.jpg",
"https://randomuser.me/api/portraits/women/83.jpg"
]
},
{
"id": "demo_user_9",
"name": "Nigina",
"age": 24,
"gender": "female",
"city": "Fergana",
"bio": "Movie lover 🎬 and travel dreamer.",
"interests": ["Movies","Travel","Music","Photography"],
"languages": ["Uzbek","Russian"],
"height": 166,
"relationshipGoal": "Dating",
"photos": [
"https://randomuser.me/api/portraits/women/91.jpg",
"https://randomuser.me/api/portraits/women/92.jpg",
"https://randomuser.me/api/portraits/women/93.jpg"
]
},
{
"id": "demo_user_10",
"name": "Laylo",
"age": 23,
"gender": "female",
"city": "Tashkent",
"bio": "I like good coffee, sunsets and spontaneous trips.",
"interests": ["Travel","Coffee","Photography","Nature"],
"languages": ["Uzbek","English"],
"height": 167,
"relationshipGoal": "Dating",
"photos": [
"https://randomuser.me/api/portraits/women/101.jpg",
"https://randomuser.me/api/portraits/women/102.jpg",
"https://randomuser.me/api/portraits/women/103.jpg"
]
}
]
''';

class DemoUserSeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Future<int> seedDemoUsers() async {
    int addedCount = 0;
    try {
      final List<dynamic> parsedList = jsonDecode(demoUsersJson);

      for (var user in parsedList) {
        final Map<String, dynamic> userData = user as Map<String, dynamic>;
        final String docId = userData['id'];

        final docRef = _db.collection('users').doc(docId);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          // Normalize the data for UserModel
          final String imageUrl = (userData['photos'] != null && (userData['photos'] as List).isNotEmpty) ? userData['photos'][0] : '';

          final finalData = {
            'nickname': userData['name'].toString().toLowerCase(),
            'photoUrl': imageUrl,
            'isAnonymous': false,
            'isPremium': true,
            'isVerified': true,
            'isAdmin': false,
            'blockedUsers': [],
            'swipesToday': 0,
            'profileCompleted': true,
            'isDemo': true,
            'createdAt': FieldValue.serverTimestamp(),
            // Merge in the root fields
            ...userData,
          };

          await docRef.set(finalData);
          addedCount++;
        }
      }
      return addedCount;
    } catch (e) {
      print('Seeding Error: $e');
      return 0;
    }
  }
}
