class SwipeModel {
  final String fromUserId;
  final String toUserId;
  final bool isLike;
  final DateTime timestamp;

  SwipeModel({
    required this.fromUserId,
    required this.toUserId,
    required this.isLike,
    required this.timestamp,
  });

  factory SwipeModel.fromMap(Map<String, dynamic> data) {
    return SwipeModel(
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      isLike: data['isLike'] ?? false,
      timestamp: data['timestamp'] != null ? data['timestamp'].toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'isLike': isLike,
      'timestamp': timestamp,
    };
  }
}
