import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Stream<List<MatchModel>> getMatches(String userId) {
    return _db
        .collection('matches')
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['deletedBy_$userId'] != true)
            .map((doc) => MatchModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(
    String chatId,
    String fromUserId,
    String text, {
    String type = 'text',
    String? replyToId,
    String? replyToText,
    String? replyToUserId,
    int? audioDuration,
  }) async {
    final Map<String, dynamic> data = {
      'fromUserId': fromUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'isRead': false,
    };
    if (replyToId != null) {
      data['replyToId'] = replyToId;
      data['replyToText'] = replyToText;
      data['replyToUserId'] = replyToUserId;
    }
    if (audioDuration != null) {
      data['audioDuration'] = audioDuration;
    }
    
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(data);
    // Update last message metadata on the match doc
    await _db.collection('matches').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': fromUserId,
    });
  }

  Future<void> addReaction(String chatId, String messageId, String emoji) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions': FieldValue.arrayUnion([emoji]),
    });
  }

  Future<void> pinMatch(String matchId, String userId) async {
    await _db.collection('matches').doc(matchId).set({
      'pinnedBy_$userId': true,
    }, SetOptions(merge: true));
  }

  Future<void> muteMatch(String matchId, String userId) async {
    await _db.collection('matches').doc(matchId).set({
      'mutedBy_$userId': true,
    }, SetOptions(merge: true));
  }

  Future<void> deleteMatch(String matchId, String userId) async {
    await _db.collection('matches').doc(matchId).set({
      'deletedBy_$userId': true,
    }, SetOptions(merge: true));
  }

  Future<void> setTypingStatus(
      String chatId, String userId, bool isTyping) async {
    await _db.collection('chats').doc(chatId).set(
      {'typing_$userId': isTyping},
      SetOptions(merge: true),
    );
  }

  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.data()?['typing_$otherUserId'] == true);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      if (doc.data()['fromUserId'] != userId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<int> getUnreadCount(String chatId, String userId) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.where((doc) => doc.data()['fromUserId'] != userId).length;
  }

  Future<UserModel?> getMatchedUser(
      String matchId, String currentUserId) async {
    try {
      final matchDoc = await _db.collection('matches').doc(matchId).get();
      if (matchDoc.exists) {
        final users =
            List<String>.from(matchDoc.data()!['users'] ?? []);
        final otherUserId =
            users.firstWhere((id) => id != currentUserId);
        final userDoc =
            await _db.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, userDoc.id);
        }
      }
    } catch (e) {
      // ignore error
    }
    return null;
  }

  Stream<Map<String, dynamic>?> getMatchMetadata(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.data());
  }
}
