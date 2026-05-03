import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/story_model.dart';
import '../models/anonymous_chat_model.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  static const int freeSwipeLimit = 30;

  Future<void> updateUserProfile(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // --- DISCOVER & SMART MATCHING ---
  
  Future<void> markProfileSeen(String currentUserId, String targetUserId) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('seenProfiles')
        .doc(targetUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<Set<String>> _getSeenProfileIds(String currentUserId) async {
    final snapshot = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('seenProfiles')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<List<UserModel>> getDiscoverUsersScored(
    String currentUserId,
    UserModel currentUserModel, {
    DocumentSnapshot? startAfter,
    int? minAgeFilter,
    int? maxAgeFilter,
    String? genderFilter,
  }) async {
    final blocked = currentUserModel.blockedUsers;
    final seenIds = await _getSeenProfileIds(currentUserId);
    
    // Add explicitly blocked and seen to the exclusion map securely
    final excludedIds = {...blocked, ...seenIds, currentUserId};

    Query query = _db.collection('users').limit(20);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Retrieve batch
    final snapshot = await query.get();
    List<UserModel> users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((u) => !excludedIds.contains(u.uid))
        .toList();

    // Preferences Filter locally
    final minAge = minAgeFilter ?? currentUserModel.minAgePref;
    final maxAge = maxAgeFilter ?? currentUserModel.maxAgePref;
    final genderPref = genderFilter ?? currentUserModel.genderPref;

    if (genderPref != null && genderPref != 'Any') {
      users = users.where((u) => u.gender == genderPref).toList();
    }
    users = users.where((u) => u.age >= minAge && u.age <= maxAge).toList();
    // Distance check could go here if using Geolocator logic

    // Sort by interest overlap score (descending)
    users.sort((a, b) {
      final scoreA = currentUserModel.interests.where((i) => a.interests.contains(i)).length;
      final scoreB = currentUserModel.interests.where((i) => b.interests.contains(i)).length;
      return scoreB.compareTo(scoreA);
    });

    return users.take(20).toList();
  }

  // --- ANONYMOUS CHAT MATCHMAKING ---

  Future<String?> enterAnonymousQueue(String userId) async {
    final queueRef = _db.collection('anonymousQueue');
    final chatRef = _db.collection('anonymousChats');

    // 1. Check if anyone is waiting
    final waitingSnapshot = await queueRef
        .where('userId', isNotEqualTo: userId)
        .orderBy('userId')
        .limit(1)
        .get();

    if (waitingSnapshot.docs.isNotEmpty) {
      // Form match
      final matchDoc = waitingSnapshot.docs.first;
      final otherUserId = matchDoc.data()['userId'] as String;

      // Delete from queue
      await queueRef.doc(matchDoc.id).delete();

      // Create new anonymous chat session
      final newChatDoc = chatRef.doc();
      final chatModel = AnonymousChatModel(
        id: newChatDoc.id,
        user1Id: otherUserId,
        user2Id: userId,
        status: 'connected',
        createdAt: DateTime.now(),
      );

      await newChatDoc.set(chatModel.toMap());
      return newChatDoc.id;
    } else {
      // 2. Put self into queue
      final myQueueDoc = await queueRef.where('userId', isEqualTo: userId).get();
      if (myQueueDoc.docs.isEmpty) {
        await queueRef.add({'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
      }
      return null; // Signals we are waiting
    }
  }

  Future<void> leaveAnonymousQueue(String userId) async {
    final docs = await _db.collection('anonymousQueue').where('userId', isEqualTo: userId).get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  Stream<AnonymousChatModel?> watchAnonymousChatAvailability(String userId) {
    return _db.collection('anonymousChats')
        .where('status', isEqualTo: 'connected')
        // Firestore logical OR requires multiple queries or local filtering, 
        // watching all and filtering local is acceptable for limited open chats
        .snapshots()
        .map((snapshot) {
           final docs = snapshot.docs.where((d) => d['user1Id'] == userId || d['user2Id'] == userId).toList();
           if (docs.isNotEmpty) {
             return AnonymousChatModel.fromMap(docs.first.data(), docs.first.id);
           }
           return null;
        });
  }

  Future<void> revealAnonymousProfile(String chatId, String userId, bool isUser1) async {
    await _db.collection('anonymousChats').doc(chatId).update({
      if (isUser1) 'user1Revealed': true else 'user2Revealed': true
    });
  }

  Future<void> closeAnonymousChat(String chatId) async {
    await _db.collection('anonymousChats').doc(chatId).update({
      'status': 'closed'
    });
  }

  // --- STORIES ---

  Stream<List<StoryModel>> getStories() {
    final now = Timestamp.now();
    return _db
        .collection('stories')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> postStory({
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String text,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    await _db.collection('stories').add({
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'photoUrl': photoUrl,
      'timestamp': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'likes': [],
    });
  }

  Future<void> toggleStoryLike(String storyId, String userId) async {
    final doc = _db.collection('stories').doc(storyId);
    final snapshot = await doc.get();
    final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await doc.update({'likes': likes});
  }

  Future<void> rsvpToEvent(String eventId, String userId) async {
    await _db.collection('events').doc(eventId).update({
      'attendees': FieldValue.arrayUnion([userId]),
    });
  }

  // --- SWIPE LIMITS & BLOCKS ---

  Future<bool> canSwipe(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return true;
    final data = doc.data()!;
    if (data['lastSwipeDate'] != today) {
      await _db.collection('users').doc(userId).update({
        'swipesToday': 0,
        'lastSwipeDate': today,
      });
      return true;
    }
    return (data['swipesToday'] ?? 0) < freeSwipeLimit;
  }

  Future<void> incrementSwipeCount(String userId) async {
    await _db.collection('users').doc(userId).update({
      'swipesToday': FieldValue.increment(1),
    });
  }

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    await _db.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> reportUser(
      String reporterId, String targetUserId, String reason) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'targetUserId': targetUserId,
      'reason': reason,
      'timestamp': Timestamp.now(),
    });
  }

  // ===========================
  // --- REFERRAL SYSTEM ---
  // ===========================

  /// Processes a referral. Called ONCE after auth completes in root_screen.
  /// [refValue] is the ref= parameter from the deep link (a Firebase UID)
  /// or a short referralCode entered manually.
  Future<bool> processReferralRegistration(String refValue, String newUserId) async {
    debugPrint('[REFERRAL] ▶ START processReferralRegistration');
    debugPrint('[REFERRAL]   refValue=$refValue, newUserId=$newUserId');

    try {
      // 1. Prevent self-referral
      if (refValue == newUserId) {
        debugPrint('[REFERRAL] ✖ Blocked: self-referral');
        return false;
      }

      // 2. Check if this user was already referred (dedup by invitedBy field)
      final newUserDoc = await _db.collection('users').doc(newUserId).get();
      if (newUserDoc.exists) {
        final existingInviter = newUserDoc.data()?['invitedBy'];
        if (existingInviter != null && existingInviter.toString().isNotEmpty) {
          debugPrint('[REFERRAL] ✖ Blocked: user $newUserId already invited by $existingInviter');
          return false;
        }
      }

      // 3. [Device Check Removed per request]

      // 4. Find the referrer — try UID first, then referralCode field
      String? referrerId;
      
      // 4a. Direct UID lookup (invite links use ref=user.uid)
      final directDoc = await _db.collection('users').doc(refValue).get();
      if (directDoc.exists) {
        referrerId = directDoc.id;
        debugPrint('[REFERRAL] ✓ Found referrer by UID: $referrerId');
      } else {
        // 4b. Query by referralCode field (manual entry)
        debugPrint('[REFERRAL]   UID not found, trying referralCode query...');
        final snapshot = await _db
            .collection('users')
            .where('referralCode', isEqualTo: refValue)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          referrerId = snapshot.docs.first.id;
          debugPrint('[REFERRAL] ✓ Found referrer by referralCode: $referrerId');
        }
      }

      if (referrerId == null) {
        debugPrint('[REFERRAL] ✖ No user found for ref=$refValue');
        return false;
      }

      // 5. Check if this exact pair was already processed (subcollection dedup)
      final existingInvite = await _db
          .collection('users')
          .doc(referrerId)
          .collection('invitedUsers')
          .doc(newUserId)
          .get();
      if (existingInvite.exists) {
        debugPrint('[REFERRAL] ✖ Blocked: invite pair already processed');
        return false;
      }

      // 6. ALL CHECKS PASSED — Apply credits atomically
      debugPrint('[REFERRAL] ✓ All checks passed. Applying credits...');

      // 6a. Credit the referrer (+1)
      await _db.collection('users').doc(referrerId).update({
        'inviteCredits': FieldValue.increment(1),
      });
      debugPrint('[REFERRAL] ✓ +1 credit to referrer $referrerId');

      // 6b. Credit the new user (+1) and mark invitedBy
      await _db.collection('users').doc(newUserId).set({
        'inviteCredits': FieldValue.increment(1),
        'invitedBy': referrerId,
      }, SetOptions(merge: true));
      debugPrint('[REFERRAL] ✓ +1 credit to new user $newUserId, invitedBy=$referrerId');

      // 6c. Store in referrer's invitedUsers subcollection (for UI + dedup)
      final newUserName = newUserDoc.data()?['name'] ?? 'User';
      await _db
          .collection('users')
          .doc(referrerId)
          .collection('invitedUsers')
          .doc(newUserId)
          .set({
        'userId': newUserId,
        'name': newUserName,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[REFERRAL] ✓ Stored in invitedUsers subcollection');

      // 7. Send notification to referrer
      try {
        await _sendReferralNotification(referrerId, newUserId);
        debugPrint('[REFERRAL] ✓ Notification sent');
      } catch (e) {
        debugPrint('[REFERRAL] ⚠ Notification failed: $e');
      }

      debugPrint('[REFERRAL] ▶ DONE — referral processed successfully');
      return true;
    } catch (e) {
      debugPrint('[REFERRAL] ✖ ERROR: $e');
      return false;
    }
  }

  /// Stream of invited users for display in the UI
  Stream<List<Map<String, dynamic>>> getInvitedUsersStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('invitedUsers')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Sends a push notification to the referrer when a new user joins via their invite link
  Future<void> _sendReferralNotification(String referrerId, String newUserId) async {
    final newUserDoc = await _db.collection('users').doc(newUserId).get();
    final newUserName = newUserDoc.data()?['name'] ?? 'Kimdir';

    final referrerDoc = await _db.collection('users').doc(referrerId).get();
    final referrerToken = referrerDoc.data()?['fcmToken'] as String?;

    if (referrerToken != null && referrerToken.isNotEmpty) {
      await _db.collection('notifications').add({
        'userId': referrerId,
        'type': 'referral_joined',
        'title': '🎉 Do\'stingiz qo\'shildi!',
        'body': '$newUserName sizning taklif havolangiz orqali qo\'shildi. +1 kredit!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    final notificationService = NotificationService();
    await notificationService.showReferralNotification(newUserName);
  }
}
