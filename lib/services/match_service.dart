import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swipe_model.dart';
import 'db_service.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Future<bool> recordSwipe(String fromUserId, String toUserId, bool isLike) async {
    // Record into seenProfiles to omit from future searches universally
    await DatabaseService().markProfileSeen(fromUserId, toUserId);

    // Record the specific swipe
    final swipe = SwipeModel(
      fromUserId: fromUserId,
      toUserId: toUserId,
      isLike: isLike,
      timestamp: DateTime.now(),
    );

    await _db.collection('swipes').add(swipe.toMap());

    // Check for match mutually
    if (isLike) {
      final reciprocalSwipe = await _db.collection('swipes')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: fromUserId)
        .where('isLike', isEqualTo: true)
        .get();

      if (reciprocalSwipe.docs.isNotEmpty) {
        // Form a match using sorted deterministic ID logic
        final users = [fromUserId, toUserId];
        users.sort();
        final matchId = '${users[0]}_${users[1]}';

        final matchDocData = await _db.collection('matches').doc(matchId).get();
        if (!matchDocData.exists) {
          await _db.collection('matches').doc(matchId).set({
            'users': [fromUserId, toUserId],
            'matchTime': DateTime.now(),
            'chatId': matchId,
          });
          return true;
        }
      }
    }
    return false;
  }
}
