class SubscriptionModel {
  final String userId;
  final bool isActive;
  final DateTime expiryDate;
  final String planType; // 'daily', 'monthly'

  SubscriptionModel({
    required this.userId,
    required this.isActive,
    required this.expiryDate,
    required this.planType,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
    return SubscriptionModel(
      userId: data['userId'] ?? '',
      isActive: data['isActive'] ?? false,
      expiryDate: data['expiryDate'] != null ? data['expiryDate'].toDate() : DateTime.now(),
      planType: data['planType'] ?? 'daily',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isActive': isActive,
      'expiryDate': expiryDate,
      'planType': planType,
    };
  }
}
