// lib/screens/vip_upsell_screen.dart
import 'package:flutter/material.dart';

class VipUpsellScreen extends StatelessWidget {
  const VipUpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium VIP'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.star, size: 80, color: Colors.amber.shade700),
            const SizedBox(height: 20),
            Text(
              'Unlock All Features!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(Icons.check_circle, 'Access ALL 150+ World Currencies'),
            _buildFeatureItem(Icons.check_circle, 'View Unlimited Conversion History (Future Feature)'),
            _buildFeatureItem(Icons.check_circle, 'Ad-Free Experience (Future Feature)'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // In a real app, this would trigger a payment flow.
                // For this project, VIP is granted by an Admin.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('VIP access is granted by an Administrator.')),
                );
                Navigator.pop(context); // Go back
              },
              style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.amber.shade700,
                 padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: const Text('Learn More (Admin Grants VIP)', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
             Text(
              'VIP status must be enabled by an administrator via the Admin Panel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
