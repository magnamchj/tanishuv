class MatchModel {
  final String id;
  final List<String> users;
  final DateTime matchTime;
  final String chatId;

  MatchModel({
    required this.id,
    required this.users,
    required this.matchTime,
    required this.chatId,
  });

  factory MatchModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MatchModel(
      id: documentId,
      users: List<String>.from(data['users'] ?? []),
      matchTime: data['matchTime'] != null ? data['matchTime'].toDate() : DateTime.now(),
      chatId: data['chatId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'matchTime': matchTime,
      'chatId': chatId,
    };
  }
}
