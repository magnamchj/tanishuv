import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String fromUserId;
  final String text;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final String? replyToId;
  final String? replyToText;
  final String? replyToUserId;
  final List<String> reactions;
  final int? audioDuration;

  MessageModel({
    required this.id,
    required this.fromUserId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
    this.isRead = false,
    this.replyToId,
    this.replyToText,
    this.replyToUserId,
    this.reactions = const [],
    this.audioDuration,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      fromUserId: data['fromUserId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: data['type'] ?? 'text',
      isRead: data['isRead'] ?? false,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToUserId: data['replyToUserId'],
      reactions: List<String>.from(data['reactions'] ?? []),
      audioDuration: data['audioDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToUserId': replyToUserId,
      'reactions': reactions,
      'audioDuration': audioDuration,
    };
  }
}
