import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/payment_service.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentService =
        Provider.of<PaymentService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tanishuv Premium',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Crown icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.shade300,
                          Colors.amber.shade800,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium,
                        size: 56, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Go Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Get 10x more matches',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 32),
                // Features
                ..._features.map((feature) => _buildFeatureRow(
                    feature['icon'] as IconData,
                    feature['title'] as String,
                    feature['desc'] as String)),
                const SizedBox(height: 32),
                // Subscription plans
                _buildPlanCard(
                  context: context,
                  title: 'Daily',
                  price: '1,000 UZS',
                  period: 'per day',
                  color: Colors.blueGrey,
                  onTap: () =>
                      paymentService.initiatePaymeCheckout(userId, 'daily'),
                ),
                const SizedBox(height: 12),
                _buildPlanCard(
                  context: context,
                  title: 'Weekly',
                  price: '5,000 UZS',
                  period: 'per week',
                  color: Colors.purple.shade800,
                  onTap: () =>
                      paymentService.initiatePaymeCheckout(userId, 'weekly'),
                ),
                const SizedBox(height: 12),
                _buildPlanCard(
                  context: context,
                  title: 'Monthly',
                  price: '15,000 UZS',
                  period: 'per month • Best Value',
                  color: Colors.amber.shade800,
                  isBest: true,
                  onTap: () =>
                      paymentService.initiatePaymeCheckout(userId, 'monthly'),
                ),
                const SizedBox(height: 24),
                // Payme logo / notice
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment,
                                color: Colors.white54, size: 16),
                            SizedBox(width: 8),
                            Text('Powered by Payme',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cancel anytime • Secure payment',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.all_inclusive,
      'title': 'Unlimited Swipes',
      'desc': 'Never run out of swipes again',
    },
    {
      'icon': Icons.visibility,
      'title': 'See Who Liked You',
      'desc': 'Skip straight to your admirers',
    },
    {
      'icon': Icons.star,
      'title': 'VIP Event Access',
      'desc': 'Exclusive parties and meetups',
    },
    {
      'icon': Icons.rocket_launch,
      'title': 'Profile Boost',
      'desc': 'Get seen by 10x more people',
    },
    {
      'icon': Icons.tune,
      'title': 'Advanced Filters',
      'desc': 'Filter by interests, location, mood',
    },
  ];

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withOpacity(0.15),
            ),
            child: Icon(icon, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text(desc,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required Color color,
    required VoidCallback onTap,
    bool isBest = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBest ? Colors.amber : color.withOpacity(0.4),
            width: isBest ? 2 : 1,
          ),
          boxShadow: isBest
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: isBest ? Colors.amber : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBest ? Colors.amber : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Subscribe',
                    style: TextStyle(
                      color: isBest ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
