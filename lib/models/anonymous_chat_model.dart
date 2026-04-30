import 'package:cloud_firestore/cloud_firestore.dart';

class AnonymousChatModel {
  final String id;
  final String? user1Id;
  final String? user2Id;
  final String status; // 'waiting', 'connected', 'closed'
  final DateTime createdAt;
  final bool user1Revealed;
  final bool user2Revealed;

  AnonymousChatModel({
    required this.id,
    this.user1Id,
    this.user2Id,
    required this.status,
    required this.createdAt,
    this.user1Revealed = false,
    this.user2Revealed = false,
  });

  factory AnonymousChatModel.fromMap(Map<String, dynamic> data, String id) {
    return AnonymousChatModel(
      id: id,
      user1Id: data['user1Id'],
      user2Id: data['user2Id'],
      status: data['status'] ?? 'waiting',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      user1Revealed: data['user1Revealed'] ?? false,
      user2Revealed: data['user2Revealed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'user1Revealed': user1Revealed,
      'user2Revealed': user2Revealed,
    };
  }
}
