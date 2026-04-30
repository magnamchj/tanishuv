import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'tanishuv');

  Future<void> initiatePaymeCheckout(String userId, String planType) async {
    // In a real app, you would call your backend here to generate a URL.
    // For MVPs without backend webhooks, we mock the redirection.
    final amount = planType == 'daily' ? 1000 : 25000; // UZS
    final fakePaymeUrl = 'https://checkout.paycom.uz/mock?amount=$amount&account=$userId';

    if (await canLaunchUrl(Uri.parse(fakePaymeUrl))) {
      await launchUrl(Uri.parse(fakePaymeUrl), mode: LaunchMode.externalApplication);
      // Simulate successful payment locally (in production, webhook updates this)
      await _simulateSuccessfulPayment(userId, planType);
    }
  }

  Future<void> _simulateSuccessfulPayment(String userId, String planType) async {
    final expiryDate = planType == 'daily' 
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 30));

    await _db.collection('subscriptions').doc(userId).set({
      'userId': userId,
      'isActive': true,
      'expiryDate': expiryDate,
      'planType': planType,
    });
    
    await _db.collection('users').doc(userId).update({
      'isPremium': true,
    });
  }
}
