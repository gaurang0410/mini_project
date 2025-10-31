// lib/screens/feature_flags_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/user_state.dart';

class FeatureFlagsScreen extends StatefulWidget {
  const FeatureFlagsScreen({super.key});

  @override
  State<FeatureFlagsScreen> createState() => _FeatureFlagsScreenState();
}

class _FeatureFlagsScreenState extends State<FeatureFlagsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _admin = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _toggleFlag(String flagName, bool currentValue) async {
    if (_admin == null) return;
    final newValue = !currentValue;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateFeatureFlag(flagName, newValue);
      await _firestoreService.addAuditLog(
        adminUid: _admin!.uid,
        action: 'TOGGLE_FEATURE_FLAG',
        targetUserEmail: 'N/A (App Config)',
        targetUid: 'app_config/features',
        details: {flagName: newValue},
      );

      if (context.mounted) {
        await Provider.of<UserState>(context, listen: false).refreshUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$flagName set to $newValue'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating flag: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags'),
      ),
      body: Stack(
        children: [
          Consumer<UserState>(
            builder: (context, userState, child) {
              final bool newUiFlag = userState.isNewUiEnabled;

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    'Toggle app features in real-time. Changes will apply to all users on their next app start.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Divider(height: 30),

                  SwitchListTile(
                    title: const Text('Enable New Home Screen UI', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Toggles the new UI color on Home page (Example)'),
                    value: newUiFlag,
                    onChanged: (newValue) {
                      _toggleFlag('isNewUIEnabled', newUiFlag);
                    },
                    secondary: Icon(newUiFlag ? Icons.design_services : Icons.design_services_outlined),
                  ),
                  // Add more flags here if needed
                ],
              );
            },
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}